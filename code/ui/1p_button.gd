extends TextureButton

func _pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.GAME)
