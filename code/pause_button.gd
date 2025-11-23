## Button to pause and continue the game when it is in the main stage
extends TextureButton

func _toggled(toggled_on: bool) -> void:
	if GameState.game_state == GameState.GAME_STATE.LAZY_RUNNING:
		return
	
	if toggled_on:
		GameState.game_state = GameState.GAME_STATE.PAUSING
	else:
		GameState.game_state = GameState.GAME_STATE.RUNNING
	# Send the pause/unpause signal to the world in order to pause its stuff
	SystemManager.world.pause_or_unpause(toggled_on)
