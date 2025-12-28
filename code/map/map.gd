extends Node2D

var tile_map_layer : TileMapLayer

func _ready() -> void:
	tile_map_layer = get_node("TileMapLayer")
	tile_map_layer.set_tile_set(load("res://resources/default_tile_set.tres"))
	
	MapController.load_map(tile_map_layer)
	
	print("map/after loading tiles ", tile_map_layer.get_used_cells().size())
	
	
