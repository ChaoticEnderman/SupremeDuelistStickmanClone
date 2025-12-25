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

## Center of the screen, for partitioning to four quadrants
var screen_center : Vector2 = Vector2(DisplayServer.window_get_size().x / 2, DisplayServer.window_get_size().y / 2)

## All the accumulated inputs that is recorded in the _input function, will be resolved and cleared every tick
var current_input_events : Array[InputEvent]

func set_joystick_corner(joystick_position : Globals.JOYSTICK_POSITION):
	self.joystick_position = joystick_position
	# Not really any way to make this simpler, but it works for now
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_LEFT)
		base_joystick.position = Vector2(0.0, get_window().size.y) + Vector2(64.0, -64.0) * Globals.JOYSTICK_SCALE
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_RIGHT)
		base_joystick.position = Vector2(get_window().size.x, get_window().size.y) + Vector2(-64.0, -64.0) * Globals.JOYSTICK_SCALE
	# HACK: Disable top stuff because now only support 2 players
	#elif joystick_position == Globals.JOYSTICK_POSITION.TOP_LEFT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
		#base_joystick.position = Vector2(0.0, 0.0) + Vector2(64.0, 64.0) * Globals.JOYSTICK_SCALE
	#elif joystick_position == Globals.JOYSTICK_POSITION.TOP_RIGHT:
		#base_joystick.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
		##base_joystick.position = Vector2(get_window().size.x, 0.0) + Vector2(-64.0, 64.0) * Globals.JOYSTICK_SCALE
	
	# Set the knob position to the default value
	knob_position = knob_joystick.position
	# Scale and rotation
	base_joystick.scale = Vector2(Globals.JOYSTICK_SCALE, Globals.JOYSTICK_SCALE)
	knob_joystick.rotation = 0.0
	base_joystick.visible = true
	# Make the joystick centralized, will be changed later for modularity but this one works even with scaling
	# Probably due to only the parent node is scaled and the local position is the same
	knob_joystick.position = Vector2(knob_joystick.position.x, knob_joystick.position.y + 32)

func _input(event: InputEvent) -> void:
	current_input_events.append(event)

func touch_input_validation(event: InputEvent) -> bool:
	# Check the type
	if (not event is InputEventMouse) and (not event is InputEventScreenTouch):
		return false
	
	
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		if not (event.position.x < screen_center.x and event.position.y > screen_center.y):
			return false
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		if not (event.position.x > screen_center.x and event.position.y > screen_center.y):
			return false
	if joystick_position == Globals.JOYSTICK_POSITION.TOP_LEFT:
		if not (event.position.x < screen_center.x and event.position.y < screen_center.y):
			return false
	if joystick_position == Globals.JOYSTICK_POSITION.TOP_RIGHT:
		if not (event.position.x > screen_center.x and event.position.y < screen_center.y):
			return false
	return true

func touch_input_dragging(event: InputEvent) -> bool:
	if event == null:
		return false
	if not touch_input_validation(event):
		return false
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		joystick_direction = (event.position - knob_joystick.global_position).normalized()
		if event.is_pressed():
			change_joystick_direction(true)
		else:
			change_joystick_direction(false)
		return true
	return false
	
func touch_input(event: InputEvent) -> bool:
	if event == null:
		return true
	if joystick_direction != Vector2.ZERO:
		return true
	if not touch_input_validation(event):
		return true
	
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if event.position == null:
			return true
		if dragging:
			joystick_direction = (event.position - knob_joystick.global_position).normalized()
			return false
	
	return true
func keyboard_input():
	if joystick_direction != Vector2.ZERO:
		return
	if joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		joystick_direction = Input.get_vector("JoystickBottomLeftMoveLeft", "JoystickBottomLeftMoveRight", "JoystickBottomLeftMoveUp", "JoystickBottomLeftMoveDown")
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		joystick_direction = Input.get_vector("JoystickBottomRightMoveLeft", "JoystickBottomRightMoveRight", "JoystickBottomRightMoveUp", "JoystickBottomRightMoveDown")

func change_joystick_direction(dragging: bool):
	self.dragging = dragging
	if dragging:
		knob_joystick.position = knob_position
		joystick_angle = Vector2.UP.angle_to(joystick_direction)
		knob_joystick.rotation = joystick_angle
	else:
		knob_joystick.position = knob_position + Vector2(0.0, 32.0)
		knob_joystick.rotation = 0.0

## Function called every tick to check the direction of the joystick movement
func tick_input() -> Vector2:
	# Store the dragging value of the very previous tick, to compare with the current
	previous_dragging = dragging
	joystick_direction = Vector2.ZERO
	
	if Globals.KEYBOARD_INPUT_ENABLED:
		keyboard_input()
	else:
		for i in range(current_input_events.size() - 1, 1, -1):
			# Return to delete the event or not
			if touch_input_dragging(current_input_events[i]):
				current_input_events.remove_at(i)
		for i in range(current_input_events.size() - 1, 1, -1):
			# Return to delete the event or not
			if touch_input(current_input_events[i]):
				current_input_events.remove_at(i)
	if Globals.KEYBOARD_INPUT_ENABLED:
		if joystick_direction == Vector2.ZERO:
			change_joystick_direction(false)
		else:
			change_joystick_direction(true)
	else:
		change_joystick_direction(self.dragging)
	
	if joystick_direction != Vector2.ZERO:
		previous_joystick_direction = joystick_direction
		
	# This to ensure that the action of releasing the joystick must be resolved in the tick input function
	# So it wont have things like ghosting of input where when it release the game doesnt receive the input
	if is_releasing == false:
		is_releasing = previous_dragging and not dragging
	
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
	if rad_to_deg(joystick_angle) < Globals.JUMPING_ANGLE_DEGREES and rad_to_deg(joystick_angle) > -Globals.JUMPING_ANGLE_DEGREES and dragging:
		jumping_time += 1
	else:
		jumping_time = 0
	
	if jumping_time >= Globals.JUMP_TIME:
		print(jumping_time)
		jumping_time = -1
		return joystick_direction
	
	return Vector2.ZERO
	
