## Manage the movement control part for one single player
## This is only initialized if the player is not a bot
extends CanvasLayer
class_name Joystick

# Base and knob of the joystick for displaying the movement dynamically
@onready var base_joystick : Node2D = get_node("JoystickBase")
@onready var knob_joystick : Node2D = get_node("JoystickBase/JoystickButton")
# This is like a constant for like the original position of the joystick, in the very center, to fallback if the joystick is not touched
var knob_position : Vector2

## Radius of the joystick, will be used to calculate distance that the joystick is active
const joystick_radius : float = 64.0
## Joystick scale
var joystick_scale : float = 2.0

# Direction and angle
var joystick_direction : Vector2
var joystick_angle : float

## Dragging is the current state of whether the input is being dragged
var dragging : bool
## This store the direct previous value of the dragging variable, determine whether the player release the joystick
var previous_dragging : bool
## Will be true if there is a difference in the previous dragging and dragging variable, when the player just release the joystick
var is_releasing : bool

## Temporary value of the time the joystick is held in jump angle, when this became 60 (time to jump) it will initialize a jump
## However if the player just stop this will be resetted
var jumping_time : int = 0

## The unique touch index id of the current streak of drag, to make each touchs independent of eachother
var touch_index : int = -1

func _ready() -> void:
	# This is moved to the set_joystick_corner function since it cant accept parameters
	return

func set_joystick_corner(joystick_position : Globals.JOYSTICK_POSITION):
	# Not really any way to make this simpler, but it works for now
	if joystick_position == Globals.JOYSTICK_POSITION.TOP_LEFT:
		base_joystick.position = Vector2(0.0, 0.0) + Vector2(64.0, 64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_LEFT:
		base_joystick.position = Vector2(0.0, 720.0) + Vector2(64.0, -64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.TOP_RIGHT:
		base_joystick.position = Vector2(1280.0, 0.0) + Vector2(-64.0, 64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.BOTTOM_RIGHT:
		base_joystick.position = Vector2(1280.0, 720.0) + Vector2(-64.0, -64.0) * joystick_scale
	
	# Set the knob position to the default value
	knob_position = knob_joystick.position
	# Scale and rotation
	base_joystick.apply_scale(Vector2(joystick_scale, joystick_scale))
	knob_joystick.rotation = 0.0
	base_joystick.visible = true
	# Make the joystick centralized, will be changed later for modularity but this one works even with scaling
	# Probably due to only the parent node is scaled and the local position is the same
	knob_joystick.position = Vector2(knob_joystick.position.x, knob_joystick.position.y + 32)

func _input(event: InputEvent) -> void:
	# Store the dragging value of the very previous tick, to compare with the current
	previous_dragging = dragging
	
	if event is InputEventScreenTouch:
		# The joystick movement can be anywhere, but to initialize the movement, it must be in the joystick
		# So if the mouse is pressed it will do another layer of check to see if it's actually in the region of the joystick
		# But for like the else part, the joystick can be released everywhere
		if base_joystick.position.distance_to(event.position) < joystick_radius * joystick_scale:
			# This only works if the touch index is not writed or is the same as the touch index
			if event.pressed == true and (touch_index == -1 or touch_index == event.index):
				dragging = true
				knob_joystick.position = knob_position
				# To uniquely identify each touch input and ignore on mouse inputs
				touch_index = event.index
		if event.pressed == false and touch_index == event.index:
			# Same, only activate reset of the joystick if the index is the same
			dragging = false
			knob_joystick.rotation = 0.0
			knob_joystick.position = Vector2(knob_position.x, knob_position.y + 32)
			touch_index = -1
	
	if event is InputEventMouseButton:
		if event.pressed == true:
			if base_joystick.position.distance_to(event.position) < joystick_radius * joystick_scale:
				dragging = true
				knob_joystick.position = knob_position
		elif event.pressed == false:
			dragging = false
			knob_joystick.rotation = 0.0
			knob_joystick.position = Vector2(knob_position.x, knob_position.y + 32)
	
	# Set the direction of the joystick dynamically
	if (event is InputEventScreenDrag and touch_index == event.index) or event is InputEventMouseMotion:
		if dragging:
			joystick_direction = (event.position - knob_joystick.global_position).normalized()
			 # Since the normals is different, we compare the relative rotation too the vector up
			joystick_angle = Vector2.UP.angle_to(joystick_direction)
			knob_joystick.rotation = joystick_angle
	
	# This to ensure that the action of releasing the joystick must be resolved in the tick input function
	# So it wont have things like ghosting of input where when it release the game doesnt receive the input
	if not is_releasing:
		is_releasing = previous_dragging and not dragging

## Function called every tick to check the direction of the joystick movement
func tick_input() -> Vector2:
	if dragging:
		return joystick_direction
	return Vector2(0.0, 0.0)

## Function called every tick to check whether the player do an impulse action of releasing the joystick
## After releasing, it still need to return the previous value of the direction
func tick_input_is_releasing() -> Vector2:
	if is_releasing:
		is_releasing = false
		return joystick_direction
	else:
		# Effectively null
		return Vector2.ZERO

## Function called every tick to check if the player is jumping at the current tick
## Return the jump direction if the player is jumping, otherwise return zero
func tick_input_is_jumping() -> Vector2:
	if rad_to_deg(joystick_angle) < Globals.JUMPING_ANGLE_DEGREES and rad_to_deg(joystick_angle) > -Globals.JUMPING_ANGLE_DEGREES and dragging:
		jumping_time += 1
	else:
		jumping_time = 0
	
	if jumping_time >= Globals.JUMP_TIME:
		jumping_time = -1
		return joystick_direction
	
	return Vector2.ZERO
	
