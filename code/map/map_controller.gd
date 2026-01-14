## Control class for the low level basic operations to the map, like save, load, draw, draw rect, ...
## Work mostly as a type of abstraction for the TileMapLayer functions, also for storing the maps
extends Node

## List of all saved maps in the game
# TODO: Add some default maps later on
# HACK: Storing maps as different map entities instead of resource, will need optimization later on
var maps : Array[TileMapLayer]
## List of map names, must be in 1-1 direct mapping with the maps array
var map_names : Array[String]

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

## Reference to the map that is being actively edited
var current_map : int

## Dictionary to save tiles of the tilemap that map to the atlas coords
const TILE := {
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

## To store the status after saving the file
enum SAVE_MAP_ERROR {SUCCESS, FILE_EXIST, FAILED}

func _init() -> void:
	pass

## Load data of the current map to the parameter map
## This can be inefficient since it require loading the entire map each time it is edited
# FIXME: A way to cache the last change and only load that change each time instead of everything
# TODO: For that, make a variable to store the latest change and a special quickload function to load only the edited part
func load_map(map: TileMapLayer):
	map.clear()
	# Loop through the coordinates of the saved map
	for coords in maps[current_map].get_used_cells():
		map.set_cell(coords, 1,maps[current_map].get_cell_atlas_coords(coords))

## Set the current map to the id position in the map array
func edit_map(id: int):
	current_map = id

## Erase all data of the current map
func clear_current_map():
	maps[current_map].clear()


## Save the current map to file in a custom .dat format
func save_map_to_file(map_name: String, overriding_map: bool) -> SAVE_MAP_ERROR:
	var path : String = "res://maps/" + map_name + ".dat"
	# If player tried to save a map, it will return a warning. If player bypass that and override then it will do
	if FileAccess.file_exists(path) and overriding_map == false:
		return SAVE_MAP_ERROR.FILE_EXIST
	var string : String = ""
	for coords in maps[current_map].get_used_cells():
		# Method used to store file: Each coordinate is stored in blocks of 4 ints
		# They are tile coord x and y, atlas x and y respectively seperated by a comma
		# The file is read in a similiar manner
		string = string + str(coords.x) + "," + str(coords.y) + ","
		string = string + str(maps[current_map].get_cell_atlas_coords(coords).x) + "," + str(maps[current_map].get_cell_atlas_coords(coords).y) + ","
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(string)
	return SAVE_MAP_ERROR.SUCCESS

## Read, decrypt (the custom data type), and load up map data from file
func read_map_from_file(map_name: String) -> bool:
	var path : String = "res://maps/" + map_name + ".dat"
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if !FileAccess.file_exists(path):
		return false
	
	var tile_coords : Vector2i
	var atlas_coords : Vector2i
	maps[current_map].clear()
	var i : int = 0
	var parsed_array : PackedStringArray = file.get_csv_line()
	# Since the size is always in the form of 3n+1, minus 4 so that the last iteration wont be out of bounds
	while i < parsed_array.size() - 4:
		# As mentioned in the save, the data is assumed to be int without any checking
		# Also the order is this because like it wont be changed later on
		tile_coords.x = int(parsed_array[i])
		tile_coords.y = int(parsed_array[i+1])
		atlas_coords.x = int(parsed_array[i+2])
		atlas_coords.y = int(parsed_array[i+3])
		maps[current_map].set_cell(tile_coords, 1, atlas_coords, 0)
		# Batching the reads 4 at a time
		i += 4
	return true

## Read all maps in the folder and put into the maps array after clearing all
func clear_and_read_all_maps_from_file() -> bool:
	var dir = DirAccess.open("res://maps/")
	if not dir:
		return false
	# When loading all maps for the game everything should be cleared
	maps.clear()
	map_names.clear()
	dir.list_dir_begin()
	# Assume that at least one map exist
	var file_name : String = " "
	var map_name : String = ""
	var extension : String = ""
	var i : int = 0
	while file_name != "":
		file_name = dir.get_next()
		extension = file_name.substr(file_name.length() - 4, 4)
		# Basic check if the extension is .dat file
		if extension == ".dat":
			map_name = file_name.substr(0, file_name.length() - 4)
			maps.append(TileMapLayer.new())
			map_names.append("")
			map_names[i] = map_name
			# Use the other functions to read from file one by one
			edit_map(i)
			read_map_from_file(map_name)
			# Only incremental if the map is valid, so the maps array will have no wasted space
			i += 1
	return true

## Set the default map when loading the maps
func default_map() -> String:
	current_map = 0
	return map_names[current_map]

## Change the current map pointer to next and reset to head in circle if needed
func next_map() -> String:
	if current_map == maps.size() - 1:
		current_map = 0
	else:
		current_map += 1
	return map_names[current_map]

## Change the current map pointer to prev and reset to head in circle if needed
func prev_map() -> String:
	if current_map == 0:
		current_map = maps.size() - 1
	else: current_map -= 1
	return map_names[current_map]

## Draw a single tile, set tile to Vector2(-1, -1) to erase the tile instead
func draw_single_tile(pos: Vector2i, tile: Vector2i):
	if tile == TILE.ERASE_TILE:
		maps[current_map].erase_cell(pos)
		return
	maps[current_map].set_cell(pos, 1, tile, 0)

## Draw the entire rectangle of the same tile, not implemented yet
# TODO: Implement this
func draw_rect(rect: Rect2i, tile: Vector2i):
	pass
