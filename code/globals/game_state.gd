## Universal class to control the state of the game and the system
extends Node

# Signals to everything in the app when game state is changed
## Signal when the game state changed by the function
signal game_state_changed(state)
## Signal when the system state changed by the function
signal system_state_changed(state)
## Signal every physics tick only when the state is in the game
signal game_tick

## Enum for all system states
enum SYSTEM_STATE {MENU, GAME}
## Enum for the game states, only works when the system state is game
enum GAME_STATE {NONE, RUNNING, PAUSING, PAUSING_SETTING, LAZY_RUNNING}

## Store the current game state, not supposed to be modified directly
var game_state = GAME_STATE.RUNNING
## Store the current system state, not supposed to be modified directly
var system_state = SYSTEM_STATE.GAME

func _ready() -> void:
	return

func _physics_process(delta: float) -> void:
	if game_state == GAME_STATE.RUNNING:
		game_tick.emit()

## This should be used to change the game state, will automatically emit the signal
func change_game_state(state: GAME_STATE):
	game_state = state
	game_state_changed.emit(state)

## This should be used to change the system state, will automatically emit the signal
## Also automatically change the game state to none
func change_system_state(state: SYSTEM_STATE):
	system_state = state
	# Automatically change game state to none or n/a or similiar when the system is not running the game
	if system_state != SYSTEM_STATE.GAME:
		change_game_state(GAME_STATE.NONE)
	system_state_changed.emit(state)
