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

## The matchmaking menu, showing the online games to join
var matchmaking_menu : MatchmakingMenu = load("res://scenes/matchmaking_menu.tscn").instantiate()

# Store the arrays that is going to be flushed and sent over the network from client to server
var buffer_packet_client_sender : Array[PackedFloat32Array]
var buffer_packet_client_receiver : Array[PackedFloat32Array]
var buffer_packet_server_sender : Array[PackedFloat32Array]
var buffer_packet_server_receiver : Array[PackedFloat32Array]

## Note on packet id: For packets in float32 arrays, the first element denote the type.
enum PACKET_TYPE {
	PLAYER_INPUT = 1,
	PLAYER_DATA = 2,
	CAMERA = 3,
	GAME_STUFF = 4,
}


## Map editor menu
var map_editor : Control = load("res://scenes/map_editor.tscn").instantiate()

## Active map of the current world
#var game_map : Map
## Active tile map of the current world, retrieved from the map object
#var game_map_tile_map : TileMapLayer

## Storing the state of the current client whether its a server or not
var is_server : bool

## Stored on the client to know what server id the client is connecting to
var server_id : int

func _ready():
	is_server = Globals.SERVER_ADDRESS in IP.get_local_addresses()
	
	print("sysman/CODE VERSION 8") 
	print("sysman/what is ip ", IP.get_local_addresses())
	
	PlayerSpriteGlobals.set_default_color()
	PlayerSpriteGlobals.load_hats()
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.system_state_changed.connect(_on_system_state_changed)
	add_child(main_menu)
	add_child(ready_menu)
	add_child(map_editor)
	add_child(matchmaking_menu)
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
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
	active_world = offline_world
	
	active_world.world_type = World.WORLD_TYPE.OFFLINE
	add_child(active_world)

func connect_lobby(menu: MatchmakingMenu):
	multiplayer.multiplayer_peer.close()
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	print("sysman/client trying to connect")
	var error = peer.create_client(Globals.SERVER_ADDRESS, Globals.NETWORK_PORT)
	if error:
		print("sysman/client menu error ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("sysman/client connected done")
	player_joined.rpc()

func create_lobby(menu: MatchmakingMenu):
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(Globals.NETWORK_PORT, 16)
	if error:
		print("sysman/server menu error ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("sysman/server status ", peer.get_connection_status())

## For server to create an online game world at the start
func create_game(id: String) -> String:
	online_world = load("res://world.tscn").instantiate()
	online_world.world_id = str(ResourceUID.create_id())
	online_world.world_type = World.WORLD_TYPE.SERVER
	server_worlds.append(online_world)
	
	return id + "_" + online_world.world_id

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
	server_id = id
	active_world = null
	join_online_world_rpc.rpc(id)

@rpc("any_peer", "call_remote", "reliable")
func join_online_world_rpc(id: int):
	if multiplayer.is_server():
		if server_worlds[id].online_player1_id == "":
			server_worlds[id].online_player1_id = str(multiplayer.get_remote_sender_id())
		elif server_worlds[id].online_player2_id == "":
			server_worlds[id].online_player2_id = str(multiplayer.get_remote_sender_id())
		else:
			join_online_world_ack_rpc.rpc(JOIN_ONLINE_WORLD_ERROR.FULL)
			return
		print("sysman/server with players ", server_worlds[id].online_player1_id, " - ", server_worlds[id].online_player2_id)
		if server_worlds[id].online_player1_id != "" and server_worlds[id].online_player2_id != "":
			active_world = server_worlds[id]
			active_world.world_type = World.WORLD_TYPE.SERVER
			active_world.game_state = GameState.GAME_STATE.RUNNING
			GameState.change_system_state(GameState.SYSTEM_STATE.ONLINE)
			add_child(active_world)
		
			join_online_world_ack_rpc.rpc(JOIN_ONLINE_WORLD_ERROR.OK)

## To send back acknowledge if the player can join the world or not
@rpc("authority", "call_remote", "reliable")
func join_online_world_ack_rpc(error: JOIN_ONLINE_WORLD_ERROR):
	if error == JOIN_ONLINE_WORLD_ERROR.OK:
		active_world = load("res://world.tscn").instantiate()
		active_world.world_type = World.WORLD_TYPE.CLIENT
		active_world.game_state = GameState.GAME_STATE.RUNNING
		GameState.change_system_state(GameState.SYSTEM_STATE.ONLINE)
		add_child(active_world)
		print("sysman/world ok, creating local world ", active_world, " ", active_world.game_state == GameState.GAME_STATE.RUNNING)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_client_packet_rpc(id: int, packet: PackedFloat32Array):
	if multiplayer.is_server():
		if packet.get(0) == PACKET_TYPE.PLAYER_INPUT:
			var new_packet : PackedFloat32Array = packet.duplicate()
			if str(multiplayer.get_remote_sender_id()) == active_world.online_player1_id:
				new_packet.set(1, multiplayer.get_remote_sender_id())
				if packet.get(2) != 0.0:
					print("sysman/receiving incoming input packet from player 1 ", new_packet)
			elif str(multiplayer.get_remote_sender_id()) == active_world.online_player2_id:
				new_packet.set(1, multiplayer.get_remote_sender_id())
				if packet.get(2) != 0.0:
					print("sysman/receiving incoming input packet from player 2 ", new_packet)
			buffer_packet_server_receiver.append(new_packet)
		else:
			buffer_packet_server_receiver.append(packet)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_server_packet_rpc(id: int, packet: PackedFloat32Array):
	if not multiplayer.is_server():
		buffer_packet_client_receiver.append(packet)
		return

## Disconnect the client from the current match
func disconnect_client():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _on_player_connected(id):
	if is_server:
		print("sysman/server player connected ", id)
	else:
		print("sysman/client player connected ", id)

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
	if not multiplayer.is_server():
		if GameState.system_state == GameState.SYSTEM_STATE.ONLINE and active_world != null:
			while buffer_packet_client_sender.size() != 0:
				var packet : PackedFloat32Array = buffer_packet_client_sender.pop_back()
				#print("sysman/sending packets client ", packet.slice(0, 6))
				send_client_packet_rpc.rpc(server_id, packet)
	elif multiplayer.is_server():
		if GameState.system_state == GameState.SYSTEM_STATE.ONLINE and active_world != null:
			while buffer_packet_server_sender.size() != 0:
				var packet : PackedFloat32Array = buffer_packet_server_sender.pop_back()
				print("sysman/sending packets server ", packet.slice(0, 6))
				send_server_packet_rpc.rpc(server_id, packet)
		

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
