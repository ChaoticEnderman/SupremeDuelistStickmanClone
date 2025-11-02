## A node for controlling everything regard to a player in the game
## Contain a ragdoll, one input manager which is a joystick or other types of input such as controllers or keyboard
## Also contain specific HUD elements tied to that player such as hp bar and jump bar
extends Node2D

## The physical body of this player
@onready var ragdoll : Node2D = get_node("RagdollPhysicsManager")
## Input manager scene that handle all types of input
@onready var input_manager : CanvasLayer = get_node("Joystick")
## HUD jump bar
@onready var jump_bar : ProgressBar = get_node("ProgressBar")

# Position and direction
var player_position : Vector2 = Vector2.ZERO
var player_direction : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Get input for this tick from input manager and store, first step
	player_direction = input_manager.tick_input()
	# Check for abilities being used, this method is unused but left here as a reminder later on
	input_manager.tick_input_is_releasing()
	# Check the last input before ticking ragdoll
	if input_manager.tick_input_is_jumping():
		ragdoll.jump()
	# Ticking ragdoll, that function will tick other ragdoll functions
	ragdoll.tick_ragdoll(player_direction)
	# Just a simple update function but will be made to a full function for updating HUD later on
	update_jump_bar()

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
	
