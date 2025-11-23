extends TextureButton

func _ready() -> void:
	self.visible = false

func _pressed() -> void:
	self.visible = false
	SystemManager.world.clear_round()
