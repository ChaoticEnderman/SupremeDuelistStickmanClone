## Bigger map class to control everything about a map. Other than just a TileMapLayer, this class will need to control its own TilemapLayer
## This will also contain other parameters of a map like the infinite damaging area for water and stuff
## As well as other potential settings later on
extends Node2D
class_name Map

## Name for the map
var map_name : String

## TileMapLayer object of this map, used to represent the tiles
var tile_map_layer : TileMapLayer = TileMapLayer.new()
## Instant kill zone that sketch really far, to the bit limit of the x axis and decently deep under the y axis
var instant_kill_zone : Area2D = Area2D.new()
## Collision shape for the instant kill zone
var instant_kill_zone_collision_shape : CollisionShape2D = CollisionShape2D.new()
## Repeating texture for showing the instant kill visual
var instant_kill_zone_texture : TextureRect = TextureRect.new()

## Value to see how deep or shallow will the instant kill zone go in the y axis
var instant_kill_zone_y_displacement : int = 500

## Store data for this map's instant kill type
var instant_kill_type : MapController.INSTANT_KILL_TYPE = MapController.INSTANT_KILL_TYPE.NONE

## Texture atlas region coordinates for the repeating texture for the instant kill zone
const INSTANT_KILL_SPRITE : Dictionary = {
	MapController.INSTANT_KILL_TYPE.ACID: "res://assets/instant_kill_acid.png",
	MapController.INSTANT_KILL_TYPE.LAVA: "res://assets/instant_kill_lava.png",
	MapController.INSTANT_KILL_TYPE.WATER: "res://assets/instant_kill_water.png"
}

func get_map_name() -> String:
	return map_name

func set_map_name(map_name: String):
	self.map_name = map_name

func get_tile_map_layer() -> TileMapLayer:
	return self.tile_map_layer

func set_tile_map_layer(tile_map_layer: TileMapLayer):
	self.tile_map_layer = tile_map_layer

func get_instant_kill_type() -> int:
	return instant_kill_type

func set_instant_kill_type(instant_kill_type: int):
	self.instant_kill_type = instant_kill_type
	change_instant_kill_type(instant_kill_type)


func _init() -> void:
	add_child(instant_kill_zone)
	instant_kill_zone.add_child(instant_kill_zone_collision_shape)
	instant_kill_zone.add_child(instant_kill_zone_texture)
	add_child(tile_map_layer)
	
	# Add default settings for the texture
	#instant_kill_zone_texture.texture = load("res://assets/instant_kill_water.png")
	set_instant_kill_type(MapController.INSTANT_KILL_TYPE.NONE)
	instant_kill_zone_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	instant_kill_zone_texture.stretch_mode = TextureRect.STRETCH_TILE
	instant_kill_zone_texture.size = Vector2(63356.0, 10000.0)
	instant_kill_zone_texture.position = Vector2(-32768.0, 0.0 + instant_kill_zone_y_displacement)
	
	# Default settins for the shape
	var shape : Shape2D = RectangleShape2D.new()
	shape.size = Vector2(65536.0, 10000.0)
	instant_kill_zone_collision_shape.shape = shape
	instant_kill_zone_collision_shape.position = Vector2(0.0, 5000.0 + instant_kill_zone_y_displacement)
	# TODO: Add collision mask as an enum in some kind of globals
	instant_kill_zone.set_collision_layer_value(4, true)
	
	print("map/tree ", instant_kill_zone_collision_shape.shape)

func _ready() -> void:
	tile_map_layer.set_tile_set(load("res://resources/default_tile_set.tres"))
	
	MapController.load_map(self)
	
	print("map/after loading tiles ", tile_map_layer.get_used_cells().size())

## Use to edit components like instant kill zone after the map is added to the scene tree
## instant_kill is a reference to MapController enum INSTANT_KILL_TYPE
func change_instant_kill_type(instant_kill: int):
	if instant_kill == MapController.INSTANT_KILL_TYPE.NONE:
		instant_kill_zone.visible = false
		print("map/ikill none ")
	else:
		instant_kill_zone.visible = true
		print("map/ikill texture region ", instant_kill, " path ", INSTANT_KILL_SPRITE[instant_kill])
		instant_kill_zone_texture.texture = load(INSTANT_KILL_SPRITE[instant_kill])
