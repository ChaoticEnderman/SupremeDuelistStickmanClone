## The menu to edit the maps. Have features like a tile map layer to show the map tiles
## Just like how normal game map works. Also contain operations to edit the map
## Features like saving and loading only exist at the code level for the moment
extends Control

## Tilemap layer used to show the current working map
@onready var tile_map_layer : TileMapLayer = get_node("TileMapLayer")

## Camera used for the tilemap to let user move around and edit
@onready var camera : Camera2D = get_node("Camera2D")
## Zoom of the camera, will be the same for the x and y axis
var camera_zoom : float = 1.0

## Test object, unused
@onready var map_dragger : Button = get_node("MapDragger")
## The state of whether the user is dragging
var map_dragging : bool = false
## Variable to make sure that when the user drag the map inside the map area
var is_mouse_inside_map_dragging_area : bool = false
## The start of when user start dragging
var dragging_start : Vector2

## Bottom panel responsible for the normal operations like brush, move, erase, ...
@onready var bottom_panel_ui : HBoxContainer = get_node("CanvasLayer/BottomPanel/HBoxContainer")
## Left pannel responsible for displaying the tiles in the atlas
@onready var left_panel_ui : GridContainer = get_node("CanvasLayer/LeftPanel/ScrollContainer/VBoxContainer")
## Buttons in the bottom panel
var bottom_panel_buttons : Array[TextureButton]

## Current tool that is selected in the editor
var editing_tool : EDITING_TOOL = EDITING_TOOL.MOVE
enum EDITING_TOOL {
	MOVE,
	PAINT,
	ERASE
}

## Atlas coords from the enum MapController.TILE to choose the tile that is currently selected
var brush_tile : Vector2i 

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

func _ready() -> void:
	GameState.system_state_changed.connect(_on_system_state_changed)
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonMove"))
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonPaint"))
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonErase"))
	set_left_panel_tile_buttons()
	load_map(0)
	#print("ME/cam pos ", camera.position)

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MAP_EDIT)

## Looping to set the tiles on the left panel based on the atlas, each atlas tile is a button
func set_left_panel_tile_buttons():
	var texture_button : TextureButton
	var atlas_texture : AtlasTexture
	var atlas : TileSetAtlasSource = default_tile_set.get_source(1)
	for atlas_coords in MapController.TILE:
		# Do not load the empty tile
		if MapController.TILE[atlas_coords] == MapController.TILE.ERASE_TILE:
			continue
		texture_button = TextureButton.new()
		atlas_texture = AtlasTexture.new()
		#
		atlas_texture.set_atlas(atlas.get_texture())
		atlas_texture.set_region(atlas.get_tile_texture_region(MapController.TILE[atlas_coords], 0))
	
		texture_button.texture_normal = atlas_texture
		left_panel_ui.add_child(texture_button)
		
		texture_button.pressed.connect(_on_tile_button_pressed.bind(MapController.TILE[atlas_coords]))

## When a button of the painting tile is pressed, will change the tool to the paint
func _on_tile_button_pressed(tile: Vector2i):
	brush_tile = tile
	bottom_panel_ui.get_node("ButtonPaint").button_pressed = true

## Load a map from MapController by the id
func load_map(id: int):
	MapController.edit_map(id)
	MapController.load_map(tile_map_layer)
	print("ME/after loading ", tile_map_layer.get_used_cells().size())

## Take the input event and split it to the respective functions based on EDITING_TOOL enum
func _input(event: InputEvent) -> void:
	if editing_tool == EDITING_TOOL.MOVE:
		map_dragging_input(event)
	elif editing_tool == EDITING_TOOL.PAINT:
		paint_input(event, brush_tile)
	elif editing_tool == EDITING_TOOL.ERASE:
		paint_input(event, MapController.TILE.ERASE_TILE)

## Listen, I dont understand why this works but it works and let user drag the map around
## Refactor at your own risk hehe
func map_dragging_input(event: InputEvent) -> void:
	if event is InputEventMouse or event is InputEventScreenTouch:
		# Toggle dragging every action of pressing the stuff
		if event.is_pressed():
			if input_is_invalid(event):
				return
			map_dragging = not map_dragging
			# Only when it is just toggled on, set the start of dragging
			if map_dragging:
				# Start at the displacement when the camera move
				dragging_start = event.position + camera.position
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if map_dragging:
			# Change the position when the map is dragging
			camera.position = -(event.position - dragging_start)

## Similiar to map dragging input, this will do paint but only for like one by one block
func paint_input(event: InputEvent, tile_type: Vector2i):
	if event is InputEventMouse or event is InputEventScreenTouch:
		if event.is_pressed():
			if input_is_invalid(event):
				return
			# Minus the vector to drive this to the screen center
			var screen_center = Vector2(DisplayServer.window_get_size().x / 2, DisplayServer.window_get_size().y / 2)
			var tile_position : Vector2 = (event.position - screen_center) + camera.position * camera_zoom
			tile_position = tile_position / camera_zoom
			tile_position = Vector2(tile_position.x / 64, tile_position.y / 64).floor()
			MapController.draw_single_tile(tile_position, tile_type)
			MapController.load_map(tile_map_layer)

## A rather hack to check if the event is outside the editing area. Will have other checks too
func input_is_invalid(event: InputEvent) -> bool:
	# HACK: Hardcode this value, will need to review and check if the input is in the layer behind
	if event.position.x > 256.0 and event.position.y < 592.0:
		return false
	return true

## Change the tool, and disable other tool buttons
func change_tool(tool: int, exclude_button : TextureButton):
	editing_tool = tool
	for button in bottom_panel_buttons:
		if button != exclude_button:
			button.set_pressed_no_signal(false)

func _on_button_move_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.MOVE, bottom_panel_ui.get_node("ButtonMove"))
	elif editing_tool == EDITING_TOOL.MOVE:
		# Solving edge case if the button is on but pressed again, then all button is off
		bottom_panel_ui.get_node("ButtonMove").set_pressed_no_signal(true)

func _on_button_paint_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.PAINT, bottom_panel_ui.get_node("ButtonPaint"))
	elif editing_tool == EDITING_TOOL.PAINT:
		# Solving edge case if the button is on but pressed again, then all button is off
		bottom_panel_ui.get_node("ButtonPaint").set_pressed_no_signal(true)

func _on_button_erase_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.ERASE, bottom_panel_ui.get_node("ButtonErase"))
	elif editing_tool == EDITING_TOOL.ERASE:
		# Solving edge case if the button is on but pressed again, then all button is off
		bottom_panel_ui.get_node("ButtonErase").set_pressed_no_signal(true)

func _on_button_zoom_up_pressed() -> void:
	camera_zoom += 0.1
	camera.zoom = Vector2(camera_zoom, camera_zoom)

func _on_button_zoom_down_pressed() -> void:
	# Make the camera not zoom to negative value that might flip the screen upside down
	if camera_zoom >= 0.1:
		camera_zoom -= 0.1
	camera.zoom = Vector2(camera_zoom, camera_zoom)

## Reset the position and the zoom
func _on_button_center_pressed() -> void:
	camera.position = Vector2(0.0, 0.0)
	camera_zoom = 1.0
	camera.zoom = Vector2(camera_zoom, camera_zoom)

## Only for testing purposes
# TODO: Delete after finishing
func _on_test_pressed() -> void:
	MapController.save_map_to_file("desolation")
	#MapController.read_map_from_file("desolation", tile_map_layer)

## Button to go back to the main menu
# TODO: Add some confirmation stuff
func _on_back_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
