extends Node2D

var tile_map_layer : TileMapLayer

func _ready() -> void:
	tile_map_layer = get_node("TileMapLayer")
	tile_map_layer.set_tile_set(load("res://resources/default_tile_set.tres"))
	
	MapController.edit_map(0)
	MapController.draw_single_tile(Vector2i(0, 0), MapController.TILE.IK_WATER)
	
	#map_controller.load_map(0, tile_map_layer)
	print("map/after loading tiles ", tile_map_layer.get_used_cells().size())
	
	
