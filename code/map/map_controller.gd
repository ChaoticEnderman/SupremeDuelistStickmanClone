## Control class for the low level basic operations to the map, like save, load, draw, draw rect, ...
## Work mostly as a type of abstraction for the TileMapLayer functions, also for storing the maps
extends Node

## List of all saved maps in the game
# TODO: Add some default maps later on
# HACK: Storing maps as different map entities instead of resource, will need optimization later on
var maps : Array[TileMapLayer]

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

## Reference to the map that is being actively edited
var current_map : TileMapLayer

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

func _init() -> void:
	maps.resize(10)
	for i in range(10):
		maps[i] = TileMapLayer.new()

## Load data of the current map to the parameter map
## This can be inefficient since it require loading the entire map each time it is edited
# FIXME: A way to cache the last change and only load that change each time instead of everything
# TODO: For that, make a variable to store the latest change and a special quickload function to load only the edited part
func load_map(map: TileMapLayer):
	map.clear()
	# Loop through the coordinates of the saved map
	for coords in current_map.get_used_cells():
		map.set_cell(coords, 1,current_map.get_cell_atlas_coords(coords))

## Choose the map that is currently being edited
func edit_map(id: int):
	current_map = maps[id]

## Erase all data of the current map
func clear_current_map():
	current_map.clear()

## Save the current map to file in a custom .dat format
func save_map_to_file(id: int, map_name: String):
	var path : String = "res://maps/map001.dat"
	# First line of the file is for the map name
	var string : String = map_name + '\n'
	for coords in current_map.get_used_cells():
		# Method used to store file: Each coordinate is stored in blocks of 4 ints
		# They are tile coord x and y, atlas x and y respectively seperated by a comma
		# The file is read in a similiar manner
		string = string + str(coords.x) + "," + str(coords.y) + ","
		string = string + str(current_map.get_cell_atlas_coords(coords).x) + "," + str(current_map.get_cell_atlas_coords(coords).y) + ","
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(string)

## Read, decrypt, and load up map data from file
func read_map_from_file(map: TileMapLayer) -> bool:
	var path : String = "res://maps/map001.dat"
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if !FileAccess.file_exists(path):
		return false
	
	var tile_coords : Vector2i
	var atlas_coords : Vector2i
	current_map.clear()
	var i : int = 0
	# Ignoring the first line as its just for names and we dont need to read the names here
	print("MC/reading file name: ", file.get_line())
	var parsed_array : PackedStringArray = file.get_csv_line()
	# Since the size is always in the form of 3n+1, minus 4 so that the last iteration wont be out of bounds
	while i < parsed_array.size() - 4:
		# As mentioned in the save, the data is assumed to be int without any checking
		# Also the order is this because like it wont be changed later on
		tile_coords.x = int(parsed_array[i])
		tile_coords.y = int(parsed_array[i+1])
		atlas_coords.x = int(parsed_array[i+2])
		atlas_coords.y = int(parsed_array[i+3])
		current_map.set_cell(tile_coords, 1, atlas_coords, 0)
		# Batching the reads 4 at a time
		i += 4
	load_map(map)
	return true

## Draw a single tile, set tile to Vector2(-1, -1) to erase the tile instead
func draw_single_tile(pos: Vector2i, tile: Vector2i):
	if tile == TILE.ERASE_TILE:
		print("MC/erasing tile ", tile)
		current_map.set_cell(pos, 1, TILE.MAGMA, 0)
		current_map.erase_cell(pos)
		return
	print("MC/not erasing")
	current_map.set_cell(pos, 1, tile, 0)
