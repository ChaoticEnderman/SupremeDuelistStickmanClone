extends Node2D

@onready var player_list : Array[Player] = []
@onready var projectile_list : Array[Projectile] = []

var temptick : int = 0

func _ready() -> void:
	var player1 : Player = load("res://scenes/player.tscn").instantiate()
	var player2 : Player = load("res://scenes/player.tscn").instantiate()
	player1.position = Vector2(200.0, 200.0)
	player2.position = Vector2(1080.0, 100.0)
	player_list.append(player1)
	player_list.append(player2)
	add_child(player1)
	add_child(player2)
	player1.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_LEFT)
	player2.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_RIGHT)


func _physics_process(delta: float) -> void:
	tick_players()
	tick_projectiles()
	temptick = temptick + 1
	if temptick % 10 == 0:
		var projectile_scene = load("res://scenes/projectile.tscn").instantiate()
		projectile_list.append(projectile_scene)
		add_child(projectile_scene)
		projectile_scene.setup(player_list.front(), load("res://resources/projectile1.tres"))
		

func tick_players():
	for player in player_list:
		player.tick_player()

func tick_projectiles():
	for projectile in projectile_list:
		if projectile.to_kill:
			projectile_list.erase(projectile)
			remove_child(projectile)
			projectile.free()
		else:
			projectile.tick()
