## Wisp projectile object of the scythe weapon
extends GameArea
class_name Projectile2

## Owner weapon of the projectile to fly back to
var weapon : Weapon
## Time for the wisp to fly in the straight direction before moving back
var timer : int

func _init(player: Player, direction: Vector2, position: Vector2):
	GameState.game_tick.connect(_on_game_tick)
	super._init(player, direction, position)
	super.add_projectile_data(load("res://resources/projectile2.tres"))
	super.add_collision_shape(projectile_data.hitbox)
	SystemManager.world.add_child(self)
	super.summon_as_projectile(direction, position)

func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)
	timer = 0

func _on_game_tick(delta: float):
	# If the player is deleted then skip frame
	if get_dependent_player() == null:
		queue_free()
		return
	timer += 1
	# For the first 2 seconds, it will fly straight to the direction of the weapon
	if timer < 120:
		self.position = self.position + (self.direction * projectile_data.speed)
	else:
		var position_difference : Vector2 = self.position.direction_to(get_dependent_player().weapon.position)
		# Moving back to weapon at increasing speed
		self.position = self.position + (position_difference * projectile_data.speed)
		# Slowly incrementing speed to ensure it will touch the owner weapon
		# Still go for normal speed for 2 seconds first
		# HACK: Hardcode this instead of checking for collision since its not consistent, but this works good enough
		if position.distance_to(get_dependent_player().weapon.position) < 20:
			qfree()

func qfree():
	super.qfree()
	self.queue_free()
