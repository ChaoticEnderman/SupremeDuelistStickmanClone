## Base class for all shared projectile data
extends Resource
class_name ProjectileData

@export var speed: float = 10.0
@export var direction: Vector2 = Vector2.RIGHT

@export var is_affected_by_gravity: bool = false
@export var can_go_through_wall: bool = false

@export var hitbox_scene : PackedScene
@export var sprite : NodePath
