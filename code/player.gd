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
var player_hp : int = 100

func initialize(is_real_player: bool, joystick_position: Globals.JOYSTICK_POSITION, weapon: Weapon):
	self.weapon = weapon
	if is_real_player:
		input_manager = load("res://scenes/joystick.tscn").instantiate()
		add_child(input_manager)
		input_manager.set_joystick_corner(joystick_position)
	# Create a custom stylebox for changing the hp bar color and override the fill stylebox
	health_bar.add_theme_stylebox_override("fill", health_bar_color)

func tick_player():
	# Get input for this tick from input manager and store, first step
	player_direction = input_manager.tick_input()
	
	# Check for abilities being used
	weapon.tick_release_ability(input_manager.tick_input_is_releasing())
	
	# Check the last input before ticking ragdoll
	ragdoll.jump(input_manager.tick_input_is_jumping())
	
	# Ticking ragdoll, that function will tick other ragdoll functions
	ragdoll.tick_ragdoll(player_direction)
	
	# Just several simple update functions but will be made to a full function for updating HUD later on
	update_jump_bar()
	update_health_bar()
	
	# Tick the weapon
	update_weapon()
	
	# Testing
	check_collision()
	
	#hand_position = ragdoll.p_arm.global_position
	hand_position = ragdoll.p_forearm.global_position

func update_jump_bar():
	# Reset jump when the radgoll just jumped and is airborne
	if ragdoll.jump_cache == 0:
		jump_bar.value = 0
		input_manager.jumping_time = 0 
	# Otherwise, update the jump bar by the jumping percentage
	else:
		jump_bar.value = input_manager.jumping_time
	jump_bar.set_position(ragdoll.head.position + Vector2(-30.0, -40.0)) # Offsetting the bar so it will be on top of the player head
	
	if input_manager.jumping_time > 0:
		jump_bar.visible = true
	else:
		jump_bar.visible = false
	
func update_health_bar():
	health_bar.value = player_hp
	health_bar.set_position(ragdoll.head.position + Vector2(-30.0, -30.0))
	# To create a gradient for the hp bar. Note that the values range from 0 to 1
	# Also change the color space to srgb to display, the value seems like linear idk
	health_bar_color.bg_color = Color(((100 - health_bar.value) / 100), (health_bar.value / 100), 0).linear_to_srgb()

func update_weapon():
	weapon.position = hand_position
	weapon.tick(player_direction)

func check_collision():
	var damages : Array[int] = ragdoll.tick_check_damage_collisions()
	if not (damages == null or damages == []):
		for d in damages:
			player_hp -= d
	
	if player_hp <= 0:
		ragdoll.dying_animation()
