## Passive arrow projectile for crossbow and potentially bow later on
extends Projectile
class_name Projectile7

## Storing previous position of the projectile to calculate dynamic direction each time
var prev_position : Vector2

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)

func get_damage() -> float:
	return super.get_damage()

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	var direction = (self.position - prev_position).normalized()
	var rotation = Vector2.UP.angle_to(direction)
	self.rotation = rotation
	
	prev_position = self.position

func qfree():
	super.qfree()
	self.queue_free()
