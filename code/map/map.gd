extends Node2D
class_name MapGlobals

var map_controller : MapController
var tile_map_layer : TileMapLayer

func _ready() -> void:
	
	map_controller = MapController.new()
	tile_map_layer = get_node("TileMapLayer")
	tile_map_layer.set_tile_set(load("res://resources/default_tile_set.tres"))
	
	map_controller.edit_map(0)
	map_controller.draw_single_tile(Vector2i(0, 0))
	
	map_controller.load_map(0, tile_map_layer)
	print("map/after loading tiles ", tile_map_layer.get_used_cells().size())
	
	
