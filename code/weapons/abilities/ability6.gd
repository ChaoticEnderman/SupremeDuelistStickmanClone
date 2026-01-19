extends AbilityProjectile
class_name Ability6

func release_ability(player, direction: Vector2) -> int:
	# The first ever weapon will release 3 bullets in a rather shotgun pattern, like sds gun
	
	var projectile = Projectile3.new(player, super.get_projectile_data_by_id(3))
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	super.release_ability(player, direction)
	return WeaponGlobals.ability1_cooldown
