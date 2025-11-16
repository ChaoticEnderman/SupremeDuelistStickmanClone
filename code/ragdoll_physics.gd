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
## When the player is killed, the physics functions will stop
var is_alive : bool = true
## The jump action will apply the force 6 times in 6 frames
var jump_stacking : int = 0
## This will lock the jumping angle even if the joystick move during the jump stacking period
var locked_jumping_direction : Vector2

@onready var head : RigidBody2D = get_node("Head")
@onready var torso : RigidBody2D = get_node("Torso")
@onready var stomach : RigidBody2D = get_node("Stomach")

# P for primary, which will be the arm that have the weapon
@onready var p_arm : RigidBody2D = get_node("P Arm")
#@onready var p_forearm : RigidBody2D = get_node("P Forearm")

#@onready var p_arm = get_node("Shoulder Pivot/P Arm")
@onready var p_forearm = get_node("P Forearm")

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
			child.freeze = false
		if child is PinJoint2D:
			child.softness = 0.0
	
	# This monstrosity need to be refactored but Im procastinating
	
	# Making the legs dont touch eachother
	l_thigh.add_collision_exception_with(r_thigh)
	r_thigh.add_collision_exception_with(l_thigh)
	l_shin.add_collision_exception_with(r_shin)
	r_shin.add_collision_exception_with(l_shin)
	l_thigh.add_collision_exception_with(r_shin)
	r_thigh.add_collision_exception_with(l_shin)
	l_shin.add_collision_exception_with(r_thigh)
	r_shin.add_collision_exception_with(l_thigh)
	
	# Making the arms dont collide with the body and become independent
	p_arm.add_collision_exception_with(head)
	p_arm.add_collision_exception_with(torso)
	p_arm.add_collision_exception_with(stomach)
	p_forearm.add_collision_exception_with(head)
	p_forearm.add_collision_exception_with(torso)
	p_forearm.add_collision_exception_with(stomach)
	p_forearm.add_collision_exception_with(l_shin)
	p_forearm.add_collision_exception_with(r_shin)
	p_forearm.add_collision_exception_with(l_thigh)
	p_forearm.add_collision_exception_with(r_thigh)
	
	# Test
	p_arm.add_collision_exception_with(p_forearm)

## Master tick function to runs all other tick functions per physics tick
func tick_ragdoll(force: Vector2) -> void:
	if is_alive:
		#Flipping the normals since the game normal is always like this
		apply_ragdoll_central_force(Vector2(force.x, force.y), Globals.RAGDOLL_MOVE_FORCE * airborne_multiplier)
		tick_check_legs()
		tick_check_airborne()
		tick_move_arms(force)
		apply_central_torque(200.0, Globals.ANGULAR_DAMP)
		apply_leg_torque(200.0, Globals.ANGULAR_DAMP)
		apply_constant_leg_spacing(Globals.RAGDOLL_TORQUE_FORCE, Globals.ANGULAR_DAMP)
		#walking(force)
		
		tick_jump_stack()
		
## A base function to move the ragdoll entirely by just the central parts, the torso and stomach
## Other functions can assume this is a full ragdoll movement force
func apply_ragdoll_central_force(direction: Vector2, strength: float):
	# Direction should be normalized
	if direction == Vector2.ZERO:
		return
	
	torso.apply_central_force(direction * strength)
	stomach.apply_central_force(direction * strength)


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

func tick_move_arms(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	var angle = rad_to_deg(Vector2.UP.angle_to(direction)) - 180
	#p_arm.freeze = true
	#p_forearm.freeze = true
	#p_arm.apply_torque(torque * Globals.RAGDOLL_TORQUE_FORCE * 500)
	
	var arm_angle_displacement = rad_to_deg(p_arm.global_rotation) - angle
	var forearm_angle_displacement = rad_to_deg(p_forearm.global_rotation) - angle
	# To anybody going to maintaince this code, good luck hehehe prepare to die
	
	# Ok but still need comments, so this will always make the angle smaller than 180
	if abs(arm_angle_displacement) > 180:
		arm_angle_displacement = -(360 - arm_angle_displacement)
	if abs(forearm_angle_displacement) > 180:
		forearm_angle_displacement = -(360 - forearm_angle_displacement)
	
	
	# Limit the turning speed of like the arm to stop the bug, otherwise it will go crazy
	var angle_displacement_limit : int = 15
	if arm_angle_displacement > angle_displacement_limit:
		arm_angle_displacement = angle_displacement_limit
	elif arm_angle_displacement < -angle_displacement_limit:
		arm_angle_displacement = -angle_displacement_limit
	if forearm_angle_displacement > angle_displacement_limit:
		forearm_angle_displacement = angle_displacement_limit
	elif forearm_angle_displacement < -angle_displacement_limit:
		forearm_angle_displacement = -angle_displacement_limit
	
	# This is rather like the similiar code used in the angular limit but tweaked
	var arm_torque = (-Globals.RAGDOLL_TORQUE_FORCE * arm_angle_displacement * abs(arm_angle_displacement))
	var forearm_torque = (-Globals.RAGDOLL_TORQUE_FORCE * forearm_angle_displacement * abs(forearm_angle_displacement))
	
	p_arm.apply_torque(arm_torque)
	p_forearm.apply_torque(forearm_torque)

	
	#print(rad_to_deg(p_arm.global_rotation))
	#apply_angular_limit_torque(p_forearm, Globals.angle_to_360(rad_to_deg(p_arm.global_rotation)), Globals.RAGDOLL_TORQUE_FORCE/500, 0.0)
	

## Checking every single limbs for collision to any damagable objects
## No need for like removing duplicates since it will deal damage multiple times if hit multiple limbs
## Can be laggy since it's yet to implement broadphase collision checking
func tick_check_damage_collisions() -> Array[int]:
	var colliding_bodies : Array[int]
	# Nested nightmare
	for child in self.get_children():
		if child is RigidBody2D:
			for body in child.get_colliding_bodies():
				if body.get_owner().has_node("Damageable"):
					if not body.get_owner().damageable.owner_stickman == self.get_owner():
						colliding_bodies.append(body.get_owner().get_damage())
	return colliding_bodies

## Jump if the direction is not zero. Technically works without the != zero condition but just keep it
func jump(direction: Vector2):
	if jump_cache > 0 and direction != Vector2.ZERO and is_alive:
		apply_ragdoll_central_force(direction, Globals.RAGDOLL_JUMP_FORCE)
		locked_jumping_direction = direction
		recently_jumped = true
		jump_cache = 0
		jump_stacking = 6

## Check if the current jump stack is active, if yes it will continue to jump for next ticks
func tick_jump_stack():
	if jump_stacking > 0 and is_alive:
		jump_stacking -= 1
		apply_ragdoll_central_force(locked_jumping_direction, Globals.RAGDOLL_JUMP_FORCE)
		recently_jumped = true

## Animation called once when the ragdoll dies, will remove all pinjoints and stop physics
func dying_animation():
	is_alive = false
	for child in self.get_children():
		if child is PinJoint2D:
			child.free()

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

## Spread the legs out from eachother, make it stand and not topple over one side
func apply_constant_leg_spacing(force: float, damp: float):
	#var leg_distance = l_thigh.rotation - r_thigh.rotation
	apply_angular_limit_torque(l_thigh, 30.0, force / 2, damp)
	apply_angular_limit_torque(r_thigh, -30.0, force / 2, damp)
	apply_angular_limit_torque(l_shin, 0.0, force, damp)
	apply_angular_limit_torque(r_shin, 0.0, force, damp)
