--[[
CStore = class("CStore");

function CStore:initialize( )
	self:CEventAdd( "OnResourceStart", resourceRoot, self.OnStart );
	
	self:AddCommand( "xmrt_upload", self.Upload );
end

function CStore:OnStart( )
	iprint("res init");
end;

function CStore:Upload( )
	iprint("hello");
end;

function CStore:Download( )
	--- ...
end;

g_pStore = CStore();
--]]