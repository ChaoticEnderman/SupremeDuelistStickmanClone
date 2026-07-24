## Contain all the components of a match and is persistent
class_name World
extends Node2D

## Uniquely identify a world for online worlds
var world_id : String

# ID for online players connecting to this game
var online_player1_id : String = ""
var online_player2_id : String = ""
var online_player1_name : String = ""
var online_player2_name : String = ""

@onready var player_list : Array[Player]
@onready var player_scores : Array[int]

var player1 : Player
var player2 : Player

# Store the position of players for the camera to follow
var p1_position : Vector2
var p2_position : Vector2

var weapon1 : Weapon
var weapon2 : Weapon

@onready var next_round_button : TextureButton = get_node("UI/GameUI/NextRoundButton")
@onready var pause_menu : Control = get_node("UI/PauseMenu")
@onready var camera : Camera2D = get_node("CameraGame/Camera")

enum WORLD_TYPE {
	OFFLINE,
	CLIENT,
	SERVER
}

var world_type : WORLD_TYPE

## Store the current game state, not supposed to be modified directly
var game_state : GameState.GAME_STATE

var rng = RandomNumberGenerator.new()

## Queue for the next round to continue
var queue_game : bool = false

var delta : int

func add_projectile(projectile: Projectile):
	add_child(projectile)

func _init() -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.system_state_changed.connect(_on_system_state_changed)
	GameState.game_tick.connect(_on_game_tick)

func _ready() -> void:
	camera.enabled = true
	player_scores.resize(2)
	player_scores[0] = 0
	player_scores[1] = 0
	
	load_single_map("rebirth", get_map())
	
	clear_round()

func get_map() -> Map:
	return get_node("CameraGame/Map")

func get_map_tile_map() -> TileMapLayer:
	return get_node("CameraGame/Map").tile_map_layer

func load_single_map(path: String, map: Map):
	MapController.set_single_map_for_server(path, map)

## Reset the previous round object and values, for any round other than the first one
func clear_round():
	player_list = []
	# TODO: Recursive function for players to queue free
	if player1 != null:
		player1.qfree()
	if player2 != null:
		player2.qfree()
	# Set the round to start in the next frame, after one frame so the game objects can queue free
	queue_game = true
	
	for child in get_children():
		if child is GameArea:
			child.qfree()
		if child is GameObject:
			child.qfree()
	
	start_round()

## Start each individual round of the game, reset some values and process
func start_round() -> void:
	queue_game = false
	# Make new players each time
	player1 = load("res://scenes/player.tscn").instantiate()
	player2 = load("res://scenes/player.tscn").instantiate()
	player1.position = Vector2(-500, 0)
	player2.position = Vector2(500, 0)
	player_list.append(player1)
	player_list.append(player2)
	
	# The new players will have everything new except for the score
	player1.score = player_scores[0]
	player2.score = player_scores[1]
	
	add_child(player1)
	add_child(player2)
	
	# Choose weapon, either from globals or random
	choose_weapon()
	
	add_child(weapon1)
	add_child(weapon2)
	
	player1.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_LEFT, weapon1, PlayerSpriteGlobals.PLAYER.LEFT)
	player2.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_RIGHT, weapon2, PlayerSpriteGlobals.PLAYER.RIGHT)
	# Make the player body dont touch eachother
	for body in player2.ragdoll.get_children():
		if body is RigidBody2D:
			player1.ragdoll.ragdoll_collision_exception(body)
	
	GameState.queue_run_game()

func is_player1():
	return str(multiplayer.get_unique_id()) == online_player1_id

## Attempt to convert all the stuff in the world to serializable PackedByteArray or something else to send over a network for online game
func serialize_world_data() -> PackedFloat32Array:
	var data : PackedFloat32Array = PackedFloat32Array()
	data.append(SystemManager.PACKET_TYPE.GAME_BULK)
	var game_area_count : int = 0
	var game_object_count : int = 0

	for child in get_children():
		if child is GameArea:
			game_area_count += 1
			data.append_array(child.serialize_object_data(0))
			data.append(MultiplayerGlobal.PACKED_SPLIT_TAG)
		if child is GameObject:
			game_object_count += 1
			data.append_array(child.serialize_object_data(0))
			data.append(MultiplayerGlobal.PACKED_SPLIT_TAG)
	
	return data

## Taking the data from the server and construct the GameArea and GameObject. Will reuse current objects of the same id or create new ones if they arent there
func deserialize_world_data(data: PackedFloat32Array) -> bool:
	# a copy of the array that will slowly decay until all object is cleared (either updated or created)
	var dynamic_data : PackedFloat32Array = data.duplicate()
	if dynamic_data.size() == 0:
		return false
	if dynamic_data.get(0) != SystemManager.PACKET_TYPE.GAME_BULK:
		return false
	# remove the first data tag for the bulk of game object for next objects to read
	dynamic_data.remove_at(0)	
	var has_object : bool
	
	var count : int = 0
	for c in get_children():
		if c is GameObject:
			count += 1
			#print("world sysman/game object id ", c.multiplayer_id)
	#print("world sysman/count ", count, " packet is", data)
	
	# loop through until the entire array is clear
	while dynamic_data.size() != 0:
		has_object = false
		for child in get_children():
			if child is GameObject:
				if child.deserialize_object_data(dynamic_data):
					has_object = true
					# remove the data elements until the next packet splitter data
					while dynamic_data.get(0) != MultiplayerGlobal.PACKED_SPLIT_TAG:
						dynamic_data.remove_at(0)
					dynamic_data.remove_at(0)
			if child is GameArea:
				if child.deserialize_object_data(dynamic_data):
					has_object = true
					# remove the data elements until the next packet splitter data
					while dynamic_data.get(0) != MultiplayerGlobal.PACKED_SPLIT_TAG:
						dynamic_data.remove_at(0)
					dynamic_data.remove_at(0)
		# if this object doesnt exist on the client side, create it
		if not has_object:
			var id : int = int(dynamic_data.get(2))
			var object : GameObject
			var area : GameArea
			var player = SystemManager.active_world.player1
			
			# TODO: move this to another global class
			match id:
				1:
					object = Projectile1.new(player, null)
				2:
					area = Projectile2.new(player, Vector2.ZERO, Vector2.ZERO)
				3:
					object = Projectile3.new(player, null)
				4:
					area = Projectile4.new(player, Vector2.ZERO, Vector2.ZERO)
				5:
					object = Projectile5.new(player, null)
				6:
					object = Projectile6.new(player, null)
				7:
					object = Projectile7.new(player, null)
				8:
					object = Projectile8.new(player, null, player.weapon.abilities[0])
				9:
					object = Projectile9.new(player, null)
				10:
					area = Projectile10.new(player, Vector2.ZERO, Vector2.ZERO)
				11:
					area = Projectile11.new(player, Vector2.ZERO, Vector2.ZERO)
				12:
					object = Projectile12.new(player, null)
				13:
					object = Projectile13.new(player, null, false)
				14:
					area = Projectile14.new(player, Vector2.ZERO, Vector2.ZERO)
				15:
					object = Projectile15.new(player, null)
			if object != null:
				add_child(object)
				object.multiplayer_id = int(dynamic_data.get(1))
				object.deserialize_object_data(dynamic_data)
			if area != null:
				add_child(area)
				area.multiplayer_id = int(dynamic_data.get(1))
				area.deserialize_object_data(dynamic_data)
			
			# remove the data elements until the next packet splitter data
			while dynamic_data.get(0) != MultiplayerGlobal.PACKED_SPLIT_TAG:
				dynamic_data.remove_at(0)
			dynamic_data.remove_at(0)
			#print("world sysman/creating new object after create ", dynamic_data.size())
	return true

## Pause the game when the state is not running
func _on_game_state_changed(state):
	print("world/this world ", self, " state to ", GameState.get_beautiful_game_state(game_state))
	if game_state == GameState.GAME_STATE.RUNNING:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		get_tree().paused = false
		self.visible = true
		for player in player_list:
			player.joy_stick_visibility(true)
			player.freeze(false)
		next_round_button.visible = false
	elif game_state == GameState.GAME_STATE.PAUSING:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		get_tree().paused = true
		self.visible = true
	elif game_state == GameState.GAME_STATE.LAZY_RUNNING:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		for i in range(player_list.size()):
			player_scores[i] += 1
		if world_type == WORLD_TYPE.CLIENT or world_type == WORLD_TYPE.SERVER:
			clear_round()
	elif game_state == GameState.GAME_STATE.NONE:
		pass
		#process_mode = Node.PROCESS_MODE_DISABLED
		#self.visible = false
		#camera.enabled = false
		#for player in player_list:
			#player.joy_stick_visibility(false)
			#player.freeze(true)

func _on_system_state_changed(state):
	if state == GameState.SYSTEM_STATE.MENU:
		return

## Retrieve the weapon data from WeaponGlobals
func choose_weapon():
	weapon1 = WeaponGlobals.get_weapon(WeaponGlobals.weapon_left)
	weapon2 = WeaponGlobals.get_weapon(WeaponGlobals.weapon_right)
	if weapon1 == null:
		weapon1 = randomize_weapon()
	if weapon2 == null:
		weapon2 = randomize_weapon()
	
	# FIXME: bad code
	weapon1.init(player1, "")
	weapon2.init(player2, "")

## Randomize weapon in case the weapon is random aka null
func randomize_weapon() -> Weapon:
	var weapons = [
		Weapon1.new(),
		Weapon2.new(),
		Weapon3.new(),
		Weapon4.new(),
		Weapon5.new(),
		Weapon6.new(),
		Weapon7.new(),
		Weapon8.new(),
		Weapon9.new(),
		Weapon10.new(),
		Weapon11.new()
		]
	return weapons[rng.randi_range(0, weapons.size() - 1)]

## Main function to run every tick to control whether other tick function can run easily
func _on_game_tick(delta: float) -> void:
	if game_state == GameState.GAME_STATE.RUNNING:
		if queue_game == true:
			start_round()
		tick_players()
		if player1 != null and player2 != null:
			if world_type == WORLD_TYPE.SERVER:
				SystemManager.buffer_packet_server_sender.append(player1.serialize_data(true))
				SystemManager.buffer_packet_server_sender.append(player2.serialize_data(false))
				SystemManager.buffer_packet_server_sender.append(serialize_world_data())
			if world_type == WORLD_TYPE.CLIENT:
				if SystemManager.buffer_packet_client_receiver.size() > 0:
					for i in range(SystemManager.buffer_packet_client_receiver.size() - 1, -1, -1):
						var packet = SystemManager.buffer_packet_client_receiver.get(i)
						if packet.get(1) == 0.0:
							if player1.deserialize_data(packet):
								SystemManager.buffer_packet_client_receiver.remove_at(i)
						elif packet.get(1) == 1.0:
							if player2.deserialize_data(packet):
								SystemManager.buffer_packet_client_receiver.remove_at(i)
						if self.deserialize_world_data(packet):
							SystemManager.buffer_packet_client_receiver.remove_at(i)

## Call the tick function in each players to do their stuff
func tick_players():
	for i in range(player_list.size()):
		# HACK: Call on game tick directly to make player tick before world tick
		# Will need to establish a more formal system for order of game tick
		player_list[i]._on_game_tick()
		# If one player is dead then add the score to all other players
		if player_list[i].is_dead_check():
			GameState.change_game_state(SystemManager.active_world, GameState.GAME_STATE.LAZY_RUNNING)
			next_round_button.visible = true
			# Minus one for the players that is dead and add one to everyone
			player_scores[i] -= 1
	
