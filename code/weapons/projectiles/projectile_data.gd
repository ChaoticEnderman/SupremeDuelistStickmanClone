## Base class for all shared projectile data
extends Resource
class_name ProjectileData

@export var speed: float = 100.0

@export var is_affected_by_gravity: bool = false
@export var can_go_through_wall: bool = false

@export var sprite : NodePath
@export var hitbox : NodePath
