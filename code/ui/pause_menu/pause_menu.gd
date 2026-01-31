## The pause menu, will be visible if the game is paused
extends Control

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = false

func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.PAUSING)

func _on_resume_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATE.RUNNING)

func _on_menu_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)

func _on_setting_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATE.PAUSING_SETTING)
