## Stunning zone for the gauntlet weapon, will be really short
extends GameArea
class_name Projectile4

var tick : int

func _init(player: Player, direction: Vector2, position: Vector2):
	GameState.game_tick.connect(_on_game_tick)
	super._init(player, direction, position)
	super.add_projectile_data(load("res://resources/projectile4.tres"))
	super.add_collision_shape(projectile_data.hitbox)
	# Since the speed inside the Resource is zero, this will work just fine
	super.summon_as_projectile(direction, position)
	print("PO2 direction ", direction)


func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)
	tick = 30

func _on_game_tick(delta: float):
	# If the player is deleted then skip frame
	if get_dependent_player() == null:
		queue_free()
	else:
		tick -= 1
		if tick <= 0:
			queue_free()
