

--globalVars.remove 		#current_lib 
--globalVars.remove 		#current_lib_path

global repo
global userfile 
global current_lib_path, current_lib
global globalPaths, userPaths
global rendersize = 800
global myRollout
global selected_mtl, current_directory

-- current_lib_path i.e. = "X:\05_Benutzerordner\Jonas\bega\anderes\test - Kopie.mat"

global whiteColor = (dotNetClass "System.Drawing.Color").fromARGB 255 255 255
global greyColor = (dotNetClass "System.Drawing.Color").fromARGB 180 180 180
global redColor = (dotNetClass "System.Drawing.Color").fromARGB 255 128 128
global orangeColor = (dotNetClass "System.Drawing.Color").fromARGB 255 180 50
global greenColor = (dotNetClass "System.Drawing.Color").fromARGB 128 255 128
global blueColor = (dotNetClass "System.Drawing.Color").fromARGB 192 220 255
global purpleColor = (dotNetClass "System.Drawing.Color").fromARGB 200 180 255
global yellowColor = (dotNetClass "System.Drawing.Color").fromARGB 255 128 25
global lightgrey = (dotNetClass "System.Drawing.Color").fromARGB 128 128 128
global darkgrey = (dotNetClass "System.Drawing.Color").fromARGB 45 45 45


fn get_image mtl = (
	local libname = getFileNameFile current_lib_path
	img_name = (pathConfig.removePathLeaf current_lib_path) + "\\" + libname + "__THUMBS__\\" + mtl.name + ".*"
	files = getfiles img_name
	if files.count > 0 then return files[1]
	img_name = (pathConfig.removePathLeaf current_lib_path) + "\\" + mtl.name + ".*"
	files = getfiles img_name
	files[1]
)
fn get_thumbnail mtl = (
	local libname = getFileNameFile current_lib_path
	img_name = (pathConfig.removePathLeaf current_lib_path) + "\\" + libname + "__THUMBS__\\" + mtl.name + "_thmbnl.*"
	files = getfiles img_name
	if files.count > 0 then return files[1]
	img_name = (pathConfig.removePathLeaf current_lib_path) + "\\" + mtl.name + "_thmbnl.*"
	files = getfiles img_name
	files[1]
)
fn write_file myPath lines = (
	stream = openFile myPath mode:"w+"
	if stream != undefined then
	(
		try(for l in lines do format (l + "\n") to:stream)
		catch(print "Error while writing to file")
		flush stream
		close stream 
	)
	else messageBox ( "No File: " + myPath)
)
fn add_to_public_paths newPath = (
	if newPath == undefined or newPath == "" then return false
	append globalPaths newPath
	write_file (repo + "\\" + "paths.txt") globalPaths
)
fn add_to_user_paths newPath = (
	if newPath == undefined or newPath == "" then return false
	append userPaths newPath
	write_file userfile userPaths
)



filein "relink_paths.ms"
filein "edit_libs.ms"


fn show_image mtl = (
	try display (openBitmap (get_image mtl))
	catch()
)
fn apply_material index = (
)
fn show_preview index = (
	selected_mtl = current_lib[index]
	if selected_mtl != undefined then show_image selected_mtl
)
fn read_directories_from_file file = (
	lines = (dotnetClass "System.IO.File").ReadAllLines file
	lines
)
fn read_global_directories = (
	out = read_directories_from_file (repo + "\\" + "paths.txt")
	out
)
fn read_user_directories = (
	if not doesFileExist userfile then (
		createfile userfile
		return #()
	)
	out = read_directories_from_file userfile
	out
)
fn get_Directories = (
	globalPaths = read_global_directories()
	userPaths = read_user_directories()
)
fn get_repo = (
	global repo = readLine (openFile "repo_path.txt")
)
fn select_material index = (
	selected_mtl = current_lib[index]
	if selected_mtl == undefined then return undefined
	print_metadata selected_mtl 
	local meta = read_metadata selected_mtl
	myTool.dnc_label_a.text = selected_mtl.name
	if meta != undefined then (
		myTool.dnc_label_b.text = meta[3] + "          " + meta[4] + "-" + meta[1] as string
		myTool.dnc_label_c.text = meta[2] 
	)
	else (
		myTool.dnc_label_b.text = "no info"
		myTool.dnc_label_b.text = "no info"
	)
	true
)


global ilTv = dotNetObject "System.Windows.Forms.ImageList"
ilTv.imageSize = dotNetObject "System.Drawing.Size" 16 15

fn open_icon iconspath n = (
	local fpath = iconspath + "\\" + n + ".bmp"
	local fname = (getfiles fpath)[1]
	if fname != undefined and doesFileExist fname then (
		img = dotNetClass "System.Drawing.Image" --create an image
		ilTv.images.add (img.fromFile fname)
	)
	else print "no icon"
)
fn open_icons = (
	
	local iconspath = repo + "\\icons" 
	--local names = #("basic_archive_full","basic_folder_multiple","basic_bookmark", "basic_folder","basic_world")
	local names = #("basic_folder_col","lib","bookmark_col")
	for n in names do open_icon iconspath n
)

if myTool != undefined then DestroyDialog myTool

Utility myTool "Material Browser"
(

	dotNetControl 	lv_mtls 			"System.Windows.Forms.ListView" width:250 height:500 align:#left offset:[300,0] visible:false
	dotNetControl 	tv 					"TreeView" pos:[0,0] width:300 height:600 across:2
	dotNetControl 	dnc_label_a 		"Windows.Forms.Label" pos:[10,660] width:290 
	dotNetControl 	dnc_label_c 		"Windows.Forms.Label" pos:[10,690] width:290 
	dotNetControl 	dnc_label_b 		"Windows.Forms.Label" pos:[10,780] width:290 
	subrollout 		theSub 				height:728 width:1100 pos:[305,0]
	bitmap 			bmp_preview 		width:400 height:400 pos:[600,5] visible:false
	imgTag   		img_black 			bitmap:(bitmap 280 1 color:(color 50 50 50))  pos:[10,645] 

	imgTag   		img_green_1 		bitmap:(bitmap 100 2 color:green)  pos:[320,760] width:100
	button 			but_load 			"LOAD" pos:[320,765] width:50
	button 			but_apply 			"APPLY" pos:[370,765] width:50
	imgTag   		img_green_2 		bitmap:(bitmap 100 2 color:green)  pos:[320,789] width:100
	button 			but_replace 		"REPLACE" pos:[420,765] width:50

	button 			but_add 			"Add" pos:[600,765] width:50
	button 			but_rem 			"Delete" pos:[650,765] width:50--iconname: (repo + "\\" + "apply.png")
	button 			but_new 			"New Lib" pos:[800,765] width:100

	button 			but_edit_meta 		"Edit" pos:[900,765] width:50 tooltip:"Edit the metadata of the selected material"
	button 			but_edit_libmeta 	"Edit all" pos:[950,765] width:50 tooltip:"Edit the metadata of the current library"
	button 			but_relink 			"Relink" pos:[1000,765] width:50 tooltip:"Opens a window where you can relink maps of the current library\nThis is useful after moving a library"
	button 			but_repair 			"R" pos:[1050,765] width:20 tooltip:"updates metadata format" visible:false

	button 			but_go 				"render previews"  pos:[1100,765] width:100
	button 			but_settings 		"settings" pos:[1200,765] width:100
	

	-- tree view


	fn add_lib_to_tree node m = (
		newNode = node.Nodes.add (getFilenameFile m)
		newNode.tag = dotNetMXSValue m
		newNode.imageIndex = 1
		newNode.SelectedImageIndex = 1
		--newNode.foreColor = blueColor
		newNode
	)
	fn add_dir_to_tree node d = (
		if (matchpattern d pattern: "*\\") then d = substring d 1 (d.count - 1)
		newNode = node.Nodes.add (pathConfig.stripPathToLeaf d)
		newNode.imageIndex = 0
		newNode.SelectedImageIndex = 0
		newNode.tag = dotNetMXSValue d
		newNode.foreColor = greyColor
		newNode
	)


	fn create_Tree_rec node dir = (
		dirs = getDirectories (dir + "\\*")
		for d in dirs where ((matchpattern d pattern:"*__MAPS__*") == false) AND ((matchpattern d pattern:"*__THUMBS__*") == false)do (
			newNode = add_dir_to_tree node d
			create_Tree_rec newNode d
		)
		matlibs = getFiles (dir + "\\*.mat")
		for m in matlibs do (
			add_lib_to_tree node m
		)
	)
	fn create_tree = (
		tv.nodes.clear()
		root = tv.Nodes.add "Public"
		root.imageIndex = 2
		root.SelectedImageIndex = 2
		root.foreColor = greenColor
		for dir in globalPaths do 
		(
			if (matchpattern dir pattern:"*.mat") then add_lib_to_tree root dir
			else (
				newNode = add_dir_to_tree root dir
				create_tree_rec newNode dir
			)
		)
		root = tv.Nodes.add "User"
		root.imageIndex = 2
		root.SelectedImageIndex = 2
		root.foreColor = greenColor
		for dir in userPaths do 
		(
			if (matchpattern dir pattern:"*.mat") then add_lib_to_tree root dir
			else (
				newNode = add_dir_to_tree root dir
				create_tree_rec newNode dir
			)
		)
	)
	fn show_image mtl = (
		img_name = (pathConfig.removePathLeaf current_lib_path) + "\\" + mtl.name + ".*"
		files = getfiles img_name
		if files.count > 0 then bmp_preview.filename = files[1]
	)
	fn print_lib = print current_lib

	fn create_Images = (
		print current_lib
		if current_lib == undefined then( print "no lib"; return undefined)
		
		try (removesubRollout theSub myRollout)
		catch()
		--imgs = (getfiles ((pathConfig.removePathLeaf current_lib_path) + "\\" +"*.jpg"))
		try (
			errorImg = openbitmap (repo + "\\" + "noPreview.jpg")
			if errorImg == undefined then print "could not load error image"

			rci = rolloutCreator "myRollout" "Previews"
			rci.begin()
			for i = 1 to current_lib.count do
			(
				--print current_lib[i]
				rci.addControl #button  ("bmp" + (i as string)) 	"" 					paramStr:"width:200 height:200 across:10 align:#left offset:[0,10]"  
				rci.addControl #label 	("label_" + (i as string)) current_lib[i].name 	paramStr:"align:#left offset:[-110,215]" 
				rci.addHandler ("bmp" + (i as string)) #pressed 		codeStr:("select_material(" +  i as string + ")")
				rci.addHandler ("bmp" + (i as string)) #doubleclick 	codeStr:("apply_material(" +  i as string + ")")
				rci.addHandler ("bmp" + (i as string)) #rightclick 		codeStr:("show_preview(" + i as string + ")")

			)
			rci.end()

			addsubrollout theSub myRollout 

			for i = 1 to current_lib.count do
			(
				btm = execute ("myRollout.bmp" + (i as string))
				mtl = current_lib[i]
				imgfile = get_thumbnail mtl
				img = if imgfile != undefined then (openbitmap imgfile) else errorImg
				btm.images = #(img, undefined, 1,1,1,1,1 )
			)
		)
		catch (print "error while creating images")
	)
	fn init_tv = (
		--tv.Indent = 20
		--tv.CheckBoxes = true
		tv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 45 45 45
		tv.forecolor = whiteColor
		tv.borderstyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
		open_icons()	
		tv.imageList = ilTv

		--getIconFromBitmap (iconDir + "Helpers_16i.bmp") 1 "Helper"
		--At the end, we assign the ImageList to the TreeView.
		--tv.imageList = ilTv
		create_tree()
	)
	fn init_labels = (
		local bkgCol = (colorman.getcolor #background * 255) as color
		local bg = (dotNetClass "System.Drawing.Color").fromARGB bkgCol.r bkgCol.r bkgCol.r
		dnc_label_a.text = ""
		dnc_label_b.text = ""
		dnc_label_c.text = ""
		dnc_label_a.backColor = bg
		dnc_label_b.backColor = bg
		dnc_label_c.backColor = bg
		dnc_label_b.foreColor = lightgrey
		dnc_label_c.foreColor = lightgrey
		--dnc_label_a.backColor = (dotNetClass "System.Drawing.Color").fromArgb bkgCol.r bkgCol.g bkgCol.b
		--dnc_label_a.foreColor = (dotNetClass "System.Drawing.Color").fromARGB 128 255 128
		dnc_label_a.foreColor = (dotNetClass "System.Drawing.Color").fromARGB 255 255 255
		dnc_label_a.AutoSize = false
		dnc_label_a.Size = 		dotNetObject "System.Drawing.Size" 290 14
		dnc_label_a.font = dotnetobject "System.Drawing.Font" "Arial" 12
		--dnc_label_b.foreColor = (dotNetClass "System.Drawing.Color").fromARGB 255 128 128
		dnc_label_a.Size = 		dotNetObject "System.Drawing.Size" 290 80
		--dnc_label_b.foreColor = (dotNetClass "System.Drawing.Color").fromARGB 255 128 128
		
	)





	fn get_selected_mtl = (
		if lv_mtls.SelectedItems.count != 1 then return 0
		mtl = current_lib[lv_mtls.SelectedItems.Item[0].index+1]
		--print mtl
		mtl
	)
	fn load_material_lib p = (
		if (loadMaterialLibrary p) then (
			global current_lib = currentMaterialLibrary
			global current_lib_path = p
		)
		else print "cannot open lib"
	)
	fn refresh_images = create_Images()









	-- events

	

	on tv Click arg do(
		hitNode = tv.GetNodeAt (dotNetObject "System.Drawing.Point" arg.x arg.y)
		if hitNode != undefined AND hitnode.tag != undefined do 
		--try (
			local p = hitNode.tag.value
			if p == undefined then return undefined
			if matchpattern p pattern:"*.mat" then (
				current_directory = pathConfig.removePathLeaf p
				load_material_lib p
				--print current_lib
				print_lib()
				create_Images()
			)
			else current_directory = p

			--print current_directory
		--)
		--catch()
	)
	on lv_mtls click do (
		mtl = get_selected_mtl()
		show_image mtl
	)
	on lv_mtls doubleclick do with undo label:"apply material" on (
		mtl = get_selected_mtl()
		$.material = mtl
	)
	/*
	fn init_lv = (
		lv_mtls.Clear()
		lv_mtls.backColor = (dotNetClass "System.Drawing.Color").fromARGB 50 50 50
		lv_mtls.View = (dotNetClass "System.Windows.Forms.View").Details
		lv_mtls.gridLines = false
		lv_mtls.fullRowSelect = true
		lv_mtls.checkboxes = false
		lv_mtls.Columns.add "" 0 
		lv_mtls.Columns.add "" 200
		lv_mtls.hideSelection = true
		lv_mtls.forecolor = whiteColor
		lv_mtls.HeaderStyle = lv_mtls.HeaderStyle.None	
	)
	*/



	-- buttons 

	on but_go pressed do (
		local p = getSourceFileName()
		p = pathConfig.removePathLeaf p 
		p += "\\" + "run_renderscript_local.bat"
		ShellLaunch  p ""
	)
	on but_add pressed do (
		success = addToLibrary current_lib_path
		refresh_images()
	)
	on but_replace pressed do with undo label: "Replace" on replace_materials()

	on but_rem pressed do removefromlibrary current_lib_path selected_mtl

	on but_settings pressed do (
		global settingsWindow
		Utility settingsWindow "Settings"(

			group "Public Paths"
			(
				MultiListBox  		mlt_paths 			"" width:600 height:20 align:#left  across:2
				label 				lab_info 			"Public Librarys are accessable \nfor all users" width:200 height:100 offset:[130,0] 
				button 				but_add 			"Add" align:#left across:3 align:#left 
				button 				but_remove 			"Remove" align:#left 
				button 				but_private 		"make private" align:#left offset:[-200,0]

			)
			label space00 ""
			group "User Paths"
			(
				MultiListBox  		mlt_paths_User 		"" width:600 height:20 align:#left across:2
				label 				lab_info_user 		"Public Librarys are only visible to \nyou. Click 'make public' if you want \nothers to use your Materials " width:210 height:100 offset:[130,0]
				button 				but_add_user 		"Add" align:#left across:3 align:#left
				button 				but_remove_user		"Remove" align:#left 
				button 				but_public 			"make public" align:#left offset:[-200,0]
			)

			fn init = (
				get_Directories()
				mlt_paths.items = globalPaths
				mlt_paths_User.items = userPaths
			)

			on but_add_user pressed do (
				p = getOpenFileName caption:"Select a Library" types:"Material Library(*.mat)"
				add_to_user_paths p
				init()
			)
			on but_add pressed do (
				p = getOpenFileName caption:"Select a Library" types:"Material Library(*.mat)"
				add_to_public_paths p
				init()
			)


			fn remove_public  = (
				sel = mlt_paths.selection
				newLines = for i = 1 to globalPaths.count where (not sel[i]) collect globalPaths[i]
				write_file (repo + "\\" + "paths.txt") newLines 
				init()
			)

			fn remove_user  = (
				sel = mlt_paths_user.selection
				newLines = for i = 1 to userPaths.count where (not sel[i]) collect userPaths[i]
				write_file userfile newLines
				init() 
			)

			on but_public pressed do 
			(
				sel = mlt_paths_user.selection
				lines_to_keep = for i = 1 to userPaths.count where (not sel[i]) collect userPaths[i]
				for i = 1 to userPaths.count where sel[i] do append globalPaths userPaths[i]
				write_file (repo + "\\" + "paths.txt") globalPaths
				write_file userfile lines_to_keep 
				init()
			)

			on but_private pressed do 
			(
				sel = mlt_paths.selection
				lines_to_keep = for i = 1 to globalPaths.count where (not sel[i]) collect globalPaths[i]
				for i = 1 to globalPaths.count where sel[i] do append userPaths globalPaths[i]
				write_file userfile userpaths
				write_file (repo + "\\" + "paths.txt") lines_to_keep
				init()
			)










			on settingsWindow open do init()


			on but_remove pressed do (
				remove_public()
				init()
			)

			on but_remove_user pressed do (
				remove_user()
				init()
			)
			on settingsWindow close do (try(create_tree());catch())


			

		)
		CreateDialog settingsWindow width:800 height:800
	)
	on but_load pressed do with undo label:"Load Material" on (
		try (
			add_to_sme selected_mtl
			)
		catch("could not load material")
	)
	on but_apply pressed do with undo label:"Apply Material" on (
		try $.material = selected_mtl
		catch()
	)
	on but_edit_meta pressed do edit_metadata selected_mtl

	on but_repair pressed do repair_old_metadata() 

	on but_edit_libmeta pressed do edit_metadata_lib() 

	on but_relink pressed do user_relink()

	on but_new pressed do (
		create_new_library()
		create_tree()
	)



	
	on myTool open do (
		init_labels()

		if current_lib != undefined AND current_lib_path != undefined then (
			load_material_lib current_lib_path
			create_Images()
		)
		else global current_lib_path, current_lib

		get_repo()
		set_user_path()
		get_Directories()
		--init_lv()
		init_tv()
		
	)
	on myTool close do (
		try( DestroyDialog settingsWindow)
		catch()
	)











)
CreateDialog myTool width:1400 height:800 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox) -- bgcolor:(color 45 45 45)
		