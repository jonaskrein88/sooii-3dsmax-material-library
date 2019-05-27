global directory 
global pattern

global xOffset = 0
global yOffset = 0

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











try DestroyDialog materialMaker
catch()

rollout materialMaker "material maker"
(
	edittext edt_path  "Directory"
	button but_clear "clear" align:#left
	edittext edt_pattern "optional pattern" width:300

	edittext edt_matName "Name" width:250 across:2 align:#left
	checkbox chk_namefrommap "use map name" align:#left
	checkbox chk_useSpecAsGloss "Use specular map for Gloss"
	checkbox chk_invertspec "Invert specular for Glossiness" 
	checkbox chk_fresnel "Blend Glossiness with Falloff"
	checkbox chk_specGamma "Gamma correct Specular/Glossiness" tooltip:"Load maps with gamma 2.2.\nIn my experience:\nArrowWay = on\nMegaScans = off"
	checkbox chk_negativeRange "Displacement Range [-1 to 1]"
	button 	 but_loadMaps "Only load maps" align:#left
	button 	 but_nameFromMap "Set Name from Map" align:#left

	spinner spn_gloss "Glossiness" align:#right width:80 range:[0,1,1]
	spinner spn_spec  "Spec" align:#right width:80 range:[0,1,1]
	spinner spn_ior   "ior"  align:#right width:80 range:[0,100,1.6]
	label l ""

	spinner spn_mapGloss "Glossiness Map"  align:#right width:80  range:[0,100,100]
	spinner spn_mapSpec  "Spec Map" align:#right width:80 range:[0,100,100]
	spinner spn_mapBump  "Bump Map" align:#right width:80 range:[0,100,30]
	spinner spn_mapDispl  "Displace Map" align:#right width:80 range:[0,100,5]

	
	button but_go  "Go" width:100 height:50 across:2





	fn texture_to_bitmapnode file gamma:1 = (
		local node = Bitmaptexture()
		if gamma != 2.2 then node.bitmap = openBitmap file gamma:gamma
		else node.bitmap = openBitmap file 
		node
	)


	fn find_texture path name type gamma:1 = (
		local pattern = (path + "\\" + "*" + name + "*" + type + "*")
		local maps = getfiles pattern
		--print pattern
		if maps[1] != undefined then (
			--print ("found " + maps[1])
			return (texture_to_bitmapnode maps[1] gamma:gamma)
		)
	)

	fn does_exist path name = (
		local pattern = (path + "\\" + "*" + name + "*")
		files = getfiles pattern
		if files == undefined or files == #() then return false
		true
	)


	fn find_textures path name = (
		local maps = mapsStruct()
		local specGamma = if chk_specGamma.checked then 2.2 else 1

		
		maps.diffuse 		= find_texture path name "diffuse" 		gamma:2.2
		maps.albedo 		= find_texture path name "albedo" 		gamma:2.2
		maps.opacity 		= find_texture path name "opacity"  	
		maps.ao 			= find_texture path name "ao"  			
		maps.specular 		= find_texture path name "specular"  	gamma:specGamma	
		maps.roughness 		= find_texture path name "roughness" 	 	
		maps.glossiness 	= find_texture path name "gloss" 		gamma:specGamma
		maps.bump 			= find_texture path name "bump"  		
		maps.normal 		= find_texture path name "normal"
		maps.displacement 	= find_texture path name "displacement"
		maps.metalness 		= find_texture path name "metalness"
		maps.cavity 		= find_texture path name "cavity"

		if maps.diffuse == undefined 		then maps.diffuse 		= find_texture path name "_d" 		gamma:2.2
		if maps.bump == undefined 			then maps.bump 			= find_texture path name "_b"
		if maps.specular == undefined 		then maps.specular 		= find_texture path name "_r" 		gamma:specGamma	
		if maps.specular == undefined 		then maps.specular 		= find_texture path name "_s" 		gamma:specGamma	


		if maps.opacity == undefined 		then maps.opacity 		= find_texture path name "alpha"
		if maps.opacity == undefined 		then maps.opacity 		= find_texture path name "coverage"
		if maps.ao == undefined 			then maps.ao 			= find_texture path name "ambient"
		if maps.displacement == undefined 	then maps.displacement 	= find_texture path name "height"
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
		map.type = 2
		map
	)

	fn set_blur node = (
		node.filtering = 1
		node.coords.blur = 0.1
	)



	fn add_to_SME mat jump:true isMap:false = (
		if mat == undefined then return 0
		
		if not (sme.isOpen()) then sme.open()
		local actIndex = sme.activeview
		local theView = sme.getview actIndex
		if theView == undefined then (messageBox "open sme"; return false)
		--local pos = if index == undefined then [random -1000 1000, random -1000 1000] else [0, index * 200]
		yOffset += 1
		local ySpacing = if isMap then 80 else 500
		local pos = [xOffset * 1000, yOffset * ySpacing]
		local newNode = theView.createnode mat pos
		if jump then (
			theView.SetSelectedNodes  #(mat)
			sme.SetMtlInParamEditor mat
			theView.ZoomExtents type:#selected
		)
		mat
	)


	fn SMEGetSelNodes = (
		if NOT sme.IsOpen() then return undefined
		local actIndex = sme.activeview
		local theView = sme.getview actIndex
		local selNodes = theView.getSelectedNodes()
		local mtls = for n in selNodes where(superclassof n.reference) == material collect n.reference
		local maps = for n in selNodes where(superclassof n.reference) == textureMap collect n.reference
		return #(mtls, maps)
	)
	fn get_selected_mtls = (
		selected = SMEGetSelNodes()
		if selected != undefined and selected[1] != undefined then return selected[1]
	)
	fn get_selected_maps = (
		selected = SMEGetSelNodes()
		if selected != undefined and selected[2] != undefined then return selected[2]
	)



	fn repair_name test = (
		test = substituteString test " " "_"
		out = ""
		valid = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_-"
		for i = 1 to (test.count) do (
			if ((findString valid test[i]) != undefined) then out += test[i]
		)
		out
	)


	fn name_from_node node = (
		local file = node.filename
		file = substituteString file "albedo" ""
		file = substituteString file "diffuse" ""
		file = substituteString file "_d." "."
		name = getFilenameFile file
		name
	)






	fn create_material path name mtlname:undefined = (

		if not (does_exist path name) then return undefined

		local maps = find_textures path name

		if maps.diffuse == undefined AND maps.albedo == undefined then (print "could not find diffuse";return undefined)


		local mtl = vraymtl()
		local normalNode
		local compositeNode


		mtl.texmap_diffuse = if maps.diffuse != undefined then maps.diffuse else maps.albedo



		if chk_namefrommap.checked then 		mtl.name = name_from_node mtl.texmap_diffuse
		else (if mtlname != undefined then 		mtl.name = mtlname					 
		else 									mtl.name = edt_matName.text + (pathConfig.stripPathToLeaf path))





		mtl.name = repair_name mtl.name


		
 
		if maps.opacity != undefined then mtl.texmap_opacity = maps.opacity

		--if maps.specular != undefined then set_gamma maps.specular


		-- specular
		if maps.specular != undefined then mtl.texmap_reflection = maps.specular

		-- glossiness
		if maps.glossiness != undefined then mtl.texmap_reflectionGlossiness = maps.glossiness
		else
		if maps.roughness != undefined 	then (
			mtl.texmap_reflectionGlossiness = invert_texture maps.roughness
		)
		-- use spec
		if chk_useSpecAsGloss.checked and mtl.texmap_reflectionGlossiness == undefined and mtl.texmap_reflection != undefined then (
			mtl.texmap_reflectionGlossiness = mtl.texmap_reflection
			if chk_invertspec.checked then mtl.texmap_reflectionGlossiness = invert_texture mtl.texmap_reflection  
		)
		-- falloff
		if chk_fresnel.checked and mtl.texmap_reflectionGlossiness != undefined then make_falloff &mtl.texmap_reflectionGlossiness

		-- normal
		if maps.normal != undefined then (
			set_blur maps.normal
			normalnode = make_normal_node maps.normal
			mtl.texmap_bump = normalnode
		)
		-- bump
		if maps.bump != undefined then (
			set_blur maps.bump
			if normalnode != undefined then normalnode.bump_map = maps.bump
			else mtl.texmap_bump = maps.bump
		)
		-- displacement
		if maps.displacement != undefined then (
			if chk_negativeRange.checked then (
				local outputnode = output()
				outputnode.map1 = set_gamma(maps.displacement)
				outputnode.output.rgb_level = 2
				outputnode.output.rgb_offset = -1
				mtl.texmap_displacement = outputnode
			)
			else mtl.texmap_displacement = maps.displacement
		)
		-- AO
		if maps.ao != undefined then (
			if (classof mtl.texmap_diffuse) != CompositeTexturemap then mtl.texmap_diffuse = make_composite mtl.texmap_diffuse
			add_map_to_comp mtl.texmap_diffuse maps.ao
		)
		-- Cavity
		if maps.cavity != undefined then (
			if (classof mtl.texmap_diffuse) != CompositeTexturemap then mtl.texmap_diffuse = make_composite mtl.texmap_diffuse
			add_map_to_comp mtl.texmap_diffuse maps.cavity
		)
		-- Metalness
		if maps.metalness != undefined then (
			mtl.texmap_reflectionIOR = invert_texture maps.metalness 
			mtl.reflection_fresnel = false
		)


		--mtl.reflection_lockIOR = false
		mtl.texmap_reflectionGlossiness_multiplier 		= spn_mapGloss.value
		mtl.texmap_bump_multiplier 						= spn_mapBump.value
		mtl.texmap_displacement_multiplier 				= spn_mapDispl.value
		mtl.texmap_reflection_multiplier 				= spn_mapSpec.value

		mtl.refraction_ior 								= spn_ior.value
		mtl.reflection_glossiness 						= spn_gloss.value 
		mtl.reflection 									= (local c = spn_spec.value * 255; color c c c)

		--try $.material = mtl
		--catch()
		print ("Created:    " + mtl.name)
		add_to_SME mtl
		return mtl
	)




	-- regex 
	/*
	fn batch_create = (
		local pattern = edt_pattern.text
		local directory = edt_path.text
		if (findstring pattern "#") != 0 then (

			fileNames = ""
			files = getfiles (directory + "\\*")
			for f in files do fileNames += f + "\n"

			filenames = substituteString filenames "#" @"\d+"

			rgx = dotnetObject "System.Text.RegularExpressions.Regex" pattern
			result = rgx.Replace input " "

		)

	)
	*/

	fn batch_create = (

		local pattern = edt_pattern.text
		local directory = edt_path.text
		if (findstring pattern "#") != 0 then 
		(
			placeholder = ""
			placeholder2 = undefined
			
			for i = 0 to pattern.count where pattern[i] == "#" do placeholder += "#"

			-- check if we need second counter
			if (findstring pattern "%") != 0 then (
				placeholder2 = "%"
				--for i = 0 to pattern.count where pattern[i] == "%" do placeholder2 += "%"
			)
			xOffset += 1
			for i = 51 to 80 do 
			(
				local index = i as string
				while index.count < placeholder.count do index = "0" + index


				local combinedPattern 	= substituteString pattern placeholder index 
				local materialname 		= substituteString edt_matName.text placeholder index


				-- second counter
				if placeholder2 != undefined then 
				(
					for j = 1 to 9 do 
					(
						local index = j as string
						local combinedPattern2 	= substituteString combinedPattern 	"%" index
						local materialname2 	= substituteString materialname 	"%" index
						local mtl = create_material directory combinedPattern2 mtlname:materialname2
					)
				)
				else local mtl = create_material directory combinedPattern mtlname:materialname
				
			)

		)
	)







	fn iterate_directories dir = (
		local directories = getDirectories (dir + "/*")
		for d in directories do (
			local mtl = create_material d edt_pattern.text

		)
	)




	fn run = (
		--create_material edt_path.text edt_pattern.text
		batch_create()


	)






	fn set_text ui var = (
		if not (globalVars.isglobal var) then return undefined
		value = globalVars.get var
		if value != undefined then ui.text = value
	)
	fn set_checkbox ui var = (
		if not (globalVars.isglobal var) then return undefined
		value = globalVars.get var
		if value != undefined then ui.checked = value
	)
	fn set_spinner ui var = (
		if not (globalVars.isglobal var) then return undefined
		value = globalVars.get var
		if value != undefined then ui.value = value
	)



	on materialMaker close do ( 
		global pattern 			= edt_pattern.text
		global directory 		= edt_path.text
		global matName 			= edt_matName.text

		global useFresnel 		= chk_fresnel.checked
		global useSpecAsGloss 	= chk_useSpecAsGloss.checked
		global invertspec 		= chk_invertspec.checked
		global specGamma 		= chk_specGamma.checked
		global namefrommap		= chk_namefrommap.checked

		global specamount 		= spn_Spec.value
		global glossamount 		= spn_gloss.value
		global ioramount 		= spn_ior.value

		global map_gloss 		= spn_mapGloss.value
		global map_bump 		= spn_mapBump.value
		global map_spec 		= spn_mapSpec.value
		global map_displ 		= spn_mapDispl.value



	)
	on materialMaker open do (
		set_text edt_pattern 				#pattern
		set_text edt_path 					#directory
		set_text edt_matName 				#matname

		set_checkbox chk_fresnel 			#useFresnel
		set_checkbox chk_useSpecAsGloss 	#useSpecAsGloss
		set_checkbox chk_invertspec 		#invertspec
		set_checkbox chk_specGamma 			#specGamma
		set_checkbox chk_namefrommap 		#namefrommap

		set_spinner spn_Spec 				#specamount
		set_spinner spn_gloss 				#glossamount
		set_spinner spn_ior 				#ioramount

		set_spinner spn_mapGloss 			#map_gloss
		set_spinner spn_mapBump 			#map_bump
		set_spinner spn_mapSpec 			#map_spec
		set_spinner spn_mapDispl 			#map_displ


	)



	on but_clear pressed do edt_pattern.text = ""
	on but_go pressed do run() 

	on but_loadMaps pressed do (
		allfiles = #()
		formats = #("png", "jpg", "tif")
		for f in formats do (
			files = getFiles (edt_path.text + "\\*." + f) 
			allfiles += files
		)
		qsort allfiles stricmp
		for f in allfiles do (
			local node = texture_to_bitmapnode f gamma:2.2
			add_to_SME node isMap:true
		)
	)

	on but_nameFromMap pressed do (
		mtls = get_selected_mtls()
		if mtls == undefined then return false
		for m in mtls do 
		(
			maps = getClassInstances bitmapTexture target:m
			if maps != undefined and maps != #() then 
			(
				name = name_from_node maps[1]
				m.name = name
				print ("changed to " + name)
			)
		)
	)


)
CreateDialog materialMaker width:600




