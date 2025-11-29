## The manager for the entire game, is loaded perpetually until the game close. 
## Will handle the game world, main menu, settings, ... on a general case
extends Node

## The world of the game, containing the main action space for fighting
var world : Node2D

## The main menu, containing the general stuff
var menu : Node2D = preload("res://scenes/main_menu.tscn").instantiate()

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.system_state_changed.connect(_on_system_state_changed)

func _on_game_state_changed(state):
	return

func _on_system_state_changed(state):
	if state == GameState.SYSTEM_STATE.MENU:
		back_to_main_menu()
	elif state == GameState.SYSTEM_STATE.GAME:
		start_game()

## Start command to start the game world. Will create a new game world each time
func start_game() -> void:
	remove_child(menu)
	world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	GameState.change_game_state(GameState.GAME_STATE.RUNNING)

## Function to go back to the main menu, it will not be deleted each time
func back_to_main_menu():
	# Will check to add only if the current node doesnt have menu yet
	remove_child(menu)
	if world != null:
		world.queue_free()
	add_child(menu)
