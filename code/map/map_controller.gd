## Control class for the low level basic operations to the map, like save, load, draw, draw rect, ...
## Work mostly as a type of abstraction for the TileMapLayer functions, also for storing the maps
extends Node
class_name MapController

## List of all saved maps in the game
# TODO: Add some default maps later on
# HACK: Storing maps as different map entities instead of resource, will need optimization later on
var maps : Array[TileMapLayer]

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

## Reference to the map that is being actively edited
var current_map : TileMapLayer

func _init() -> void:
	maps.resize(10)
	maps[0] = TileMapLayer.new()

func load_map(id: int, map: TileMapLayer):
	map.clear()
	# Loop through the coordinates of the saved map
	for coords in maps[id].get_used_cells():
		map.set_cell(coords, 1, maps[id].get_cell_atlas_coords(coords))
	

## Choose the map that is currently being edited
func edit_map(id: int):
	current_map = maps[id]

func save_map_to_file(id: int):
	maps[id] = current_map

func draw_single_tile(pos: Vector2i):
	current_map.set_cell(pos, 1, Vector2i(6, 0), 0)
