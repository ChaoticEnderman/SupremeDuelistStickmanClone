## Menu to find matches in the online mode before connecting
class_name MatchmakingMenu
extends Control

@onready var container : VBoxContainer = get_node("Control/ScrollContainer/VBoxContainer")
@onready var dialog : AcceptDialog = get_node("AcceptDialog")

var connecting_port : String = ""
var connecting_time : int = 0

var http_sync : int = 0

func _ready():
	print("MMM/ready")
	GameState.system_state_changed.connect(_on_system_state_changed)
	if SystemManager.is_server:
		SystemManager.create_game()
	add_to_container()

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MATCHMAKING)
	if state == GameState.SYSTEM_STATE.MATCHMAKING:
		reload_server_data()
	print("MMM/visible ", self.visible)

func add_to_container():
	for i in container.get_children():
		i.queue_free()
	for i in range(10):
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
		
		rich_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rich_text_label.custom_minimum_size = Vector2(960.0, 50.0)
		texture_button.custom_minimum_size = Vector2(960.0, 50.0)
		
		rich_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(texture_button)
		texture_button.add_child(rich_text_label)

func _on_game_connected(id: int):
	print("MMM sysman/connecting id ", id, " port ", SystemManager.server_data[id * 4])
	SystemManager.connect_server(int(SystemManager.server_data[id * 4]))
	connecting_port = SystemManager.server_data[id * 4]

func _on_back_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)

func _on_reload_pressed() -> void:
	reload_server_data()

func reload_server_data():
	SystemManager.reload_button(1)
	var index = 0
	for c in container.get_children():
		if c is TextureButton:
			if SystemManager.server_data.size() > index:
				var text : String = "\t\t"
				text += "Server ID: " + SystemManager.server_data[index] + "\t\t\t\t"
				text += "Region: " + SystemManager.server_data[index + 1] + "\t\t\t\t"
				text += "Player Count: " + SystemManager.server_data[index + 2] + "\t\t\t\t"
				text += "Game Map: " + SystemManager.server_data[index + 3] + "\t\t\t\t"
				var rich_text_label : RichTextLabel = c.get_child(0)
				rich_text_label.text = text
			else:
				c.visible = false
			index += 4

func show_waiting_dialog():
	dialog.popup()
	connecting_time = Time.get_unix_time_from_system()

func join_game_signal():
	dialog.hide()

func _physics_process(delta: float) -> void:
	http_sync += 1
	if http_sync >= 60:
		http_sync = 0
		reload_server_data()
	var text : String = "Connected to server with port " + connecting_port + ". You are the only one here, waiting for another player to join."
	text += "Time elapsed: " + str(int(Time.get_unix_time_from_system()) - connecting_time) + " seconds "
	dialog.dialog_text = text

func _on_name_text_changed(new_text: String) -> void:
	SystemManager.player_name_changed(new_text)

func _on_accept_dialog_canceled() -> void:
	SystemManager.disconnect_client()

func _on_accept_dialog_confirmed() -> void:
	SystemManager.disconnect_client()
