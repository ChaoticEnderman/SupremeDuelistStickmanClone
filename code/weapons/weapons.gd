## Base class for all weapons in the game, will have a mandatory hitbox, optional abilities
## This class will handle the ability releasing events from the joysticks and move its own physical weapon
extends Node2D
class_name Weapon

## The mandatory hitbox for the weapon for melee attacks
@export var hitbox : CollisionShape2D
## Sprite for the weapon, also required like the melee weapon
@export var sprite : Sprite2D

## List of abilities in the weapon, can be at most two and zero
@export var abilities : Array[AbilityProjectile]
## The ability chain in case
@export var ability_cycle : int = 0
@export var ability_cycle_max : int

@export var ability_index : int = 0

@export var cooldown : int

var damageable : Damageable
var player : Player

var world : Node2D

func init(player: Player) -> void:
	self.player = player

func set_abilities(abilities: Array[AbilityProjectile]):
	self.abilities = abilities

func add_sprite(sprite: Sprite2D, texture: Texture2D):
	self.sprite = sprite
	self.sprite.texture = texture
	sprite.scale = Vector2(0.2, 0.2)
	add_child(sprite)

func set_damage(damageable: Damageable):
	self.damageable = damageable

func set_cooldown(cooldown: int):
	self.cooldown = cooldown

func _ready():
	world = get_tree().get_root().get_node("World")

func tick(rotation: Vector2):
	cooldown -= 1
	if rotation != Vector2.ZERO:
		sprite.global_position = self.position
		sprite.rotation = Vector2.UP.angle_to(rotation)
	
	# Prototype dynamic thingy for like the responsive sprite, will be implemented as a full sprite soon
	if cooldown > 0:
		sprite.modulate = Color(0.1, 0.5, 0.1)
	else:
		sprite.modulate = Color(1, 1, 1)

func tick_release_ability(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	
	if cooldown < 1:
		return true
	else:
		return false
