# Sniper fast bouncy projectile
extends Projectile
class_name Projectile9

signal reduce_cooldown

var emit_signal : bool = false

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, load("res://resources/projectile9.tres"))
	
	# On the RigidBody2D
	var material = PhysicsMaterial.new()
	material.bounce = 1.0
	material.friction = 0.0
	physics_material_override = material

func _on_game_tick(delta: float):
	check_collision()

## Overriding collision check to disable tilemap collision to bounce instead
## Also signal to the weapon to reduce cooldown if hit a player
func check_collision():
	for body in self.get_colliding_bodies():
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				if not emit_signal:
					reduce_cooldown.emit()
					emit_signal = true
					qfree()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(9)
	# 11th position
	# note: dont need to serialize the cooldown since it will be serialized on the player side
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		return true
	return false

func get_damage() -> float:
	return super.get_damage()

func qfree():
	super.qfree()
	self.queue_free()
