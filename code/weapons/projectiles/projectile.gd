## Base class for all projectiles that can be summoned by abilities
## This is intended to be summoned with ability and its subclass
extends Node2D
class_name Projectile

# Components
var projectile_data : ProjectileData
var damageable : Damageable

var hitbox : RigidBody2D
var to_kill : bool = false

var direction : Vector2

func setup(owner: Player, data: ProjectileData) -> void:
	projectile_data = data
	hitbox = get_node("Hitbox")
	damageable = Damageable.new(5)
	hitbox.position = Vector2(400.0, 400.0) + Vector2(randf_range(-100.0,100.0), randf_range(-100.0,100.0))
	
	#direction = projectile_data.direction 
	direction = Vector2.from_angle(deg_to_rad(randf_range(0.0, 360.0)))
	
	if projectile_data.is_affected_by_gravity:
		hitbox.gravity_scale = 0.5
	else:
		hitbox.gravity_scale = 0.0
	hitbox.contact_monitor = true
	hitbox.max_contacts_reported = 100
	
	damageable.owner_stickman = owner
	
	# Make the projectile doesnt touch the owner
	for child in damageable.owner_stickman.ragdoll.get_children():
		hitbox.add_collision_exception_with(child)
	
	# Shooting the projectile
	hitbox.apply_central_impulse(direction * projectile_data.speed)

func get_damage() -> int:
	return damageable.get_damage()

func tick():
	check_collision()

func check_collision():
	for body in hitbox.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			to_kill = true
		if body is RigidBody2D and body.get_owner() is Player:
			to_kill = true
