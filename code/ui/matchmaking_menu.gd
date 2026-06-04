## Menu to find matches in the online mode before connecting
class_name MatchmakingMenu
extends Control

@onready var container : VBoxContainer = get_node("Control/ScrollContainer/VBoxContainer")

@export var world_ids : Array[String] = ["", "", "", "", ""]

func _ready():
	print("MMM/ready")
	GameState.system_state_changed.connect(_on_system_state_changed)
	if SystemManager.is_server:
		print("MMM sysman/remote, creating")
		for i in range(5):
			world_ids[i] = SystemManager.create_game(str(i))
	add_to_container()

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MATCHMAKING)
	print("MMM/visible ", self.visible)

func add_to_container():
	for i in container.get_children():
		remove_child(i)
		i.queue_free()
	for i in range(5):
		var texture_button : TextureButton = TextureButton.new()
		var rich_text_label : RichTextLabel = RichTextLabel.new()
		
		texture_button.pressed.connect(_on_game_connected.bind(i))
		
		texture_button.texture_normal = GradientTexture1D.new()
		texture_button.texture_normal.gradient = Gradient.new()
		texture_button.texture_normal.gradient.set_color(0, Color(0.3, 0.3, 0.3))
		texture_button.texture_normal.gradient.set_color(1, Color(0.3, 0.3, 0.3))
		
		texture_button.texture_hover = GradientTexture1D.new()
		texture_button.texture_hover.gradient = Gradient.new()
		texture_button.texture_hover.gradient.set_color(0, Color(0.1, 0.1, 0.1))
		texture_button.texture_hover.gradient.set_color(1, Color(0.1, 0.1, 0.1))
		
		texture_button.ignore_texture_size = true
		texture_button.stretch_mode = TextureButton.STRETCH_SCALE
		
		var text : String = "\t\t"
		text += "SERVER " + str(i) + "\t\t\t\t"
		text += "Region: " + "Asia" + "\t\t\t\t"
		text += "World id " + world_ids[i]
		
		rich_text_label.text = text
		rich_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rich_text_label.custom_minimum_size = Vector2(960.0, 50.0)
		texture_button.custom_minimum_size = Vector2(960.0, 50.0)
		
		rich_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(texture_button)
		texture_button.add_child(rich_text_label)

func _on_game_connected(id: int):
	print("MMM/connecting game ", id)
	SystemManager.join_online_world(id)

func _on_back_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)

func _on_reload_pressed() -> void:
	add_to_container()
	SystemManager.reload_button(1)
	print("sysman MMM/adding to container values ", world_ids)

func _on_reload_2_pressed() -> void:
	SystemManager.reload_button(2)

func _on_name_text_changed(new_text: String) -> void:
	SystemManager.player_name_changed(new_text)
