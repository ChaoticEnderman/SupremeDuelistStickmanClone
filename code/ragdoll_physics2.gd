## A renewed version of the ragdoll physics class. Have much better stability over the previous version.
## Since the ragdoll physics is the most complicated class and it create a lot of problems, I am rewriting this as a whole
## The old class is still rather complicated so it will be kept as backup. Later on it might be an artifact in the old code
extends Node2D
class_name Ragdoll2

@onready var head : RigidBody2D = $Head
@onready var torso : RigidBody2D = $Torso
@onready var stomach : RigidBody2D = $Stomach
@onready var l_thigh : RigidBody2D = $"L Thigh"
@onready var r_thigh : RigidBody2D = $"R Thigh"
@onready var l_shin : RigidBody2D = $"L Shin"
@onready var r_shin : RigidBody2D = $"R Shin"
@onready var p_forearm : RigidBody2D = $"P Forearm"
@onready var p_arm : RigidBody2D = $"P Arm"

@onready var hip : PinJoint2D = $"Hip Joint"
@onready var l_pelvis : PinJoint2D = $"L Pelvis Joint"
@onready var r_pelvis : PinJoint2D = $"R Pelvis Joint"
@onready var l_knee : PinJoint2D = $"L Knee Joint"
@onready var r_knee : PinJoint2D = $"R Knee Joint"

## List of limbs in a specific order
@onready var ordered_limbs : Array[RigidBody2D] = [head, torso, stomach, l_thigh, r_thigh, l_shin, r_shin, p_forearm, p_arm]
@onready var ordered_joints : Array[PinJoint2D] = [hip, l_pelvis, r_pelvis, l_knee, r_knee]

## Seperate hat spriteo of the ragdoll, set by player
@onready var hat : Sprite2D = head.get_node("Hat")

## Reference to the master player sprite that direct this ragdoll
var player : Player

## Ragdoll direction, controlled by the joystick
var ragdoll_direction : Vector2 = Vector2.ZERO

## Cumulative tick added once internally per every tick, will use modulo by engine TPS to make a 0-60 cycle of walking 
var walking_tick : int = 0

var stored_collision_layer : Array[int]
var stored_collision_mask : Array[int]

## Storing the state for the ragdoll if its alive or not. Used primarily to stop some physics interaction and to call the death animation
var is_alive = true
## Whether the ragdoll is on the air or not. Used to nulify jumping and reduce control when ragdoll is on air.
## This is calculated by whether any of the shin touch the TileMapLayer or not
var is_on_air : bool = false
## Force multiplier when the player is airborne, making a drag effect when falling players will drag slower
var on_air_multiplier : float = 1.0
## Every instance the player touch the ground, they can still jump after like falling down in SDS or similiar effect.
## So the jump cache will be the time where players can actually jump after falling.
## For example the ragdoll just recently fall out a cliff but since they touch the cliff, its still possible to quickly do the jump action
var recently_touched_ground : int = 60
## Jump direction written and locked the instant the ragdoll jump, to make the jump not manipulated by quickly changing direction
var locked_jumping_direction : Vector2
## The number of succesion the jump apply jump impulse. Will apply a small impulse every tick until the stack deplete
## This is for making a more stable jump animation that can still go high if needed 
var jump_stacking : int

## Store temporary damages for the player class to clear out and reduce hp for damage on each tick
var damages : Array[float] = []

## Special custom variable for the slow down effect
var slow_down_time : int = 0
## Special custom variable for the freeze effect
var freeze_time : int = 0
## Special custom variable for the enlarge effect
var enlarge_time : int  = 0
## Special custom variable for counting number of the enlarge effect 
var enlarge_number : int = 0
## Special custom variable to lock to teleport for one tick
var teleport_lock : bool = false
## Special custom variable to save teleport direction
var teleport_direction : Vector2 = Vector2.ZERO
## Cooldown between teleporting, particularly for the portal gun
var teleport_cooldown : int = 0

## Helper function for the player class to get arm position to put the weapon in
func get_arm_position() -> Vector2:
	return self.p_forearm.global_position

## Slow down basically the entire ragdoll for some time
func slow_down_ragdoll(ticks: int):
	slow_down_time = ticks
	for body in self.get_children():
		if body is RigidBody2D and body.linear_damp == Globals.LINEAR_DAMP:
			# This is to resolve the stacking behavior of multiple slow at the same time
			# Only make the damp add up
			body.linear_damp += 500
			body.angular_damp += 500

## Completely freeze the ragdoll for a number of ticks
func freeze_ragdoll(ticks: int):
	freeze_time = ticks
	for body in self.get_children():
		if body is RigidBody2D:
			body.freeze = true

## Disable the entire ragdoll and make it like a ghost
func lock_freeze_ragdoll(is_freezing: bool):
	for body in self.get_children():
		if body is RigidBody2D:
			if is_freezing:
				pass
			else:
				body.collision_layer = 2

#func enlarge_ragdoll(ticks: int):
	#print("rag/enlarge ", pow(1.1, enlarge_number))
	#enlarge_time = ticks
	#enlarge_number += 1
	#for body in self.get_children():
		#if body is RigidBody2D:
			#body.freeze = true
			#var scale_vector = Vector2(pow(1.1, enlarge_number), pow(1.1, enlarge_number))
			#body.scale = scale_vector
			#body.get_node("Sprite2D").scale = scale_vector
			#head.get_node("Sprite2D").scale = Vector2(0.059, 0.059)
			#body.get_node("CollisionShape2D").scale = scale_vector
			##head.get_node("CollisionShape2D").scale = Vector2(0.059, 0.059)
			#body.freeze = false

## Set the hat for the ragdoll at starting time
func set_hat(texture: Texture2D):
	hat.texture = texture

func _ready() -> void:
	
	self.player = self.get_owner()
	
	Engine.physics_ticks_per_second = 60
	walking_tick = Engine.physics_ticks_per_second / 2
	
	for child in ordered_limbs:
		child.contact_monitor = true
		child.max_contacts_reported = 100
		child.linear_damp = Globals.LINEAR_DAMP
		child.angular_damp = Globals.ANGULAR_DAMP
		
		child.add_collision_exception_with(p_forearm)
		child.add_collision_exception_with(p_arm)
		
		child.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	for child in ordered_joints:
		child.motor_enabled = true
	
	l_thigh.add_collision_exception_with(r_thigh)
	l_shin.add_collision_exception_with(r_shin)
	
	l_thigh.add_collision_exception_with(r_shin)
	r_thigh.add_collision_exception_with(l_shin)

## Make the entire ragdoll not collide with a physics body
func ragdoll_collision_exception(hitbox: PhysicsBody2D):
	for child in ordered_limbs:
		child.add_collision_exception_with(hitbox)

## Move the entire ragdoll for movement like walking or jumping but not the arm since they are seperate
func move_entire_ragdoll_impulse(direction: Vector2, force: float):
	for child in ordered_limbs:
		if not (child == p_arm or child == p_forearm):
			child.apply_central_impulse(direction * force)

## Let every limb in the ragdoll jump up including the arm in this special case for more stable hands
func jump_entire_ragdoll_impulse(direction: Vector2, force: float):
	for child in ordered_limbs:
		# Scale up the jump height based on how close it to the direct jump upward angle.
		# When its perfectly up, scaling is 1 and when its at an angle, scaling is less than 1
		# This is to nerf rather horizontal jumping and make it looks smoother
		child.apply_central_impulse(direction * force * cos(Vector2.UP.angle_to(direction)))

func teleport_entire_ragdoll_impulse(displacement: Vector2):
	teleport_lock = true
	teleport_direction = displacement

func tick_ragdoll(direction: Vector2) -> void:
	self.ragdoll_direction = direction
	if not is_alive:
		return
	if tick_freeze_ragdoll():
		return
	if tick_teleport_ragdoll():
		# Also ignore all movement when the tick is for teleporting
		return
	
	for child in ordered_limbs:
		child.apply_force(Vector2(
		# Basically also affect horizontal movement but 6 time less than if the ragdoll is on air
		(ragdoll_direction.x * on_air_multiplier * 6) if (on_air_multiplier < 1) else ragdoll_direction.x,
		ragdoll_direction.y * on_air_multiplier)
		* Globals.RAGDOLL_MOVE_FORCE)
	
	rotate_arm(direction)
	
	make_ragdoll_stand_upright()
	#make_ragdoll_shin_upright()
	
	check_thigh_options(ragdoll_direction)
	
	tick_check_on_air()
	tick_jump_stack()
	
	tick_slow_down_ragdoll()
	#tick_enlarge_ragdoll()
	
	tick_check_collisions()


func tick_slow_down_ragdoll():
	if slow_down_time > 0:
		slow_down_time -= 1
	if slow_down_time == 1:
		for body in ordered_limbs:
			body.linear_damp = Globals.LINEAR_DAMP
			body.angular_damp = Globals.ANGULAR_DAMP
		print("rag/removing slow ", torso.linear_damp)

## Checking for freezing state timer depletion, will return true if its still freezing
func tick_freeze_ragdoll():
	if freeze_time > 0:
		freeze_time -= 1
		return true
	elif freeze_time == 0:
		for body in ordered_limbs:
			body.freeze = false
	return false

#func tick_enlarge_ragdoll():
	#if enlarge_time > 0:
		#enlarge_time -= 1
	#elif enlarge_time == 0:
		#for body in self.get_children():
			#if body is RigidBody2D:
				#body.scale = Vector2(1, 1)
				##body.get_node("Sprite2D").scale = Vector2(1, 1)
				##head.get_node("Sprite2D").scale = Vector2(0.059, 0.059)
				#body.get_node("CollisionShape2D").scale = Vector2(1, 1)
				##head.get_node("CollisionShape2D").scale = Vector2(0.059, 0.059)
		#enlarge_number = 0
	#print("rag/scale ", enlarge_time)

## Function to poll the teleport signal and resolve in the current frame, return whether it is teleporting this frame or no
func tick_teleport_ragdoll() -> bool:
	if teleport_cooldown > 0:
		teleport_cooldown -= 1
	if teleport_lock:
		for child in ordered_limbs:
			child.freeze = true
			child.position += teleport_direction
			child.freeze = false
		teleport_lock = false
		return true
	return false

func rotate_arm(direction: Vector2):
	# Angle limit 
	var angle_limit : float = (0.1 * PI) / Globals.TPS
	var angle_limit_degrees : float = 1.0 / Globals.TPS
	
	if rad_to_deg(direction.angle()) == 0:
		return
	
	# TODO: try to add angle limit again because the previous approach doesnt work
	var arm_target_angle : float = rad_to_deg(direction.angle()) - 90.0
	var forearm_target_angle : float = rad_to_deg(direction.angle()) - 90.0
	angular_limit_torque(p_forearm, forearm_target_angle, Globals.RAGDOLL_TORQUE_FORCE)
	angular_limit_torque(p_arm, arm_target_angle, Globals.RAGDOLL_TORQUE_FORCE)

func make_ragdoll_stand_upright():
	angular_limit_torque(head, 0, Globals.RAGDOLL_TORQUE_FORCE * 2)
	angular_limit_torque(torso, 0, Globals.RAGDOLL_TORQUE_FORCE * 5)
	angular_limit_torque(stomach, 0, Globals.RAGDOLL_TORQUE_FORCE * 5)

## Make the shin upright and relatively parallel to the stomach limb. Torque is calculated directly from thighs so indirectly from shins
## Through the intermediate thigh, it will be a 45-45 angle flick in most cases. 
func make_ragdoll_shin_upright():
	var l_shin_target_angle = l_thigh.global_rotation_degrees + (-Globals.RAGDOLL_WALK_ANGLE if l_thigh.global_rotation_degrees > 0 else Globals.RAGDOLL_WALK_ANGLE)
	var r_shin_target_angle = r_thigh.global_rotation_degrees + (Globals.RAGDOLL_WALK_ANGLE if r_thigh.global_rotation_degrees < 0 else -Globals.RAGDOLL_WALK_ANGLE)
	
	l_shin_target_angle = 0.0
	r_shin_target_angle = 0.0
	angular_limit_torque(l_shin, l_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 2)
	angular_limit_torque(r_shin, r_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 2)

## Making the ragdoll thigh roughly in 45 degrees angle left and right of the stomach, useful for standing states
func make_ragdoll_thigh_seperated():
	angular_limit_torque(l_thigh, stomach.global_rotation_degrees + Globals.RAGDOLL_WALK_ANGLE, Globals.RAGDOLL_TORQUE_FORCE * 3)
	angular_limit_torque(r_thigh, stomach.global_rotation_degrees - Globals.RAGDOLL_WALK_ANGLE, Globals.RAGDOLL_TORQUE_FORCE * 3)

## Check to see what should be done with the thigh, the important parts for moving the ragdolls
## If the angle is none then make the thigh seperated, basic and will work for stances
## If its inside the jumping angle range then will also make seperated like normal, to have a jumping stance
## If its in right or left angle then will swing the leg back and forth for the walking animation
## If the angle is too low to the ground then it will not walk and instead of crouch, to prevent instability (also wont seperate thighs)
func check_thigh_options(direction: Vector2):
	if direction == Vector2.ZERO:
		make_ragdoll_thigh_seperated()
		make_ragdoll_shin_upright()
		return
	if abs(rad_to_deg(Vector2.UP.angle_to(direction))) > 150:
		# When crouching, reducing shin torque by a third to let the legs stay horizontal in some cases
		# TODO: Put all of this back to the shin torque function with parameters
		var walk_angle = Globals.RAGDOLL_WALK_ANGLE / 3
		var l_shin_target_angle = l_thigh.global_rotation_degrees + (-walk_angle if l_thigh.global_rotation_degrees > 0 else walk_angle)
		var r_shin_target_angle = r_thigh.global_rotation_degrees + (walk_angle if r_thigh.global_rotation_degrees < 0 else -walk_angle)
		angular_limit_torque(l_shin, l_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 2)
		angular_limit_torque(r_shin, r_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 2)
		#make_ragdoll_shin_upright()
		return
	
	walk(direction)
	# Same with the make_ragdoll_shin_upright, but with different parameters
	# Reduce shin torque by one third to be more flexible following the thigh that is moving quickly
	#var walk_angle = Globals.RAGDOLL_WALK_ANGLE / 3
	#var l_shin_target_angle = l_thigh.global_rotation_degrees + (-walk_angle if l_thigh.global_rotation_degrees > 0 else walk_angle)
	#var r_shin_target_angle = r_thigh.global_rotation_degrees + (walk_angle if r_thigh.global_rotation_degrees < 0 else -walk_angle)
	#angular_limit_torque(l_shin, l_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 1)
	#angular_limit_torque(r_shin, r_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 1)
	#make_ragdoll_thigh_seperated()
	
	var walk_angle = Globals.RAGDOLL_WALK_ANGLE / 3
	var l_shin_target_angle = l_thigh.global_rotation_degrees# + (-walk_angle if l_thigh.global_rotation_degrees > 0 else walk_angle)
	var r_shin_target_angle = r_thigh.global_rotation_degrees# + (walk_angle if r_thigh.global_rotation_degrees < 0 else -walk_angle)
	l_shin_target_angle = 0.0
	r_shin_target_angle = 0.0
	angular_limit_torque(l_shin, l_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 4)
	angular_limit_torque(r_shin, r_shin_target_angle, Globals.RAGDOLL_TORQUE_FORCE * 4)
	#make_ragdoll_thigh_seperated()

## Walk animation by swinging the legs back and forth based on a sine function oscillation
## Direction can be scaled based on the on_air_multiplier multiplier which limit how it can walk while being on air??
func walk(direction: Vector2):
	var walk_power : float
	var multiplier : int = (100 * on_air_multiplier) if (on_air_multiplier < 1) else 5
	
	walking_tick += 1
	#if walking_tick % (Globals.TPS / 2)!= 0: 
	#	return
	walk_power = sin(((walking_tick * 2 / (Globals.TPS + 0.0)) * PI))
	walk_power *= 1
	print("rag/walk l ", (Globals.RAGDOLL_WALK_ANGLE) * -walk_power)
	print("rag/walk r ", (Globals.RAGDOLL_WALK_ANGLE) * walk_power)
	
	
	#walk_power = 1
	angular_limit_torque(l_thigh, stomach.global_rotation_degrees + (Globals.RAGDOLL_WALK_ANGLE) * walk_power, Globals.RAGDOLL_TORQUE_FORCE * multiplier)
	angular_limit_torque(r_thigh, stomach.global_rotation_degrees + (Globals.RAGDOLL_WALK_ANGLE) * -walk_power, Globals.RAGDOLL_TORQUE_FORCE * multiplier)
	
	var left_thigh : RigidBody2D
	var right_thigh : RigidBody2D
	
	if l_thigh.rotation_degrees > r_thigh.rotation_degrees:
		left_thigh = l_thigh
		right_thigh = r_thigh
	else:
		left_thigh = r_thigh
		right_thigh = l_thigh
	
	if direction.x < 0:
		# moving left 
		pass
		#angular_limit_torque(right_thigh, stomach.global_rotation_degrees + (Globals.RAGDOLL_WALK_ANGLE), Globals.RAGDOLL_TORQUE_FORCE * multiplier * walk_power)
		#angular_limit_torque(left_thigh, stomach.global_rotation_degrees - (Globals.RAGDOLL_WALK_ANGLE), Globals.RAGDOLL_TORQUE_FORCE * multiplier * walk_power)
	
	if direction.x > 0:
		# moving right
		pass
		#angular_limit_torque(right_thigh, stomach.global_rotation_degrees - (Globals.RAGDOLL_WALK_ANGLE), Globals.RAGDOLL_TORQUE_FORCE * multiplier * walk_power)
		#angular_limit_torque(left_thigh, stomach.global_rotation_degrees + (Globals.RAGDOLL_WALK_ANGLE), Globals.RAGDOLL_TORQUE_FORCE * multiplier * walk_power)


## Function to check if the ragdoll shins is airborne, since these limbs are what dictate the air state of the ragdoll
func tick_check_on_air():
	is_on_air = true
	# When airborne (falling) the movement is slower and limited
	on_air_multiplier = 0.1
	# Checking both the legs touch the map
	tick_check_airborne_one_shin(l_shin)
	tick_check_airborne_one_shin(r_shin)
	
	# If the player has recently jumped, this will override the airborne code and instead reset the variable
	#if recently_jumped:
		## Overide the recently_touched_ground code until the player is fully on air
		#if is_on_air:
			#recently_jumped = false
			#recently_touched_ground = 0
		#return
	
	if not is_on_air:
		# If touching the ground then set on_air multiplier back to normal
		on_air_multiplier = 1.0
		recently_touched_ground = 60
	if recently_touched_ground > 0:
		recently_touched_ground = recently_touched_ground - 1
	#print("rag/air multi ", on_air_multiplier)

func tick_check_airborne_one_shin(shin: RigidBody2D):
	for body in shin.get_colliding_bodies():
		if body is TileMapLayer:
			is_on_air = false
			return

## Check if the current jump stack is active, if yes it will continue to jump upward for next ticks.
func tick_jump_stack():
	if jump_stacking > 0 and is_alive:
		jump_stacking -= 1
		jump_entire_ragdoll_impulse(locked_jumping_direction, Globals.RAGDOLL_JUMP_FORCE)
		#recently_jumped = true

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
	for child in ordered_limbs:
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
	for child in ordered_limbs:
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
							damages.append(a.get_damage())
						if a is Projectile4:
							freeze_ragdoll(Globals.TPS / 2)
							damages.append(a.get_damage())
						if (a is Projectile10 or a is Projectile11) and teleport_cooldown == 0:
							print("rag/tping touch portal")
							teleport_cooldown = Globals.TPS / 2
							#teleport_entire_ragdoll_impulse(Vector2(0, -100))
							teleport_entire_ragdoll_impulse(a.get_other_portal_displacement())
							damages.append(a.get_damage())
						if a is Projectile14:
							damages.append(a.get_damage())
								
					# Kill immediately if the player touch the instant kill zone
				if a.get_collision_layer_value(4) == true:
					player.player_hp = 0

## Check collision with tiles in the tilemap, work once each tick for each limb
func tick_check_tile_map_layer_collisions():
	# Another nested nightmare, cant really refactor other than split to multiple functions so I will leave it like this
	for child in ordered_limbs:
		# Getting state of the limbs from the Physics Server, for reading the collision data
		var state : PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(child.get_rid())
		# The limbs can collide with several objects, this loop is for looping for each individual one
		if state == null:
			return
		for i in state.get_contact_count():
			# Get the rid and object id of the colliding object
			var collider_rid : RID = state.get_contact_collider(i)
			var collider_object_id := PhysicsServer2D.body_get_object_instance_id(collider_rid)
			
			# After getting the ID, we will generate a similiar instance of the collision object
			var collider = instance_from_id(collider_object_id)
			# If it turns out to be the exact instance as the game map, it imply that the colliding object is the map tile
			if collider == SystemManager.active_world.get_map_tile_map():
				# Get contact position to the map tile
				var colliding_position = state.get_contact_collider_position(i)
				var local_pos: Vector2 = SystemManager.active_world.get_map_tile_map().to_local(colliding_position)
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

## Internal helper function to recursively check if a node has the damageable composition
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

## Jump if the direction is not zero.
func jump(direction: Vector2):
	if recently_touched_ground > 0 and direction != Vector2.ZERO and is_alive:
		print("rag/jump! ")
		#teleport_entire_ragdoll_impulse(Vector2(0.0, -1000.0))
		#return
		# Lock the jump direction to the same thing so the tick_jump_stack function will jump same
		locked_jumping_direction = direction
		#recently_jumped = true
		recently_touched_ground = 0
		jump_stacking = Globals.JUMP_HEIGHT

## Animation called once when the ragdoll dies, will remove all pinjoints and stop physics
func dying_animation():
	if is_alive:
		print("player/dying")
		for child in ordered_joints:
			child.free()
		for child in ordered_limbs:
			child.apply_central_impulse(Vector2.from_angle(randf() * TAU).normalized() * 500)
	is_alive = false

## An internal method to replace the broken pinjoint2d's angular limit in the current Godot versions
## This will calculate angle displacement of the body from the target angle and apply a torque that scale based on that
## Also there will be angle limit (default: 5 degrees) to ignore torque in this angle range to make it less chaotic at micro state
## Target angle is in degree, force is a multiplier, if the displacement is less than limit then the function call is discarded
func angular_limit_torque(body: RigidBody2D, target_angle: float, force: float, angle_limit: float = 5.0):
	var angle_displacement : float = body.global_rotation_degrees - target_angle
	angle_displacement = wrapf(angle_displacement, -180, 180)
	if abs(angle_displacement) < angle_limit:
		#print("alt/ignoring small disp")
		return
	
	var torque : float = force * -angle_displacement
	body.apply_torque_impulse(torque)
