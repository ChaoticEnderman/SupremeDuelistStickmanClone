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

## Temporary value of the time the joystick is held in jump angle, when this became 60 (time to jump) it will initialize a jump
## However if the player just stop this will be resetted
var jumping_time : int = 0

func _ready() -> void:
	# This is moved to the set_joystick_corner function since it cant accept parameters
	return

func set_joystick_corner(joystick_position : Globals.JOYSTICK_POSITION):
	# Not really any way to make this simpler, but it works for now
	if joystick_position == Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_TOP_LEFT:
		base_joystick.position = Vector2(0.0, 0.0) + Vector2(64.0, 64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_BOTTOM_LEFT:
		base_joystick.position = Vector2(0.0, 720.0) + Vector2(64.0, -64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_TOP_RIGHT:
		base_joystick.position = Vector2(1280.0, 0.0) + Vector2(-64.0, 64.0) * joystick_scale
	elif joystick_position == Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_BOTTOM_RIGHT:
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
	if (event is InputEventScreenTouch or event is InputEventMouseButton):
		# The joystick movement can be anywhere, but to initialize the movement, it must be in the joystick
		# So if the mouse is pressed it will do another layer of check to see if it's actually in the region of the joystick
		# But for like the else part, the joystick can be released everywhere
		if event.pressed == true:
			if base_joystick.position.distance_to(event.position) < joystick_radius * joystick_scale:
				dragging = true
				knob_joystick.position = knob_position
		else:
			dragging = false
			knob_joystick.rotation = 0.0
			knob_joystick.position = Vector2(knob_position.x, knob_position.y + 32)
	
	# Set the direction of the joystick dynamically
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if dragging:
			joystick_direction = (event.position - knob_joystick.global_position).normalized()
			 # Since the normals is different, we compare the relative rotation too the vector up
			joystick_angle = Vector2.UP.angle_to(joystick_direction)
			knob_joystick.rotation = joystick_angle

## Function called every tick to check the direction of the joystick movement
func tick_input() -> Vector2:
	if dragging:
		return joystick_direction
	return Vector2(0.0, 0.0)

## Function called every tick to check whether the player do an impulse action of releasing the joystick
func tick_input_is_releasing() -> bool:
	previous_dragging = dragging
	return previous_dragging and not dragging

## Function called every tick to check if the player is jumping at the current tick
func tick_input_is_jumping() -> bool:
	if rad_to_deg(joystick_angle) < Globals.JUMPING_ANGLE_DEGREES and rad_to_deg(joystick_angle) > -Globals.JUMPING_ANGLE_DEGREES and dragging:
		jumping_time += 1
	else:
		jumping_time = 0
	
	if jumping_time >= Globals.JUMP_TIME:
		print("Just jumped now!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		jumping_time = -1
		return true
	return false
	
