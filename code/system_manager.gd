## The manager for the entire game, is loaded perpetually until the game close. 
## Will handle the game world, main menu, settings, ...
extends Node

enum JOIN_ONLINE_WORLD_ERROR {
	OK,
	FULL,
	ERROR,
}

## Reference to the current active world
var active_world : World

## The world of the game, containing the main action space for fighting
var offline_world : World

## World node when connecting to remote server to sync data from server to the client
var online_world : World

## List of all worlds that a server is currently maintaining
var server_worlds : Array[World]
## Mapping from current player ids to their respective names
var server_players : Dictionary = {}

## The main menu, containing the general stuff
var main_menu : Control = load("res://scenes/main_menu.tscn").instantiate()

## The ready menu, settings before the game
var ready_menu : Control = load("res://scenes/ready_menu.tscn").instantiate()

var matchmaking_menu : MatchmakingMenu = load("res://scenes/matchmaking_menu.tscn").instantiate()

var mmm_syncer : MultiplayerSynchronizer

## Map editor menu
var map_editor : Control = load("res://scenes/map_editor.tscn").instantiate()

## Active map of the current world
#var game_map : Map
## Active tile map of the current world, retrieved from the map object
#var game_map_tile_map : TileMapLayer

## Storing the state of the current client whether its a server or not
var is_server : bool

var dummy_to_sync : String = ""

## Player1 dynamic position for the camera follow
var p1_position : Vector2
## Player2 dynamic position for the camera follow
var p2_position : Vector2

func _ready():
	is_server = Globals.SERVER_ADDRESS in IP.get_local_addresses()
	
	print("sysman/CODE VERSION 6") 
	print("sysman/what is ip ", IP.get_local_addresses())
	
	PlayerSpriteGlobals.set_default_color()
	PlayerSpriteGlobals.load_hats()
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.system_state_changed.connect(_on_system_state_changed)
	add_child(main_menu)
	add_child(ready_menu)
	add_child(map_editor)
	add_child(matchmaking_menu)
	matchmaking_menu.multiplayer.peer_connected.connect(_on_player_connected)
	matchmaking_menu.multiplayer.peer_disconnected.connect(_on_player_disconnected)
	matchmaking_menu.multiplayer.connected_to_server.connect(_on_connected_ok)
	matchmaking_menu.multiplayer.connection_failed.connect(_on_connected_fail)
	matchmaking_menu.multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	mmm_syncer = matchmaking_menu.get_node(("MultiplayerSynchronizer"))
	#mmm_syncer.add_property(NodePath(".:world_ids"))
	
	if is_server:
		pass
		#create_lobby(matchmaking_menu)

func _on_game_state_changed(state):
	return

## Call functions for change of state here, when system state change
func _on_system_state_changed(state):
	if state == GameState.SYSTEM_STATE.MENU:
		back_to_main_menu()
	elif state == GameState.SYSTEM_STATE.READY:
		to_ready_menu()
	elif state == GameState.SYSTEM_STATE.MATCHMAKING:
		to_matchmaking_menu()
		#connect_lobby(matchmaking_menu)
		#if not is_server:
			#print("sysman/client, synced, worlds ", matchmaking_menu.world_ids)
	elif state == GameState.SYSTEM_STATE.GAME:
		start_offline_game()
	#elif state == GameState.SYSTEM_STATE.ONLINE:
		#connect_lobby()
	elif state == GameState.SYSTEM_STATE.MAP_EDIT:
		open_map_editor()

## Clear all the menus and stuff to only put back the menus that is needed, to go to other menus
func clear_everything():
	remove_child(main_menu)
	remove_child(ready_menu)
	remove_child(matchmaking_menu)
	remove_child(map_editor)
	remove_child(active_world)
	if active_world != null:
		active_world.queue_free()

## Start command to start the game world. Will create a new game world each time
func start_offline_game() -> void:
	clear_everything()
	offline_world = load("res://world.tscn").instantiate()
	offline_world.set_type(false)
	active_world = offline_world
	add_child(active_world)
	#switch_world(active_world)

### Function for the server to start a remote world
#func create_online_game(id: String) -> void:
	#clear_everything()
	#var world : World = load("res://world.tscn").instantiate()
	#world.set_type(false)
	##add_child(world)
	##game_map = world.get_node("CameraGame/Map")
	##game_map_tile_map = game_map.tile_map_layer
	#print("SM/creating world ", world)
	#world.world_id = id
	#server_worlds.append(world)
	#GameState.change_game_state(world, GameState.GAME_STATE.NONE)
	#
	#var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	#if peer.create_server(Globals.NETWORK_PORT, 2):
		#return
	##world.multiplayer.multiplayer_peer = peer
#
### Start several games for server
## TODO: Add dynamic creation and deletion of worlds later on
#func create_online_games() -> void:
	#clear_everything()
	#server_worlds.clear()
	#for i in range(5):
		#create_online_game(str(i))

func connect_lobby(menu: MatchmakingMenu):
	multiplayer.multiplayer_peer.close()
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Globals.SERVER_ADDRESS, Globals.NETWORK_PORT)
	if error:
		print("sysman/client menu error ", error)
		return
	multiplayer.multiplayer_peer = peer
	for i in range(10):
		player_joined.rpc()
	print("sysman/client rpc done?")

func create_lobby(menu: MatchmakingMenu):
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(Globals.NETWORK_PORT, 16)
	if error:
		print("sysman/server menu error ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("sysman/server status ", peer.get_connection_status())

## For server to create an online match
func create_game(id: String) -> String:
	online_world = load("res://world.tscn").instantiate()
	server_worlds.append(online_world)
	active_world = online_world
	
	active_world.world_id = str(ResourceUID.create_id())
	print("sysman/remote world id ", active_world.world_id)
	
	return id + "_" + active_world.world_id

@rpc("any_peer", "call_remote", "reliable")
func player_joined():
	if is_server:
		print("sysman/server receiving signal")
	else:
		print("sysman/client receiving signal")

@rpc("authority", "call_local", "reliable")
func sync_world_ids(world_ids : Array[String]):
	print("sysman/syncing world ids ", multiplayer.get_remote_sender_id())
	matchmaking_menu.world_ids = world_ids
	matchmaking_menu.add_to_container()

func player_name_changed(name: String):
	player_name_changed_rpc.rpc(name, multiplayer.get_unique_id())

@rpc("any_peer", "call_remote", "reliable")
func player_name_changed_rpc(name: String, player_id: int):
	if multiplayer.is_server():
		server_players[player_id] = name

## Client call this to join a server world
func join_online_world(id: int):
	print("sysman/about to join world")
	active_world = null
	join_online_world_rpc.rpc(id)
	await join_online_world_ack_rpc
	if active_world != null:
		# Connection success, start firing input data
		pass
	else:
		# Connection failed
		pass

@rpc("any_peer", "call_remote", "reliable")
func join_online_world_rpc(id: int):
	if multiplayer.is_server():
		if server_worlds[id].online_player1_id == "":
			server_worlds[id].online_player1_id = str(multiplayer.get_remote_sender_id())
		elif server_worlds[id].online_player2_id == "":
			server_worlds[id].online_player2_id = str(multiplayer.get_remote_sender_id())
		else:
			join_online_world_ack_rpc.rpc(JOIN_ONLINE_WORLD_ERROR.FULL)
		print("sysman/server with players ", server_worlds[id].online_player1_id, " - ", server_worlds[id].online_player2_id)
		server_worlds[id].game_state = GameState.GAME_STATE.RUNNING

## To send back acknowledge if the player can join the world or not
@rpc("authority", "call_remote", "reliable")
func join_online_world_ack_rpc(error: JOIN_ONLINE_WORLD_ERROR):
	if not multiplayer.is_server():
		if error != JOIN_ONLINE_WORLD_ERROR.OK:
			active_world = load("res://world.tscn").instantiate()

## Disconnect the client from the current match
func disconnect_client():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _on_player_connected(id):
	if is_server:
		print("sysman/server signal connected ", id)
	else:
		print("sysman/client player connected", id)

func _on_player_disconnected(id):
	if is_server:
		print("sysman/server player disconnected")
	else:
		print("sysman/client player disconnected")

func _on_connected_ok():
	if is_server:
		print("sysman/server ok")
	else:
		print("sysman/client ok")

func _on_connected_fail():
	if is_server:
		print("sysman/server fail")
	else:
		print("sysman/client fail")

func _on_server_disconnected():
	if is_server:
		print("sysman/server server disconnected")
	else:
		print("sysman/client server disconnected")

## Function to go back to the main menu, it will not be deleted each time
func back_to_main_menu():
	clear_everything()
	add_child(main_menu)

## Function to go to the ready menu before starting the game
func to_ready_menu():
	clear_everything()
	add_child(ready_menu)

## Function to go to the matchmaking menu
func to_matchmaking_menu():
	clear_everything()
	add_child(matchmaking_menu)

## Function to open the map editor
func open_map_editor(): 
	clear_everything()
	add_child(map_editor)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Test"):
		pass

func _physics_process(delta: float) -> void:
	pass

func switch_world(world: World):
	active_world = world
	print("sysman GS/switching world")
	for w in server_worlds:
		GameState.change_game_state(w, GameState.GAME_STATE.NONE)
		remove_child(w)
	GameState.change_game_state(offline_world, GameState.GAME_STATE.NONE)
	GameState.change_game_state(active_world, GameState.GAME_STATE.RUNNING)

func reload_button(value: int):
	if value == 1:
		connect_lobby(matchmaking_menu)
	elif value == 2:
		create_lobby(matchmaking_menu)
