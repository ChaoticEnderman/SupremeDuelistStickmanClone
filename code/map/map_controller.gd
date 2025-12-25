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
	maps[0] = TileMapLayer.new()

## Load data of a map to the parameter map
func load_map(id: int, map: TileMapLayer):
	# Loop through the coordinates of the saved map
	for coords in maps[id].get_used_cells():
		map.set_cell(coords, 1, maps[id].get_cell_atlas_coords(coords))

## Choose the map that is currently being edited
func edit_map(id: int):
	current_map = maps[id]

## Erase all data of the current map
func clear_current_map():
	current_map.clear()

## Not working yet
func save_map_to_file(id: int):
	maps[id] = current_map

## Draw a single tile, set tile to Vector2(-1, -1) to erase the tile instead
func draw_single_tile(pos: Vector2i, tile: Vector2i):
	current_map.set_cell(pos, 1, tile, 0)
