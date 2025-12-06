extends Node2D

@onready var player_list : Array[Player]
@onready var player_scores : PackedInt32Array
@onready var projectile_list : Array[Projectile]

var player1 : Player
var player2 : Player

var weapon1 : Weapon
var weapon2 : Weapon

@onready var next_round_button : TextureButton = get_node("GameUI/NextRoundButton")
@onready var pause_menu : Node2D = get_node("PauseMenu")

var rng = RandomNumberGenerator.new()

func add_projectile(projectile: Projectile):
	projectile_list.append(projectile)
	add_child(projectile)

func _ready() -> void:
	get_node("GameUI").process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.game_tick.connect(_game_tick)
	player_scores.resize(2)
	player_scores[0] = 0
	player_scores[1] = 0
	start_round()

## Reset the previous round object and values, for any round other than the first one
func clear_round():
	player_list = []
	player1.queue_free()
	player2.queue_free()
	weapon1.queue_free()
	weapon2.queue_free()
	projectile_list = projectile_list.filter(is_instance_valid)
	for projectile in projectile_list:
		projectile.queue_free()
	GameState.change_game_state(GameState.GAME_STATE.RUNNING)
	start_round()

## Start each individual round of the game, reset some values and process
func start_round() -> void:
	# Make new players each time
	player1 = load("res://scenes/player.tscn").instantiate()
	player2 = load("res://scenes/player.tscn").instantiate()
	player1.position = Vector2(200.0, 200.0)
	player2.position = Vector2(1080.0, 100.0)
	player_list.append(player1)
	player_list.append(player2)
	
	# The new players will have everything new except for the score
	player1.score = player_scores[0]
	player2.score = player_scores[1]
	
	add_child(player1)
	add_child(player2)
	
	# New weapon every round also, since they can be different
	weapon1 = randomize_weapon()
	weapon2 = randomize_weapon()
	weapon1.init(player1)
	weapon2.init(player2)
	add_child(weapon1)
	add_child(weapon2)
	
	player1.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_LEFT, weapon1)
	player2.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_RIGHT, weapon2)
	for body in player2.ragdoll.get_children():
		if body is RigidBody2D:
			player1.ragdoll.ragdoll_collision_exception(body)

func _on_game_state_changed(state):
	projectile_list = projectile_list.filter(is_instance_valid)
	if state == GameState.GAME_STATE.RUNNING:
		get_tree().paused = false
	elif state == GameState.GAME_STATE.PAUSING:
		get_tree().paused = true

func randomize_weapon() -> Weapon:
	var weapons = [Weapon1.new(), Weapon2.new(), Weapon3.new()]
	return weapons[rng.randi_range(0, weapons.size() - 1)]

## Main function to run every tick to control whether other tick function can run easily
func _game_tick() -> void:
	tick_players()
	tick_projectiles()

## Call the tick function in each players to do their stuff
func tick_players():
	for player in player_list:
		player.tick_player()
		# If one player is dead then add the score to all other players
		if player.is_dead: 
			GameState.change_game_state(GameState.GAME_STATE.LAZY_RUNNING)
			next_round_button.visible = true
			for i in range(player_list.size()):
				if player_list[i] != player:
					player_scores[i] += 1

## Call the tick function for all projectiles and also filter out freed ones
func tick_projectiles():
	projectile_list = projectile_list.filter(is_instance_valid)
	for p in projectile_list:
		p.tick()
