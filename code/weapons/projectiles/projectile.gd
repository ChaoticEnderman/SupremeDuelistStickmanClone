## Base class for all projectiles that can be summoned by abilities
## This is intended to be summoned with ability and its subclass
extends RigidBody2D
class_name Projectile

@export var data : ProjectileData

@export var speed : float
@export var direction : Vector2

@export var is_affected_by_gravity : bool
@export var can_go_through_wall : bool

@export var hitbox : CollisionShape2D
@export var owner_stickman : Node2D

func tick():
	apply_central_force(direction * speed)
	check_collision()

func check_collision():
	for body in self.get_colliding_bodies():
		if body is TileMapLayer and not can_go_through_wall:
			self.free()
		if body is RigidBody2D:
			print("PROJECTILE COLLIDING WITH ", body)
