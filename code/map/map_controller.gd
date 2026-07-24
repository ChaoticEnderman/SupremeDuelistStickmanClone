## Control class for the low level basic operations to the map, like save, load, draw, draw rect, ...
## The goal of this class is to store multiple Map object that store full data of each map
## This can also be interacted like a normal map object. As long as we set the current_map variable,
## This can just accept functions like the Map object and execute on the current map
extends Node

## List of all saved maps in the game
# HACK: Storing maps as different map objects instead of resource, will need optimization later on
var maps : Array[Map]

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

## Reference to the map that is being actively edited
var current_map : int

## Dictionary to save tiles of the tilemap that map to the atlas coords
const TILE : Dictionary = {
	"ERASE_TILE" : Vector2i(-1, -1),
	"PLATFORM_BLUE" : Vector2i(0, 0),
	"PLATFORM_YELLOW" : Vector2i(1, 0),
	"PLATFORM_RED" : Vector2i(2, 0),
	"PLATFORM_GREEN" : Vector2i(3, 0),
	"MAGMA" : Vector2i(4, 0),
	"IK_ACID" : Vector2i(5, 0),
	"IK_LAVA" : Vector2i(6, 0),
	"IK_WATER" : Vector2i(7, 0)
}

## List of types of instant kill
enum INSTANT_KILL_TYPE {
	NONE = 0,
	WATER = 1,
	LAVA = 2,
	ACID = 3
}

## To store the status after saving the file
enum SAVE_MAP_ERROR {SUCCESS, FILE_EXIST, FAILED}

func _init() -> void:
	pass

## Load data of the current map to the parameter map
## This can be inefficient since it require loading the entire map each time it is edited
# FIXME: A way to cache the last change and only load that change each time instead of everything
# TODO: For that, make a variable to store the latest change and a special quickload function to load only the edited part
func load_map(map: Map):
	map.get_tile_map_layer().clear()
	# Loop through the coordinates of the saved map
	for coords in maps[current_map].get_tile_map_layer().get_used_cells():
		map.get_tile_map_layer().set_cell(coords, 1, maps[current_map].get_tile_map_layer().get_cell_atlas_coords(coords))
	map.set_instant_kill_type(maps[current_map].get_instant_kill_type())

## Set the current map to the id position in the map array
func edit_map(id: int):
	current_map = id

## Erase all data of the current map
func clear_current_map():
	maps[current_map].get_tile_map_layer().clear()

## Loading a map for the server from the pool of default map
func set_single_map_for_server(map_name: String, map: Map):
	maps.clear()
	maps.append(Map.new())
	current_map = 0
	read_map_from_file("", FileGlobals.maps_path + "/" + map_name + ".json")
	load_map(map)

## Save the current map to file in a .json format
func save_map_to_file(map_name: String) -> SAVE_MAP_ERROR:
	var path : String = FileGlobals.maps_path + "/" + map_name + ".json"
	path = ProjectSettings.globalize_path(path)
	
	# Put in the default data
	var cells : Dictionary = {}
	var map_data : Dictionary = {
		"head": {
			"name": map_name,
			"instant_kill": maps[current_map].get_instant_kill_type()
		},
		"body": cells
	}
		
	# Temporary data to iterate each time
	var temp_key : String = ""
	var temp_value : String = ""
	for cell in maps[current_map].get_tile_map_layer().get_used_cells():
		# Method used to store file: Store by key and value pairs in the sub dictionary
		# x and y coordinates is seperated by a single comma, will be sliced in the reading process
		# This method is not the best but it worked out, see more in the corresponding load function
		temp_key = str(cell.x) + "," + str(cell.y)
		temp_value = str(get_atlas_coords_by_position(cell).x) + "," + str(get_atlas_coords_by_position(cell).y)
		cells[temp_key] = temp_value
	var json_string = JSON.stringify(map_data, '\t')
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	file.store_string(json_string)
	print("MC/json/test save ", json_string)
	return SAVE_MAP_ERROR.SUCCESS

## Read, decrypt (the custom data type), and load up map data from file. Will search for any maps with the same name for normal loading
## It will also automatically replace current map 
func read_map_from_file(map_name: String, path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	var tile_coords : Vector2i
	var atlas_coords : Vector2i
	
	# Several checks to see where does the newly loaded map belongs to inside the map array
	if maps[current_map].get_tile_map_layer() == null:
		print("MC/RMFF/map is clear, overriding")
		maps[current_map].set_map_name(map_name)
	else:
		var is_map_valid : bool = false
		for i in range(maps.size()):
			if maps[i].get_map_name() == map_name:
				print("MC/RMFF/opening same map, loading")
				is_map_valid = true
				current_map = i
		if not is_map_valid:
			print("MC/RMFF/opening wrong map, crashing", map_name)
			return false
	
	# Get the json from parsing the entire file
	var json_result : JSON = JSON.new()
	var error = json_result.parse(file.get_as_text())
	# Key and value for the tilemap tiles and their corresponding atlas coords
	var key : Vector2i
	var value : Vector2i
	if error == OK:
		# Get the setting data of the json file. 
		var data = json_result.get_data()
		print("MC/json/head is ", data["head"])
		print("MC/json/head is ", data["head"]["name"])
		var instant_kill : int = round(data["head"]["instant_kill"])
		maps[current_map].set_instant_kill_type(instant_kill)
		print("MC/json ikill ", instant_kill == INSTANT_KILL_TYPE.LAVA)
		for i in data["body"]:
			key.x = i.get_slice(",", 0).to_int()
			key.y = i.get_slice(",", 1).to_int()
			value.x = data["body"][i].get_slice(",", 0).to_int()
			value.y = data["body"][i].get_slice(",", 1).to_int()
			#print("MC/json/dict/ list ", key, " ", value)
			maps[current_map].get_tile_map_layer().set_cell(key, 1, value, 0)
	else:
		print("MC/json/error ? ", json_result.get_error_message())
	return true

## Read all maps in the folder and put into the maps array after clearing all maps. Basically clear and reread the maps
## Should be called every time a map is saved or loaded inside the ReadyMenu state
func reload_all_maps() -> bool:
	var dir = DirAccess.open(FileGlobals.maps_path)
	if not dir:
		return false
	# When loading all maps for the game everything should be cleared
	maps.clear()
	dir.list_dir_begin()
	# Assume that at least one map exist
	var file_name : String = " "
	var map_name : String = ""
	var extension : String = ""
	var i : int = 0
	var path : String
	var file : FileAccess
	# Loop for all files
	while file_name != "":
		file_name = dir.get_next()

		if file_name == "":
			continue
		print("MC/reload/filename is ", file_name)
		extension = file_name.substr(file_name.length() - 5, 5)
		# Basic check if the extension is .json file
		if extension == ".json":
			map_name = file_name.substr(0, file_name.length() - 5)
			# Append new entries in the map arrays
			
			maps.append(Map.new())
			maps[i].set_map_name(map_name)
			# Use the other functions to read from file one by one
			edit_map(i)
			path = FileGlobals.maps_path + "/" + map_name + ".json"
			path = ProjectSettings.globalize_path(path)
			print("MC/reload/editing map ", path)
			if FileAccess.file_exists(path):
				print("MC/reload/reading map id ", i, " with name ", map_name)
				read_map_from_file(map_name, path)
				# Only incremental if the map is valid, so the maps array will have no wasted space
				i += 1
			else:
				print("MC/reload/file doesnt exist")
		else:
			print("MC/reload/file is not json ", file_name)
	dir.list_dir_end()
	return true

## Append an empty map to the end of the map arrays, with empty name so it will not be read and will be ignore when loading maps
## The empty map will be discarded unless the player save it
func create_untitled_map():
	maps.append(Map.new())
	current_map = maps.size() - 1
	# Should be nothing
	print("MC/Created untitled map is", maps[current_map].get_map_name())

## IMPORTANT: This function will attempt to load a file from the maps directory. Will search for by the name,
## and if a map have the exact name then it will replace that map
## In the special case of a map that isnt loaded into the game (not really possible because it will always reload maps after each save)
## Then it will fallback to like making a new entry in the map array and load the map in
func load_map_from_file_to_map_list(selected_paths: String):
	print("MC/loading map from file")
	var map_name : String = selected_paths.get_file()
	map_name = map_name.substr(0, map_name.length() - 4)
	print("MC/map path is ", selected_paths)
	read_map_from_file(map_name, selected_paths)

func test_save_map_to_json(map_name: String):
	var path : String = FileGlobals.maps_path + "/" + map_name + ".json"
	path = ProjectSettings.globalize_path(path)
	print("MC/json/save ", path)
	
	var cells : Dictionary = {}
	var map_data : Dictionary = {
		"head": {
			"name": map_name,
			"instant_kill": "LAVA"
		},
		"body": cells
	}
	
	var temp_key : String
	var temp_value : String
	for cell in maps[current_map].get_tile_map_layer().get_used_cells():
		# Convert vector2i data type to "x,y" that is just 2 numbers seperated by a comma
		# HACK: This is simple and can replace the method for many sub dict for vector2i x and y, consider refactoring
		temp_key = str(cell.x) + "," + str(cell.y)
		temp_value = str(get_atlas_coords_by_position(cell).x) + "," + str(get_atlas_coords_by_position(cell).y)
		cells[temp_key] = temp_value
	var json_string : String = JSON.stringify(map_data, '\t')
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json_string)
	print("MC/json/test save ", json_string)

func test_load_map_to_json(path: String = FileGlobals.maps_path + "/desolation.json"):
	var globalized_path = ProjectSettings.globalize_path(path)
	print("MC/json/load path ", globalized_path)
	var file = FileAccess.open(globalized_path, FileAccess.READ)
	
	var json_result : JSON = JSON.new()
	var error = json_result.parse(file.get_as_text())
	# Key and value for the tilemap tiles and their corresponding atlas coords
	var key : Vector2i
	var value : Vector2i
	if error == OK:
		var data = json_result.get_data()
		print("MC/json/head is ", data["head"])
		print("MC/json/head is ", data["head"]["name"])
		print("MC/json/head is ", data["head"]["instant_kill"])
		for i in data["body"]:
			key.x = i.get_slice(",", 0).to_int()
			key.y = i.get_slice(",", 1).to_int()
			value.x = data["body"][i].get_slice(",", 0).to_int()
			value.y = data["body"][i].get_slice(",", 1).to_int()
			print("MC/json/dict/ list ", key, " ", value)
	else:
		print("MC/json/error ? ", json_result.get_error_message())

## Set the default map when loading the maps
func default_map() -> String:
	current_map = 0
	return maps[current_map].get_map_name()

## Change the current map pointer to next and reset to head in circle if needed
func next_map() -> String:
	if current_map == maps.size() - 1:
		current_map = 0
	else:
		current_map += 1
	print("MC/next map ", maps[current_map].get_map_name(), " with id ", current_map)
	return maps[current_map].get_map_name()

## Change the current map pointer to prev and reset to head in circle if needed
func prev_map() -> String:
	if current_map == 0:
		current_map = maps.size() - 1
	else:
		current_map -= 1
	print("MC/prev map ", maps[current_map].get_map_name(), " with id ", current_map)
	return maps[current_map].get_map_name()

## Change the saved instant kill type setting and sync with the current map object also 
func change_map_instant_kill_type(instant_kill: int, map: Map):
	print("MC/change ikill to ", instant_kill)
	maps[current_map].set_instant_kill_type(instant_kill)
	map.set_instant_kill_type(instant_kill)

## Helper function to return atlas coords of a tile in the current tilemap
func get_atlas_coords_by_position(position: Vector2i):
	print("MC/atlas coords is ", maps[current_map].get_tile_map_layer().get_cell_atlas_coords(position))
	return maps[current_map].get_tile_map_layer().get_cell_atlas_coords(position)

## Draw a single tile, set tile to Vector2(-1, -1) to erase the tile instead
func draw_single_tile(pos: Vector2i, tile: Vector2i):
	if tile == TILE.ERASE_TILE:
		maps[current_map].get_tile_map_layer().erase_cell(pos)
		return
	maps[current_map].get_tile_map_layer().set_cell(pos, 1, tile, 0)

## Draw the entire rectangle of the same tile. This will require the rectangle to be kinda normalized
## Which mean the position paremeter must be top left and end must be top right
func draw_rect(rect: Rect2i, tile: Vector2i):
	print("MC/draw rect/rect is ", rect.position, rect.end)
	for y in range(rect.position.y, rect.end.y + 1):
		print("MC/draw rect/looping ", y)
		for x in range(rect.position.x, rect.end.x + 1):
			maps[current_map].get_tile_map_layer().set_cell(Vector2i(x, y), 1, tile, 0)
			print("MC/draw rect/drawing cell ", Vector2i(x, y))

## Fill all tile of the same type (source_tile) by another tile type (fill_type)
func fill_bucket(position: Vector2i, source_tile: Vector2i, fill_tile: Vector2i):
	var stack : Array[Vector2i] = []
	stack.append(position)
	
	print("MC/starting to recursive fill ", position)
	fill_bucket_recursive(source_tile, fill_tile, stack)

## Private recursive function to implement flood fill to fill the area. Not sure if its BFS or DFS lol but it works
func fill_bucket_recursive(source_tile: Vector2i, fill_tile: Vector2i, stack: Array[Vector2i]):
	print("MC/recursive/stack size ", stack.size())
	# Take from the end of the stack and check current node
	var current_node : Vector2i = stack.pop_back()
	# Set this node to the new tile type
	maps[current_map].get_tile_map_layer().set_cell(current_node, 1, fill_tile, 0)
	
	# Now loop over its neighbors, see if any tile is still the previous source_tile and append to stack 
	var neighbors : Array[Vector2i]
	neighbors.append(current_node + Vector2i(1,0))
	neighbors.append(current_node + Vector2i(-1,0))
	neighbors.append(current_node + Vector2i(0,1))
	neighbors.append(current_node + Vector2i(0,-1))
	for n in neighbors:
		print("MC/checking neighbor ", n, " so ", source_tile)
		# Add to stack if neighbor is still the old source_tile. Will not reinitate since old tiles is already set to new
		if get_atlas_coords_by_position(n) == source_tile:
			print("MC/neighbor is source")
			stack.append(n)
	
	# End if the stack is clear, aka everything has been filled after checking all neighbors
	if stack.is_empty():
		return
	
	fill_bucket_recursive(source_tile, fill_tile, stack)
