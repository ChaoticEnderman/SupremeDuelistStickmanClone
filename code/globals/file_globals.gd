extends Node

## Place to store the default maps in the project structure
const res_maps_path = "res://maps"

## Path to store all the maps of the game to user filesystem
const maps_path = "user://maps"

## Load a single map in the maps_path location
func load_map_file_from_user_directory():
	pass

## Save current map in the maps_path location
func save_map_file_from_user_directory():
	pass

## Runs every time the project start to copy default maps from res:// folder to user:// folder
func copy_maps_to_user_maps_directory():
	print("FG/copying maps to user maps ", ProjectSettings.globalize_path(maps_path))
	# Creating the maps folder if not exist already
	if not DirAccess.dir_exists_absolute(maps_path):
		DirAccess.make_dir_absolute(maps_path)
	
	# Copy the default map data files inside the res folder outside to the user folder
	# This is to put both the default maps and custom maps in one place
	var res_maps = DirAccess.open(res_maps_path)
	print("FG/res saved maps ", res_maps)
	var extension : String
	if res_maps:
		res_maps.list_dir_begin()
		var file_name = res_maps.get_next()
		print("FG/first file name is")
		while file_name != "":
			print("FG/Loading from ", (res_maps_path + "/" + file_name), " to ", (maps_path + "/" + file_name))
			extension = file_name.substr(file_name.length() - 5, 5)
			# Basic check if the extension is .dat file
			if extension == ".json":
				DirAccess.copy_absolute((res_maps_path + "/" + file_name), (maps_path + "/" + file_name))
			file_name = res_maps.get_next()
		print("FG/done reading files")
	else:
		print("FG/Some error while loading default maps")

	
