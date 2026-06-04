extends TextureButton

func _ready() -> void:
	self.visible = false

func _pressed() -> void:
	self.visible = false
	SystemManager.active_world.clear_round()
