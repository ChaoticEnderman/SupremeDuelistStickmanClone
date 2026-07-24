## Area for the bomb explosion
class_name Projectile14
extends GameArea

var timeout : int = 1

func _init(player: Player, direction: Vector2, position: Vector2):
	super._init(player, direction, position)
	super.add_projectile_data(load("res://resources/projectile14.tres"))
	super.add_collision_shape(projectile_data.hitbox)
	GameState.game_tick.connect(_on_game_tick)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)

func _on_game_tick(delta: float):
	super._on_game_tick(delta)

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(2)
	# 10th value from here
	data.append(float(timeout))
	return data

func deserialize_object_data(data: PackedFloat32Array) -> bool:
	if super.deserialize_object_data(data):
		var i : int = 9
		timeout = int(data.get(i))
		return true
	return false

func _physics_process(delta: float) -> void:
	timeout -= 1
	if timeout == 0:
		self.qfree()

func qfree():
	super.qfree()
	self.queue_free()
