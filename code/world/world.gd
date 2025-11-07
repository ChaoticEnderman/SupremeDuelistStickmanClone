extends Node2D

@onready var player_list : Array[Player] = []

func _ready() -> void:
	var player1 : Player = load("res://scenes/player.tscn").instantiate()
	var player2 : Player = load("res://scenes/player.tscn").instantiate()
	player1.position = Vector2(200.0, 200.0)
	player2.position = Vector2(1080.0, 100.0)
	player_list.append(player1)
	player_list.append(player2)
	add_child(player1)
	add_child(player2)
	player1.initialize(true, Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_BOTTOM_LEFT)
	player2.initialize(true, Globals.JOYSTICK_POSITION.JOYSTICK_POSITION_BOTTOM_RIGHT)

func _physics_process(delta: float) -> void:
	tick_players()

func tick_players():
	for player in player_list:
		player.tick_player()
