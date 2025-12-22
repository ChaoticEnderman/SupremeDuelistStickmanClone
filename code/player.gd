## A node for controlling everything regard to a player in the game
## Contain a ragdoll, one input manager which is a joystick or other types of input such as controllers or keyboard
## Also contain specific HUD elements tied to that player such as hp bar and jump bar
extends Node2D
class_name Player

## The physical body of this player
@onready var ragdoll : Node2D = get_node("RagdollPhysicsManager")
## HUD jump bar
@onready var jump_bar : ProgressBar = get_node("JumpBar")
## HUD health bar
@onready var health_bar : ProgressBar = get_node("HealthBar")
## HUD score label to display numerical score
@onready var score_label : Label = get_node("ScoreLabel")
## Stylebox element to override hp bar color
@onready var health_bar_color : StyleBoxFlat = health_bar.get_theme_stylebox("fill").duplicate()

## Input manager scene that handle all types of input
var input_manager = CanvasLayer

## The single weapon that this stickman hold, since each stickman have exactly one weapon holding
var weapon = Weapon

# Position and direction
var player_position : Vector2 = Vector2.ZERO
var player_direction : Vector2 = Vector2.ZERO

## Position of the hand, the starting point for melee weapons and projectiles
var hand_position : Vector2 = Vector2.ZERO

## The hp
var player_hp : float = Globals.STARTING_HP

## Score of the player, will be carried over rounds of the same session
var score : int = 0

## Will change when the player is dead (when their hp is zero)
var is_dead : bool = false

var player_side : PlayerSpriteGlobals.PLAYER

func initialize(is_real_player: bool, joystick_position: Globals.JOYSTICK_POSITION, weapon: Weapon, player_side: PlayerSpriteGlobals.PLAYER):
	# Not connecting now since like the world need to dictate the order of these, see world for info
	#GameState.game_tick.connect(_on_game_tick)
	self.weapon = weapon
	player_hp = 100.0
	is_dead = false
	# Real player variable is reserved for bots long ago, but seems like this will probably never be added
	# This will just be like an artifact of the early stages of development where its kinda unclear
	if is_real_player:
		input_manager = load("res://scenes/joystick.tscn").instantiate()
		add_child(input_manager)
		input_manager.set_joystick_corner(joystick_position)
	self.player_side = player_side
	# Create a custom stylebox for changing the hp bar color and override the fill stylebox
	health_bar.add_theme_stylebox_override("fill", health_bar_color)
	
	# Make the player not touch the hitbox
	ragdoll.ragdoll_collision_exception(weapon.hitbox)
	
	# Add the color to the player
	ragdoll.torso.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.TORSO, player_side)
	ragdoll.stomach.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.STOMACH, player_side)
	ragdoll.a_thigh.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_THIGH, player_side)
	ragdoll.a_shin.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_SHIN, player_side)
	ragdoll.b_thigh.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.R_THIGH, player_side)
	ragdoll.b_shin.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.R_SHIN, player_side)
	ragdoll.p_arm.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_ARM, player_side)
	ragdoll.p_forearm.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_FOREARM, player_side)

# Master tick function to tick the player and its dependencies
func _on_game_tick():
	# Get input for this tick from input manager and store, first step
	player_direction = input_manager.tick_input()
	
	# Check for abilities being used
	weapon.tick_release_ability(input_manager.tick_input_is_releasing())
	
	# Check the last jump input before ticking ragdoll
	ragdoll.jump(input_manager.tick_input_is_jumping())
	
	# Ticking ragdoll, that function will tick other ragdoll functions
	ragdoll.tick_ragdoll(player_direction)
	
	# Check for hitbox collision to damages
	check_collision()
	
	# Change cooldown for the weapon
	weapon.tick_cooldown()
	
	# Update the position
	if self.player_side == PlayerSpriteGlobals.PLAYER.LEFT:
		SystemManager.p1_position = self.ragdoll.torso.global_position
	elif self.player_side == PlayerSpriteGlobals.PLAYER.RIGHT:
		SystemManager.p2_position = self.ragdoll.torso.global_position
	
	tick_weapon_hud()

func _process(delta: float) -> void:
	tick_hud()

## Several simple update functions to update the huds, will work independently on physics tick
## Including at the game state of lazy loading
func tick_hud():
	update_jump_bar()
	update_health_bar()
	update_score_label()
	hand_position = ragdoll.p_forearm.global_position

## Update the value and the visibility status of the jump bar according to the jump time
func update_jump_bar():
	# Reset jump when the radgoll just jumped and is airborne
	if ragdoll.jump_cache == 0:
		jump_bar.value = 0
		input_manager.jumping_time = 0 
	# Otherwise, update the jump bar by the jumping percentage
	else:
		jump_bar.value = input_manager.jumping_time
	
	jump_bar.max_value = Globals.JUMP_TIME
	jump_bar.set_position(ragdoll.head.position + Vector2(-30.0, -40.0)) # Offsetting the bar so it will be on top of the player head
	
	if input_manager.jumping_time > 0:
		jump_bar.visible = true
	else:
		jump_bar.visible = false

## Update health bar to the current hp value
func update_health_bar():
	health_bar.value = player_hp
	health_bar.set_position(ragdoll.head.position + Vector2(-30.0, -30.0))
	# To create a gradient for the hp bar. Note that the values range from 0 to 1
	# Also change the color space to srgb to display, the value seems like linear idk
	health_bar_color.bg_color = Color(((100 - health_bar.value) / 100), (health_bar.value / 100), 0).linear_to_srgb()
	
	if player_hp <= 0.0:
		ragdoll.dying_animation()
		self.is_dead = true

## Update score label to follow the player and change according to the rounds score
func update_score_label():
	score_label.text = str(score)
	score_label.scale = Vector2(2.0, 2.0)
	score_label.set_position(ragdoll.head.position + Vector2(-20.0, -60.0))

## Call the tick function from the weapon
func tick_weapon_hud():
	if ragdoll.is_alive:
		weapon.position = hand_position
		weapon.tick_rotation(player_direction)

## Check for player collision with anything that can do damage
func check_collision():
	var damages : Array[float] = ragdoll.tick_check_damage_collisions()
	if not (damages == null or damages == []):
		for damage in damages:
			player_hp -= damage * Globals.DAMAGE_MULTIPLIER

func _queue_free():
	weapon._queue_free()
	input_manager.queue_free()
	for child in get_children(true):
		child.queue_free()
	queue_free()

func is_dead_check() -> bool:
	return is_dead
