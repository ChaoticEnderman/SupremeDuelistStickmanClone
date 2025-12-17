## The pause menu, will be visible if the game is paused
extends Node2D
# TODO: Combine all seperate pause menu scripts into this script

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = false

func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.PAUSING)
