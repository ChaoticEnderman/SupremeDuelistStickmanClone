## This script control the rather low-level implementation of a physics body for each player

## Already have been deprecated and replaced with Ragdoll2 class
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
## The jump action will apply the force 6 times in 6 frames, or a different constant in Globals for jump time
var jump_stacking : int = 0
## This will lock the jumping angle even if the joystick move during the jump stacking period
var locked_jumping_direction : Vector2

## Reference to the player that control this ragdoll physic manager
var player : Player

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

@onready var hip_joint : PinJoint2D = get_node("Hip Joint")
@onready var l_pelvis_joint : PinJoint2D = get_node("L Pelvis Joint")
@onready var r_pelvis_joint : PinJoint2D = get_node("R Pelvis Joint")
@onready var l_knee_joint : PinJoint2D = get_node("L Knee Joint")
@onready var r_knee_joint : PinJoint2D = get_node("R Knee Joint")
@onready var neck_joint : PinJoint2D = get_node("Neck Joint")
@onready var p_shoulder_joint : PinJoint2D = get_node("P Shoulder Joint")
@onready var p_elbow_joint : PinJoint2D = get_node("P Elbow Joint")
#@onready var _joint : PinJoint2D = get_node("")

## Store the damage to be applied for this tick, will be subtracted from player's hp and clear every tick
var damages : Array[float] = []

## Hat skin for the player
@onready var hat : Sprite2D = head.get_node("Hat")

## Special custom variable for the slow down effect
var slow_down_time : int = 0

## Special custom variable for the slow down effect
var freeze_time : int = 0

# TEST: Make a cycle for walking
var walking_cycle : int = 0

func _ready() -> void:
	for child in self.get_children():
		if child is RigidBody2D:
			child.linear_damp = Globals.LINEAR_DAMP
			child.angular_damp = Globals.ANGULAR_DAMP
			child.contact_monitor = true
			child.max_contacts_reported = 100 # Upper bound, can be changed later
			child.freeze = false
			
			# Adding area2d to detect collisions with other area2ds
			#var area2d : Area2D = Area2D.new()
			#var collision_shape : CollisionShape2D = CollisionShape2D.new()
			## Copy the RigidBody2D collision shape to the Area2D collision shape
			#collision_shape.shape = child.get_node("CollisionShape2D").shape
			#child.add_child(area2d)
		if child is PinJoint2D:
			child.softness = 0.0
			child.motor_enabled = true
			
	
	# This monstrosity need to be refactored but Im procastinating
	# Making the legs dont touch eachother
	l_thigh.add_collision_exception_with(r_thigh)
	r_shin.add_collision_exception_with(l_shin)
	
	l_thigh.add_collision_exception_with(r_shin)
	r_thigh.add_collision_exception_with(l_shin)
	
	# TEST: Making thigh and skin dont touchh eachother also
	#l_shin.add_collision_exception_with(l_thigh)
	#l_thigh.add_collision_exception_with(r_thigh)
	
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
	
	p_arm.add_collision_exception_with(p_forearm)
	
	player = self.get_owner()

## Make the entire ragdoll not collide with a physics body
func ragdoll_collision_exception(hitbox: PhysicsBody2D):
	for child in self.get_children():
		if child is RigidBody2D:
			child.add_collision_exception_with(hitbox)

## Set the hat for the ragdoll at starting time
func set_hat(texture: Texture2D):
	hat.texture = texture

## Master tick function to runs all other tick functions per physics tick
## Force should be a normalized vector sent from the player movement input
func tick_ragdoll(force: Vector2):
	if is_alive:
		if tick_freeze_ragdoll():
			return
		#Flipping the normals since the game normal is always like this
		apply_ragdoll_central_force(Vector2(force.x, force.y * airborne_multiplier), Globals.RAGDOLL_MOVE_FORCE / 1000)
		#tick_check_legs()
		tick_check_airborne()
		#tick_move_arms(force)
		apply_central_torque(Globals.RAGDOLL_TORQUE_FORCE * 2, Globals.ANGULAR_DAMP)
		#apply_leg_torque(Globals.RAGDOLL_TORQUE_FORCE, Globals.ANGULAR_DAMP)
		#apply_constant_leg_spacing(Globals.RAGDOLL_TORQUE_FORCE, Globals.ANGULAR_DAMP)
		
		walking(force,Globals.RAGDOLL_TORQUE_FORCE)
		
		tick_jump_stack()
		
		# For special effects
		tick_slow_down_ragdoll()
		
		#print("rag/walking/l_disp ", l_thigh.rotation_degrees)
		#print("rag/walking/r_disp ", r_thigh.rotation_degrees)

## A base function to move the ragdoll entirely by just the central parts, the torso and stomach
## Other functions can assume this is a full ragdoll movement force
func apply_ragdoll_central_force(direction: Vector2, strength: float):
	# Direction should be normalized
	if direction == Vector2.ZERO:
		return
	
	print("rag/central direction ", direction * strength)
	torso.apply_central_force(direction * strength)
	stomach.apply_central_force(direction * strength)

## Impulse the entire ragdoll body to move to a specific direction. Useful when doing abilities like dash or jump and smash
func move_entire_ragdoll_impulse(direction: Vector2, strength: float):
	if direction == Vector2.ZERO:
		return
	
	for limb in self.get_children():
		if limb is RigidBody2D:
			limb.apply_central_impulse(direction * strength)

## Slow down basically the entire ragdoll for some time
func slow_down_ragdoll(ticks: int):
	slow_down_time = ticks
	for body in self.get_children():
		if body is RigidBody2D and body.linear_damp == Globals.LINEAR_DAMP:
			# This is to resolve the stacking behavior of multiple slow at the same time
			# Only make the damp add up
			body.linear_damp += 200
			print("rag/before slow ", body.linear_damp)

## Completely freeze the ragdoll for a number of ticks
func freeze_ragdoll(ticks: int):
	print("rag/freezing ragdoll ", ticks)
	freeze_time = ticks
	for body in self.get_children():
		if body is RigidBody2D:
			body.freeze = true

func tick_slow_down_ragdoll():
	if slow_down_time > 0:
		slow_down_time -= 1
	if slow_down_time == 1:
		for body in self.get_children():
			if body is RigidBody2D:
				body.linear_damp = Globals.LINEAR_DAMP
		print("rag/removing slow ", torso.linear_damp)

## Checking for freezing state timer depletion, will return true if its still freezing
func tick_freeze_ragdoll():
	if freeze_time > 0:
		freeze_time -= 1
		return true
	elif freeze_time == 0:
		for body in self.get_children():
			if body is RigidBody2D:
				body.freeze = false
	return false

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
	airborne_multiplier = 0.1
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

## Move the primary arm every tick to follow the player direction
func tick_move_arms(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	var angle = rad_to_deg(Vector2.UP.angle_to(direction)) - 180
	#p_arm.freeze = true
	#p_forearm.freeze = true
	#p_arm.apply_torque(torque * Globals.RAGDOLL_TORQUE_FORCE * 500)
	
	var arm_angle_displacement = rad_to_deg(p_arm.global_rotation) - angle
	var forearm_angle_displacement = rad_to_deg(p_forearm.global_rotation) - angle
	# To anybody going to maintaince this code, good luck
	
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

func tick_check_collisions():
	damages = []
	tick_check_damage_collisions()
	tick_check_area_collisions()
	tick_check_tile_map_layer_collisions()

## Checking every single limbs for collision to any damagable objects
## No need for like removing duplicates since it will deal damage multiple times if hit multiple limbs
## Can be laggy since it's yet to implement broadphase collision checking
## Also a lot laggy because the nested function is in higher degree polynomial time
# TODO: optimize this idk
func tick_check_damage_collisions():
	var rounded_vector : Vector2i
	# Nested nightmare
	var tile_data : TileData
	for child in self.get_children():
		if child is RigidBody2D:
			for body in child.get_colliding_bodies():
				# Check if the body has any of the damageable composition
				# Need to check both the body and owner of that because different objects will have different way of resolving the Damageable
				# Some collision objects will have Damageable as child and some will have Damageable as siblings
				if has_damageable(body):
					#print("rag/body touch body ", body)
					# Do not damage if the owner is itself
					if not body.damageable.owner_stickman == self:
						damages.append(body.get_damage())
				if has_damageable(body.owner):
					# Do not damage if the owner is itself
					if not body.owner.damageable.owner_stickman == self:
						#print("rag/body touch owner ", body.owner.get_damage())
						damages.append(body.owner.get_damage())
			# TODO: Implement the tilemap damage system
			
			# Test to see the touching tile
			#rounded_vector = Vector2i(round(child.global_position.x / 64), round(child.global_position.y / 64))
			# TEST: Get the state of the children node from the physics server
			
			# HACK: This old approach is based on position of the limb when contacting the map, not the collision point
			#rounded_vector = nearest_neighbor_vector(child.global_position/64)
			#tile_data = SystemManager.game_map_tile_map.get_cell_tile_data(rounded_vector)
			#tile_data = SystemManager.game_map_tile_map.get_cell_tile_data(nearest_neighbor_vector(child.global_position/64))
			#if tile_data != null:
				#print("rag/touching map/tile ", tile_data, " dmg ", tile_data.get_custom_data("damage"))
				#damages.append(tile_data.get_custom_data("damage"))

## Check overlapping areas to the stickman for damage
func tick_check_area_collisions():
	var area : Area2D
	for child in self.get_children():
		if child is RigidBody2D:
			area = child.get_node("Area2D")
			if area != null:
				for a in area.get_overlapping_areas():
					if has_damageable(a):
						#print("rag/has dmg ", a.damageable.owner_stickman, self, (a.damageable.owner_stickman == self))
						if not a.damageable.owner_stickman == self:
							#print("rag/colliding areas dmg ", a.get_damage())
							# Do some check to find collision to different types of projectiles
							# FIXME: Refactor this monstrosity to a new function
							if a is Projectile2:
								slow_down_ragdoll(Globals.TPS * 2)
							if a is Projectile4:
								freeze_ragdoll(Globals.TPS / 2)
							damages.append(a.get_damage())
					# Kill immediately if the player touch the instant kill zone
					if a.get_collision_layer_value(4) == true:
						player.player_hp = 0

## Check collision with tiles in the tilemap, work once each tick for each limb
func tick_check_tile_map_layer_collisions():
	# Another nested nightmare, cant really refactor other than split to multiple functions so I will leave it like this
	for child in self.get_children():
		if child is RigidBody2D:
			# Getting state of the limbs from the Physics Server, for reading the collision data
			var state : PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(child.get_rid())
			# The limbs can collide with several objects, this loop is for looping for each individual one
			for i in state.get_contact_count():
				# Get the rid and object id of the colliding object
				var collider_rid : RID = state.get_contact_collider(i)
				var collider_object_id := PhysicsServer2D.body_get_object_instance_id(collider_rid)
				
				# After getting the ID, we will generate a similiar instance of the collision object
				var collider = instance_from_id(collider_object_id)
				# If it turns out to be the exact instance as the game map, it imply that the colliding object is the map tile
				if collider == SystemManager.game_map_tile_map:
					# Get contact position to the map tile
					var colliding_position = state.get_contact_collider_position(i)
					var local_pos: Vector2 = SystemManager.game_map_tile_map.to_local(colliding_position)
					# Nearest neighbor vector return a list of all possible tiles that might be colliding
					# Read the function for more info, but basically this is for solving an edge case
					# So if it happens to be not exact we will still be able to list all possibilities and try all 
					var potential_collision_vectors = nearest_neighbor_vector(local_pos)
					for vector in potential_collision_vectors:
						# Getting tile coords and custom damage data for the tiles
						var tile_coords: Vector2i = SystemManager.active_world.get_map_tile_map().local_to_map(vector)
						var tile_data = SystemManager.active_world.get_map_tile_map().get_cell_tile_data(tile_coords)
						if tile_data != null:
							#print("rag/touching map/tile ", tile_data, " dmg ", tile_data.get_custom_data("damage"))
							damages.append(tile_data.get_custom_data("damage"))
							if tile_data.get_custom_data("damage") != 0.0:
								print("rag/touching map ", colliding_position)

## Internal helper function to check if a node has the damageable composition
func has_damageable(parent: Node) -> bool:
	# HACK: unknown case but sometimes parent is null
	if parent == null:
		return false
	for child in parent.get_children():
		if child is Damageable:
			return true
	return false

## Test to find the nearest neighbor of the current limb touching position, to see the contacting tiles
## Still mostly in the test state
func nearest_neighbor_vector(vector: Vector2) -> Array[Vector2i]:
	# TODO: Write explaination math wise
	# Will need some diagrams to explain this so will do later (procastinating max level)
	var results : Array[Vector2i] = []
	var fract = vector - vector.floor()
	var dist_left = abs(fract.x)
	var dist_right = 1 - dist_left
	var dist_up = abs(fract.y)
	var dist_down = 1 - dist_up
	# If its in between a vertical or horizontal line then only two surrounding tiles are possible 
	if dist_left == 0:
		return [Vector2i(floor(vector.x) - 1, floor(vector.y)), Vector2i(floor(vector.x), floor(vector.y))]
	if dist_up == 0:
		return [Vector2i(floor(vector.x), floor(vector.y) - 1), Vector2i(floor(vector.x), floor(vector.y))]
	
	var nearest_neighbor = min(dist_left, dist_right, dist_up, dist_down)
	if dist_left == nearest_neighbor:
		return [Vector2i(floor(vector.x) - 1, floor(vector.y))]
	elif dist_right == nearest_neighbor:
		return [Vector2i(floor(vector.x) + 1, floor(vector.y))]
	elif dist_up == nearest_neighbor:
		return [Vector2i(floor(vector.x), floor(vector.y) - 1)]
	elif dist_down == nearest_neighbor:
		return [Vector2i(floor(vector.x), floor(vector.y) + 1)]
	# This is impossible to happen but Godot will complain lol
	return [Vector2i.ZERO]

## Jump if the direction is not zero. Technically works without the != zero condition but just keep it
func jump(direction: Vector2):
	if jump_cache > 0 and direction != Vector2.ZERO and is_alive:
		apply_ragdoll_central_force(direction, Globals.RAGDOLL_JUMP_FORCE)
		locked_jumping_direction = direction
		recently_jumped = true
		jump_cache = 0
		jump_stacking = Globals.JUMP_HEIGHT

## Check if the current jump stack is active, if yes it will continue to jump for next ticks
func tick_jump_stack():
	if jump_stacking > 0 and is_alive:
		jump_stacking -= 1
		apply_ragdoll_central_force(locked_jumping_direction, Globals.RAGDOLL_JUMP_FORCE)
		recently_jumped = true

## Animation called once when the ragdoll dies, will remove all pinjoints and stop physics
func dying_animation():
	if is_alive:
		for child in self.get_children():
			if child is PinJoint2D:
				child.free()
		for child in self.get_children():
			if child is RigidBody2D:
				child.apply_central_impulse(Vector2.from_angle(randf() * TAU).normalized() * 500)
	is_alive = false

## Function to add walk animation if the direction is not in the jumping direction
## Also if direction is in the range for 90 degrees arc under, it will skip and not walk also
## If not walking then it will do leg torque function instead 
func walking(direction: Vector2, force: float) -> bool:
	if direction == Vector2.ZERO:
		print("rag/walk/ ", stomach.global_rotation_degrees)
		apply_angular_limit_torque(l_thigh, stomach.global_rotation_degrees + 30, 1500, 0)
		apply_angular_limit_torque(r_thigh, stomach.global_rotation_degrees - 30, 1500, 0)
		#apply_constant_leg_spacing(Globals.RAGDOLL_TORQUE_FORCE, Globals.ANGULAR_DAMP)
		return false
	if abs(rad_to_deg(Vector2.UP.angle_to(direction))) > 135:
		#apply_constant_leg_spacing(Globals.RAGDOLL_TORQUE_FORCE, Globals.ANGULAR_DAMP)
		return false
	
	
	walking_cycle += 1
	var walk_power : float = 1.0
	
	# Use sine function to oscilate walking stuff
	walk_power = cos(PI * (walking_cycle % 60) / 30)
	print("rag/walk power left ", +(30 * -walk_power), " right ", -(30 * -walk_power))
	print("rag/walk power true ", walk_power)
	#apply_angular_limit_torque(l_thigh, stomach.global_rotation_degrees + (45 * -walk_power), 2000, 0.0)
	#apply_angular_limit_torque(r_thigh, stomach.global_rotation_degrees - (45 * -walk_power), 2000, 0.0)
	
	var l_shin_target_angle = l_thigh.global_rotation_degrees + (-30 if l_thigh.global_rotation_degrees > 0 else 30)
	var r_shin_target_angle = r_thigh.global_rotation_degrees + (30 if r_thigh.global_rotation_degrees < 0 else -30)
	apply_angular_limit_torque(l_shin, l_shin_target_angle, 5000, 0)
	apply_angular_limit_torque(r_shin, r_shin_target_angle, 5000, 0)
	
	#apply_angular_limit_torque(l_shin, 0, 500, 0)
	#apply_angular_limit_torque(r_shin, 0, 500, 0)
	
	return true

## Custom angular limit system that apply the torque that scale quadratically by the angle difference
## To make the quadratic function keep the sign, one of the variable is the absolute value
func apply_angular_limit_torque(body: RigidBody2D, target_angle: float, force: float, damp: float, angle_limit: float = 5.0):
	var angle_displacement = body.global_rotation_degrees - target_angle
	angle_displacement = wrapf(angle_displacement, -180, 180)
	if abs(angle_displacement) < angle_limit:
		print("rag/aalt/ignoring small disp")
		return
	
	# Torque calculated by quadratic interpolation. This was used primarily before to create smooth torque
	# However, the quadratic function grow really fast and might make the ragdoll unstable
	#var torque = (-force * angle_displacement * abs(angle_displacement)) - (damp * body.angular_velocity)
	# So now we are testing this with linear interpolation, as shown here
	var torque = (force * -angle_displacement)# - (damp * body.angular_velocity)
	
	var torque_limit = 64000
	if torque > torque_limit:
		pass
		#print("rag/alq/excess limit ", torque)
		#torque = torque_limit
	if torque < -torque_limit:
		pass
		#print("rag/alq/excess limit ", torque)
		#torque = -torque_limit
	body.apply_torque_impulse(torque)

## Make the ragdoll stand rather upright
func apply_central_torque(force : float, damp : float):
	apply_angular_limit_torque(torso, 0, force, damp)
	apply_angular_limit_torque(stomach, 0, force, damp)

## Make the shins standing in a stable manner, relatively to the thighs
func apply_leg_torque(force : float, damp : float):
	var l_shin_target_angle = l_thigh.global_rotation_degrees + (-45 if l_thigh.global_rotation_degrees > 0 else 45)
	var r_shin_target_angle = r_thigh.global_rotation_degrees + (45 if r_thigh.global_rotation_degrees < 0 else -45)
	apply_angular_limit_torque(l_shin, l_shin_target_angle, force, 0)
	apply_angular_limit_torque(r_shin, r_shin_target_angle, force, 0)
	

## FIXME: This is about to be removed
## Spread the legs out from eachother, make it stand and not topple over one side
func apply_constant_leg_spacing(force: float, damp: float):
	pass
	#var leg_distance = l_thigh.rotation - r_thigh.rotation
	#apply_angular_limit_torque(l_thigh, 20.0, force / 2, damp)
	#apply_angular_limit_torque(r_thigh, -20.0, force / 2, damp)
	#apply_angular_limit_torque(l_shin, 0.0, force / 4, damp)
	#apply_angular_limit_torque(r_shin, 0.0, force / 4, damp)
	
	#var target_angle : int = 30# + stomach.global_rotation_degrees
	#var motor_velocity_thigh : float = 15000 / Globals.TPS
	#var l_thigh_displacement : float = (target_angle - l_thigh.rotation_degrees)
	#var r_thigh_displacement : float = -(target_angle + r_thigh.rotation_degrees)
	#var motor_velocity_shin : float = 10000 / Globals.TPS
	#var l_shin_displacement : float = (l_thigh.rotation_degrees - l_shin.rotation_degrees)
	#var r_shin_displacement : float = (r_thigh.rotation_degrees - r_shin.rotation_degrees)
	#if abs(l_shin_displacement) > 180 or abs(r_shin_displacement) > 180:
	#	print("rag/abnormal shin angle l ", l_shin_displacement, " r ", r_shin_displacement)
	#	print("rag/abnormal fixed angle l ", wrapf(l_shin_displacement, -180.0, 180.0), " r ", wrapf(r_shin_displacement, -180.0, 180.0))
	#l_shin_displacement = wrapf(l_shin_displacement, -180.0, 180.0)
	#r_shin_displacement = wrapf(r_shin_displacement, -180.0, 180.0)
	#l_shin_displacement = -l_shin.rotation_degrees
	#r_shin_displacement = -r_shin.rotation_degrees
	
	#l_displacement = l_displacement * abs(l_displacement) / 20
	#r_displacement = r_displacement * abs(r_displacement) / 20
	
	#print("rag/leg spacing/stomach angle ", stomach.global_rotation_degrees)
	
	#l_thigh_displacement = deg_to_rad(l_thigh_displacement)
	#r_thigh_displacement = deg_to_rad(r_thigh_displacement)
	#l_shin_displacement = deg_to_rad(l_shin_displacement)
	#r_shin_displacement = deg_to_rad(r_shin_displacement)
	#l_pelvis_joint.motor_target_velocity = motor_velocity_thigh * l_thigh_displacement
	#r_pelvis_joint.motor_target_velocity = motor_velocity_thigh * r_thigh_displacement
	#l_knee_joint.motor_target_velocity = motor_velocity_shin * l_shin_displacement
	#r_knee_joint.motor_target_velocity = motor_velocity_shin * r_shin_displacement
	
