## Manage the movement control part for one single player
## This is only initialized if the player is not a bot
extends CanvasLayer
class_name Joystick

# Base and knob of the joystick for displaying the movement dynamically
@onready var base_joystick : Control = get_node("JoystickBase")
@onready var knob_joystick : Node2D = get_node("JoystickBase/JoystickButton")
# This is like a constant for like the original position of the joystick, in the very center, to fallback if the joystick is not touched
var knob_position : Vector2

## Radius of the joystick, will be used to calculate distance that the joystick is active
const joystick_radius : float = 64.0

## Direction that the joystick is pointing at, will be zero when its not touched
var joystick_direction : Vector2
## Previous joystick direction that is not erased every tick, for the release of abilities that isnt nulified in the tick that the user release
var previous_joystick_direction : Vector2
## The angle in degrees instead of vector, for displaying
var joystick_angle : float

## Value from the position enum, is responsible for saving the corner of the joystick
var joystick_position : Globals.JOYSTICK_POSITION

## Dragging is the current state of whether the input is being dragged
var dragging : bool
## This store the direct previous value of the dragging variable, determine whether the player release the joystick
var previous_dragging : bool
## Will be true if there is a difference in the previous dragging and dragging variable, when the player just release the joystick
var is_releasing : bool

## Temporary value of the time the joystick is held in jump angle, when this became 60 (time to jump) it will initialize a jump
## However if the player just stop this will be resetted
var jumping_time : int = 0
## Store the jump cooldown in a short succesion after jumping, to prevent double jump bugs
var jump_cooldown : int


## Center of the screen, for partitioning to four quadrants
var screen_center : Vector2# = Vector2(DisplayServer.window_get_size().x / 2, DisplayServer.window_get_size().y / 2)

func set_joystick_corner(joystick_position : Globals.JOYSTICK_POSITION):
	self.joystick_position = joystick_position
	
	# This is independent to viewport scaling and these stuff
	var window_size = get_viewport().get_visible_rect().size
	screen_center = Vector2((get_viewport().get_visible_rect().size.x / 2), (get_viewport().get_visible_rect().size.y / 2))
	# Not really any way to make this simpler, but it works for now
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_LEFT)
		base_joystick.global_position = Vector2(0.0, window_size.y) + Vector2(64.0, -64.0) * Globals.JOYSTICK_SCALE
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_RIGHT)
		base_joystick.global_position = Vector2(window_size.x, window_size.y) + Vector2(-64.0, -64.0) * Globals.JOYSTICK_SCALE
	# Disable top stuff because now only support 2 players
	#elif joystick_position == Globals.JOYSTICK_POSITION.TOP_LEFT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
		#base_joystick.position = Vector2(0.0, 0.0) + Vector2(64.0, 64.0) * Globals.JOYSTICK_SCALE
	#elif joystick_position == Globals.JOYSTICK_POSITION.TOP_RIGHT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
		##base_joystick.position = Vector2(get_window().size.x, 0.0) + Vector2(-64.0, 64.0) * Globals.JOYSTICK_SCALE
	
	print("joy/center ", screen_center)
	
	# Set the knob position to the default value
	knob_position = knob_joystick.position
	# Scale and rotation
	base_joystick.scale = Vector2(Globals.JOYSTICK_SCALE, Globals.JOYSTICK_SCALE)
	knob_joystick.rotation = 0.0
	base_joystick.visible = true
	# Make the joystick centralized, will be changed later for modularity but this one works even with scaling
	# Probably due to only the parent node is scaled and the local position is the same
	knob_joystick.position = Vector2(knob_joystick.position.x, knob_joystick.position.y + 32)

## Resolving input by interruption for near instant speed and will not need polling
## Will store the input data locally on this node, only polled by physics to move the player or sent continously to server through UDP node
func _input(event: InputEvent) -> void:
	if Globals.KEYBOARD_INPUT_ENABLED:
		keyboard_input()
	else:
		touch_input(event)
	if GameState.system_state == GameState.SYSTEM_STATE.ONLINE:
		prepare_input_packet()

## Check if the input is in the correct partition. Only count mouse or touch input
func touch_input_validation(event: InputEvent) -> bool:
	
	# Partition the screen into four quarters and only check input for the respective quarter
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		if get_pos(event).x < screen_center.x and get_pos(event).y > screen_center.y:
			return true
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		if get_pos(event).x > screen_center.x and get_pos(event).y > screen_center.y:
			return true
	#if joystick_position == Globals.JOYSTICK_POSITION.TOP_LEFT:
		#if not (event.global_position.x < screen_center.x and event.global_position.y < screen_center.y):
			#return false
	#if joystick_position == Globals.JOYSTICK_POSITION.TOP_RIGHT:
		#if not (event.global_position.x > screen_center.x and event.global_position.y < screen_center.y):
			#return false
	return false

## Get the position of the mouse/touch event independent on the scaling of the game viewport
func get_pos(event: InputEvent) -> Vector2:
	#var vp_size = get_viewport().get_visible_rect().size
	#var mouse_pos = get_viewport().get_mouse_position()
	#var normalized_pos = mouse_pos / vp_size
	return event.position
	return base_joystick.get_global_mouse_position()
	return get_viewport().get_mouse_position()

## Joystick touch input. Support both touch and mouse input on the screen. Will also partition the screen to quarters for less buggy multi-touch support
func touch_input(event: InputEvent) -> bool:
	if event == null:
		return false
	#if not touch_input_validation(event):
		#return false
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if not touch_input_validation(event):
			return false
		joystick_direction = (get_pos(event) - knob_joystick.global_position).normalized()
		if event.is_pressed():
			change_dragging(true)
		else:
			change_dragging(false)
		print("joy/touch press ", dragging)
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if not touch_input_validation(event):
			#change_dragging(false)
			return false
		#else:
		if dragging:
			joystick_direction = (get_pos(event) - knob_joystick.global_position).normalized()
			change_dragging(dragging)
	
	return true

## Keyboard input, harcoded WASD for left and Arrow keys for right joystick, I dont see the need in making this custom
## Players will just learn to deal with this and use this as default joystick config anyways
func keyboard_input():
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		joystick_direction = Input.get_vector("JoystickBottomLeftMoveLeft", "JoystickBottomLeftMoveRight", "JoystickBottomLeftMoveUp", "JoystickBottomLeftMoveDown")
		if Input.is_action_pressed("JoystickBottomLeftMoveLeft"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomLeftMoveRight"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomLeftMoveUp"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomLeftMoveDown"):
			change_dragging(true)
		else:
			change_dragging(false)
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		joystick_direction = Input.get_vector("JoystickBottomRightMoveLeft", "JoystickBottomRightMoveRight", "JoystickBottomRightMoveUp", "JoystickBottomRightMoveDown")
		if Input.is_action_pressed("JoystickBottomRightMoveLeft"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomRightMoveRight"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomRightMoveUp"):
			change_dragging(true)
		elif Input.is_action_pressed("JoystickBottomRightMoveDown"):
			change_dragging(true)
		else:
			change_dragging(false)

## Helper function to automatically set the knob of joystick to center if the direction is zero and its not being dragged actively
## Also change drection of joystick based on the direction
func change_dragging(dragging: bool):
	previous_dragging = self.dragging
	self.dragging = dragging
	# This to ensure that the action of releasing the joystick must be resolved in the tick input function
	# So it wont have things like ghosting of input where when it release the game doesnt receive the input
	if is_releasing == false:
		is_releasing = previous_dragging and not dragging
		if is_releasing:
			print("joy/releasing")
	
	if dragging:
		knob_joystick.position = knob_position
		joystick_angle = Vector2.UP.angle_to(joystick_direction)
		knob_joystick.rotation = joystick_angle
	else:
		knob_joystick.position = knob_position + Vector2(0.0, 32.0)
		knob_joystick.rotation = 0.0
		joystick_direction = Vector2.ZERO

## Function called every tick to check the direction of the joystick movement
func tick_input() -> Vector2:
	if joystick_direction != Vector2.ZERO:
		previous_joystick_direction = joystick_direction
	
	return joystick_direction

## Function called every tick to check whether the player do an impulse action of releasing the joystick
## After releasing, it still need to return the previous value of the direction
func tick_input_is_releasing() -> Vector2:
	if is_releasing:
		is_releasing = false
		return previous_joystick_direction
	return Vector2.ZERO

## Function called every tick to check if the player is jumping at the current tick
## Return the jump direction if the player is jumping, otherwise return zero
func tick_input_is_jumping() -> Vector2:
	if jump_cooldown > 0:
		jump_cooldown -= 1
	
	if rad_to_deg(joystick_angle) < Globals.JUMPING_ANGLE_DEGREES and rad_to_deg(joystick_angle) > -Globals.JUMPING_ANGLE_DEGREES and dragging:
		if jump_cooldown == 0:
			jumping_time += 1
		else:
			jumping_time == 0
	else:
		jumping_time = 0
	
	if jumping_time >= Globals.JUMP_TIME:
		jumping_time = 0
		jump_cooldown = Globals.TPS / 4
		return joystick_direction
	
	return Vector2.ZERO

## Sending raw input data to the server, including jump time and jumping cooldown which can be hacked at client level
## However we still have no server heuristic anticheat and raw input can just be cheated, so assume all of client side data is also not cheated for now
## Since just finding a bot to play this game and win is some kind of achievement the developer decide to let it a bit open
func prepare_input_packet():
	var input_state : Dictionary = {
	"joystick_direction" : "",
	"previous_joystick_direction" : "",
	"joystick_position" : "",
	"dragging" : "=",
	"previous_dragging" : "=",
	"is_releasing" : "=",
	"jumping_time" : "=",
	"jump_cooldown" : "=",
	}
	
	input_state.joystick_direction = joystick_direction
	input_state.previous_joystick_direction = previous_joystick_direction
	input_state.dragging = dragging
	input_state.previous_dragging = previous_dragging
	input_state.is_releasing = is_releasing
	input_state.jumping_time = jumping_time
	input_state.jump_cooldown = jump_cooldown
