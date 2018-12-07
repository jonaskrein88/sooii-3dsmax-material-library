

/*
changelog

- rendering user Materials
- previews to __THUMBS__
- thumbnails to __THUMBS__

*/


global rendersize = 800
global repo 
global all_paths =#()

filein "edit_libs.ms"



-- previews

fn show_geo mtl = (
	local meta = read_metadata mtl
	local type = if meta != undefined then meta[1] else 1
	print type
	(LayerManager.getLayerFromName "DEFAULT").on = if type == 1 then true else false
	(LayerManager.getLayerFromName "FLOOR").on = if type == 2 then true else false
	(LayerManager.getLayerFromName "FABRIC").on = if type == 3 then true else false
)


fn render_preview mtl dir = (
		filename = dir + "\\" + mtl.name + ".jpg"
		show_geo mtl
		for o in $_GEO* do o.material = mtl
		cam = getNodeByName "_CAM"
		--return true
		makeDir dir
		render camera:cam vfb:false outputfile:filename cancelled:&cancel quiet:true outputwidth:rendersize outputheight:rendersize
		return (not cancel)
	)
	fn read_library libfile = (
		loadMaterialLibrary libfile
		lib = currentMaterialLibrary
		for mtl in lib collect mtl
	)
	fn create_joblist dir mtls = (
		for mtl in mtls collect(
			imgs = (getfiles (dir + "\\" + mtl.name +".*"))
			if imgs.count == 0 then mtl 
			else continue
		)
	)
	fn render_previews_for_lib libfile dir = (
		mtls = read_library libfile 
		jobs = create_joblist dir mtls
		fileoutgamma = 2.2
		for j in jobs do (
			success = render_preview j dir
			if not success then return false
		)
		true
	)
	fn find_librarys_rec dir &libs &paths = (
		matlibs = getFiles (dir + "\\*.mat")
		for l in matlibs do (
			append libs l
			local fname = pathconfig.stripPathToLeaf l
			local libname = substring fname 1 (fname.count - 4)
			local previewDir = dir + "\\" + libname + "__THUMBS__"
			print previewDir
			append paths previewDir 
		)
		dirs = getDirectories (dir + "\\*")
		for d in dirs do find_librarys_rec d libs paths
	)
	fn find_librarys repo &libs &paths = (
		libs = #()
		paths = #()
		find_librarys_rec repo &libs &paths
	)
	fn render_previews repo = (
		find_librarys repo &libs &paths
		for i = 1 to libs.count do (
			success = render_previews_for_lib libs[i] paths[i]
			if not success then return false
		)
		true
	)



	-- thumbs

	fn has_thumbnail mtl path = (
		files = getfiles (path + "\\" + mtl.name + ".thmbnl")
		return (files != undefined and files[1] != undefined)
	)
	fn create_thumbnail mtl path = (
		--if has_thumbnail mtl path then return true
		files = getfiles (path + "\\" + mtl.name + ".jpg")
		if (files != undefined and files[1] != undefined) then 
		(
			img = openBitMap files[1]
			new_img = bitmap 200 200
			copy img new_img
			new_img.filename = (path + "\\" + mtl.name + "_thmbnl.jpg")
			save new_img
		)
	)
	fn create_thumbnails_for_lib libfile path = (
		lib = read_library libfile
		for mtl in lib do create_thumbnail mtl path
	)
	fn create_thumbnails repo = (
		find_librarys repo &libs &paths
		for i = 1 to libs.count do create_thumbnails_for_lib libs[i] paths[i]
	)

	fn read_directories_from_file file = (
		lines = (dotnetClass "System.IO.File").ReadAllLines file
		all_paths += lines
	)
	fn read_global_directories = (
		read_directories_from_file (repo + "\\" + "paths.txt")
		true
	)
	fn read_user_directories = (
		local p = set_user_path()
		read_directories_from_file p
		true
	)
	fn get_repo = (
		global repo = readLine (openFile "repo_path.txt")
	)






get_repo()
read_global_directories()
read_user_directories()
for dir in all_paths do 
(
	render_previews dir
	create_thumbnails dir
)
quitMax #noprompt



