## Projectile object for the gauntlet projectile
extends Projectile
class_name Projectile3

var game_tick : int = 0

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)

func get_damage() -> float:
	print("P3/damage is ", super.get_damage())
	return super.get_damage()

## Runs each physics tick to check collision and other stuff
func _on_game_tick(delta: float):
	# Rough speed estimation, to bounce again many times in the directed direction at the start
	var estimated_speed : float = self.linear_velocity.distance_to(Vector2.ZERO)
	print("P3/speed ", estimated_speed)
	if estimated_speed < 1000:
		self.apply_central_impulse(direction * projectile_data.speed)
	
	game_tick += 1
	if game_tick > Globals.TPS * 2:
		self.queue_free()
	self.check_collision()
	
	print("P3/damage is ", super.get_damage())

func check_collision():
	pass
