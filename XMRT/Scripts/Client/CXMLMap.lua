local table_insert 	= table.insert;
local tonumber 		= tonumber;
local tostring		= tostring;
local tobool		= function ( pointer )
	return tostring(pointer) == "true" and true or false;
end;

CXMLMap = class("CXMLMap");

function CXMLMap:initialize( )
	self.m_pObjects = { };
end;

function CXMLMap:GetData( sFilePath )
	local aObjects 	= {};
	local pXML 		= XML.load( sFilePath, true );
	
	if ( pXML ) then	
		for i, pNode in ipairs ( pXML:getChildren() ) do
			table_insert(aObjects, 
			{
				m_sType			= pNode:getName(),
				m_sID			= pNode:getAttribute( "id" ),
				m_bBreakable 	= pNode:getAttribute( "breakable" ),
				m_iInterior 	= pNode:getAttribute( "interior" ),
				m_iAlpha  		= tonumber( pNode:getAttribute( "alpha" ) ),
				m_iDimension  	= tonumber( pNode:getAttribute( "dimension" ) ),
				m_iModel  		= tonumber( pNode:getAttribute( "model" ) ),
				m_fScale  		= tonumber( pNode:getAttribute( "scale" ) ),
				m_bDoublesided 	= tobool( pNode:getAttribute( "doublesided" ) ),
				m_bCollisions 	= tobool( pNode:getAttribute( "collisions" ) ),
				m_bFrozen 		= tobool( pNode:getAttribute( "frozen" ) ),
				m_fPosX  		= tonumber( pNode:getAttribute( "posX" ) ),
				m_fPosY  		= tonumber( pNode:getAttribute( "posY" ) ),
				m_fPosZ  		= tonumber( pNode:getAttribute( "posZ" ) ),
				m_fRotX  		= tonumber( pNode:getAttribute( "rotX" ) ),
				m_fRotY  		= tonumber( pNode:getAttribute( "rotY" ) ),
				m_fRotZ  		= tonumber( pNode:getAttribute( "rotZ" ) ),
				m_fRadius  		= tonumber( pNode:getAttribute( "radius" ) ),
				m_sXMRT			= pNode:getAttribute( "XMRT" )
			});
		end
		
		pXML:unload( );
		
		return aObjects;
	end
	
	return NULL;
end;

function CXMLMap:LoadMap( sFilePath )
	local aObjects = self:GetData( sFilePath );
	
	if ( aObjects ) then
		for i, pData in ipairs ( aObjects ) do
			if ( pData.m_sType == "object" ) then
				local pObject 		= Object( pData.m_iModel, pData.m_fPosX, pData.m_fPosY, pData.m_fPosZ, pData.m_fRotX, pData.m_fRotY, pData.m_fRotZ );
				
				pObject.dimension 	= pData.m_iDimension;
				pObject.interior 	= pData.m_iInterior;
				pObject.doubleSided = pData.m_bDoublesided;
				pObject.frozen 		= pData.m_bFrozen;
				
				self.m_pObjects [ pObject ] = pData.m_sID;
				
				if ( pData.m_sXMRT ) then
					for iIndex, pTextures in pairs ( table.deserialize( pData.m_sXMRT ) ) do
						-- Create texture to cache
						if ( not g_pCore.m_pTextures [ iIndex ] ) then
							g_pCore.m_pTextures[iIndex] = DxTexture( S_ASSETS_DEFAULT_PATH .. iIndex .. ".png" );
						end
						
						-- Create object struct
						if ( not g_pCore.m_pEditedObjects [ pObject ] ) then
							g_pCore.m_pEditedObjects [ pObject ] = {};
						end
						
						-- Create texture store
						if ( not g_pCore.m_pEditedObjects [ pObject ] [ iIndex ] ) then
							g_pCore.m_pEditedObjects [ pObject ] [ iIndex ] = pTextures;
						end
						
						-- Apply
						for sTextureName, pDiffuse in pairs ( pTextures ) do
							g_pCore:ApplyCustomTexture( pObject, sTextureName, iIndex, pDiffuse );
						end
					end
				end
			elseif ( pData.m_sType == "removeWorldObject" ) then
				removeWorldModel( pData.m_iModel, pData.m_fRadius, pData.m_fPosX, pData.m_fPosY, pData.m_fPosZ, -1 );
			end
		end
		
		return true;
	end
	
	return NULL;
end;

function CXMLMap:Save( sFilePath, pEditedObjects )
	local aObjects 	= {};
	local pXML 		= XML.load( sFilePath, false );
	
	if ( pXML ) then
		for i, pNode in ipairs ( pXML:getChildren() ) do
			local sID = pNode:getAttribute( "id" );
			if ( pEditedObjects [ sID ] ) then
				-- pNode:setAttribute( "XMRT", toJSON( pEditedObjects [ sID ] ) );
				pNode:setAttribute( "XMRT", table.serialize( pEditedObjects [ sID ] ) );
			end
		end
		
		pXML:saveFile( );
		pXML:unload( );
	end
	
	return NULL;
end;

function CXMLMap:GetObjectID( pObject )
	return self.m_pObjects [ pObject ];
end;