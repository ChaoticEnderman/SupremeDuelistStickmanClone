## Universal class to control the state of the game and the system
extends Node

# Signals to everything in the app when game state is changed
## Signal when the game state changed by the function
signal game_state_changed(state)
## Signal when the system state changed by the function
signal system_state_changed(state)
## Signal every physics tick only when the state is in the game
signal game_tick
## Signal to clear all game objects when the current round end
signal clear_round

## Enum for all system states
enum SYSTEM_STATE {MENU, GAME, READY, MAP_EDIT}
## Enum for the game states, only works when the system state is game
enum GAME_STATE {NONE, RUNNING, PAUSING, PAUSING_SETTING, LAZY_RUNNING}

## Store the current game state, not supposed to be modified directly
var game_state = GAME_STATE.RUNNING
## Store the current system state, not supposed to be modified directly
var system_state = SYSTEM_STATE.GAME

var queue_game : bool = false

func _ready() -> void:
	return

## Runs every tick to signal game tick from this centralised place
## Not through broken or random game tick many places
# TODO: Make all components using the game tick use this instead
func _physics_process(delta: float) -> void:
	if queue_game:
		queue_game = false
		change_game_state(GAME_STATE.RUNNING)
		return
	if game_state == GAME_STATE.RUNNING:
		game_tick.emit()

## This should be used to change the game state, will automatically emit the signal
func change_game_state(state: GAME_STATE):
	game_state = state
	game_state_changed.emit(state)

## Queue to run the game in the next tick after freeing last round's objects
func queue_run_game():
	self.queue_game = true

## This should be used to change the system state, will automatically emit the signal
## Also automatically change the game state to none
func change_system_state(state: SYSTEM_STATE):
	system_state = state
	print("GS/System State is ", get_beautiful_system_state(state))
	# Automatically change game state to none or n/a or similiar when the system is not running the game
	if system_state != SYSTEM_STATE.GAME:
		change_game_state(GAME_STATE.NONE)
	system_state_changed.emit(state)

## Return a game state string instead of int, for better debugging
func get_beautiful_game_state(state: GAME_STATE) -> String:
	match state:
		GAME_STATE.NONE:
			return "NONE"
		GAME_STATE.RUNNING:
			return "RUNNING"
		GAME_STATE.PAUSING:
			return "PAUSING"
		GAME_STATE.PAUSING_SETTING:
			return "PAUSING_SETTING"
		GAME_STATE.LAZY_RUNNING:
			return "LAZY_RUNNING"
		_:
			return str(state)

## Return a system state string instead of int, for better debugging
func get_beautiful_system_state(state: SYSTEM_STATE) -> String:
	match state:
		SYSTEM_STATE.MENU:
			return "MENU"
		SYSTEM_STATE.GAME:
			return "GAME"
		SYSTEM_STATE.READY:
			return "READY"
		_:
			return str(state)
