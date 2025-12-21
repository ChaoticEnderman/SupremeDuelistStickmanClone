## Bootstraper class to initialize the game and stuff, will works as a loading screen later on
extends Node

func _ready() -> void:
	WeaponGlobals.load_weapons()
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)

func _process(delta: float) -> void:
	return
