local middleclass = {
  _VERSION     = 'middleclass v4.1.1',
  _DESCRIPTION = 'Object Orientation for Lua',
  _URL         = 'https://github.com/kikito/middleclass',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local function _createIndexWrapper(aClass, f)
  if f == nil then
    return aClass.__instanceDict
  else
    return function(self, name)
      local value = aClass.__instanceDict[name]

      if value ~= nil then
        return value
      elseif type(f) == "function" then
        return (f(self, name))
      else
        return f[name]
      end
    end
  end
end

local function _propagateInstanceMethod(aClass, name, f)
  f = name == "__index" and _createIndexWrapper(aClass, f) or f
  aClass.__instanceDict[name] = f

  for subclass in pairs(aClass.subclasses) do
    if rawget(subclass.__declaredMethods, name) == nil then
      _propagateInstanceMethod(subclass, name, f)
    end
  end
end

local function _declareInstanceMethod(aClass, name, f)
  aClass.__declaredMethods[name] = f

  if f == nil and aClass.super then
    f = aClass.super.__instanceDict[name]
  end

  _propagateInstanceMethod(aClass, name, f)
end

local function _tostring(self) return "class " .. self.name end
local function _call(self, ...) return self:new(...) end

local function _createClass(name, super)
	local dict = {}
		dict.__index = dict

	local aClass = 
	{ 
		name = name, 
		super = super, 
		static = {},
		__instanceDict = dict, 
		__declaredMethods = {},
		subclasses = setmetatable( { }, { __mode = 'k' } )
	}

	if super then
		setmetatable(aClass.static, {
		__index = function(_,k)
			local result = rawget(dict,k)
			if result == nil then
				return super.static[k]
			end
			return result
		end
		})
	else
		setmetatable(aClass.static, { __index = function(_,k) return rawget(dict,k) end })
	end

	setmetatable(aClass, { __index = aClass.static, __tostring = _tostring,
	__call = _call, __newindex = _declareInstanceMethod })

	return aClass
end

local function _includeMixin(aClass, mixin)
	assert(type(mixin) == 'table', "mixin must be a table")

	for name, method in pairs(mixin) do
		if name ~= "included" and name ~= "static" then 
			aClass[name] = method
		end
	end

	for name, method in pairs(mixin.static or {}) do
		aClass.static[name] = method
	end

	if type(mixin.included) =="function" then 
		mixin:included(aClass)
	end

	return aClass
end

local DefaultMixin = {
	__tostring   = function(self) return "instance of " .. tostring(self.class) end,

	initialize   = function(self, ...) end,

	isInstanceOf = function(self, aClass)
		return type(aClass) == 'table' and type(self) == 'table' and (self.class == aClass or type(self.class) == 'table' and type(self.class.isSubclassOf) == 'function' and self.class:isSubclassOf(aClass))
	end,

	CEventAdd 	= function ( self, eventName, element, _function, ... )
		self.__bindetFunctions = self.__bindetFunctions or setmetatable( {}, { __mode = 'k' } )
		local bind = self.__bindetFunctions[_function] or function( ... )
			_function( self, ... )
		end
		self.__bindetFunctions[_function] = bind
		addEventHandler( eventName:sub(1,1):lower() .. eventName:sub(2), element, bind, ... )
	end,
	
	CEventRemove = function ( self, eventName, element, _function )
		if removeEventHandler( eventName, element, self.__bindetFunctions[_function] ) then
	
		else
			self:error( 'Can not remove event handler', 2 )
		end
	end,
	
	AddCommand = function ( self, sCommand, _function ) 
		self.__bindetFunctions = self.__bindetFunctions or setmetatable( {}, { __mode = 'k' } )
		local bind = self.__bindetFunctions[_function] or function( ... )
			_function( self, ... )
		end
		self.__bindetFunctions[_function] = bind
		return addCommandHandler( sCommand, bind );
	end,
	
	static = 
	{
		allocate = function(self)
			assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
			return setmetatable({ class = self }, self.__instanceDict)
		end,

		new = function(self, ...)
			assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
			local instance = self:allocate()
			instance:initialize(...)
			return instance
		end,

		subclass = function(self, name)
			assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
			assert(type(name) == "string", "You must provide a name(string) for your class")

			local subclass = _createClass(name, self)

			for methodName, f in pairs(self.__instanceDict) do
				_propagateInstanceMethod(subclass, methodName, f)
			end
			subclass.initialize = function(instance, ...) return self.initialize(instance, ...) end

			self.subclasses[subclass] = true
			self:subclassed(subclass)

			return subclass
		end,

		subclassed = function(self, other) end,

		isSubclassOf = function(self, other)
			return type(other)      == 'table' and type(self.super) == 'table' and ( self.super == other or self.super:isSubclassOf(other) )
		end,

		include = function(self, ...)
			assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
			for _,mixin in ipairs({...}) do 
				_includeMixin(self, mixin) 
			end
			return self
		end
	}
}

function class(name, super)
	assert(type(name) == 'string', "A name (string) is needed for the new class")
	return super and super:subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
end

-- default

Debug 					= outputDebugString;
Chat  					= outputChatBox;

S_EDITOR_DEFAULT_PATH	= "Editor/";
S_ASSETS_DEFAULT_PATH	= ":XMRT_Assets/Resources/Textures/";
S_README_PATH			= "Editor/ReadMe.txt";

function GetCountAssets( )
	local pElements = getElementsByType("XMRT_Assets");
	
	if ( #pElements > 0 ) then
		return pElements[1]:getData("CElement::m_iXMRTAssets");
	else
		return 0;
	end
end

function SizeOf ( pTable )
	local length = 0
    for _ in pairs( pTable ) do length = length + 1 end
    return length
end;

function table.serialize( t ) 
    if not t or type( t ) ~= 'table' then  
        return false 
    end -- if nil or not a table 
    local buf = '{' 
    for key,value in pairs( t ) do 
        local v_type,k_type = type( value ),type( key ) 
        if      v_type ~= 'userdata'    and k_type ~= 'userdata' -- ignore fields and keys witch contain userdata, thread or function 
        and     v_type ~= 'thread'      and k_type ~= 'thread'  
        and     v_type ~= 'function'    and k_type ~= 'function'      
        then 
            if k_type == 'number' then   
                buf = buf .. '['..key..'] = ' 
            else 
                buf = buf .. '[\''..key..'\'] = ' end 
            if v_type == 'table' then  
                value = table.serialize( value )  
            elseif v_type == 'string' then  
                value = '\''..value..'\'' 
            else  
                value = tostring( value )  
            end 
            buf = buf .. value 
            if next( t,key ) then buf = buf..',' end 
        end 
    end 
    return buf .. '}' 
end 

function table.deserialize( s ) 
    if type( s ) == 'string' then 
        local getTableFromString = loadstring( 'return '..s )
		if ( getTableFromString ) then
			local t = getTableFromString( ) 
			if type( t ) ~= 'table' then return false end 
			return t 
		end
    end 
    return false     
end 