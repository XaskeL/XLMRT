CCore = class("CCore");

function CCore:initialize( )
	Debug("XMRT: Sucessfully started.");
	
	-- ReadMe Creation
	if ( not File.exists( S_README_PATH ) ) then
		local pFile = File.new ( S_README_PATH );
		if ( pFile ) then
			pFile:write([[
(X)askeL (M)apping (R)eTexture (T)ool v1.0 			
			
Author: XaskeL ( https://vk.com/xaskel or https://www.youtube.com/c/XaskeL )
Use: /xmrt_load <map file name> & /xmrt_unload to exit from editor.

1. Copy your map file to %DISK_PATH%\MTA San Andreas 1.5\mods\deathmatch\resources\XMRT\Editor
2. Enter command to F8: xmrt_load filename
3. Wait for the game to open the editor menu
4. Select an object with mouse1
5. Select an texture name with menu
6. Select an texture in assets editor
7. Press to apply
8. Press to Save
9. Enter command to F8: xmrt_unload
10. Add new mapfile to map resource
11. Add XMRT_Streamer and XMRT_Assets to your server
12. Run your map file and XMRT_Streamer
13. ...
]]);
			pFile:close();
		end
	end;
	
	-- Commands
	self:AddCommand( "xmrt_load", self.Load );
	self:AddCommand( "xmrt_unload", self.Unload );
	
	-- Mapping XML Parser
	self.m_pXMLMap 			= CXMLMap( );
	
	-- Select Object
	self.m_pSelectedObject 	= NULL;
	self.m_sSelectedTexture = NULL;
	
	self:CEventAdd( "OnClientClick", root, self.OnClick );
	
	-- Editor
	self.m_pTextures		= {}; -- [ int->textureIndex ];
	self.m_pShaders			= {}; -- [ int->textureIndex ];
	self.m_pEditedObjects	= {}; -- [ ptr->object ]; [ int->textureIndex ] = { }; [ string->textureName ] = { }; -- return { diffuse color };
	
	if ( _DEBUG ) then
		addEventHandler("onClientRender", root, function ( )
			dxDrawText( inspect(self.m_pEditedObjects), 700, 200, 0, 0 );
		end );
	end
end;

function CCore:ApplyCustomTexture ( pObject, sTextureName, iIndex, pDiffuse )
	if ( not self.m_pShaders [ iIndex ] ) then
		self.m_pShaders [ iIndex ] = g_pShaderStore:Create("tx_replacer");
	end

	local pObjectInfo = self.m_pEditedObjects [ pObject ];
	
	if ( pObjectInfo ) then
		-- TODO: Проверять, если уже где-то есть эта текстура в другом индексе и очищать +
		-- TODO: Если нет текстур и шейдеров в нужном индексе на объектах, то выгружать их
		for iIndex2, pTextures in pairs ( pObjectInfo ) do
			if ( pTextures [ sTextureName ] and iIndex2 ~= iIndex ) then
				self:ResetCustomTexture( pObject, sTextureName, iIndex2 );
				break;
			end
		end
	
		self:ResetRainBow( );
		
		self.m_pShaders[iIndex]:setValue( "gTexture", g_pCore.m_pTextures [ iIndex ] );
		
		if ( pDiffuse ) then
			self.m_pShaders[iIndex]:setValue( "f4Diffuse", { 
				pDiffuse[1], pDiffuse[2], 
				pDiffuse[3], pDiffuse[4] 
			} );
			
			-- static prelight
			if ( pDiffuse[5] ) then
				self.m_pShaders[iIndex]:setValue( "bStaticPreLight", pDiffuse[5] );
			end
		end
		
		self.m_pShaders[iIndex]:applyToWorldTexture( sTextureName, pObject, true );
	end
end;

function CCore:ResetCustomTexture ( pObject, sTextureName, iIndex )
	local pObjectInfo = self.m_pEditedObjects [ pObject ];

	if ( pObjectInfo and pObjectInfo [ iIndex ] ) then
		self.m_pShaders[iIndex]:removeFromWorldTexture( sTextureName, pObject );
	
		pObjectInfo [ iIndex ] [ sTextureName ] = NULL;
	
		-- Clear Struct's
		if ( SizeOf( pObjectInfo [ iIndex ] ) < 1 ) then
			pObjectInfo [ iIndex ] = NULL;
		end
		
		if ( SizeOf( pObjectInfo ) < 1 ) then
			self.m_pEditedObjects [ pObject ] = NULL;
		end
		
		-- Check
		
	end
	
	return NULL;
end;

function CCore:ResetRainBow( )
	if ( self.m_sSelectedTexture ) then
		g_pRainBowShader:removeFromWorldTexture( self.m_sSelectedTexture, self.m_pSelectedObject );
	end
	
	return NULL;
end;

function CCore:SetObjectRainBow( sTextureName )
	self:ResetRainBow( );
	
	g_pRainBowShader:applyToWorldTexture( sTextureName, self.m_pSelectedObject, true );
	
	self.m_sSelectedTexture = sTextureName;
	
	return NULL;
end;

function CCore:OnClick( sButton, sState, _, _, _, _, _, pElement )
	if ( sButton == "left" and sState == "down" and self.m_pXMLMap.m_pObjects [ pElement ] ) then
		self:ResetRainBow( );
		
		self.m_pSelectedObject = pElement;
		
		g_pInterface:CreateTexList( pElement );
	end
	
	return NULL;
end;

function CCore:Load( _, sFileName )
	if ( not sFileName ) then
		Chat( "#ff0000XMRT_ERROR:#ffffff /xmrt_load <file path>", 255, 255, 255, true );
	
		return NULL;
	end
	
	local sFilePath = S_EDITOR_DEFAULT_PATH .. sFileName .. ".map";
	
	if ( not File.exists ( sFilePath ) ) then
		Chat( ("#ff0000XMRT_ERROR:#ffffff File (%s.map) not found."):format( sFileName ), 255, 255, 255, true );
		
		return NULL;
	end
	
	if ( self.m_bState ) then
		Chat( "#ff0000XMRT_ERROR:#ffffff You are already in the editor. Use /unload for exit without save.", 255, 255, 255, true );
		
		return NULL;
	end
	
	-- Load, Join to editor
	local bStatus = self.m_pXMLMap:LoadMap( sFilePath )
	
	if ( bStatus ) then
		self.m_bState		= true;
		self.m_sFileName 	= sFileName;
		self.m_sFilePath 	= sFilePath;
		
		g_pInterface:SetShow( true );
	end
	
	return NULL;
end;

function CCore:Unload( )
	if ( not self.m_bState ) then
		return NULL;
	end
	
	self:ResetRainBow( );
	
	for pObject, sID in pairs ( self.m_pXMLMap.m_pObjects ) do
		pObject:destroy();
	end
	
	for iIndex, pTexture in pairs ( self.m_pTextures ) do
		pTexture:destroy();
	end
	
	for iIndex, pShader in pairs ( self.m_pShaders ) do
		pShader:destroy();
	end
	
	-- reset variables
	self.m_pSelectedObject		= NULL;
	self.m_sSelectedTexture		= NULL;
	self.m_pXMLMap.m_pObjects	= {};
	self.m_pTextures 			= {};
	self.m_pShaders				= {};
	self.m_pEditedObjects		= {};
	self.m_bState 				= NULL;
	self.m_sFileName 			= NULL;
	self.m_sFilePath 			= NULL;
	
	--
	restoreAllWorldModels( ); 
	
	-- hide interface
	g_pInterface:SetShow( false );
	
	return NULL;
end;

function CCore:Save ( )
	local pEditedObjects = {};
	
	for pObject, pData in pairs ( self.m_pEditedObjects ) do
		local sID = self.m_pXMLMap:GetObjectID( pObject );
		if ( sID ) then
			pEditedObjects [ sID ] = pData;
		end
	end
	
	self.m_pXMLMap:Save( self.m_sFilePath, pEditedObjects );
	
	return NULL;
end;

g_pCore = CCore( );