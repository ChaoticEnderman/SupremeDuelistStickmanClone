extends Node2D
## This script control the rather low-level implementation of a physics body

@onready var PlayerNode: Node2D = get_node(".")
const Globals = preload("res://code/Globals.gd")

var is_dragging : bool = false
var offset : Vector2
var is_airborne : bool = false


@onready var head : RigidBody2D = get_node("Head")
@onready var torso : RigidBody2D = get_node("Torso")
@onready var stomach : RigidBody2D = get_node("Stomach")

# The legs name is dependent on the current position of the limbs, not the true name. So if a leg is more in the left direction, it will be the left
@onready var a_thigh : RigidBody2D = get_node("L Thigh")
@onready var b_thigh : RigidBody2D = get_node("R Thigh")
@onready var a_shin : RigidBody2D = get_node("L Shin")
@onready var b_shin : RigidBody2D = get_node("R Shin")
# True leg name
@onready var l_thigh : RigidBody2D = a_thigh
@onready var r_thigh : RigidBody2D = b_thigh
@onready var l_shin : RigidBody2D = a_shin
@onready var r_shin : RigidBody2D = b_shin


func _ready() -> void:
	for child in self.get_children():
		if child is RigidBody2D:
			child.linear_damp = Globals.LINEAR_DAMP
			child.angular_damp = Globals.ANGULAR_DAMP
			child.linear_damp = 0.2
			child.angular_damp = 0.2
			child.contact_monitor = true
			child.max_contacts_reported = 100 # Upper bound, can be changed later
		if child is PinJoint2D:
			child.softness = 0.0
			
	
	#This monstrosity need to be refactored
	l_thigh.add_collision_exception_with(r_thigh)
	r_thigh.add_collision_exception_with(l_thigh)
	l_shin.add_collision_exception_with(r_shin)
	r_shin.add_collision_exception_with(l_shin)
	l_thigh.add_collision_exception_with(r_shin)
	r_thigh.add_collision_exception_with(l_shin)
	l_shin.add_collision_exception_with(r_thigh)
	r_shin.add_collision_exception_with(l_thigh)


#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		## Freeze/unfreeze all children and move them by the mouse offset, virtually creating the dragging effect
		#if event.pressed:
			#is_dragging = true
			#offset = get_global_mouse_position() - global_position
			#for child in get_children():
				#if child is RigidBody2D:
					#child.freeze = true
		#else:
			#is_dragging = false
			#for child in get_children():
				#if child is RigidBody2D:
					#child.freeze = false


func tick_ragdoll(force: Vector2) -> void:
	#Flipping the normals again, since the game normal is always like this
	add_ragdoll_central_force(Vector2(force.x, -force.y), Globals.MOVE_FORCE)
	tick_check_legs()
	tick_check_airborne()
	apply_constant_leg_spacing()
	apply_central_torque(200.0, 0.0)
	apply_leg_torque(200.0, 0.0)

#func _process(_delta: float) -> void:
	#if is_dragging:
		#global_position = get_global_mouse_position() - offset
		## Keep children aligned to parent manually
		#for child in get_children():
			#if child is RigidBody2D:
				#child.global_position = child.global_position


func add_ragdoll_central_force(direction: Vector2, strength: float):
	# direction should be a normalized vector
	if direction == Vector2.ZERO:
		return

	torso.apply_force(direction * strength * torso.mass)
	stomach.apply_force(direction * strength * stomach.mass)

## Simple function to determine which of the two identical legs are left and right, based on their rotation
func tick_check_legs():
	if a_thigh.rotation > b_thigh.rotation:
		l_thigh = a_thigh
		l_shin = a_shin
		r_thigh = b_thigh
		r_shin = b_shin
	else:
		l_thigh = b_thigh
		l_shin = b_shin
		r_thigh = a_thigh
		r_shin = a_shin

func tick_check_airborne():
	print(l_shin.get_colliding_bodies())

func jump():
	#print("jumping!")
	add_ragdoll_central_force(Vector2.UP, Globals.JUMP_FORCE)

func apply_angular_limit_torque(body: RigidBody2D, target_angle : float, force : float, damp : float):
	var angle_displacement = rad_to_deg(body.global_rotation) - target_angle
	var torque = (-force * angle_displacement * abs(angle_displacement)) - (damp * body.angular_velocity)
	body.apply_torque(torque)

func apply_central_torque(force : float, damp : float):
	apply_angular_limit_torque(torso, 0.0, Globals.UPRIGHT_TORQUE_FORCE, 0.0)
	apply_angular_limit_torque(stomach, 0.0, Globals.UPRIGHT_TORQUE_FORCE * 4, 0.0)

func apply_leg_torque(force : float, damp : float):
	apply_angular_limit_torque(l_shin, l_thigh.rotation, force, damp)
	apply_angular_limit_torque(r_shin, r_thigh.rotation, force, damp)

func apply_constant_leg_spacing():
	var leg_distance = l_thigh.rotation - r_thigh.rotation
	#print(rad_to_deg(leg_distance))
	apply_angular_limit_torque(l_thigh, 30.0, Globals.UPRIGHT_TORQUE_FORCE / 2, 0.0)
	apply_angular_limit_torque(r_thigh, -30.0, Globals.UPRIGHT_TORQUE_FORCE / 2, 0.0)
	apply_angular_limit_torque(l_shin, 0.0, Globals.UPRIGHT_TORQUE_FORCE, 0.0)
	apply_angular_limit_torque(r_shin, 0.0, Globals.UPRIGHT_TORQUE_FORCE, 0.0)
