## Base class for all shared projectile data
extends Resource
class_name ProjectileData

@export var speed: float

@export var damage: int

@export var is_affected_by_gravity: bool
@export var can_go_through_wall: bool

@export var sprite_path : PackedScene
@export var hitbox_path : PackedScene
