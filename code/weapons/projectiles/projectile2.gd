### Wisp projectile object of the scythe weapon
#extends GameObject
#class_name Projectile2
#
### Owner weapon of the projectile to fly back to
#var weapon : Weapon
### Time for the wisp to fly in the straight direction before moving back
#var timer : int
#
### Increasing speed of the wisp until it touch the scythe
#var speed_multiplier : float = 1.0
#
#func _init(player: Player, direction: Vector2, position: Vector2):
	#speed_multiplier = 1.0
	#GameState.game_tick.connect(_on_game_tick)
	#super._init(player, direction, position)
	#super.add_projectile_data(load("res://resources/projectile2.tres"))
	#SystemManager.world.add_child(self)
	#print("PO2/direction ", direction)
	#super.summon_as_projectile(direction, position)
	## This is so that it can touch the weapon and be destroyed
	#remove_collision_exception_with(player.weapon)
#
#func _ready() -> void:
	#GameState.game_tick.connect(_on_game_tick)
	#timer = 0
#
#func _on_game_tick(delta: float):
	## If the player is deleted then skip frame
	#if get_dependent_player() == null:
		#queue_free()
		#return
	#timer += 1
	## for the first 2 seconds, it will fly straight to the direction of the weapon
	#if timer < 120:
		#super.apply_central_force(direction * projectile_data.speed)
	#elif timer == 120:
		#speed_multiplier = 2.0
	#else:
		#var position_difference : Vector2 = self.position.direction_to(get_dependent_player().weapon.position)
		## Moving back to weapon at 2x the speed
		#super.apply_central_force(position_difference * projectile_data.speed * speed_multiplier)
		## Slowly incrementing speed to ensure it will touch the owner weapon
		#if speed_multiplier < 5.0:
			## Still have a limit to prevent it being so fast
			#speed_multiplier += 0.1
		#print("PO2/tick collision ", get_colliding_bodies().size())
		## HACK: Hardcode this instead of checking for collision since its not consistent, but this works enough
		#if position.distance_to(get_dependent_player().weapon.position) < 50:
			#_on_destroy()

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
	print("PO2/direction ", direction)
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
		# HACK: Hardcode this instead of checking for collision since its not consistent, but this works enough
		if position.distance_to(get_dependent_player().weapon.position) < 20:
			_on_destroy()
