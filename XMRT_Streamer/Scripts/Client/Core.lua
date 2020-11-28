CCore = class("CCore");

function CCore:initialize( )
	Debug("XMRT_Streamer: Sucessfully started.");

	self:CEventAdd( "OnClientElementStreamIn",  root, self.OnStream );
	self:CEventAdd( "OnClientElementStreamOut", root, self.OutStream );
	
	self.m_pTextures	= {}; -- [ int->textureIndex ];
	self.m_pShaders		= {}; -- [ int->textureIndex ];
	self.m_pUses		= {}; -- [ int->textureIndex ];
	
	if ( _DEBUG ) then
		addEventHandler("onClientRender", root, function ( )
			dxDrawText( "self.m_pTextures: " .. inspect(self.m_pTextures), 300, 200, 0, 0 );
			dxDrawText( "self.m_pShaders: " .. inspect(self.m_pShaders), 700, 200, 0, 0 );
			dxDrawText( "self.m_pUses: " .. inspect(self.m_pUses), 1000, 200, 0, 0 );
		end );
	end
	
	local aObjects = getElementsByType("object", root, true);
	for i, pObject in ipairs ( aObjects ) do
		self:Apply( pObject );
	end
end;

function CCore:OnStream( )
	if ( source.type == "object" ) then
		self:Apply( source );
	end
end;

function CCore:OutStream( )
	if ( source.type == "object" ) then
		local pData = source:getData("XMRT");
		if ( pData ) then
			for iIndex, pTextures in pairs ( table.deserialize( pData ) ) do
				if ( ( self.m_pUses [ iIndex ] or 0 ) > 0 ) then
					self.m_pUses [ iIndex ] = (self.m_pUses [ iIndex ] or 0) - 1;
				end
			end
			
			self:Unload( );
		end
	end
end;

function CCore:Apply( pObject )
	local pData = pObject:getData("XMRT");
	if ( pData ) then
		for iIndex, pTextures in pairs ( table.deserialize( pData ) ) do
			if ( not self.m_pTextures [ iIndex ] ) then
				self.m_pTextures[iIndex] = DxTexture( S_ASSETS_DEFAULT_PATH .. iIndex .. ".png" );
			end
			
			if ( not self.m_pShaders [ iIndex ] ) then
				self.m_pShaders[iIndex] = g_pShaderStore:Create("tx_replacer");
				self.m_pShaders[iIndex]:setValue( "gTexture", self.m_pTextures [ iIndex ] );
			end
			
			for sTextureName, pDiffuse in pairs ( pTextures ) do
				self.m_pShaders[iIndex]:setValue( "f4Diffuse", { 
					pDiffuse[1], pDiffuse[2], 
					pDiffuse[3], pDiffuse[4] 
				} );
				
				-- static prelight
				if ( pDiffuse[5] ) then
					self.m_pShaders[iIndex]:setValue( "bStaticPreLight", pDiffuse[5] );
				end
				
				self.m_pShaders[iIndex]:applyToWorldTexture( sTextureName, pObject, true );
			end
			
			self.m_pUses [ iIndex ] = (self.m_pUses [ iIndex ] or 0) + 1;
		end
	end
end;

function CCore:Unload( )
	for iIndex, iCountUses in pairs ( self.m_pUses ) do
		if ( iCountUses < 1 ) then
			if ( isElement ( self.m_pTextures [ iIndex ] ) ) then
				self.m_pTextures[iIndex]:destroy( );
			end
			
			self.m_pTextures[iIndex] = NULL;
			
			if ( isElement ( self.m_pShaders [ iIndex ] ) ) then
				self.m_pShaders[iIndex]:destroy( );
			end
			
			self.m_pShaders[iIndex] = NULL;
		end
	end
end;

g_pCore = CCore();