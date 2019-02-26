
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
	return #(mtls, maps)
)
function get_materials = (
	-- checks if sme selection 
	-- then checks object selection
	sel = SMEGetSelNodes()
	if sel != undefined then (
		mtls = sel[1]
		maps = sel[2]
		if mtls == undefined OR mtls[1] == undefined then 
		( 
			if maps.count > 0 then (
				hdris = for m in maps where (classof m) == vrayhdri collect m
				if hdris.count > 0 then return hdris
			) 
		)
	)
	-- check scene selection
	else (
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

	local pos = [random -1000 1000, random -1000 1000]
	local newNode = theView.createnode mat pos
	if jump then (
		theView.SetSelectedNodes  #(mat)
		sme.SetMtlInParamEditor mat
		theView.ZoomExtents type:#selected
	)
	mat
)




struct metadataStruct (
	type,
	id,
	comment,
	saved_at
)






function create_metadata mtl metadata:undefined = (
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
	mtl.meta.comment = if metadata != undefined then metadata.comment else ""
	mtl.meta.type = if metadata != undefined then metadata.type else 1
	mtl.meta.id = create_Hash()
)



function read_metadata mtl = (
	if not isProperty mtl "meta" then return undefined
	local meta = metadataStruct()
	meta.type 		= if mtl.meta.type != undefined 		then mtl.meta.type else 1
	meta.comment 	= if mtl.meta.comment != undefined 		then mtl.meta.comment else ""
	meta.saved_at 	= if mtl.meta.saved_at != undefined 	then mtl.meta.saved_at else ""
	meta.id 		= if mtl.meta.id != undefined 			then mtl.meta.id else ""
	return meta
)
function has_metadata mtl = (
	x = isProperty mtl "meta"
	x
)
function print_metadata mtl = (
	print (read_metadata mtl)
)









struct infoBoxStruct 
(
	mtl,
	meta,
	fn launch selected_mtl:undefined = (
		mtl = selected_mtl
		
		rollout infoBox "Enter Material Info" 
		(
			edittext edt_comment "Material Information" width:350 height:200 labelontop:true
			radiobuttons rad_type "Preview Type:" labels:#("Default", "Floor", "Fabric") columns:1 align:#left
			button but_done "Done" width:200
			
			on but_done pressed do (
				try DestroyDialog infoBox
				catch()
				meta = metadataStruct()
				meta.type = rad_type.state
				meta.comment = edt_comment.text
			)
			
			on infoBox open do (
				if mtl != undefined then (
					if has_metadata mtl then (
						edt_comment.text = mtl.meta.comment
						rad_type.state = mtl.meta.type
					)
				)
			)
		)
		destroyDialog infoBox 
		createDialog infoBox width:370 modal:true
		return meta
	)
)



fn get_metadata_from_user mtl:undefined = (
	infoBoxVar = infoBoxStruct()
	meta = infoBoxVar.launch selected_mtl:mtl
	return meta
)
	

function edit_metadata mtl = (
	if mtl == undefined then return undefined
	local meta = get_metadata_from_user mtl:mtl
	if meta == undefined then return undefined

	if not has_metadata mtl then create_metadata mtl
	
	mtl.meta.type = meta.type
	mtl.meta.comment = meta.comment
	mtl.saved_at = get_time()
	
	saveMaterialLibrary current_lib_path
)

function edit_metadata_lib = (
	if current_lib_path == undefined  OR current_lib == undefined then return undefined
	local meta = get_metadata_from_user()
	if meta == undefined then return undefined

	for i = 1 to current_lib.count do
	(
		local mtl = current_lib[i]
		if not has_metadata mtl then create_metadata mtl
		mtl.meta.type = meta.type
		mtl.meta.comment = meta.comment
		mtl.saved_at = get_time()
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

	local result = getSaveFileName caption:"Save" types:"Material Library(*.mat)"
	if result == undefined then return false
	if not matchpattern result pattern:"*.mat" then result += ".mat"
	
	
 	local newName = getFilenameFile result 
 	local savePath = pathConfig.removePathLeaf result

	if newName == undefined OR newName == "" then return undefined

	newName = repair_name newName


	if doesFileExist  (savePath + "\\" + newName + ".mat") then (
		messageBox "Library does alredy exist"
		return undefined
	)

	matlib = MaterialLibrary()

	success = saveTempMaterialLibrary matlib (savePath + "\\" + newName + ".mat")
	if success then (
		success = makeDir (savePath + "\\" + newName + "__THUMBS__")
		messageBox "Library created" bleep:false title:"Success"
		add_to_user_paths (savePath + "\\" + newName + ".mat")
		return success
	)
)





function addToLibrary lib_path = (

	load = loadMaterialLibrary lib_path
	if NOT load then (print "Library not found"; return false)
	local mtls = get_materials()

	if mtls == undefined then return false
	--for mtl in mtls do mtl.name = repair_name mtl.name

	local lib = currentMaterialLibrary

	local maps = check_maps_multi mtls
	if maps.count > 0 then 
	(
		local txt = "The following maps are missing: \n\n"
		for m in maps do txt += m + "\n"
		txt += "\n Do you want to continue?"
		q = queryBox txt title: "Broken Links"
		if not q then return false
	)
	
	-- check existing materials
	local override_all = false

	-- rename hdri nodes
	for mat in mtls where classof mat == vrayhdri do mat.name = pathConfig.stripPathToLeaf (get_filename mat)

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
	local meta = undefined
	if existing_mtls.count != mtls.count then meta = get_metadata_from_user()

	-- write materials
	for mat in mtls do 
	(
		x = isInLibrary lib mat
		-- does not exist
		if x == 0 then 
		(
			relink mat ((pathconfig.removePathLeaf lib_path) + "\\" + (getFileNameFile lib_path) + "__MAPS__")
			create_metadata mat metadata:meta
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
				create_metadata mat metadata:metadata
				--mat.meta.type 		= metadata.type
				--mat.meta.comment 	= metadata.comment
				--mat.meta.id 		= metadata.id
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





































-- replacing materials in scene









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
	meta_b.id == meta_a.id
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