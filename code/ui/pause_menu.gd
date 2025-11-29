## The pause menu, will be visible if the game is paused
extends Node2D

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = false

func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.PAUSING)
