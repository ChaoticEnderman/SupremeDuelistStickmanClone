# Bomb projectile to launch bombs that explode based on the range
extends AbilityProjectile
class_name Ability14

func release_ability(player, direction: Vector2) -> int:
	var projectile = Projectile13.new(player, super.get_projectile_data_by_id(13), false)
	projectile.summon_as_projectile(direction, player.weapon.position)

	return WeaponGlobals.ability14_cooldown

func qfree():
	super.qfree()
	self.queue_free()
