## Base class for all shared projectile data
extends Resource
class_name ProjectileData

@export var speed: float
@export var damage: float

@export var gravity_scale: float
@export var can_go_through_wall: bool

@export var sprite : Texture
@export var hitbox : Shape2D
