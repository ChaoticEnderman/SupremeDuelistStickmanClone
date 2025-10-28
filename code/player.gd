extends Node2D

@onready var ragdoll : Node2D = get_node("RagdollPhysicsManager")
@onready var input_manager : CanvasLayer = get_node("Joystick")
const Globals = preload("res://code/Globals.gd")

var player_position : Vector2 = Vector2.ZERO
var player_direction : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	player_direction = input_manager.tick_input()
	input_manager.tick_input_is_releasing()
	if input_manager.tick_input_is_jumping():
		ragdoll.jump()
	ragdoll.tick_ragdoll(player_direction)
