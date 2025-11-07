## This script control the rather low-level implementation of a physics body for each player
extends Node2D
class_name Ragdoll

var is_airborne : bool = false
## Force multiplier when the player is airborne, making a drag effect when falling players will drag slower
var airborne_multiplier : float = 1.0
## Every instance the player touch the ground, they can still jump after like falling down
## So the jump cache will be the time where players can actually jump after falling
var jump_cache : int = 60
## This will override the airborne check function, until the player is fully airborne
## This is because jumps are not instant and some ticks later the player is still on the ground
var recently_jumped : bool = false

@onready var head : RigidBody2D = get_node("Head")
@onready var torso : RigidBody2D = get_node("Torso")
@onready var stomach : RigidBody2D = get_node("Stomach")

# The legs name is dependent on the current position of the limbs, not the true name. So if a leg is more in the left direction, it will be the left
@onready var a_thigh : RigidBody2D = get_node("L Thigh")
@onready var b_thigh : RigidBody2D = get_node("R Thigh")
@onready var a_shin : RigidBody2D = get_node("L Shin")
@onready var b_shin : RigidBody2D = get_node("R Shin")

# Pseudo leg name, will be changed each tick depend on the position
@onready var l_thigh : RigidBody2D = a_thigh
@onready var r_thigh : RigidBody2D = b_thigh
@onready var l_shin : RigidBody2D = a_shin
@onready var r_shin : RigidBody2D = b_shin

func _ready() -> void:
	for child in self.get_children():
		if child is RigidBody2D:
			child.linear_damp = Globals.LINEAR_DAMP
			child.angular_damp = Globals.ANGULAR_DAMP
			child.contact_monitor = true
			child.max_contacts_reported = 100 # Upper bound, can be changed later
		if child is PinJoint2D:
			child.softness = 0.0
	
	# Making the legs dont touch eachother
	# This monstrosity need to be refactored
	l_thigh.add_collision_exception_with(r_thigh)
	r_thigh.add_collision_exception_with(l_thigh)
	l_shin.add_collision_exception_with(r_shin)
	r_shin.add_collision_exception_with(l_shin)
	l_thigh.add_collision_exception_with(r_shin)
	r_thigh.add_collision_exception_with(l_shin)
	l_shin.add_collision_exception_with(r_thigh)
	r_shin.add_collision_exception_with(l_thigh)

## Master tick function to runs all other tick functions per physics tick
func tick_ragdoll(force: Vector2) -> void:
	#Flipping the normals since the game normal is always like this
	add_ragdoll_central_force(Vector2(force.x, -force.y), Globals.RAGDOLL_MOVE_FORCE * airborne_multiplier)
	tick_check_legs()
	tick_check_airborne()
	apply_central_torque(200.0, 0.0)
	apply_leg_torque(200.0, 0.0)
	apply_constant_leg_spacing(Globals.RAGDOLL_TORQUE_FORCE, 0.0)
	#walking(force)
	print(is_airborne, "   ", recently_jumped)

## A base function to move the ragdoll entirely by just the central parts, the torso and stomach
## Other functions can assume this is a full ragdoll movement force
func add_ragdoll_central_force(direction: Vector2, strength: float):
	# Direction should be a normalized vector
	if direction == Vector2.ZERO:
		return
	
	torso.apply_force(direction * strength)
	stomach.apply_force(direction * strength)

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

## Function to check if the ragdoll shins is airborne, since these limbs are what dictate the air state of the ragdoll
func tick_check_airborne():
	is_airborne = true
	# When airborne (falling) the movement is slower and limited
	airborne_multiplier = 0.2
	# Checking both the legs touch the map
	tick_check_airborne_one_shin(l_shin)
	tick_check_airborne_one_shin(r_shin)
	
	# If the player has recently jumped, this will override the airborne code and instead reset the variable
	if recently_jumped:
		# Overide the jump_cache code until the player is fully airborne
		if is_airborne:
			recently_jumped = false
			jump_cache = 0
		return
	
	if not is_airborne:
		airborne_multiplier = 1.0
		jump_cache = 60
	if jump_cache > 0:
		jump_cache = jump_cache - 1

func tick_check_airborne_one_shin(shin: RigidBody2D):
	for body in shin.get_colliding_bodies():
		if body is TileMapLayer:
			is_airborne = false
			return

## Do we really need documentation on this?
func jump():
	if jump_cache > 0:
		add_ragdoll_central_force(Vector2.UP, Globals.RAGDOLL_JUMP_FORCE)
		recently_jumped = true
		jump_cache = 0


## Function to add walk animation if the direction is not in the jumping direction
#func walking(force: Vector2) -> bool:
	## This is kinda redundant so just ignore this probably, the walk effect that the leg create is enough
	#if force == Vector2.ZERO:
		#return false
	#var temp_angle : float = rad_to_deg(force.angle()) - 90
	#if not (temp_angle < Globals.JUMPING_ANGLE_DEGREES and temp_angle > -Globals.JUMPING_ANGLE_DEGREES):
		##l_thigh.apply_torque(100000.0)
		##r_thigh.apply_torque(-100000.0)
		#return true
	#return false

## Custom angular limit system that apply the torque that scale quadratically by the angle difference
## To make the quadratic function keep the sign, one of the variable is the absolute value
func apply_angular_limit_torque(body: RigidBody2D, target_angle : float, force : float, damp : float):
	var angle_displacement = rad_to_deg(body.global_rotation) - target_angle
	var torque = (-force * angle_displacement * abs(angle_displacement)) - (damp * body.angular_velocity)
	body.apply_torque(torque)

## Make the ragdoll stand rather upright
func apply_central_torque(force : float, damp : float):
	apply_angular_limit_torque(torso, 0.0, force, damp)
	apply_angular_limit_torque(stomach, 0.0, force * 4, damp)

## Make the shins standing in a stable manner
func apply_leg_torque(force : float, damp : float):
	apply_angular_limit_torque(l_shin, l_thigh.rotation, force, damp)
	apply_angular_limit_torque(r_shin, r_thigh.rotation, force, damp)

func apply_constant_leg_spacing(force: float, damp: float):
	#var leg_distance = l_thigh.rotation - r_thigh.rotation
	apply_angular_limit_torque(l_thigh, 30.0, force / 2, damp)
	apply_angular_limit_torque(r_thigh, -30.0, force / 2, damp)
	apply_angular_limit_torque(l_shin, 0.0, force, damp)
	apply_angular_limit_torque(r_shin, 0.0, force, damp)
