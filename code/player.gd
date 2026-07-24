## A node for controlling everything regard to a player in the game
## Contain a ragdoll, one input manager which is a joystick or other types of input such as controllers or keyboard
## Also contain specific HUD elements tied to that player such as hp bar and jump bar
extends Node2D
class_name Player

## The physical body of this player
@onready var ragdoll : Ragdoll2 = get_node("RagdollPhysicsManager")
## HUD jump bar
@onready var jump_bar : ProgressBar = get_node("JumpBar")
## HUD health bar
@onready var health_bar : ProgressBar = get_node("HealthBar")
## HUD score label to display numerical score
@onready var score_label : Label = get_node("ScoreLabel")
## Stylebox element to override hp bar color
@onready var health_bar_color : StyleBoxFlat = health_bar.get_theme_stylebox("fill").duplicate()

## Input manager scene that handle all types of input
var input_manager : Joystick

## The single weapon that this stickman hold, since each stickman have exactly one weapon holding
var weapon : Weapon

# Position and direction
var player_position : Vector2 = Vector2.ZERO
var player_movement_direction : Vector2 = Vector2.ZERO
var player_weapon_direction : Vector2 = Vector2.ZERO
var player_jumping_direction : Vector2 = Vector2.ZERO

## Position of the hand, the starting point for melee weapons and projectiles
var hand_position : Vector2 = Vector2.ZERO

## The hp
var player_hp : float = Globals.STARTING_HP

## Score of the player, will be carried over rounds of the same session
var score : int = 0

## Will change when the player is dead (when their hp is zero)
var is_dead : bool = false

var player_side : PlayerSpriteGlobals.PLAYER

func initialize(is_real_player: bool, joystick_position: Globals.JOYSTICK_POSITION, weapon: Weapon, player_side: PlayerSpriteGlobals.PLAYER):
	# Not connecting now since like the world need to dictate the order of these, see world for info
	#GameState.game_tick.connect(_on_game_tick)
	self.weapon = weapon
	player_hp = 100.0
	is_dead = false
	# Real player variable is reserved for bots long ago, but seems like this will probably never be added
	# This will just be like an artifact of the early stages of development where its kinda unclear
	if is_real_player:
		input_manager = load("res://scenes/joystick.tscn").instantiate()
		add_child(input_manager)
		input_manager.set_joystick_corner(joystick_position)
		joy_stick_visibility(false)
	self.player_side = player_side
	# Create a custom stylebox for changing the hp bar color and override the fill stylebox
	health_bar.add_theme_stylebox_override("fill", health_bar_color)
	
	# Make the player not touch the hitbox
	ragdoll.ragdoll_collision_exception(weapon.hitbox)
	
	# Add the color to the player
	ragdoll.head.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.HEAD, player_side)
	ragdoll.torso.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.TORSO, player_side)
	ragdoll.stomach.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.STOMACH, player_side)
	ragdoll.l_thigh.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_THIGH, player_side)
	ragdoll.l_shin.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_SHIN, player_side)
	ragdoll.r_thigh.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.R_THIGH, player_side)
	ragdoll.r_shin.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.R_SHIN, player_side)
	ragdoll.p_arm.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_ARM, player_side)
	ragdoll.p_forearm.get_node("Sprite2D").modulate = PlayerSpriteGlobals.get_limb(PlayerSpriteGlobals.LIMB_INDEX.L_FOREARM, player_side)
	
	ragdoll.set_hat(PlayerSpriteGlobals.get_hat(player_side))
	
	# TODO: change this to account for for active world also
	input_manager.visible = not Globals.KEYBOARD_INPUT_ENABLED
	
	Globals.setting_reloaded.connect(func():
		print("player/change setting")
		if Globals.KEYBOARD_INPUT_ENABLED:
			input_manager.visible = false
		else:
			input_manager.visible = true
	)

## Freeze the player physics
func freeze(is_freezing: bool):
	for body in get_node("RagdollPhysicsManager").get_children():
		if body is RigidBody2D:
			body.freeze = is_freezing

## Serialize player data for online games to send over a network.
## This will serialize player data from server to client to read
func serialize_data(is_player1: bool) -> PackedFloat32Array:
	var data : PackedFloat32Array
	data.append(SystemManager.PACKET_TYPE.PLAYER_DATA)
	
	if player_side == PlayerSpriteGlobal.PLAYER.LEFT:
		data.append(0.0)
	elif player_side == PlayerSpriteGlobal.PLAYER.RIGHT:
		data.append(1.0)
		
	# data 2th element next
	data.append(self.position.x)
	data.append(self.position.y)
	data.append(player_hp)
	data.append(self.hand_position.x)
	data.append(self.hand_position.y)
	data.append(score)
	data.append(float(self.weapon.weapon_id))
	# data 9th element next
	for child in ragdoll.ordered_limbs:
		data.append(child.position.x)
		data.append(child.position.y)
		data.append(child.rotation)
		data.append(child.linear_velocity.x)
		data.append(child.linear_velocity.y)
		data.append(child.angular_velocity)
		# 9 * 6 = 54
	# data 63th element next
	for child in ragdoll.ordered_joints:
		if child != null:
			data.append(child.position.x)
			data.append(child.position.y)
		else:
			data.append(0.0)
			data.append(0.0)
		# 5 * 2 = 10
	# data 73th element next
	data.append(float(weapon.cooldown))
	data.append(weapon.hitbox.scale.x)
	data.append(weapon.hitbox.scale.y)
	data.append(weapon.sprite.scale.x)
	data.append(weapon.sprite.scale.y)
	return data

## Deserialize data from server to match the client data from the server for player data
## Run once per tick to replace the game tick
func deserialize_data(data: PackedFloat32Array) -> bool:
	if int(data.get(0)) != SystemManager.PACKET_TYPE.PLAYER_DATA:
		return false
	if data.get(1) == 1.0 and player_side == PlayerSpriteGlobal.PLAYER.LEFT:
		return false
	if data.get(1) == 0.0 and player_side == PlayerSpriteGlobal.PLAYER.RIGHT:
		return false
	
	var i : int = 2
	self.position.x = data.get(i)
	self.position.y = data.get(i + 1)
	self.player_hp = data.get(i + 2)
	self.hand_position.x = data.get(i + 3)
	self.hand_position.y = data.get(i + 4)
	self.score = data.get(i + 5)
	
	# will change the weapon once if the weapon is different from the one on the server
	# TODO: will change this to an intermediate layer of lobby when connecting
	if str(int(data.get(i + 6))) != self.weapon.weapon_id:
		self.weapon.qfree()
		var weapon : Weapon = WeaponGlobals.get_weapon(int(data.get(i + 6)))
		weapon.init(self, "")
		self.weapon = weapon
		SystemManager.active_world.add_child(weapon)
		# Make the player not touch the hitbox
		ragdoll.ragdoll_collision_exception(weapon.hitbox)
	
	i = 9
	for child in ragdoll.ordered_limbs:
		child.position.x = data.get(i)
		child.position.y = data.get(i + 1)
		child.rotation = data.get(i + 2)
		child.linear_velocity.x = data.get(i + 3)
		child.linear_velocity.y = data.get(i + 4)
		child.angular_velocity = data.get(i + 5)
		i += 6
	i = 63
	for child in ragdoll.ordered_joints:
		child.position.x = data.get(i)
		child.position.y = data.get(i + 1)
		i += 2
	i = 73
	weapon.cooldown = int(data.get(i))
	weapon.hitbox.scale.x = data.get(i + 1)
	weapon.hitbox.scale.y = data.get(i + 2)
	weapon.sprite.scale.x = data.get(i + 3)
	weapon.sprite.scale.y = data.get(i + 4)
	return true

## Player side serialize input to send over the network to server
func serialize_input() -> PackedFloat32Array:
	var data : PackedFloat32Array
	var input_result : Vector2 = input_manager.tick_input()
	player_movement_direction = input_result
	player_weapon_direction = input_manager.tick_input_is_releasing()
	player_jumping_direction = input_manager.tick_input_is_jumping()
	
	if player_side == PlayerSpriteGlobal.PLAYER.RIGHT and SystemManager.active_world.is_player1():
		data.append(SystemManager.PACKET_TYPE.NULL)
	if player_side == PlayerSpriteGlobal.PLAYER.LEFT and not SystemManager.active_world.is_player1():
		data.append(SystemManager.PACKET_TYPE.NULL)
	data.append(float(SystemManager.PACKET_TYPE.PLAYER_INPUT))
	
	# following convention of serializing data, this is empty and server will use it to store the remote sender id
	# this is to prevent cheating, as the player can't send the state of whether they are left or right player
	# but instead the player will read that from the remote sender id
	data.append(0.0)
	
	data.append(player_movement_direction.x)
	data.append(player_movement_direction.y)
	data.append(player_weapon_direction.x)
	data.append(player_weapon_direction.y)
	data.append(player_jumping_direction.x)
	data.append(player_jumping_direction.y)
	
	return data

## For the player instance in the server, will receive this and use as input
func deserialize_input(data: PackedFloat32Array) -> bool:
	if data.get(0) != float(SystemManager.PACKET_TYPE.PLAYER_INPUT):
		return false
	
	# assume this is already written with data of remote sender id when the packet is received
	# only allow each packet with the sender to affect one player in the game
	if data.get(1) == 1.0:
		if self.player_side == PlayerSpriteGlobal.PLAYER.RIGHT:
			return false
	if data.get(1) == 2.0:
		if self.player_side == PlayerSpriteGlobal.PLAYER.LEFT:
			return false
	
	
	var i : int = 2
	player_movement_direction.x = data.get(i)
	player_movement_direction.y = data.get(i + 1)
	player_weapon_direction.x = data.get(i + 2)
	player_weapon_direction.y = data.get(i + 3)
	player_jumping_direction.x = data.get(i + 4)
	player_jumping_direction.y = data.get(i + 5)
	i = 8
	return true

## Change visibility of joystick
func joy_stick_visibility(is_visible: bool):
	input_manager.visible = is_visible

# Master tick function to tick the player and its dependencies
func _on_game_tick():
	if SystemManager.active_world.world_type == World.WORLD_TYPE.OFFLINE:
		# Get input for this tick from input manager and store locally
		player_movement_direction = input_manager.tick_input()
		player_weapon_direction = input_manager.tick_input_is_releasing()
		player_jumping_direction = input_manager.tick_input_is_jumping()
	elif SystemManager.active_world.world_type == World.WORLD_TYPE.CLIENT:
		SystemManager.buffer_packet_client_sender.append(serialize_input())
		
		tick_weapon_hud()
	elif SystemManager.active_world.world_type == World.WORLD_TYPE.SERVER:
		# loop through all packets in the buffer and resolve any packet that is input packet
		if SystemManager.buffer_packet_server_receiver.size() > 0:
			for i in range(SystemManager.buffer_packet_server_receiver.size() - 1, -1, -1):
				if deserialize_input(SystemManager.buffer_packet_server_receiver.get(i)):
					SystemManager.buffer_packet_server_receiver.remove_at(i)
	
	if SystemManager.active_world.world_type == World.WORLD_TYPE.OFFLINE or SystemManager.active_world.world_type == World.WORLD_TYPE.SERVER:
		# Ticking ragdoll, that function will tick other ragdoll functions
		ragdoll.tick_ragdoll(player_movement_direction)
		
		# Check for abilities being used
		weapon.tick_release_ability(player_weapon_direction)
		
		# Check the last jump input before ticking ragdoll
		ragdoll.jump(player_jumping_direction)
		
		# Check for hitbox collision to damages
		check_collision()
		
		# Change cooldown for the weapon
		weapon.tick_cooldown()
		
		# Update the position
		if self.player_side == PlayerSpriteGlobals.PLAYER.LEFT:
			SystemManager.active_world.p1_position = self.ragdoll.torso.global_position
		elif self.player_side == PlayerSpriteGlobals.PLAYER.RIGHT:
			SystemManager.active_world.p2_position = self.ragdoll.torso.global_position
		
		tick_weapon_hud()
	

func _process(delta: float) -> void:
	tick_hud()

## Several simple update functions to update the huds, will work independently on physics tick
## Including at the game state of lazy loading
func tick_hud():
	update_jump_bar()
	update_health_bar()
	update_score_label()
	hand_position = ragdoll.get_arm_position()
	if SystemManager.active_world.world_type == SystemManager.active_world.WORLD_TYPE.CLIENT:
		if player_side == PlayerSpriteGlobal.PLAYER.RIGHT and SystemManager.active_world.is_player1():
			joy_stick_visibility(false)
		if player_side == PlayerSpriteGlobal.PLAYER.LEFT and not SystemManager.active_world.is_player1():
			joy_stick_visibility(false)

## Update the value and the visibility status of the jump bar according to the jump time
func update_jump_bar():
	# Reset jump when the radgoll just jumped and is airborne
	if ragdoll.recently_touched_ground == 0:
		jump_bar.value = 0
		input_manager.jumping_time = 0 
	# Otherwise, update the jump bar by the jumping percentage
	else:
		jump_bar.value = input_manager.jumping_time
	
	jump_bar.max_value = Globals.JUMP_TIME
	jump_bar.set_position(ragdoll.head.position + Vector2(-30.0, -40.0)) # Offsetting the bar so it will be on top of the player head
	
	if input_manager.jumping_time > 0:
		jump_bar.visible = true
	else:
		jump_bar.visible = false

## Update health bar to the current hp value
func update_health_bar():
	health_bar.value = player_hp
	health_bar.set_position(ragdoll.head.position + Vector2(-30.0, -30.0))
	# To create a gradient for the hp bar. Note that the values range from 0 to 1
	# Also change the color space to srgb to display, the value seems like linear idk
	health_bar_color.bg_color = Color(((100 - health_bar.value) / 100), (health_bar.value / 100), 0).linear_to_srgb()
	
	if player_hp <= 0.0:
		ragdoll.dying_animation()
		self.is_dead = true

## Update score label to follow the player and change according to the rounds score
func update_score_label():
	score_label.text = str(score)
	score_label.scale = Vector2(2.0, 2.0)
	score_label.set_position(ragdoll.head.position + Vector2(-20.0, -60.0))

## Call the tick function from the weapon
func tick_weapon_hud():
	if ragdoll.is_alive:
		weapon.position = hand_position
		weapon.tick_rotation(Vector2.from_angle(ragdoll.p_forearm.rotation + PI/2))
		weapon.change_cooldown_sprite()

## Check for player collision with anything that can do damage
func check_collision():
	ragdoll.tick_check_collisions()
	if not (ragdoll.damages == null or ragdoll.damages == []):
		for damage in ragdoll.damages:
			player_hp -= damage * Globals.DAMAGE_MULTIPLIER

func qfree():
	weapon.qfree()
	input_manager.queue_free()
	queue_free()

func is_dead_check() -> bool:
	return is_dead
