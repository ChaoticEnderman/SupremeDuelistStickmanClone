## The pause menu, will be visible if the game is paused
extends Control

@onready var confirmation_dialog : ConfirmationDialog = get_node("ConfirmationDialog")

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = false

func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.PAUSING)

func _on_resume_button_pressed() -> void:
	GameState.change_game_state(SystemManager.active_world, GameState.GAME_STATE.RUNNING)

func _on_menu_button_pressed() -> void:
	if SystemManager.active_world.world_type == World.WORLD_TYPE.OFFLINE:
		GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
	elif SystemManager.active_world.world_type == World.WORLD_TYPE.CLIENT:
		confirmation_dialog.visible = true

func _on_setting_button_pressed() -> void:
	GameState.change_game_state(SystemManager.active_world, GameState.GAME_STATE.PAUSING_SETTING)

func _on_confirmation_dialog_confirmed() -> void:
	SystemManager.disconnect_client()
