extends Node2D

@onready var player_list : Array[Player] = []
@onready var projectile_list : Array[Projectile] = []

var temptick : int = 0

func add_projectile(projectile: Projectile):
	projectile_list.append(projectile)
	add_child(projectile)

func _ready() -> void:
	var player1 : Player = load("res://scenes/player.tscn").instantiate()
	var player2 : Player = load("res://scenes/player.tscn").instantiate()
	player1.position = Vector2(200.0, 200.0)
	player2.position = Vector2(1080.0, 100.0)
	player_list.append(player1)
	player_list.append(player2)
	add_child(player1)
	add_child(player2)
	
	var weapon1 : Weapon1 = Weapon1.new()
	var weapon2 : Weapon1 = Weapon1.new()
	
	weapon1.init(player1)
	weapon2.init(player2)
	add_child(weapon1)
	add_child(weapon2)
	
	player1.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_LEFT, weapon1)
	player2.initialize(true, Globals.JOYSTICK_POSITION.BOTTOM_RIGHT, weapon2)

func _physics_process(delta: float) -> void:
	tick_players()
	tick_projectiles()
	temptick = temptick + 1

func tick_players():
	for player in player_list:
		player.tick_player()

func tick_projectiles():
	projectile_list = projectile_list.filter(is_instance_valid)
	for p in projectile_list:
		if p.to_kill:
			p.free()
			remove_child(p)
		else:
			p.tick()
