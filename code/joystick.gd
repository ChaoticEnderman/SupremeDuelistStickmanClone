extends CanvasLayer

@onready var base_joystick : Node2D = get_node("JoystickBase")
@onready var knob_joystick : Node2D = get_node("JoystickBase/JoystickButton")

@onready var knob_position : Vector2 = knob_joystick.position

var joystick_scale : float = 2.0

var joystick_direction : Vector2
var joystick_angle : float

var dragging : bool
var previous_dragging : bool

var jumping_time : int = 0

func _ready() -> void:
	base_joystick.apply_scale(Vector2(joystick_scale, joystick_scale))
	#knob_joystick.apply_scale(Vector2(joystick_scale, joystick_scale))
	knob_joystick.rotation = 0.0
	knob_joystick.position = Vector2(knob_joystick.position.x, knob_joystick.position.y + 32)
	

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed == true:
			dragging = true
			knob_joystick.position = knob_position
		else:
			dragging = false
			knob_joystick.rotation = 0.0
			knob_joystick.position = Vector2(knob_joystick.position.x, knob_joystick.position.y + 32)
			

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if dragging:
			joystick_direction = (event.position - knob_joystick.global_position).normalized()
			# Add 90 degree because of the normals problem , before flipping the y
			joystick_angle = (joystick_direction.angle() + deg_to_rad(90.0))
			#Flip the y because of the normals problem, might be changed later on bruh like wtf is going on
			joystick_direction = Vector2(joystick_direction.x, -joystick_direction.y)
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

func tick_input_is_jumping() -> bool:
	#print("A ", jumping_time, "  ", rad_to_deg(joystick_angle))
	if rad_to_deg(joystick_angle) < 30.0 and rad_to_deg(joystick_angle) > -30.0 and dragging:
		jumping_time += 1
	else:
		jumping_time = 0
	
	if jumping_time >= Globals.JUMP_TIME:
		jumping_time = 0
		return true
	return false
	
