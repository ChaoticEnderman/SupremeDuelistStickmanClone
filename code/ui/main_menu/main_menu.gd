extends Control

func _ready():
	GameState.system_state_changed.connect(_on_system_state_changed)
	self.visible = true

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MENU)

func _on_map_edit_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MAP_EDIT)

func _on_1p_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.READY)

func _on_2p_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MATCHMAKING)
