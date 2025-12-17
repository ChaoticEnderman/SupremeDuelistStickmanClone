extends TextureButton
# TODO: Combine all seperate main menu scripts into one main script

func _pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.READY)
