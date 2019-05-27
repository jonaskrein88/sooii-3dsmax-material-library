

fn path_to_mapped p = ( 
	local p = substituteString p @"\\FILESERVER\sooii" "X:" 
	substituteString p @"\\172.16.100.10\sooii-Daten" "X:" 
)
fn is_good_path p = (matchpattern p pattern:@"X:\_Basics*") or (matchpattern p pattern:@"*05_Benutzerordner\Jonas\*")

fn get_maps mtl = (
	-- gets all nodes from material
	bmp_nodes = getClassinstances Bitmaptexture target:mtl
	hdri_nodes = getClassinstances vrayhdri target:mtl
	hdri_nodes + bmp_nodes
)
fn get_filename n = (
	-- gets the path from hdri or bitmap nodes
	x = case (classof n) of (
		Bitmaptexture: n.filename
		vrayhdri: n.HDRIMapName
		default:undefined
	)
)
fn set_filename n newpath = (
	-- changes the path in hdri or bitmap nodes
	case (classof n) of (
		Bitmaptexture: n.filename = newpath
		vrayhdri: n.HDRIMapName = newpath
		default:undefined
	)
)
fn check_maps mtl &files:#() = (
	-- returns false if maps are missing, returns maps as &files
	local out = true
	local all_maps = get_maps mtl
	for map in all_maps do (
		local file = get_filename map
		if not (doesfileexist file) then (
			append files file
			out = false
		)
	)
	out	
)
fn check_maps_multi mtls = (
	-- checks multiple materials and returns failing paths
	local maps = #()
	for mtl in mtls do (
		local _maps = #()
		check_maps mtl files:&_maps
		maps += _maps
	)
	maps
)
fn array_to_string l = (
	local out = ""
	for x in l do (
		x = substitutestring x "\\" "\\\\"
		append out (x + "\n")
	)
	out
)
fn find_nodes mtl = (
	-- collects nodes to relink
	all_maps = get_maps mtl 
	found = for m in all_maps collect (
		filename = get_filename m
		if not (is_good_path filename) then m 
		else continue
	)
	found
)
fn copy_and_relink n newDir = (
	-- relinks a bitmap or hdri node
	oldpath = get_filename n
	if not doesFileExist newDir then makeDir newDir
	newpath = newDir + "\\"+ (pathconfig.strippathtoleaf oldpath)
	newpath = path_to_mapped newpath
	if (copyfile oldpath newpath) then 
	(
		set_filename n newpath
		print "relink success"
	)
	else print "relink failed"
)




fn relink mtl newpath = (
	-- main function for copying and relinking
	-- relinks all maps in a material to the new location
	maps = find_nodes mtl
	for m in maps do copy_and_relink m newpath
)



fn find_moved_images_rec filename dir = (
	-- rec util for find_moved_image
	local files = getFiles (dir + "\\" + filename)
	if files != undefined and files[1] != undefined then return files[1]

	local directories = getDirectories (dir + "\\*")
	for dir in directories do 
	(
		local file = find_moved_images_rec filename dir 
		if file != undefined then return file
	)
	undefined
)
fn find_moved_image filename directories = (
	-- iterates directory to find new location
	for dir in directories do 
	(
		local file = find_moved_images_rec filename dir
		if file != undefined then return file
	)
	undefined
)


fn relink_maps_from_directories mtl directories = (
	if classof directories != Array then directories = #(directories)
	nodes = get_maps mtl 
	for node in nodes do (
		local oldpath = get_filename node 
		set_filename node (path_to_mapped oldpath)

		local imgfile = pathconfig.strippathtoleaf oldpath

		local found_image = find_moved_image imgfile directories
		if found_image != undefined then 
		(
			set_filename node found_image
			print ("relinked: " + found_image)
		)
		else (
			print ("not found: " + imgfile)
			undefined 
		)

	)
)

fn user_collect_maps = (
	-- collecting, copying and relinking maps to the current __Maps__ Directory
	if current_lib == undefined OR current_lib_path == undefined then return undefined

	Utility collectWindow "Collect maps"
	(
		edittext edt_path "New Path" width:500
		checkbox chk_wholeLib "Collect complete Library" checked:true
		button but_go "Collect"


		on but_go pressed do (

			try DestroyDialog collectWindow
			catch()

			if current_lib_path == undefined OR current_lib == undefined then return false


			local newPath = edt_path.text 
			if newPath == undefined OR newPath == "" then return false


			if chk_wholeLib.checked then
			(
				for mtl in current_lib do relink mtl newpath
			)


			else (
				if selected_mtl != undefined then relink selected_mtl newpath
				else messageBox "No material selected"
			)

			

		)
		on collectWindow open do (
			local libpath = pathConfig.removePathLeaf current_lib_path
			edt_path.text = libpath 
		)

	)
	CreateDialog collectWindow width:550
)


fn user_relink = (
	-- only updating links to a new location
	-- when the lib already has been moved
	if current_lib == undefined OR current_lib_path == undefined then return undefined

	Utility relinkWindow "Relink maps"
	(
		edittext edt_path "Collect into:" width:500
		checkbox chk_wholeLib "Relink complete Library" checked:true
		button but_go "Relink"
		button but_show "Show maps"


		on but_go pressed do (

			try DestroyDialog relinkWindow
			catch()

			if current_lib_path == undefined OR current_lib == undefined then return false
			local newPath = edt_path.text 
			if newPath == undefined OR newPath == "" then return false


			if (matchpattern newPath pattern: "*\\") then newPath = (substring newPath 0 (newPath.count - 1))
			print ("searching" + newpath)

			if chk_wholeLib.checked then for mtl in current_lib do (
				relink_maps_from_directories mtl newPath
			)
			else if selected_mtl != undefined then relink_maps_from_directories selected_mtl newPath

			saveTempMaterialLibrary current_lib current_lib_path 
			

		)
		on but_show pressed do (
			local mtls
			mtls = if chk_wholeLib.checked then current_lib else #(selected_mtl)
			if mtls == undefined or mtls == #() then return undefined

			local all_maps = #()

			for mtl in mtls do 
			(
				local nodes = get_maps mtl
				local maps = for node in nodes collect (
					local file = get_filename node
					if (doesfileexist file) then ("OK      " + file )
					else ("MISSING " + file)
				)
				all_maps += maps
			)
			all_maps = makeUniqueArray all_maps

			messageBox (array_to_string all_maps) beep:false title:(all_maps.count as string + " maps")

		)
		on relinkWindow open do (
			local libpath = pathConfig.removePathLeaf current_lib_path
			edt_path.text = libpath 
		)
	)
	CreateDialog relinkWindow width:550

)














