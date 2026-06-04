## The menu that will be shown in between the main menu and the game menu
## To let user set the weapon and the skin color of stickmen
extends Control

# Containers
@onready var left_panel_container : VBoxContainer = get_node("LeftPanel/LeftPanelContainer")
@onready var right_panel_container : VBoxContainer = get_node("RightPanel/RightPanelContainer")

# Popup panel to show up every time the weapon is chosen
@onready var left_panel_weapon_popup : Control = get_node("LeftPanelWeaponPopup")
@onready var right_panel_weapon_popup : Control = get_node("RightPanelWeaponPopup")
# Popup panel to show up every time the hat is chosen
@onready var left_panel_hat_popup : Control = get_node("LeftPanelHatPopup")
@onready var right_panel_hat_popup : Control = get_node("RightPanelHatPopup")

# The panel for choosing the map
@onready var map_chooser : Control = get_node("MapChooser")

## Hat sprites for like the player stickman at ReadyMenu stage, since they are different
var l_hat : Sprite2D = Sprite2D.new()
## Same with the left hat
var r_hat : Sprite2D = Sprite2D.new()

func _ready():
	GameState.system_state_changed.connect(_on_system_state_changed)
	initialize_weapons(left_panel_weapon_popup)
	initialize_weapons(right_panel_weapon_popup)
	initialize_hats(left_panel_hat_popup)
	initialize_hats(right_panel_hat_popup)
	create_sprite_stickmen(get_node("LeftPanel/LPlayer"), PlayerSpriteGlobal.PLAYER.LEFT)
	create_sprite_stickmen(get_node("RightPanel/RPlayer"), PlayerSpriteGlobal.PLAYER.RIGHT)
	
	l_hat.scale = Vector2(0.15, 0.15)
	r_hat.scale = Vector2(0.15, 0.15)
	
	MapController.reload_all_maps()
	map_chooser.get_node("Label").text = MapController.default_map()
	self.visible = false

func create_sprite_stickmen(root_node: Control, player_side: PlayerSpriteGlobals.PLAYER):
	# Creating each individual limb, not really any better way
	var torso := TextureButton.new()
	var stomach := TextureButton.new()
	var head := TextureButton.new()
	var l_thigh := TextureButton.new()
	var l_shin := TextureButton.new()
	var r_thigh := TextureButton.new()
	var r_shin := TextureButton.new()
	var l_arm := TextureButton.new()
	var l_forearm := TextureButton.new()
	var r_arm := TextureButton.new()
	var r_forearm := TextureButton.new()
	# limbs array for shortening some parts. Does not contain the head as it is fundamentally different
	var nh_limbs : Array[TextureButton] = [torso, stomach, l_thigh, l_shin, r_thigh, r_shin, l_arm, l_forearm, r_arm, r_forearm]
	# Add the empty sprite to be able to modulate later on
	for limb in nh_limbs:
		limb.size = Vector2(10.0, 50.0)
		limb.pivot_offset = Vector2(5.0, 25.0)
		limb.texture_normal = load("res://assets/ui/EmptyPlayerLimbTexture10x50.png")
	head.size = Vector2(30.0, 30.0)
	head.pivot_offset = Vector2(15.0, 15.0)
	head.texture_normal = load("res://assets/ui/EmptyPlayerLimbTexture30x30.png")
	# Set the position of the limbs to build a stickman-like object
	torso.position = Vector2(root_node.size.x / 2, root_node.size.y / 2)
	torso.position = torso.position + Vector2(0.0, -100.0)
	# Change the position of the limbs based on the base position of the torso
	var reference_point = torso.position
	torso.position = reference_point
	stomach.position = reference_point + Vector2(0.0, 100.0)
	head.position = reference_point + Vector2(0.0, -80.0) - head.pivot_offset
	l_thigh.position = reference_point + Vector2(50.0, 200.0)
	r_thigh.position = reference_point + Vector2(-50.0, 200.0)
	l_shin.position = reference_point + Vector2(100.0, 300.0)
	r_shin.position = reference_point + Vector2(-100.0, 300.0)
	l_thigh.rotation_degrees = -45.0
	r_thigh.rotation_degrees = 45.0
	l_arm.position = reference_point + Vector2(50.0, 0.0)
	r_arm.position = reference_point + Vector2(-50.0, 0.0)
	l_forearm.position = reference_point + Vector2(100.0, 100.0)
	r_forearm.position = reference_point + Vector2(-100.0, 100.0)
	l_arm.rotation_degrees = -45.0
	r_arm.rotation_degrees = 45.0
	
	for limb in nh_limbs:
		limb.position = limb.position - limb.pivot_offset
		limb.scale = Vector2(2.0, 2.0)
		root_node.add_child(limb)
	#head.position = head.position - head.pivot_offset
	head.scale = Vector2(2.0, 2.0)
	root_node.add_child(head)
	
	# Another piece of code that I cant really trust the index of the enum so just do it like this
	head.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.HEAD, head))
	torso.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.TORSO, torso))
	stomach.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.STOMACH, stomach))
	l_thigh.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.L_THIGH, l_thigh))
	l_shin.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.L_SHIN, l_shin))
	r_thigh.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.R_THIGH, r_thigh))
	r_shin.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.R_SHIN, r_shin))
	l_arm.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.L_ARM, l_arm))
	l_forearm.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.L_FOREARM, l_forearm))
	r_arm.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.R_ARM, r_arm))
	r_forearm.pressed.connect(_on_limb_pressed.bind(player_side, PlayerSpriteGlobals.LIMB_INDEX.R_FOREARM, r_forearm))
	
	# Making the hat for the stickmen, this will only store the sprite and not be clicked on directly by the player
	if player_side == PlayerSpriteGlobals.PLAYER.LEFT:
		l_hat.position = reference_point + Vector2(0.0, -80.0)
		root_node.add_child(l_hat)
	elif player_side == PlayerSpriteGlobals.PLAYER.RIGHT:
		r_hat.position = reference_point + Vector2(0.0, -80.0)
		root_node.add_child(r_hat)
	

## Signals runs when any limb is pressed, will change the color and update color of that limb
func _on_limb_pressed(player_side: PlayerSpriteGlobals.PLAYER, limb_index: PlayerSpriteGlobals.LIMB_INDEX, body: TextureButton):
	PlayerSpriteGlobals.set_limb(limb_index, player_side)
	body.modulate = PlayerSpriteGlobals.get_brush_color(player_side)

## Call this when progressing to the game state, since the signal receiver is somehow not reliable
func show_or_hide(is_show: bool):
	self.visible = is_show
	MapController.reload_all_maps()

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.READY)

## Process to the game state and hide this
func _on_play_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.GAME)

func _on_l_weapon_button_pressed() -> void:
	left_panel_weapon_popup.visible = true

func _on_r_weapon_button_pressed() -> void:
	right_panel_weapon_popup.visible = true

func _on_l_hat_button_pressed() -> void:
	left_panel_hat_popup.visible = true

func _on_r_hat_button_pressed() -> void:
	right_panel_hat_popup.visible = true

func _on_l_color_picker_button_color_changed(color: Color) -> void:
	PlayerSpriteGlobal.set_brush_color(PlayerSpriteGlobal.PLAYER.LEFT, color)

func _on_r_color_picker_button_color_changed(color: Color) -> void:
	PlayerSpriteGlobal.set_brush_color(PlayerSpriteGlobal.PLAYER.RIGHT, color)

## Initialize all the weapons to be displayed in the popup panel, but not shown yet until the user chose
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
		if weapon_data.name == "Random":
			if popup_panel == left_panel_weapon_popup:
				button.pressed.connect(_on_weapon_button_pressed.bind(
					WeaponGlobals.PLAYER_SIDE.LEFT, 0))
			elif popup_panel == right_panel_weapon_popup:
				button.pressed.connect(_on_weapon_button_pressed.bind(
					WeaponGlobals.PLAYER_SIDE.RIGHT, 0))
		else:
			if popup_panel == left_panel_weapon_popup:
				button.pressed.connect(_on_weapon_button_pressed.bind(
					WeaponGlobals.PLAYER_SIDE.LEFT, id))
			elif popup_panel == right_panel_weapon_popup:
				button.pressed.connect(_on_weapon_button_pressed.bind(
					WeaponGlobals.PLAYER_SIDE.RIGHT, id))
			id += 1

## Initialize all the weapons to be displayed in the popup panel, but not shown yet until the user chose
func initialize_hats(popup_panel: Control):
	var button : TextureButton
	var control : Control
	var id : int = 0
	
	# Loop to all weapons and display them
	for hat_data in PlayerSpriteGlobal.hat_list:
		button = TextureButton.new()
		control = Control.new()
		# Related settings to control
		control.size_flags_horizontal = Control.SIZE_EXPAND
		control.custom_minimum_size = Vector2(96.0, 96.0)
		control.add_child(button)
		# Size of button and related settings
		button.texture_normal = hat_data
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(96.0, 96.0)
		button.size = Vector2(80.0, 80.0)
		# Add to the popup panel
		popup_panel.get_node("Control/GridContainer").add_child(control)
		# Connect the pressed signal automatically
		if popup_panel == left_panel_hat_popup:
			button.pressed.connect(_on_hat_button_pressed.bind(WeaponGlobals.PLAYER_SIDE.LEFT, id))
		elif popup_panel == right_panel_hat_popup:
			button.pressed.connect(_on_hat_button_pressed.bind(WeaponGlobals.PLAYER_SIDE.RIGHT, id))
		id += 1
	print("RM/loading hats number ", id)

## Trigged every time any weapon is pressed, to hide the weapon popup and save the weapon choice
func _on_weapon_button_pressed(side: WeaponGlobals.PLAYER_SIDE, id: int):
	if side == WeaponGlobals.PLAYER_SIDE.LEFT:
		WeaponGlobals.set_weapon(WeaponGlobals.PLAYER_SIDE.LEFT, id)
		left_panel_weapon_popup.visible = false
	if side == WeaponGlobals.PLAYER_SIDE.RIGHT:
		WeaponGlobals.set_weapon(WeaponGlobals.PLAYER_SIDE.RIGHT, id)
		right_panel_weapon_popup.visible = false

func _on_hat_button_pressed(side: WeaponGlobals.PLAYER_SIDE, id: int):
	if side == WeaponGlobals.PLAYER_SIDE.LEFT:
		var texture : Texture2D = PlayerSpriteGlobals.set_and_get_hat(id, PlayerSpriteGlobals.PLAYER.LEFT)
		l_hat.texture = texture
		left_panel_hat_popup.visible = false
	if side == WeaponGlobals.PLAYER_SIDE.RIGHT:
		var texture : Texture2D = PlayerSpriteGlobals.set_and_get_hat(id, PlayerSpriteGlobals.PLAYER.RIGHT)
		r_hat.texture = texture
		right_panel_hat_popup.visible = false

## Move to the next map
func _on_left_button_pressed() -> void:
	map_chooser.get_node("Label").text = MapController.prev_map()

## Move to the previous map
func _on_right_button_pressed() -> void:
	map_chooser.get_node("Label").text = MapController.next_map()

func _on_back_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
