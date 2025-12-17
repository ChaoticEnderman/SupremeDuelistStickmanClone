## Button in the pause menu to go back to main menu
extends TextureButton
# TODO: Combine all seperate pause menu scripts into one main script

func _pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
