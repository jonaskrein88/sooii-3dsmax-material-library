
fn is_good_path p = (matchpattern p pattern:@"X:\_Basics*") or (matchpattern p pattern:@"\\FILESERVER\sooii \_Basics*") or (matchpattern p pattern:@"*05_Benutzerordner\Jonas\*")


fn get_maps mtl = (
	bmp_nodes = getClassinstances Bitmaptexture target:mtl
	hdri_nodes = getClassinstances vrayhdri target:mtl
	hdri_nodes + bmp_nodes
)

fn get_filename n = (
	x = case (classof n) of (
		Bitmaptexture: n.filename
		vrayhdri: n.HDRIMapName
		default:undefined
	)
)
fn set_filename n newpath = (
	case (classof n) of (
		Bitmaptexture: n.filename = newpath
		vrayhdri: n.HDRIMapName = newpath
		default:undefined
	)
)

fn find_nodes mtl = (
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
	maps = find_nodes mtl
	for m in maps do copy_and_relink m newpath
)



