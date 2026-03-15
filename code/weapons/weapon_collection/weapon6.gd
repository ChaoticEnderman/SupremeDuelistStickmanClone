## Fifth weapon, a gauntlet with abilities for either
extends Weapon
class_name Weapon6

var passive_projectiles : Array[Projectile] = []
var passive_cooldown : int = 0

var is_rotating : bool

func init(player: Player, id: String) -> void:
	super.init(player, "6")
	
	abilities.append(Ability8.new())
	
	super.set_damage(Damageable.new(0.1, player))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)
	is_rotating = not rotation == Vector2.ZERO

func tick_cooldown():
	super.tick_cooldown()
	if passive_cooldown == 0:
		var projectile : Projectile = Projectile7.new(player, AbilityProjectile.get_projectile_data_by_id(7))
		projectile.rotation = sprite.rotation
		projectile.summon_as_projectile(
			Vector2.from_angle(sprite.rotation - PI/2), position)
		passive_cooldown = Globals.TPS
		passive_projectiles.append(projectile)
	elif is_rotating:
		passive_cooldown -= 1
	

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)

func qfree():
	super.qfree()
	self.queue_free()
