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

## The world object that this server is running
var server_world : World
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
## Null will be used for the packets that is discarded
enum PACKET_TYPE {
	NULL = -1,
	PLAYER_INPUT = 1,
	PLAYER_DATA = 2,
	CAMERA = 3,
	GAME_OBJECT = 4,
	GAME_AREA = 5,
	GAME_BULK= 6,
}


## Map editor menu
var map_editor : Control = load("res://scenes/map_editor.tscn").instantiate()

## Active map of the current world
#var game_map : Map
## Active tile map of the current world, retrieved from the map object
#var game_map_tile_map : TileMapLayer

## Storing the state of the current client whether its a server or not
var is_server : bool
## The current multiplayer peer
var peer : MultiplayerPeer
## Store error states for http requests
var err : Error
## Http client for sending matchmaking menu to MM server and back to client
var http : HTTPClient

## Store the ids and matchmaking data on the client after checking for servers
var server_data : PackedStringArray

## To send the server http POST for updating server data each second
var server_tick_update : int

func _init() -> void:
	# HACK: not a very good way to decide what is the server and what is the client
	is_server = MultiplayerGlobal.SERVER_ADDRESS in IP.get_local_addresses()

func _ready():
	print("sysman/CODE VERSION 9") # random misc and might be removed 
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
	
	http_connect_host()
	
	if is_server:
		create_server()
		
		
		server_resolve_cmdline_args(Array(OS.get_cmdline_args()))
		server_http_post()
		

## Resolve commandline arguments from the server
func server_resolve_cmdline_args(args: PackedStringArray):
	#args = ["-s", "-p=56000", "-r=AS"]
	if args.has("-s"): # this denote the script is a server instance
		print()
		print("sysman/args list is ", args)
		for a in args:
			if a.contains("="):
				# string array with two element store the kay and value of each arguments
				var key_value = a.trim_prefix("-").split("=")
				if key_value[0] == "p":
					MultiplayerGlobal.server_port = key_value[1]
				if key_value[0] == "r":
					MultiplayerGlobal.server_region = key_value[1]

func http_connect_host():
	http = HTTPClient.new()
	print("sysman/connecting to host")
	err = http.connect_to_host(MultiplayerGlobal.MM_URL, MultiplayerGlobal.MM_PORT)
	assert(err == OK)
	
	var poll : int = 0
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		poll += 1
		print("sysman/poll")
	print("sysman/http polling ", str(poll), " status ", http.get_status())
			
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)

## Run when server initialize, send a POST request
func server_http_post():
	http.poll()
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		http_connect_host()
	
	var data : Dictionary = {
		"port": MultiplayerGlobal.server_port,
		"region": MultiplayerGlobal.server_region,
		"count": 0,
	}
	if server_world.online_player2_id != "":
		data["count"] = 2
	elif server_world.online_player1_id != "":
		data["count"] = 1
	var query_str = http.query_string_from_dict(data)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_str.length())]
	err = http.request(HTTPClient.METHOD_POST, "/server", headers, query_str)
	assert(err == OK)
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
	print("sysman/http sent done ", data)

## Client send this callback to get a list of game servers that they can join
func client_http_get():
	http.poll()
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		http_connect_host()
	
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str("".length())]
	err = http.request(http.METHOD_GET, "/connect", headers)
	assert(err == OK)
	
	var poll : int = 0
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		poll += 1
	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED)
	#print("sysman/done sending request")
	
	if http.has_response():
		#print("sysman/has response")
		var response_buffer : PackedByteArray
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			var chunk = http.read_response_body_chunk()
			if chunk.size() == 0:
				await get_tree().process_frame
			else:
				response_buffer.append_array(chunk)
		var response : String = response_buffer.get_string_from_utf8()
		server_data = response.split(",")
		server_data.remove_at(server_data.size() - 1)
		print("sysman/response is ", response, " ", server_data)

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

## Connect to the server on a specific port
func connect_server(port: int) -> bool:
	multiplayer.multiplayer_peer.close()
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	var error = peer.create_client(MultiplayerGlobal.SERVER_ADDRESS, port)
	if error:
		print("sysman/client menu error ", error)
		return false
	multiplayer.multiplayer_peer = peer
	return true

## Create a listening server at the start
func create_server() -> bool:
	multiplayer.multiplayer_peer.close()
	var peer : MultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(MultiplayerGlobal.server_port, 2)
	if error:
		print("sysman/server menu error ", error)
		return false
	multiplayer.multiplayer_peer = peer
	join_online_world_rpc()
	return true

## For server to create an online game world if two player connected
func create_game() -> String:
	online_world = load("res://world.tscn").instantiate()
	online_world.world_id = str(ResourceUID.create_id())
	online_world.world_type = World.WORLD_TYPE.SERVER
	server_world = online_world
	return online_world.world_id

func player_name_changed(name: String):
	player_name_changed_rpc.rpc(name)

@rpc("any_peer", "call_remote", "reliable")
func player_name_changed_rpc(name: String):
	if multiplayer.is_server():
		server_players[multiplayer.get_remote_sender_id()] = name

## Client send this to request joining the server
@rpc("any_peer", "call_remote", "reliable")
func join_online_world_rpc():
	if multiplayer.is_server():
		if server_world.online_player1_id == "":
			server_world.online_player1_id = str(multiplayer.get_remote_sender_id())
		elif server_world.online_player2_id == "":
			server_world.online_player2_id = str(multiplayer.get_remote_sender_id())
		else:
			join_online_world_ack_rpc.rpc(JOIN_ONLINE_WORLD_ERROR.FULL)
			return
		print("sysman/server with players ", server_world.online_player1_id, " - ", server_world.online_player2_id)
		if server_world.online_player1_id != "" and server_world.online_player2_id != "":
			active_world = server_world
			active_world.world_type = World.WORLD_TYPE.SERVER
			active_world.game_state = GameState.GAME_STATE.RUNNING
			GameState.change_system_state(GameState.SYSTEM_STATE.ONLINE)
			add_child(active_world)
		
			join_online_world_ack_rpc.rpc(JOIN_ONLINE_WORLD_ERROR.OK)

## To send back acknowledge if the player can join the world or not
@rpc("authority", "call_remote", "reliable")
func join_online_world_ack_rpc(error: JOIN_ONLINE_WORLD_ERROR):
	if error == JOIN_ONLINE_WORLD_ERROR.OK:
		# Load a local world on the player side
		active_world = load("res://world.tscn").instantiate()
		active_world.world_type = World.WORLD_TYPE.CLIENT
		active_world.game_state = GameState.GAME_STATE.RUNNING
		GameState.change_system_state(GameState.SYSTEM_STATE.ONLINE)
		add_child(active_world)
		print("sysman/world ok, creating local world ", active_world, " ", active_world.game_state == GameState.GAME_STATE.RUNNING)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_client_packet_rpc(packet: PackedFloat32Array):
	# simulate 200ms ping
	await get_tree().create_timer(0.2)
	if multiplayer.is_server():
		if packet.get(0) == PACKET_TYPE.PLAYER_INPUT:
			var new_packet : PackedFloat32Array = packet.duplicate()
			if str(multiplayer.get_remote_sender_id()) == active_world.online_player1_id:
				new_packet.set(1, 1.0)
				buffer_packet_server_receiver.append(new_packet)
			elif str(multiplayer.get_remote_sender_id()) == active_world.online_player2_id:
				new_packet.set(1, 2.0)
				buffer_packet_server_receiver.append(new_packet)
			else:
				print("sysman/receiving invalid input packet")
		else:
			buffer_packet_server_receiver.append(packet)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_server_packet_rpc(id: int, packet: PackedFloat32Array):
	# simulate 200ms ping
	await get_tree().create_timer(0.2)
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
	for peer in multiplayer.get_peers():
		multiplayer.multiplayer_peer.disconnect_peer(peer)
	multiplayer.multiplayer_peer.close()
	create_server()

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
	active_world = null
	GameState.change_system_state(GameState.SYSTEM_STATE.MENU)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

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

func _physics_process(delta: float) -> void:
	server_tick_update += 1
	if server_tick_update > Globals.TPS:
		server_tick_update = 0
		server_http_post()
	# TODO: change this to a seperate thread to make it independent with game code
	#print("sysman/buffer size ", buffer_packet_client_receiver.size(), " ", buffer_packet_server_receiver.size())
	if GameState.system_state == GameState.SYSTEM_STATE.ONLINE and active_world != null:
		if not multiplayer.is_server():
			while buffer_packet_client_sender.size() != 0:
				var packet : PackedFloat32Array = buffer_packet_client_sender.pop_back()
				if int(packet.get(0)) != PACKET_TYPE.NULL and packet.size() > 1:
					send_client_packet_rpc.rpc(packet)
		elif multiplayer.is_server():
			while buffer_packet_server_sender.size() != 0:
				var packet : PackedFloat32Array = buffer_packet_server_sender.pop_back()
				#print("sysman/sending packets server ", packet.slice(0, 6))
				if int(packet.get(0)) != PACKET_TYPE.NULL:
					send_server_packet_rpc.rpc(packet)
	

func reload_button(value: int):
	if value == 1:
		client_http_get()
		#connect_lobby(matchmaking_menu)
