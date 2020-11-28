-- static CInterface
g_pInterface =
{
	m_pCEGUI = 
	{
		checkbox 		= {};
		staticimage 	= {};
		edit 			= {};
		button 			= {};
		window 			= {};
		label 			= {};
		gridlist 		= {};
	};
	
	m_iTextureIndex		= 1;

	Initialize			= function ( self )
		local sSplitter = string.rep("_", 38);
	
		self.m_pCEGUI.window[1] 		= GuiWindow( 466, 374, 283, 351, "XMRT - Editor", false );
        self.m_pCEGUI.window[1]:setSizable( false );
        self.m_pCEGUI.window[1]:setVisible( false );
		
        self.m_pCEGUI.gridlist[1] 		= GuiGridList( 10, 25, 263, 204, false, self.m_pCEGUI.window[1] );
        self.m_pCEGUI.gridlist[1]:addColumn( "List:", 0.9 );
		
        self.m_pCEGUI.button[1] 		= GuiButton( 10, 239, 115, 33, "Apply", false, self.m_pCEGUI.window[1] );
        self.m_pCEGUI.button[2] 		= GuiButton( 10, 282, 115, 33, "Hide Rainbow", false, self.m_pCEGUI.window[1] );
        self.m_pCEGUI.button[3] 		= GuiButton( 159, 239, 114, 33, "Remove from tex.", false, self.m_pCEGUI.window[1] );
        self.m_pCEGUI.button[4] 		= GuiButton( 159, 282, 115, 33, "Save", false, self.m_pCEGUI.window[1] ); -- "Hide Wnd / or mouse2"
        self.m_pCEGUI.label[1] 			= GuiLabel( 135, 241, 14, 74, "|\n|\n|\n|\n|\n|\n|\n|", false, self.m_pCEGUI.window[1] );
        self.m_pCEGUI.label[2] 			= GuiLabel( 10, 325, 263, 17, sSplitter, false, self.m_pCEGUI.window[1] );

        self.m_pCEGUI.window[2] 		= GuiWindow( 759, 374, 277, 499, "XMRT - Assets", false );
		self.m_pCEGUI.window[2]:setSizable( false );
		self.m_pCEGUI.window[2]:setVisible( false );

        self.m_pCEGUI.staticimage[1] 	= GuiStaticImage( 10, 30, 256, 201, ":XMRT_Assets/Resources/Textures/1.png", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.label[3] 			= GuiLabel( 98, 241, 80, 21, self.m_iTextureIndex .. " / ".. GetCountAssets(), false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.label[3]:setHorizontalAlign( "center", false );
        self.m_pCEGUI.label[3]:setVerticalAlign( "center" );
		
        self.m_pCEGUI.button[5] 		= GuiButton( 10, 237, 78, 35, "< <", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.button[6] 		= GuiButton( 188, 237, 78, 35, "> >", false, self.m_pCEGUI.window[2] );
		
        self.m_pCEGUI.label[4] 			= GuiLabel( 10, 282, 257, 17, sSplitter, false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.edit[1] 			= GuiEdit( 10, 341, 84, 26, "1", false, self.m_pCEGUI.window[2] );
		
		addEventHandler( "onClientGUIChanged", self.m_pCEGUI.edit[1], function( ) 
			local sText = source:getText():gsub("(%D+)", "");
			source:setText( sText );
		end)
		
        self.m_pCEGUI.label[5] 			= GuiLabel( 10, 309, 257, 17, "Do you know the texture number? Enter:", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.button[7] 		= GuiButton( 104, 341, 89, 26, "Set", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.label[6] 			= GuiLabel( 10, 377, 257, 17, sSplitter, false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.label[7] 			= GuiLabel( 10, 404, 257, 17, "Curve diffuse color:", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.edit[2] 			= GuiEdit( 10, 431, 137, 26, "1.0, 1.0, 1.0, 1.0", false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.button[8] 		= GuiButton( 172, 431, 89, 26, "Set", false, self.m_pCEGUI.window[2]);
        self.m_pCEGUI.checkbox[1] 		= GuiCheckBox( 10, 467, 257, 20, "Permanently? (Replace original diffuse)", false, false, self.m_pCEGUI.window[2] );
        self.m_pCEGUI.checkbox[1]:setProperty( "NormalTextColour", "FFFE5151" );
		
		bindKey( "mouse2", "both", function ( sKey, sState )
			if ( self.m_pCEGUI.m_bShow ) then
				self:HideCursor( sKey, sState );
			end
		end );
		
		addEventHandler( "onClientGUIClick", resourceRoot, function ( sButton, sState )
			if ( g_pCore.m_bState ) then
				if ( source == self.m_pCEGUI.button[5] ) then
					if ( self.m_iTextureIndex > 1 ) then
						self.m_iTextureIndex = self.m_iTextureIndex - 1;
					end
					self:UpdatePreview( );
				elseif ( source == self.m_pCEGUI.button[6] ) then
					if ( self.m_iTextureIndex < GetCountAssets() ) then
						self.m_iTextureIndex = self.m_iTextureIndex + 1;
					end
					self:UpdatePreview( );
				elseif ( source == self.m_pCEGUI.button[7] ) then
					local iIndex = tonumber( self.m_pCEGUI.edit[1]:getText() );
					if ( iIndex and iIndex >= 1 and iIndex <= GetCountAssets() ) then
						self.m_iTextureIndex = iIndex;
						self:UpdatePreview( );
					end
				elseif ( source == self.m_pCEGUI.gridlist[1] ) then
					local iIndex = source:getSelectedItem( );
					if ( iIndex ~= -1 ) then
						local sTextureName = self:GetSelectedTexName();
						if ( sTextureName ) then
							local pObject = g_pCore.m_pSelectedObject;
							if ( pObject and g_pCore.m_pEditedObjects[ pObject ] ) then
								for iIndex, pTextures in pairs ( g_pCore.m_pEditedObjects[ pObject ] ) do
									local pDiffuse = pTextures [ sTextureName ];
									if ( pDiffuse ) then
										self.m_pCEGUI.edit[2]:setText( table.concat({pDiffuse[1], pDiffuse[2], pDiffuse[3], pDiffuse[4]}, "," ) );
										self.m_pCEGUI.checkbox[1]:setSelected( not not pDiffuse[5] );
										break;
									end
								end
							end
							g_pCore:SetObjectRainBow( sTextureName );
						end
					end
				elseif ( source == self.m_pCEGUI.button[1] ) then
					local iIndex 	= self.m_iTextureIndex;
					local pObject 	= g_pCore.m_pSelectedObject;
				
					if ( pObject and g_pCore.m_sSelectedTexture ) then
						-- Create texture to cache
						if ( not g_pCore.m_pTextures [ iIndex ] ) then
							local pTexture = DxTexture( S_ASSETS_DEFAULT_PATH .. iIndex .. ".png" );
							g_pCore.m_pTextures [ iIndex ] = pTexture;
						end
						
						-- Create object struct
						if ( not g_pCore.m_pEditedObjects [ pObject ] ) then
							g_pCore.m_pEditedObjects [ pObject ] = {};
						end
						
						-- Create texture store
						if ( not g_pCore.m_pEditedObjects [ pObject ] [ iIndex ] ) then
							g_pCore.m_pEditedObjects [ pObject ] [ iIndex ] = {};
						end
						
						local pStore 		= g_pCore.m_pEditedObjects [ pObject ] [ iIndex ]
						local sDiffuseInfo	= self.m_pCEGUI.edit[2]:getText();
						local pDiffuse		= split(sDiffuseInfo, ",");
						
						-- Convert to int
						for i = 1, 4 do
							if ( pDiffuse[i] ) then
								pDiffuse[i] = tonumber( pDiffuse[i] );
							end
						end; pDiffuse[5] = self.m_pCEGUI.checkbox[1]:getSelected();
						
						pStore [ g_pCore.m_sSelectedTexture ] = pDiffuse;
						
						g_pCore:ApplyCustomTexture( pObject, g_pCore.m_sSelectedTexture, iIndex, pDiffuse );
					end
				elseif ( source == self.m_pCEGUI.button[3] ) then
					local sTextureName = self:GetSelectedTexName();
					if ( sTextureName ) then
						local pObject = g_pCore.m_pSelectedObject;
						if ( pObject and g_pCore.m_pEditedObjects[ pObject ] ) then
							for iIndex, pTextures in pairs ( g_pCore.m_pEditedObjects[ pObject ] ) do
								if ( pTextures [ sTextureName ] ) then
									g_pCore:ResetRainBow( );
									g_pCore:ResetCustomTexture( pObject, sTextureName, iIndex );
									break;
								end
							end
						end
						g_pCore:SetObjectRainBow( sTextureName );
					end
				elseif ( source == self.m_pCEGUI.button[2] ) then
					g_pCore:ResetRainBow( );
				elseif ( source == self.m_pCEGUI.button[4] ) then
					g_pCore:Save( );
				end
			end
		end );
	end;
	
	SetShow				= function ( self, bShow )
		self.m_pCEGUI.window[1]:setVisible( bShow );
		self.m_pCEGUI.window[2]:setVisible( bShow );
		
		self.m_pCEGUI.m_bShow = bShow;
		
		showCursor( bShow );
	end;
	
	HideCursor			= function ( self, sKey, sState )
		if ( sState == "down" ) then
			showCursor( false );
		else
			showCursor( true );
		end
	end;
	
	CreateTexList		= function ( self, pObject )
		self.m_pCEGUI.gridlist[1]:clear( );
		
		for i, sName in ipairs ( Engine.getModelTextureNames( pObject.model ) ) do
			local iIndex = self.m_pCEGUI.gridlist[1]:addRow( sName );
		end
	end;
	
	GetSelectedTexName	= function ( self )
		local pGridList = g_pInterface.m_pCEGUI.gridlist[1];
		local iIndex 	= pGridList:getSelectedItem( );
		
		if ( iIndex ~= -1 ) then
			return pGridList:getItemText( iIndex, 1 );
		end
		
		return NULL;
	end;
	
	UpdatePreview  		= function ( self )
		local sFilePath = (S_ASSETS_DEFAULT_PATH .. "/%i.png"):format( self.m_iTextureIndex );
		if ( File.exists ( sFilePath ) ) then
			self.m_pCEGUI.staticimage[1]:loadImage( sFilePath );
			self.m_pCEGUI.label[3]:setText( self.m_iTextureIndex .. " / ".. GetCountAssets() );
		end
	end;
};

g_pInterface:Initialize( );