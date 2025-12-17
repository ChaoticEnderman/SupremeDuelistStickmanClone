## Button to pause and continue the game when it is in the main stage
extends TextureButton
# TODO: Combine all seperate pause menu scripts into one main script

func _ready():
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = true

func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.RUNNING)

func _pressed() -> void:
	if GameState.game_state == GameState.GAME_STATE.LAZY_RUNNING:
		return
	GameState.change_game_state(GameState.GAME_STATE.PAUSING)
