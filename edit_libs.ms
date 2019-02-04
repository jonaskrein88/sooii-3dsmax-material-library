
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
	if hour.count == 1 then hour = "0" + hour
	if minute.count == 1 then minute = "0" + minute
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
function create_Hash =(
	lt = getLocalTime()
	-- date
	indexes = #(2,4)
	t = (lt[1] as string)
	t = substring t 3 t.count
	for i in indexes do t += lt[i] as string
	out = bit.intAsHex (t as integer)

	-- time
	indexes = #(5,6)
	t = ""
	for i in indexes do t += lt[i] as string
	out += bit.intAsHex (t as integer)

	-- user
	user = sysInfo.username 
	out += user[1] 
	out += user[3] 

	-- random
	out += bit.intAsHex (random 0 65535) as string
	out += bit.intAsHex (random 0 65535) as string
	out
)


function add_to_SME mat jump:true = (
	if mat == undefined then return 0
	
	if not (sme.isOpen()) then sme.open()
	local actIndex = sme.activeview
	local theView = sme.getview actIndex
	if theView == undefined then (messageBox "open sme"; return false)

	--navi = sme.GetMaterialPool()
	--pos = [0,0]
	--navi.position = pos
	--navi.setFocus()

	local pos = [random -1000 1000, random -1000 1000]
	local newNode = theView.createnode mat pos
	if jump then (
		theView.SetSelectedNodes  #(mat)
		sme.SetMtlInParamEditor mat
		theView.ZoomExtents type:#selected
	)
	mat
)



function create_metadata mtl = (
	myAttributes = attributes meta attribID:#(0x1995bf6c, 0x5f4fdb00)
	(
		parameters main 
		(
			type type:#integer 
			id type:#string
			comment type:#string 
			saved_at type:#string
		)
	)
	custAttributes.add mtl myAttributes

	mtl.meta.saved_at = get_time()
	mtl.meta.comment = if new_mat_comment != undefined then new_mat_comment else ""
	mtl.meta.type = if new_mat_type != undefined then new_mat_type else 1
	mtl.meta.id = create_Hash()
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
	if not isProperty mtl "meta" then return undefined
	type = if mtl.meta.type != undefined then mtl.meta.type else 1
	comment = if mtl.meta.comment != undefined then mtl.meta.comment else ""
	date = if mtl.meta.saved_at != undefined then mtl.meta.saved_at else ""
	id = if mtl.meta.id != undefined then mtl.meta.id else ""
	#(type, comment, date, id)
)
function has_metadata mtl = (
	x = isProperty mtl "meta"
	x
)
function print_metadata mtl = (
	print (read_metadata mtl)
)
function edit_metadata mtl = (
	if mtl == undefined then return undefined
	get_metadata_from_user()
	if not has_metadata mtl then create_metadata mtl
	else (
		mtl.meta.type = new_mat_type
		mtl.meta.comment = new_mat_comment
		mtl.saved_at = get_time()
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
			mtl.meta.type = new_mat_type
			mtl.meta.comment = new_mat_comment
			mtl.saved_at = get_time()
		)
	)
	saveMaterialLibrary current_lib_path
)
function repair_old_material_metadata mtl = (

	-- check if has new type
	if isProperty mtl "meta" then return true
	-- check if has old type
	if isProperty mtl "metadata" then 
	(
		global new_mat_type = if mtl.metadata.type != undefined then mtl.metadata.type else 1
		global new_mat_comment = if mtl.metadata.comment != undefined then mtl.metadata.comment else ""
	)
	-- has no old metadata
	else (
		global new_mat_comment = ""
		global new_mat_type = 1
		custAttributes.delete mtl metadata
	)
	create_metadata mtl
	--saveMaterialLibrary current_lib_path
)
function repair_old_metadata = (
	if current_lib == undefined then return 0
	for mtl in current_lib do repair_old_material_metadata mtl 
	saveMaterialLibrary current_lib_path
)







struct DialogStruct 
(
	pathQuery = rollout pathQuery "Add a Library" width:550 height:200
	(
		local returnStr = ""

		label lab_info "Set a path for the new Lib:"
		editText edit_path 	"" width: 460 across:2
		button but_browse "..." offset:[100,-1]
		button but_create "Create Library"

		on but_browse pressed do (
			p = getSaveFileName caption:"Save" types:"Material Library(*.mat)"
			if p != undefined then (
				if not matchpattern p pattern:"*.mat" then p += ".mat"
				edit_path.text = p
			)
		)

		fn launch = (
			destroyDialog DialogStruct.pathQuery
			createDialog DialogStruct.pathQuery modal:true
			returnStr
		)

		on but_create pressed do (
			destroyDialog DialogStruct.pathQuery
			returnStr = edit_path.text
		)
	)
)




fn repair_name newName = (
	if newName == undefined OR newName == "" then return undefined
	newName = substituteString newName " " "_"
	newName = substituteString newName "." "_"
	newName = substituteString newName "ä" "ae"
	newName = substituteString newName "ö" "oe"
	newName = substituteString newName "ü" "ue"
	newName
)




function create_new_library = (
	DialogStruct = DialogStruct()
	result = DialogStruct.pathQuery.launch()
	if result == undefined then return false

 	local newName = getFilenameFile result 
 	local savePath = pathConfig.removePathLeaf result

	if newName == undefined OR newName == "" then return undefined


	newName = repair_name newName

	print newName 
 	print savePath 

	if doesFileExist  (savePath + "\\" + newName + ".mat") then (
		messageBox "Library does alredy exist"
		return undefined
	)

	matlib = MaterialLibrary()

	success = saveTempMaterialLibrary matlib (savePath + "\\" + newName + ".mat")
	if success then (
		success = makeDir (savePath + "\\" + newName + "__THUMBS__")
		messageBox "Library created"
		add_to_user_paths (savePath + "\\" + newName + ".mat")
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
	-- if there are new materals, ask for metadata
	if existing_mtls.count != mtls.count then get_metadata_from_user()

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
			if override_all == true then 
			(
				relink mat ((pathconfig.removePathLeaf lib_path) + "\\" + (getFileNameFile lib_path) + "__MAPS__")
				local metadata = read_metadata currentMaterialLibrary[x]
				create_metadata mat
				mat.meta.type = metadata[1]
				mat.meta.comment = metadata[2]
				mat.meta.id = metadata[4]
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


function delete_recursive old = (

	if old == undefined then return false
	subs = for i = 1 to (getNumSubTexmaps old) collect getSubTexmap old i
	if (superclassof old) == material then 
	(
		submtls = for i = 1 to (getNumSubMtls old) collect getSubMtl old i
		subs += submtls
	)
	

	for s in subs do delete_recursive s

	-- delete the node
	local views = sme.GetNumViews()
	for i = 1 to views do (

		--local actIndex = sme.activeview
		local theView = sme.getview i --actIndex
		theView.setSelectedNodes #(old)
		theView.deleteSelection()
	)

)

function replace_submaterial mtl oldMat newMat = (
	c = classof mtl
	case c of
	(
		Multimaterial:(
			for i in 1 to mtl.materialList.count do 
			(
				if mtl.materialList[i] == oldMat then mtl.materialList[i] = newMat
			)
		)
		VRayBlendMtl:(
			if mtl.baseMtl == oldMat then mtl.baseMtl = newMat
			for i = 1 to mtl.coatMtl.count do (
				if mtl.coatMtl[i] == oldMat do mtl.coatMtl[i] = newMat 
			
			)
		)
		VRay2SidedMtl:
		(
			if mtl.frontMtl == oldMat then 
			mtl.frontMtl = newMat
			if mtl.backMtl == oldMat then 
			mtl.backMtl = newMat
		)
	)
)
function replace_material old new = (

	for obj in $* do (
		if obj.material == old then obj.material = new
		else replace_submaterial obj.material old new
	)

	for mtl in scenematerials do replace_submaterial mtl old new
	old.name = "__old"

	if not (sme.isOpen()) then sme.open()
	delete_recursive old 
)



function is_same_material a b = (
	if a == undefined OR b == undefined then return false
	-- checks if name and id matches
	if a.name != b.name then return false
	meta_a = read_metadata a
	if meta_a == undefined then return false
	meta_b = read_metadata b
	if meta_b == undefined then return false
	meta_b[4] == meta_a[4]
)

function find_submaterials_to_replace mtl newOne = (
	c = classof mtl
	case c of
	(
		Multimaterial:(
			for i in 1 to mtl.materialList.count do 
			(
				if is_same_material mtl.materialList[i] newOne then return mtl.materialList[i]
			)
		)
		VRayBlendMtl:(
			if is_same_material mtl.baseMtl newOne then return mtl.baseMtl
			for i = 1 to mtl.coatMtl.count do (
				if is_same_material mtl.coatMtl[i] newOne then return mtl.coatMtl[i]
			)
		)
		VRay2SidedMtl:
		(
			if is_same_material mtl.frontMtl newOne then return mtl.frontMtl
			if is_same_material mtl.backMtl newOne then return mtl.backMtl
		)
	)
) 
function find_materials_to_replace lib &sources &targets = (
	local sources = #()
	local targets = #()
	--if classof newMats != Array then newMats = #(newMats)

	for newMat in lib do 
	(
		--print newMat.name
		for mtl in scenematerials do 
		(
			--print ("s   " + mtl.name)
			if is_same_material mtl newMat then 
			(
				append targets mtl 
				append sources newMat
			)
			local submtl = find_submaterials_to_replace mtl newMat 
			print submtl
			if submtl != undefined then (
				append targets submtl 
				append sources newMat
			)
		)
	)
)
function replace_materials = (
	clearListener()

	if current_lib_path == undefined then (messageBox "Please select a material library"; return 0)
	loadMaterialLibrary current_lib_path
	global current_lib = currentMaterialLibrary

	find_materials_to_replace current_lib &sources &targets 
	if targets.count == 0 then (messageBox "No materials found"; return 0)
	--assigned_mtls = #()

	for i = 1 to targets.count do 
	(
		/*
		-- check if the material was already assigned and use this one
		used_mtl = (
			for mtl in assigned_mtls do (
				if is_same_material mtl targets[i] then return mtl
			)
			undefined
		)
		if used_mtl != undefined then replaceinstances targets[i] used_mtl
		else (
			replaceinstances  targets[i] sources[i]
			append assigned_mtls sources[i]
		)
		*/
		mtl = sources[i]
		mtl = add_to_SME mtl jump:false

		print ("replacing "  + mtl.name)
		--replaceinstances  targets[i] mtl
		replace_material targets[i] mtl
	)
)