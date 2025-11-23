extends Node

enum GAME_STATE {RUNNING, PAUSING, LAZY_RUNNING}
var game_state = GAME_STATE

func _ready() -> void:
	game_state = GAME_STATE.RUNNING
