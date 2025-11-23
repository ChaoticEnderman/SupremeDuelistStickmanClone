## Base class for all projectiles that can be summoned by abilities
## This is intended to be summoned by the abilities and its subclass
## Not for using directly, only make a subclass of this class
extends Node2D
class_name Projectile

## The resource data of this projectile, containing some serializable variant data and the nodepaths
var projectile_data : ProjectileData
## This damageable object will be used for the damage of the projectile
var damageable : Damageable

## Reference to the hitbox node
var hitbox : RigidBody2D
var direction : Vector2

func _init() -> void:
	hitbox = RigidBody2D.new()
	add_child(hitbox)

## Called right after the projectile is created, to do all the needed setup and shoot it
func summon(owner: Player, data: ProjectileData, direction: Vector2, position: Vector2) -> void:
	projectile_data = data
	# Construct the hitbox node
	hitbox.add_child(projectile_data.hitbox_path.instantiate())
	hitbox.add_child(projectile_data.sprite_path.instantiate())
	damageable = Damageable.new(projectile_data.damage)
	add_child(damageable)
	
	# Set the hitbox and damagable to self, this is used for like checking if the owner of the hitbox has a node damageable
	hitbox.owner = self
	damageable.owner = self
	
	hitbox.position = position
	self.direction = direction
	
	# Nullify the gravity if like its not affected
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

## Helper function to shorten the length of the code to getting the damage value
func get_damage() -> int:
	return damageable.damage_tick

## Runs each physics tick to check collision and other stuff
func tick():
	self.check_collision()

## Internal method that is not supposed to be called from children, just call tick() instead
func check_collision():
	for body in hitbox.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			queue_free()
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				queue_free()
