## The menu to edit the maps. Have features like a tile map layer to show the map tiles
## Just like how normal game map works. Also contain operations to edit the map
## Features like saving and loading only exist at the code level for the moment
extends Control

## Map node for the map data, including the tile map and other metadata
@onready var map : Map = get_node("Map")
## Tilemap layer used to show the current working map
@onready var tile_map_layer : TileMapLayer = map.get_tile_map_layer()

## Camera used for the tilemap to let user move around and edit
@onready var camera : Camera2D = get_node("Camera2D")
## Zoom of the camera, will be the same for the x and y axis
var camera_zoom : float = 1.0

## Test object, unused
@onready var map_dragger : Button = get_node("MapDragger")
## The state of whether the user is dragging
var map_dragging : bool = false
## The state of dragging the paint head
var paint_dragging : bool = false
## Variable to make sure that when the user drag the map inside the map area
var is_mouse_inside_map_dragging_area : bool = false

## The start of when user start dragging
var dragging_start : Vector2

## Bottom panel responsible for the normal operations like brush, move, erase, ...
@onready var bottom_panel_ui : HBoxContainer = get_node("CanvasLayer/BottomPanel/HBoxContainer")
## Left panel for side buttons and the tiles
@onready var left_panel : Control = get_node("CanvasLayer/LeftPanel")
## Left pannel responsible for displaying the tiles in the atlas
@onready var left_panel_atlas : GridContainer = left_panel.get_node("ScrollContainer/VBoxContainer")
## Buttons in the bottom panel for the tools, aka Move/Paint/Erase
var bottom_panel_tool_buttons : Array[TextureButton]
## Buttons in the bottom panel for brush, aka Brush/Rect/Bucket
var bottom_panel_brush_buttons : Array[TextureButton]
## Popup panel for the setting, to show the settings, this is the main area of focus and is different from the background panel
@onready var popup_setting_panel : CanvasLayer = get_node("PopupSetting")

## A panel that will dim out everything in the map editor when shown, and will stop all input from going through it
## Use for when showing the popup for map settings, so only the popup will receive input 
@onready var popup_background_panel : CanvasLayer = get_node("PopupBackground")

## Status of whether the setting popup is shown, if true then it will ignore other components
var setting_popup_shown : bool = false

## Store the temporary rectangle when using the rectangle tool to draw
var rectangle_drawn : Rect2

## Current tool that is selected in the editor
var editing_tool : EDITING_TOOL = EDITING_TOOL.MOVE
enum EDITING_TOOL {
	MOVE,
	PAINT,
	ERASE
}

## Current selected brush tool
var brush_tool : BRUSH_TOOL = BRUSH_TOOL.BRUSH
## Brush tools like how the player will draw the things on the editor. Brush is block by block, Rectangle is a rectangle, Bucket is the bucket tool
enum BRUSH_TOOL {
	BRUSH,
	RECTANGLE,
	BUCKET
}

## Setting for the instant kill area of none or not
var instant_kill_type : INSTANT_KILL_TYPE = INSTANT_KILL_TYPE.NONE
## All possible instant kill types. Values other than NONE is just for aesthetic and all will kill the same for now
enum INSTANT_KILL_TYPE {
	NONE,
	WATER,
	LAVA,
	ACID
}

## Atlas coords from the enum MapController.TILE to choose the tile that is currently selected
var brush_tile : Vector2i 

## Default game tileset resource
var default_tile_set : TileSet = preload("res://resources/default_tile_set.tres")

## Store the screen center position independent of screen scaling for various use
var screen_center : Vector2

func _ready() -> void:
	print("ME/ready")
	GameState.system_state_changed.connect(_on_system_state_changed)
	bottom_panel_tool_buttons.append(bottom_panel_ui.get_node("ButtonMove"))
	bottom_panel_tool_buttons.append(bottom_panel_ui.get_node("ButtonPaint"))
	bottom_panel_tool_buttons.append(bottom_panel_ui.get_node("ButtonErase"))
	bottom_panel_brush_buttons.append(bottom_panel_ui.get_node("ButtonBrush"))
	bottom_panel_brush_buttons.append(bottom_panel_ui.get_node("ButtonRectangle"))
	bottom_panel_brush_buttons.append(bottom_panel_ui.get_node("ButtonBucket"))
	left_panel_atlas.get_node("OpenMapButton")
	set_left_panel_tile_buttons()
	load_map(0)
	#print("ME/cam pos ", camera.position)
	
	#var edit_zone = get_node("CanvasLayer/EditingZone")
	#screen_center = Vector2(edit_zone.position + edit_zone.size / 2) 
	#screen_center = Vector2(640, 360)

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
		left_panel_atlas.add_child(texture_button)
		
		texture_button.pressed.connect(_on_tile_button_pressed.bind(MapController.TILE[atlas_coords]))

## When a button of the painting tile is pressed, will change the tool to the paint
func _on_tile_button_pressed(tile: Vector2i):
	brush_tile = tile
	bottom_panel_ui.get_node("ButtonPaint").button_pressed = true

## Load a map from MapController by the id
func load_map(id: int):
	MapController.edit_map(id)
	MapController.load_map(map)

## Take the input event and split it to the respective functions based on EDITING_TOOL enum
func _input(event: InputEvent) -> void:
	# Ignoring input for this if the settings panel is turned on
	if setting_popup_shown:
		return
	screen_center = Vector2((get_viewport().get_visible_rect().size.x / 2), (get_viewport().get_visible_rect().size.y / 2))
	print("me/input pos ", event.position, " center ", screen_center)
	if editing_tool == EDITING_TOOL.MOVE:
		map_dragging_input(event)
	else:
		if brush_tool == BRUSH_TOOL.BRUSH:
			if editing_tool == EDITING_TOOL.PAINT:
				brush_input(event, brush_tile)
			elif editing_tool == EDITING_TOOL.ERASE:
				brush_input(event, MapController.TILE.ERASE_TILE)
		if brush_tool == BRUSH_TOOL.RECTANGLE:
			if editing_tool == EDITING_TOOL.PAINT:
				rectangle_input(event, brush_tile)
			elif editing_tool == EDITING_TOOL.ERASE:
				rectangle_input(event, MapController.TILE.ERASE_TILE)
		if brush_tool == BRUSH_TOOL.BUCKET:
			if editing_tool == EDITING_TOOL.PAINT:
				bucket_input(event, brush_tile)
			elif editing_tool == EDITING_TOOL.ERASE:
				bucket_input(event, MapController.TILE.ERASE_TILE)

## Listen, I dont understand why this works but it works and let user drag the map around
## Refactor at your own risk hehe
func map_dragging_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		# Toggle dragging every action of pressing the stuff
		if event.is_pressed():
			if input_is_invalid(event):
				return
			map_dragging = true
			# Only when it is just toggled on, set the start of dragging
			if map_dragging:
				# Start at the displacement when the camera move
				dragging_start = event.position + camera.position * camera_zoom
		else:
			map_dragging = false
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if map_dragging:
			# Change the position when the map is dragging
			camera.position = (dragging_start - event.position) / camera_zoom

## Similiar to map dragging input, this will do paint but only for like one by one block
func brush_input(event: InputEvent, tile_type: Vector2i):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		# Can be shortened in the future but just leave it here for now since the code is kinda hard to understand at the moment
		if event.is_pressed():
			paint_dragging = true
		else:
			paint_dragging = false
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if paint_dragging:
			if input_is_invalid(event):
				return
			# Minus the vector to drive this to the screen center
			var tile_position : Vector2 = (event.position - screen_center) + camera.position * camera_zoom
			tile_position = tile_position / camera_zoom
			tile_position = Vector2(tile_position.x / 64, tile_position.y / 64).floor()
			MapController.draw_single_tile(tile_position, tile_type)
			MapController.load_map(map)

## Similiar to map dragging input, this will do paint but only for like one by one block
func rectangle_input(event: InputEvent, tile_type: Vector2i):
	var tile_position : Vector2 = (event.position - screen_center) + camera.position * camera_zoom
	tile_position = tile_position / camera_zoom
	#tile_position = Vector2(tile_position.x / 64, tile_position.y / 64).round()
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if input_is_invalid(event):
			return
		# Can be shortened in the future but just leave it here for now since the code is kinda hard to understand at the moment
		if event.is_pressed():
			# When input is pressed, will store the starting position 
			paint_dragging = true
			rectangle_drawn.position = tile_position
			print("ME/rect/first is ", rectangle_drawn.position)
		else:
			paint_dragging = false
			
			normalize_rectangle(tile_position)
			
			var rect : Rect2i
			rect.position = Vector2i((rectangle_drawn.position / 64).floor())
			rect.end = Vector2i((rectangle_drawn.end / 64).floor())
			MapController.draw_rect(rect, tile_type)
			MapController.load_map(map)
			
			rectangle_drawn = Rect2(0,0,0,0)
			queue_redraw()
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if paint_dragging:
			rectangle_drawn.end = tile_position
			print("ME/rect/dragging ", tile_position)
			queue_redraw()

## Private helper class to normalize the rectangle from the draw rect function
func normalize_rectangle(ending_tile_position: Vector2i):
	# Two abitrary opposite corners of the rectangle to be normalized
	var rect_corner_a = rectangle_drawn.position
	var rect_corner_b = ending_tile_position
	var true_top_left : Vector2i
	var true_bottom_right : Vector2i
	# True top left will need to have the lesser x value and lesser y value from both the corners
	true_top_left = Vector2i(min(rect_corner_a.x, rect_corner_b.x), min(rect_corner_a.y, rect_corner_b.y))
	# True bottom right will have higher x and y value from both corners. 
	# Keep in mind that the y coordinates is inverse in Godot in general so we still work with that
	true_bottom_right = Vector2i(max(rect_corner_a.x, rect_corner_b.x), max(rect_corner_a.y, rect_corner_b.y))
	
	rectangle_drawn.position = Vector2(true_top_left)
	rectangle_drawn.end = Vector2(true_bottom_right)

func bucket_input(event: InputEvent, tile_type: Vector2i):
	var tile_position : Vector2 = (event.position - screen_center) + camera.position * camera_zoom
	tile_position = tile_position / camera_zoom
	tile_position = Vector2(tile_position.x / 64, tile_position.y / 64).floor()
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if input_is_invalid(event):
			return
		if event.is_pressed():
			MapController.fill_bucket(tile_position, MapController.get_atlas_coords_by_position(tile_position), tile_type)
			MapController.load_map(map)

## Draw a custom rectangle box to draw the visual boxes for the draw_rect function 
func _draw() -> void:
	print("me/rect drawn is ", rectangle_drawn.position, " to ", rectangle_drawn.end)
	var rect : Rect2
	rect.position = rectangle_drawn.position
	rect.end = rectangle_drawn.end
	draw_rect(rect, Color.GREEN)

## A rather hack to check if the event is outside the editing area. Will have other checks too
func input_is_invalid(event: InputEvent) -> bool:
	# HACK: Hardcode this value, will need to review and check if the input is in the layer behind
	if event.position.x > 256.0 and event.position.y < 592.0:
		return false
	return true

## Change the tool, and disable other tool buttons
func change_tool(tool: int, exclude_button : TextureButton):
	editing_tool = tool
	for button in bottom_panel_tool_buttons:
		if button != exclude_button:
			button.set_pressed_no_signal(false)

## Change brush type and choose to current brush type
func change_brush(brush: int, exclude_button : TextureButton):
	brush_tool = brush
	for button in bottom_panel_brush_buttons:
		if button != exclude_button:
			button.set_pressed_no_signal(false)

func _on_button_brush_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_brush(BRUSH_TOOL.BRUSH, bottom_panel_ui.get_node("ButtonBrush"))
	elif brush_tool == BRUSH_TOOL.BRUSH:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
		bottom_panel_ui.get_node("ButtonBrush").set_pressed_no_signal(true)

func _on_button_rectangle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_brush(BRUSH_TOOL.RECTANGLE, bottom_panel_ui.get_node("ButtonRectangle"))
	elif brush_tool == BRUSH_TOOL.RECTANGLE:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
		bottom_panel_ui.get_node("ButtonRectangle").set_pressed_no_signal(true)

func _on_button_bucket_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_brush(BRUSH_TOOL.BUCKET, bottom_panel_ui.get_node("ButtonBucket"))
	elif brush_tool == BRUSH_TOOL.BUCKET:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
		bottom_panel_ui.get_node("ButtonBucket").set_pressed_no_signal(true)

func _on_button_move_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.MOVE, bottom_panel_ui.get_node("ButtonMove"))
	elif editing_tool == EDITING_TOOL.MOVE:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
		bottom_panel_ui.get_node("ButtonMove").set_pressed_no_signal(true)

func _on_button_paint_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.PAINT, bottom_panel_ui.get_node("ButtonPaint"))
	elif editing_tool == EDITING_TOOL.PAINT:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
		bottom_panel_ui.get_node("ButtonPaint").set_pressed_no_signal(true)

func _on_button_erase_toggled(toggled_on: bool) -> void:
	if toggled_on:
		change_tool(EDITING_TOOL.ERASE, bottom_panel_ui.get_node("ButtonErase"))
	elif editing_tool == EDITING_TOOL.ERASE:
		# Solving edge case if the button is on but pressed again, then all button is off
		# This will ignore the press and will make the button on again
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

## Only for testing purposes, remember to hide the test node if not used
func _on_test_pressed() -> void:
	pass
	
	MapController.change_map_instant_kill_type(MapController.INSTANT_KILL_TYPE.ACID, map)
	
	#MapController.test_save_map_to_json("desolation")
	#MapController.test_load_map_to_json()
	
	#MapController.draw_rect(Rect2i(Vector2i(1,1), Vector2i(-2,-4)), brush_tile)
	#MapController.load_map(map)
	#MapController.save_map_to_file("desolation", false)
	#MapController.read_map_from_file("desolation", tile_map_layer)

## Button to go back to the main menu
# TODO: Add some confirmation stuff
func _on_back_button_pressed() -> void:
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
	# Also reload all maps when exiting map editor to finialize reloading stuff
	MapController.reload_all_maps()

## Button to physically load up the saved files in the maps folder
func _on_load_map_button_pressed() -> void:
	DisplayServer.file_dialog_show("", FileGlobals.maps_path , "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
	["*.json"], _on_file_loaded)

## Button to create a new file for saving a new map
func _on_new_map_button_pressed() -> void:
	MapController.create_untitled_map()
	MapController.load_map(map)

## Function to save the current edited file, to the old location or to override it
func _on_save_map_button_pressed() -> void:
	DisplayServer.file_dialog_show("", FileGlobals.maps_path , "", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
	["*.json"], _on_file_saved)

## When the file is loaded it will load up the map contents to the current map
func _on_file_loaded(status: bool, selected_paths: PackedStringArray, selected_filter_index: int):
	if selected_paths == null or selected_paths.size() == 0:
		return
	print("ME/file loaded ", selected_paths[0])
	MapController.load_map_from_file_to_map_list(selected_paths[0])
	MapController.load_map(map)

func _on_file_saved(status: bool, selected_paths: PackedStringArray, selected_filter_index: int):
	if selected_paths == null or selected_paths.size() == 0:
		return
	print("ME/file saved ", selected_paths[0])
	var file_name : String = selected_paths[0].get_file()
	#file_name = file_name.substr(0, file_name.length() - 4)
	print("ME/file saved name is ", file_name)
	MapController.save_map_to_file(file_name)
	MapController.reload_all_maps()

## Show the popup panel for the map setting menu
func _on_setting_button_pressed() -> void:
	setting_popup_shown = true
	popup_background_panel.visible = true
	popup_setting_panel.visible = true

## Hide the popup panel for the map setting menu
func _on_close_setting_button_pressed() -> void:
	setting_popup_shown = false
	popup_background_panel.visible = false
	popup_setting_panel.visible = false

func _on_setting_instant_kill_type_item_selected(index: int) -> void:
	var instant_kill : int
	# Cant trust the enum index obviously, so I do this 
	match index:
		0:
			instant_kill = MapController.INSTANT_KILL_TYPE.NONE
		1:
			instant_kill = MapController.INSTANT_KILL_TYPE.WATER
		2:
			instant_kill = MapController.INSTANT_KILL_TYPE.LAVA
		3:
			instant_kill = MapController.INSTANT_KILL_TYPE.ACID
	MapController.change_map_instant_kill_type(instant_kill, map)
