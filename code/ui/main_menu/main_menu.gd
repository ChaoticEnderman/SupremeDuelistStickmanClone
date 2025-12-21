extends Control
# TODO: Combine all seperate main menu scripts into this script

func _ready():
	GameState.system_state_changed.connect(_on_system_state_changed)
	self.visible = true

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MENU)
