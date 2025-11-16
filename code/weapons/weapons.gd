extends Node2D
class_name Weapon

@export var hitbox : CollisionShape2D
@export var sprite : Sprite2D

@export var abilities : Array[String] = []
@export var ability_cycle : int = 0
@export var ability_cycle_max : int

@export var cooldown : int

var damageable : Damageable
var player : Player

var world : Node2D

func init(player: Player) -> void:
	ability_cycle_max = abilities.size()
	damageable = Damageable.new(5)
	self.player = player
	
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/weapon1.png")
	add_child(sprite)
	
	sprite.scale = Vector2(0.2, 0.2)

func tick(rotation: Vector2):
	cooldown -= 1
	if rotation != Vector2.ZERO:
		sprite.global_position = self.position
		sprite.rotation = Vector2.UP.angle_to(rotation)
	
	if cooldown > 0:
		sprite.modulate = Color(0.1, 0.5, 0.1)
	else:
		sprite.modulate = Color(1, 1, 1)

func tick_release_ability(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	world = get_tree().get_root().get_node("World")
	
	if cooldown < 1:
		var projectile = load("res://scenes/projectile.tscn").instantiate()
		world.add_projectile(projectile)
		projectile.summon(player, load("res://resources/projectile1.tres"), direction, player.hand_position)
		cooldown = WeaponGlobals.WEAPON_COOLDOWNS.SHORT
		return true
	else:
		return false
