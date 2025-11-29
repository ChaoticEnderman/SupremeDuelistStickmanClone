## Button in the pause menu to go back to main menu
extends TextureButton

func _pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
