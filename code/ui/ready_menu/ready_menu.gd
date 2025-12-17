## The menu that will be shown in between the main menu and the game menu
## To let user set the weapon and the skin color of stickmen
extends Control

# Containers
@onready var left_panel_container : VBoxContainer = get_node("LeftPanel/LeftPanelContainer")
@onready var right_panel_container : VBoxContainer = get_node("RightPanel/RightPanelContainer")

# Popup panel to show up every time the weapon is chosen
@onready var left_panel_popup : Control = get_node("LeftPanelPopup")
@onready var right_panel_popup : Control = get_node("RightPanelPopup")

func _ready():
	GameState.system_state_changed.connect(_on_system_state_changed)
	initialize_weapons(left_panel_popup)
	initialize_weapons(right_panel_popup)
	self.visible = false

## Call this when progressing to the game state, since the signal receiver is somehow not reliable
func show_or_hide(is_show: bool):
	self.visible = is_show

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.READY)

## Process to the game state and hide this
func _on_play_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.GAME)

# TODO: Make buttons like this to activate for other buttons and their corresponding system
func _on_l_weapon_button_pressed() -> void:
	left_panel_popup.visible = true

func _on_r_weapon_button_pressed() -> void:
	right_panel_popup.visible = true

## Initialize all the weapons to be displayed in the popup panel, but not shown yet until the user chose
# TODO: Make this modular for like the other two popup
func initialize_weapons(popup_panel: Control):
	var button : TextureButton
	var control : Control
	var id : int = 1
	
	# Loop to all weapons and display them
	for weapon_data in WeaponGlobals.weapon_list:
		button = TextureButton.new()
		control = Control.new()
		# Related settings to control
		control.size_flags_horizontal = Control.SIZE_EXPAND
		control.custom_minimum_size = Vector2(96.0, 96.0)
		control.add_child(button)
		# Size of button and related settings
		button.texture_normal = weapon_data.sprite
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.custom_minimum_size = Vector2(96.0, 96.0)
		button.size = Vector2(96.0, 96.0)
		# Add to the popup panel
		popup_panel.get_node("Control/GridContainer").add_child(control)
		# Connect the pressed signal automatically
		if popup_panel == left_panel_popup:
			button.pressed.connect(_on_weapon_button_pressed.bind("l", id))
		elif popup_panel == right_panel_popup:
			button.pressed.connect(_on_weapon_button_pressed.bind("r", id))
		id += 1

## Trigged every time any weapon is pressed, to hide the weapon popup and save the weapon choice
func _on_weapon_button_pressed(side: String, id: int):
	
	if side == "l":
		WeaponGlobals.set_weapon(1, id)
		left_panel_popup.visible = false
	if side == "r":
		WeaponGlobals.set_weapon(2, id)
		right_panel_popup.visible = false
