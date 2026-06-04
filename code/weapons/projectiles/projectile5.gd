## Primary projectile for crossbow ability to shoot 6 bullets after a short distance
extends Projectile
class_name Projectile5

## Timer in ticks, will spread out after 1 second
var timer : int = 0

var sub_projectiles : Array[Projectile] = []

func _init(player: Player, projectile_data: ProjectileData):
	GameState.game_tick.connect(_on_game_tick)
	super._init(player, projectile_data)

func get_damage() -> float:
	return super.get_damage()

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	timer += 1
	if timer == Globals.TPS:
		spread()

## Spread out the projectiles to the 6 bullets, and does not immediately queue_free() this since it need to keep the reference and clear the sub-projectiles also 
func spread():
	for i in range(6):
		var projectile : Projectile = Projectile6.new(player, AbilityProjectile.get_projectile_data_by_id(6))
		projectile.rotation_degrees = 60 * i + 90
		# Spread the sub projectiles a bit based on direction initially
		projectile.summon_as_projectile(Vector2.from_angle(deg_to_rad(60 * i)), 
		position + Vector2.from_angle(deg_to_rad(60 * i)) * 5)
		sub_projectiles.append(projectile)
	self.sprite.texture = null
	self.freeze = true

## This is called when clearing the world tree for making a new match
func qfree():
	for p in sub_projectiles:
		if is_instance_valid(p):
			p.qfree()
	super.qfree()
	self.queue_free()
