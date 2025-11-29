extends TextureButton

func _pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATE.PAUSING_SETTING)
