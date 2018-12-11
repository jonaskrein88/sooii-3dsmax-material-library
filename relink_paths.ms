
fn is_good_path p = (matchpattern p pattern:@"X:\_Basics*") or (matchpattern p pattern:@"\\FILESERVER\sooii \_Basics*") or (matchpattern p pattern:@"*05_Benutzerordner\Jonas\*")

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
fn copy_and_relink n dir = (
	oldpath = get_filename n
	if not doesFileExist dir then makeDir dir
	newpath = dir + "\\"+ (pathconfig.strippathtoleaf oldpath)
	print newpath
	if (copyfile oldpath newpath) then 
	(
		set_filename n newpath
		print "success"
	)
	else print "fail"
)
fn relink mtl newpath = (
	-- main function for inserting
	-- relinks all maps in a material to the new location
	maps = find_nodes mtl
	for m in maps do copy_and_relink m newpath
)



fn find_moved_images_rec filename dir = (
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



fn user_relink = (

	Utility relinkWindow "Relink maps"
	(
		edittext edt_path "Path" width:500
		checkbox chk_wholeLib "Relink complete Library" checked:true
		button but_go "Relink"


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
		on relinkWindow open do (
			local libpath = pathConfig.removePathLeaf current_lib_path
			edt_path.text = libpath 
		)
	)
	CreateDialog relinkWindow width:550

)














