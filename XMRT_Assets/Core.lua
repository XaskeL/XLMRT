-- shitty code
addEventHandler("onResourceStart", resourceRoot, function ( )
	local pElement 	= Element("XMRT_Assets", "XMRT_Assets");
	local pXML 		= XML.load( "meta.xml", true );
	local iCounter	= 0;
	
	if ( pXML ) then
		for i, pData in ipairs ( pXML:getChildren() ) do
			if ( pData:getName() == "file" ) then
				iCounter = iCounter + 1;
			end
		end
		
		pXML:unload( );
	end
	
	pElement:setParent( pElement );
	pElement:setData( "CElement::m_iXMRTAssets", iCounter );
end );