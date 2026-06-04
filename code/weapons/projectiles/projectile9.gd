# Sniper fast bouncy projectile
extends Projectile
class_name Projectile9

signal reduce_cooldown

var emit_signal : bool = false

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)
	
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


func get_damage() -> float:
	return super.get_damage()

func qfree():
	super.qfree()
	self.queue_free()
