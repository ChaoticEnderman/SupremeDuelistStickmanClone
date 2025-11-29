## Base class for all weapons in the game, will have a mandatory hitbox, optional abilities
## This class will handle the ability releasing events from the joysticks and move its own physical weapon
extends Node2D
class_name Weapon

## The mandatory hitbox for the weapon for melee attacks
@export var hitbox : CharacterBody2D = CharacterBody2D.new()
@export var collision_shape = CollisionShape2D.new()
## Sprite for the weapon, also required like the melee weapon
@export var sprite : Sprite2D

## List of abilities in the weapon, can be at most two and at least zero
@export var abilities : Array[Ability]
## Index of the current ability, used to loop through them
## Initial value is -1 so it will become the first value or 0 when the game is initialized  
@export var ability_index : int = -1

## Cooldown for the weapon, if its in cooldown then it will ignore ability releases
@export var cooldown : int

## Weapon data resource
@export var weapon_data : WeaponData

## Damageable object for the melee hitbox
var damageable : Damageable
## The owner player of the weapon, will be slightly different from just the damageable player
## Because it can contain more data than damageable default
var player : Player

func init(player: Player) -> void:
	self.player = player

## Load and add its sprite
func add_sprite(sprite: Sprite2D, texture: Texture2D):
	self.sprite = sprite
	self.sprite.texture = texture
	sprite.scale = Vector2(0.2, 0.2)
	add_child(sprite)

## Set the hitbox area
func set_hitbox(id: String):
	weapon_data = load("res://resources/weapon" + id + ".tres")
	
	collision_shape.shape = weapon_data.hitbox
	hitbox.add_child(collision_shape)
	
	add_child(hitbox)
	hitbox.owner = self

## Set the melee damage
func set_damage(damageable: Damageable):
	self.damageable = damageable
	damageable.owner_stickman = player
	add_child(damageable)
	damageable.owner = self

## Set the cooldown
func set_cooldown(cooldown: int):
	self.cooldown = cooldown

## Runs independenly of physics to change the position and rotation of the weapon
func tick_rotation(rotation: Vector2):
	if rotation != Vector2.ZERO:
		sprite.global_position = self.position
		sprite.rotation = Vector2.UP.angle_to(rotation)
		collision_shape.rotation = Vector2.UP.angle_to(rotation)

func get_damage():
	return damageable.damage_tick

## Runs each physics tick to reduce cooldown, and change the sprite based on the state
func tick_cooldown():
	cooldown -= 1
	
	# Prototype dynamic thingy for like the responsive sprite, will be implemented as a full sprite soon
	if cooldown > 0:
		sprite.modulate = Color(0.1, 0.5, 0.1)
	else:
		sprite.modulate = Color(1, 1, 1)

## Release the next ability in the cycle
func tick_release_ability(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	
	if cooldown < 1:
		cooldown = abilities[ability_index].release_ability(player, direction) * Globals.WEAPON_COOLDOWN_MULTIPLIER
		# When the ability is outside the range of abilities, it will reset to 0
		ability_index += 1
		ability_index = ability_index % abilities.size()
		return true
	else:
		return false
