extends TextureButton
# TODO: Make this independent by receiving global signals instead

func _ready() -> void:
	self.visible = false

func _pressed() -> void:
	self.visible = false
	SystemManager.world.clear_round()
