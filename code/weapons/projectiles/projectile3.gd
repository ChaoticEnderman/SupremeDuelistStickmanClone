## Projectile object for the gauntlet projectile
extends Projectile
class_name Projectile3

var game_tick : int = 0

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, load("res://resources/projectile3.tres"))

func get_damage() -> float:
	print("P3/damage is ", super.get_damage())
	return super.get_damage()

## Runs each physics tick to check collision and other stuff
func _on_game_tick(delta: float):
	# Rough speed estimation, to bounce again many times in the directed direction at the start
	var estimated_speed : float = self.linear_velocity.distance_to(Vector2.ZERO)
	if estimated_speed < 1000:
		self.apply_central_impulse(direction * projectile_data.speed)
	
	game_tick += 1
	if game_tick > Globals.TPS * 2:
		self.queue_free()
	self.check_collision()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(3)
	# 11th position
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		return true
	return false

func check_collision():
	pass

func qfree():
	super.qfree()
	self.queue_free()
