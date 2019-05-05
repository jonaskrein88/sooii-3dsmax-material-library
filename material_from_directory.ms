global directory 
global pattern




struct mapsStruct (
	diffuse,
	albedo,
	opacity,
	ao,
	specular, 
	roughness,
	glossiness,
	metalness,
	bump, 
	normal,
	displacement,
	cavity,
	sss
)



fn texture_to_bitmapnode file gamma:1 = (
	local node = Bitmaptexture()
	node.bitmap = openBitmap file gamma:gamma
	node
)


fn find_texture path name type gamma:1 = (
	local pattern = (path + "\\" + "*" + name + "*" + type + "*")
	local maps = getfiles pattern
	if maps[1] != undefined then (print ("found " + maps[1]); return (texture_to_bitmapnode maps[1] gamma:gamma))
)

fn does_exist path name = (
	local pattern = (path + "\\" + "*" + name + "*")
	files = getfiles pattern
	if files == undefined or files == #() then return false
	true
)


fn find_textures path name = (
	local maps = mapsStruct()



	maps.diffuse 		= find_texture path name "diffuse" 		gamma:2.2
	maps.albedo 		= find_texture path name "albedo" 		gamma:2.2
	maps.opacity 		= find_texture path name "opacity"  	
	maps.ao 			= find_texture path name "ao"  			
	maps.specular 		= find_texture path name "specular"  	
	maps.roughness 		= find_texture path name "roughness"  	
	maps.glossiness 	= find_texture path name "gloss"
	maps.bump 			= find_texture path name "bump"  		
	maps.normal 		= find_texture path name "normal"
	maps.displacement 	= find_texture path name "displacement"
	maps.metalness 		= find_texture path name "metalness"
	maps.cavity 		= find_texture path name "cavity"

	if maps.diffuse == undefined then maps.diffuse 		= find_texture path name "_d" 		gamma:2.2
	if maps.bump == undefined then maps.bump 			= find_texture path name "_b"
	if maps.specular == undefined then maps.specular 	= find_texture path name "_s"



	if maps.opacity == undefined 			then maps.opacity 			= find_texture path name "alpha"
	if maps.opacity == undefined 			then maps.opacity 			= find_texture path name "coverage"
	if maps.ao == undefined 				then maps.ao 				= find_texture path name "ambient"
	if maps.displacement == undefined 		then maps.displacement 		= find_texture path name "height"
	maps
)

fn invert_texture map = (
	local outputnode = output()
	outputnode.map1 = map
	outputnode.output.invert = true
	outputnode
)

fn make_normal_node map = (
	local normalnode = VRayNormalMap()
	normalnode.normal_map = map
	normalnode
)

fn set_gamma map newgamma:1 = (
	fpath = map.fileName 
	map.bitmap = openBitmap map.bitmap.filename gamma:newgamma
	map
)



fn make_composite map = (
	local comp = CompositeTexturemap()
	comp.maplist[1] = map 
	comp
)

fn add_map_to_comp comp map = (
	local num = comp.maplist.count + 1
	comp.maplist[num] = map 
	comp.blendmode[num] = 5
	comp.opacity[num] = 50
)


fn make_falloff &map = (
	old_map = map
	map = falloff()
	map.map1 = old_map
	map
)




function add_to_SME mat jump:true = (
	if mat == undefined then return 0
	
	if not (sme.isOpen()) then sme.open()
	local actIndex = sme.activeview
	local theView = sme.getview actIndex
	if theView == undefined then (messageBox "open sme"; return false)

	local pos = [random -1000 1000, random -1000 1000]
	local newNode = theView.createnode mat pos
	if jump then (
		theView.SetSelectedNodes  #(mat)
		sme.SetMtlInParamEditor mat
		theView.ZoomExtents type:#selected
	)
	mat
)




try DestroyDialog materialMaker
catch()

rollout materialMaker "material maker"
(
	edittext edt_path  "Directory"
	button but_clear "clear" align:#left
	edittext edt_pattern "optional pattern" width:300

	checkbox chk_fresnel "Blend glossiness with fresnel"
	checkbox chk_negativeRange "Displacement Range [-1 to 1]"
	edittext edt_prefix "Name prefix" width:250
	checkbox chk_useSpecAsGloss "use specular map for gloss"
	checkbox chk_invertspec "invert specular for glossiness"

	button but_go  "Go" width:100 height:50





	fn create_material path name = (

		if not (does_exist path name) then return undefined
		local maps = find_textures path name 

		if maps.diffuse == undefined AND maps.albedo == undefined then (print "could not find diffuse";return undefined)


		local mtl = vraymtl()
		local normalNode
		local compositeNode

		mtl.name = edt_prefix.text + (pathConfig.stripPathToLeaf path) 


		mtl.texmap_diffuse = if maps.diffuse != undefined then maps.diffuse else maps.albedo
 

		if maps.opacity != undefined then mtl.texmap_opacity = maps.opacity


		-- specular
		if maps.specular != undefined 	then mtl.texmap_reflection = maps.specular


		-- glossiness
		if maps.glossiness != undefined then mtl.texmap_reflectionGlossiness = maps.glossiness
		else
		if maps.roughness != undefined 	then mtl.texmap_reflectionGlossiness = invert_texture maps.roughness
		-- use spec
		if chk_useSpecAsGloss.checked and mtl.texmap_reflectionGlossiness == undefined and mtl.texmap_reflection != undefined then 
		(
			mtl.texmap_reflectionGlossiness = mtl.texmap_reflection
			if chk_invertspec.checked then mtl.texmap_reflectionGlossiness = invert_texture mtl.texmap_reflection  
		)
		-- falloff
		if chk_fresnel.checked and mtl.texmap_reflectionGlossiness != undefined then make_falloff &mtl.texmap_reflectionGlossiness






		
		if maps.normal != undefined then (
			normalnode = make_normal_node maps.normal
			mtl.texmap_bump = normalnode
		)
		if maps.bump != undefined then (
			if normalnode != undefined then normalnode.bump_map = maps.bump
			else mtl.texmap_bump = maps.bump
		)

		if maps.displacement != undefined then (

			if chk_negativeRange.checked then 
			(
				local outputnode = output()
				outputnode.map1 = set_gamma(maps.displacement)
				outputnode.output.rgb_level = 2
				outputnode.output.rgb_offset = -1
				mtl.texmap_displacement = outputnode
			)
			else mtl.texmap_displacement = maps.displacement
		)

			 
		if maps.ao != undefined then (
			if (classof mtl.texmap_diffuse) != CompositeTexturemap then mtl.texmap_diffuse = make_composite mtl.texmap_diffuse
			add_map_to_comp mtl.texmap_diffuse maps.ao
		)
		if maps.cavity != undefined then (
			if (classof mtl.texmap_diffuse) != CompositeTexturemap then mtl.texmap_diffuse = make_composite mtl.texmap_diffuse
			add_map_to_comp mtl.texmap_diffuse maps.cavity
		)

		if maps.metalness != undefined then (
			mtl.texmap_reflectionIOR = invert_texture maps.metalness 
			mtl.reflection_fresnel = false
		)


		try $.material = mtl
		catch()
		add_to_SME mtl
	)



	on materialMaker close do (
		global pattern = edt_pattern.text
		global directory = edt_path.text
	)
	on materialMaker open do (
		if pattern != undefined then edt_pattern.text = pattern
		if directory != undefined then edt_path.text = directory
	)



	on but_clear pressed do edt_pattern.text = ""
	on but_go pressed do create_material edt_path.text edt_pattern.text


)
CreateDialog materialMaker width:600




