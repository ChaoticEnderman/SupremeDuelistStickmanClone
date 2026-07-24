## Stunning zone for the gauntlet weapon, will be really short
extends GameArea
class_name Projectile4

var tick : int

func _init(player: Player, direction: Vector2, position: Vector2):
	super._init(player, direction, position)
	
func _ready() -> void:
	var projectile_data : ProjectileData = load("res://resources/projectile4.tres")
	add_projectile_data(projectile_data)
	add_collision_shape(projectile_data.hitbox)
	summon_as_projectile(direction, position)
	GameState.game_tick.connect(_on_game_tick)
	tick = Globals.TPS / 2
	
	sprite.scale = Vector2(1.0, 1.0)

func _on_game_tick(delta: float):
	# If the player is deleted then skip frame
	if get_dependent_player() == null:
		qfree()
	else:
		tick -= 1
		if tick <= 0:
			qfree()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(2)
	# 10th value from here
	data.append(float(tick))
	return data

func deserialize_object_data(data: PackedFloat32Array) -> bool:
	if super.deserialize_object_data(data):
		var i : int = 9
		tick = int(data.get(i))
		return true
	return false

func qfree():
	super.qfree()
	self.queue_free()
