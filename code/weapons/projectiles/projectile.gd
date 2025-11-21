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

func _init() -> void:
	hitbox = RigidBody2D.new()
	add_child(hitbox)

func summon(owner: Player, data: ProjectileData, direction: Vector2, position: Vector2) -> void:
	projectile_data = data
	hitbox.add_child(projectile_data.hitbox_path.instantiate())
	hitbox.add_child(projectile_data.sprite_path.instantiate())
	damageable = Damageable.new(projectile_data.damage)
	add_child(damageable)
	
	hitbox.owner = self
	damageable.owner = self
	
	hitbox.position = position
	self.direction = direction
	
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
	hitbox.add_collision_exception_with(damageable.owner_stickman.weapon.hitbox)
	
	# Shooting the projectile
	hitbox.apply_central_impulse(direction * projectile_data.speed)

## Function to shorten the length of the code to getting the damage value
func get_damage() -> int:
	return damageable.damage_tick

func tick():
	self.check_collision()

## Internal method that is not supposed to be called from children, just call tick() instead
func check_collision():
	for body in hitbox.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			print("Killing at wall")
			to_kill = true
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				to_kill = true
				print("Killing at enemy")
