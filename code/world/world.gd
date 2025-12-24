extends Node2D

@onready var player_list : Array[Player]
@onready var player_scores : Array[int]

var player1 : Player
var player2 : Player

var weapon1 : Weapon
var weapon2 : Weapon

@onready var next_round_button : TextureButton = get_node("UI/GameUI/NextRoundButton")
@onready var pause_menu : Control = get_node("UI/PauseMenu")

var rng = RandomNumberGenerator.new()

var queue_game : bool = false

func add_projectile(projectile: Projectile):
	add_child(projectile)

func _ready() -> void:
	get_node("UI/GameUI").process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.game_state_changed.connect(_on_game_state_changed)
	GameState.system_state_changed.connect(_on_system_state_changed)
	GameState.game_tick.connect(_on_game_tick)
	player_scores.resize(2)
	player_scores[0] = 0
	player_scores[1] = 0
	
	clear_round()

## Reset the previous round object and values, for any round other than the first one
func clear_round():
	player_list = []
	# TODO: Recursive function for players to queue free
	if player1 != null:
		player1._queue_free()
	if player2 != null:
		player2._queue_free()
	if is_instance_valid(weapon1):
		weapon1._queue_free()
	if is_instance_valid(weapon2):
		weapon2._queue_free()
	start_round()

## Start each individual round of the game, reset some values and process
func start_round() -> void:
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

## Pause the game when the state is not running
func _on_game_state_changed(state):
	if state == GameState.GAME_STATE.RUNNING:
		get_tree().paused = false
	elif state == GameState.GAME_STATE.PAUSING:
		get_tree().paused = true
	elif state == GameState.GAME_STATE.LAZY_RUNNING:
		for i in range(player_list.size()):
			player_scores[i] += 1

func _on_system_state_changed(state):
	if state == GameState.SYSTEM_STATE.MENU:
		return

## Retrieve the weapon data from WeaponGlobals
func choose_weapon():
	weapon1 = WeaponGlobals.get_weapon(WeaponGlobals.weapon1)
	weapon2 = WeaponGlobals.get_weapon(WeaponGlobals.weapon2)
	if weapon1 == null:
		weapon1 = randomize_weapon()
	if weapon2 == null:
		weapon2 = randomize_weapon()
		
	weapon1.init(player1, "")
	weapon2.init(player2, "")

## Randomize weapon in case the weapon is random aka null
func randomize_weapon() -> Weapon:
	var weapons = [Weapon1.new(), Weapon2.new(), Weapon3.new()]
	return weapons[rng.randi_range(0, weapons.size() - 1)]

## Main function to run every tick to control whether other tick function can run easily
# TODO: Make these tick stuff runs from the SystemManager class tick signal and not through this 
func _on_game_tick() -> void:
	tick_players()

## Call the tick function in each players to do their stuff
func tick_players():
	for i in range(player_list.size()):
		# HACK: Call on game tick directly to make player tick before world tick
		# Will need to establish a more formal system for order of game tick
		player_list[i]._on_game_tick()
		# If one player is dead then add the score to all other players
		if player_list[i].is_dead_check():
			GameState.change_game_state(GameState.GAME_STATE.LAZY_RUNNING)
			next_round_button.visible = true
			# Minus one for the players that is dead and add one to everyone
			player_scores[i] -= 1
	
