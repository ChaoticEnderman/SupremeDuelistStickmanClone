## Pause menu button to resume the game
extends TextureButton
# TODO: Combine all seperate pause menu scripts into one main script

func _pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATE.RUNNING)
