class_name Chat
extends Control

@onready var label : RichTextLabel = get_node("Label")
@onready var line_edit : LineEdit = get_node("LineEdit")

func _ready() -> void:
	GameState.system_state_changed.connect(_system_state_changed)

func _system_state_changed():
	self.visible = GameState.system_state == GameState.SYSTEM_STATE.ONLINE

func _on_text_submitted(new_text: String) -> void:
	SystemManager.send_chat.rpc(new_text)
	line_edit.clear()

func update_chat(chat_history: PackedStringArray):
	label.text = ""
	for s in chat_history:
		label.text += s + "\n"
