## Bootstraper class to initialize the game and stuff, will works as a loading screen later on
extends Node

func _init() -> void:
	FileGlobals.copy_maps_to_user_maps_directory()

func _ready() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)

func _process(delta: float) -> void:
	pass
