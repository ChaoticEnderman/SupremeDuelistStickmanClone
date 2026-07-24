## Passive arrow projectile for crossbow and potentially bow later on
extends Projectile
class_name Projectile7

## Storing previous position of the projectile to calculate dynamic direction each time
var prev_position : Vector2

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, load("res://resources/projectile7.tres"))

func get_damage() -> float:
	return super.get_damage()

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	var direction = (self.position - prev_position).normalized()
	var rotation = Vector2.UP.angle_to(direction)
	self.rotation = rotation
	
	prev_position = self.position

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(7)
	# 11th position
	data.append(prev_position.x)
	data.append(prev_position.y)
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		prev_position.x = data.get(i)
		prev_position.y = data.get(i + 1)
		return true
	return false

func qfree():
	super.qfree()
	self.queue_free()
