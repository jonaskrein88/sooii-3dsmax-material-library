
function set_user_path = (
	local userDir = (dotNetClass "System.Environment").GetEnvironmentVariable "UserProfile"
	global userfile = userDir += "\\Documents\\3dsMax\\_mtl_userPaths.txt"
	userfile
)

function SMEGetSelNodes = (
	if NOT sme.IsOpen() then return undefined
	local actIndex = sme.activeview
	local theView = sme.getview actIndex
	local selNodes = theView.getSelectedNodes()
	local mtls = for n in selNodes where(superclassof n.reference) == material collect n.reference
	local maps = for n in selNodes where(superclassof n.reference) == textureMap collect n.reference
	return mtls
)

function get_materials = (
	mtls = SMEGetSelNodes() 
	if mtls == undefined OR mtls[1] == undefined then 
	( 
		objs = getCurrentSelection()
		mtls = for o in objs where o.material != undefined collect o.material
	)
	if mtls == undefined OR mtls[1] == undefined then (messageBox "No material selected!"; return undefined)
	mtls
)

function deleteImage mtl = (
	img = get_image mtl
	if img != undefined then deletefile img
	img = get_thumbnail mtl
	if img != undefined then deletefile img
)

function get_time = (
	t = getLocalTime()
	day = t[4] as string
	month = t[2] as string
	year = t[1] as string
	hour = t[5] as string
	minute = t[6] as string
	day + "." + month + "." + year + "   " + hour + ":" + minute
)

function isInLibrary lib mat = (
	matName = mat.name
	for i = 1 to lib.count do (
		print lib[i].name 
		if lib[i].name == matName then return i 
	)
	return 0
)




function create_metadata mtl = (
	myAttributes = attributes metadata attribID:#(0x17b88b76, 0x360ea5e8)
	(
		parameters main 
		(
			type type:#integer 
			id type:#integer
			comment type:#string 
			saved_at type:#string
		)
	)
	custAttributes.add mtl myAttributes

	mtl.metadata.saved_at = get_time()
	mtl.metadata.comment = new_mat_comment
	mtl.metadata.type = new_mat_type
)
function get_metadata_from_user = (
	utility edit_infos "Edit Info"
	(
		edittext edt_comment "Comment" height:200 labelontop:true
		radiobuttons rad_type "" labels:#("Default", "Floor", "Fabric") columns:1 default: 1 align:#left
		button but_done "Done" width:200


		on edit_infos close do (
			--global new_mat_comment = edt_comment.text
			--global new_mat_type = rad_type.state
		)
		on but_done pressed do (
			global new_mat_comment = edt_comment.text
			global new_mat_type = rad_type.state
			try DestroyDialog edit_infos
			catch()
		)

	)
	CreateDialog edit_infos modal:true width:200 height:400
)
function read_metadata mtl = (
	if not isProperty mtl "metadata" then return undefined

	type = if mtl.metadata.type != undefined then mtl.metadata.type else 1
	comment = if mtl.metadata.comment != undefined then mtl.metadata.comment else ""
	date = if mtl.metadata.saved_at != undefined then mtl.metadata.saved_at else ""
	id = if mtl.metadata.id != undefined then mtl.metadata.id else ""
	#(type, comment, date, id)
)
function has_metadata mtl = (
	isProperty mtl "metadata"
)
function print_metadata mtl = (
	print (read_metadata mtl)
)
function edit_metadata mtl = (
	if mtl == undefined then return undefined
	get_metadata_from_user()
	if not has_metadata mtl then create_metadata mtl
	else (
		mtl.metadata.type = new_mat_type
		mtl.metadata.comment = new_mat_comment
	)
	saveMaterialLibrary current_lib_path
)
function edit_metadata_lib = (
	if current_lib_path == undefined  OR current_lib == undefined then return undefined
	get_metadata_from_user()
	for i = 1 to current_lib.count do
	(
		local mtl = current_lib[i]
		if not has_metadata mtl then create_metadata mtl
		else (
			mtl.metadata.type = new_mat_type
			mtl.metadata.comment = new_mat_comment
		)
	)
	saveMaterialLibrary current_lib_path
)

struct myCoolDialogs
 (
 	labelStr,
 
 	stringQuery = rollout stringQuery "String Query"
 	(
 		local returnStr
 	
 		label lblHeader
 		editText etInput
 
 		fn launch label: =
 		(
 			destroyDialog myCoolDialogs.stringQuery
 			if label != unsupplied then
 				myCoolDialogs.labelStr = label
 			else myCoolDialogs.labelStr = "Enter a Name"
 			createDialog myCoolDialogs.stringQuery modal:true
 			returnStr -- only put it here if the dialog is modal
 		)
 
 		on stringQuery open do
 		(
 			lblHeader.text = myCoolDialogs.labelStr
 			setFocus etInput
 		)
 
 		on etInput entered str do
 		(
 			destroyDialog myCoolDialogs.stringQuery
 			returnStr = str
 		)
 	)
 )


function create_new_library = (
	if current_directory == undefined then return undefined
	myCoolDialogs = myCoolDialogs() -- as there are variables, an instance is needed
 	result = myCoolDialogs.stringQuery.launch label:"Enter your credentials"
 	local newName = result
	if newName == undefined OR newName == "" then return undefined
	newName = substituteString newName " " "_"
	newName = substituteString newName "." "_"
	newName = substituteString newName "ä" "ae"
	newName = substituteString newName "ö" "oe"
	newName = substituteString newName "ü" "ue"

	if doesFileExist (current_directory + "\\" + newName + ".mat") then (
		messageBox "Library does alredy exist"
		return undefined
	)

	matlib = MaterialLibrary()

	success = saveTempMaterialLibrary matlib (current_directory + "\\" + newName + ".mat")
	if success then (
		success = makeDir (current_directory + "\\" + newName + "__THUMBS__")
		return success
	)
)





function addToLibrary lib_path = (

	load = loadMaterialLibrary lib_path
	if NOT load then (print "Library not found"; return false)
	local mtls = get_materials()
	if mtls == undefined then return false

	local lib = currentMaterialLibrary



	-- check existing materials
	local override_all = false
	local existing_mtls = for mat in mtls where (isInLibrary lib mat != 0) collect mat.name
	if existing_mtls.count != 0 then 
	(
		local txt = "The following materials are going to be overwritten: \n\n"
		for s in existing_mtls do txt += s + "\n"
		txt += "\n Do you want to continue?"
		q = queryBox txt title: "Materials already exist"
		if q then override_all = true 
		else return false

	)
	get_metadata_from_user()

	-- write materials
	for mat in mtls do 
	(
		x = isInLibrary lib mat
		-- does not exist
		if x == 0 then 
		(
			relink mat ((pathconfig.removePathLeaf lib_path) + "\\" + (getFileNameFile lib_path) + "__MAPS__")
			create_metadata mat
			append currentMaterialLibrary mat
			saveMaterialLibrary lib_path
		)
		-- does exist
		else 
		(
			if override_all == true then -- not reachable, always true atm
			(
				relink mat ((pathconfig.removePathLeaf lib_path) + "\\" + (getFileNameFile lib_path) + "__MAPS__")
				create_metadata mat
				currentMaterialLibrary[x] = mat
				saveMaterialLibrary lib_path
				deleteImage mat
				print "material replaced" + mat.name
			)
		)
	)
	true
)

function removefromlibrary lib_path mtl = (
	print "removing"
	if mtl == undefined then (print "mtl not found"; return false)
	load = loadMaterialLibrary lib_path
	if NOT load then (print "Library not found"; return false)
	lib = currentMaterialLibrary

	for i = 1 to lib.count do (
		if lib[i].name == mtl.name then 
		(
			deleteItem lib i 
			saveMaterialLibrary lib_path
			deleteImage mtl
			print "Done"
			return true
		)
	)
	print "not found"
	false
)