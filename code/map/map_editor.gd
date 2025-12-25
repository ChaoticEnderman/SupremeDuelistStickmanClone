extends Control

@onready var tile_map_layer : TileMapLayer = get_node("TileMapLayer")

@onready var camera : Camera2D = get_node("Camera2D")
var camera_position : Vector2 = Vector2(0.0, 0.0)
var camera_zoom : float = 1.0

@onready var map_dragger : Button = get_node("MapDragger")
var map_dragging : bool = false
## Variable to make sure that when the user drag the map inside the map area
var is_mouse_inside_map_dragging_area : bool = false
var dragging_start : Vector2

@onready var bottom_panel_ui : HBoxContainer = get_node("CanvasLayer/BottomPanel/HBoxContainer")
var bottom_panel_buttons : Array[TextureButton]

## Current tool that is selected in the editor
var editing_tool : EDITING_TOOL
enum EDITING_TOOL {
	MOVE,
	PAINT,
	ERASE
}

func _ready() -> void:
	GameState.system_state_changed.connect(_on_system_state_changed)
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonMove"))
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonPaint"))
	bottom_panel_buttons.append(bottom_panel_ui.get_node("ButtonErase"))
	load_map(0)

func _on_system_state_changed(state):
	self.visible = (state == GameState.SYSTEM_STATE.MAP_EDIT)

func load_map(id: int):
	MapController.edit_map(0)
	MapController.draw_single_tile(Vector2i(0, 0), MapController.TILE.IK_LAVA)
	MapController.load_map(0, tile_map_layer)

func _process(delta: float) -> void:
	print("ME/cam pos ", camera.position)

func _input(event: InputEvent) -> void:
	if editing_tool == EDITING_TOOL.MOVE:
		map_dragging_input(event)
	elif editing_tool == EDITING_TOOL.PAINT:
		paint_input(event)

## Listen, I dont understand why this works but it works and let user drag the map around
## Refactor at your own risk hehe
func map_dragging_input(event: InputEvent) -> void:
	if not is_mouse_inside_map_dragging_area:
		return
	if event is InputEventMouse or event is InputEventScreenTouch:
		# Toggle dragging every action of pressing the stuff
		if event.is_pressed():
			# HACK: Hardcode this value, will need to review and check if the input is in the layer behind
			if event.position.x > 256.0 and event.position.y < 592.0:
				map_dragging = not map_dragging
				# Only when it is just toggled on, set the start of dragging
				if map_dragging:
					# Start at the displacement when the camera move
					dragging_start = event.position + camera_position
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if map_dragging:
			# Change the position when the map is dragging
			camera_position = -(event.position - dragging_start)
			camera.position = camera_position

func paint_input(event: InputEvent):
	if event is InputEventMouse or event is InputEventScreenTouch:
		if event.is_pressed():
			# Minus the vector to drive this to the screen center
			var tile_position : Vector2 = (event.position + camera_position - Vector2(640.0, 360.0))
			tile_position = Vector2(tile_position.x / 64, tile_position.y / 64).floor()
			MapController.draw_single_tile(tile_position, MapController.TILE.PLATFORM_BLUE)
			MapController.load_map(0, tile_map_layer)
			print("ME/estimate to position: ", tile_position)

func change_tool(tool: int, exclude_button : TextureButton):
	editing_tool = tool
	for button in bottom_panel_buttons:
		if button != exclude_button:
			button.button_pressed = false

func _on_button_move_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("ME/changing tool move")
		change_tool(EDITING_TOOL.MOVE, bottom_panel_ui.get_node("ButtonMove"))

func _on_button_paint_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("ME/changing tool paint")
		change_tool(EDITING_TOOL.PAINT, bottom_panel_ui.get_node("ButtonPaint"))

func _on_button_erase_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("ME/changing tool erase")
		change_tool(EDITING_TOOL.ERASE, bottom_panel_ui.get_node("ButtonErase"))
