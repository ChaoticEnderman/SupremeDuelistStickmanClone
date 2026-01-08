## First ability for the gun weapon, shooting 3 bullets
extends AbilityProjectile
class_name Ability1

func release_ability(player, direction: Vector2) -> int:
	# The first ever weapon will release 3 bullets in a rather shotgun pattern, like sds gun
	
	var projectile_a = Projectile1.new(player, super.get_projectile_data_by_id(1))
	var projectile_b = Projectile1.new(player, super.get_projectile_data_by_id(1))
	var projectile_c = Projectile1.new(player, super.get_projectile_data_by_id(1))
	
	projectile_a.collision_exception(projectile_b)
	projectile_a.collision_exception(projectile_c)
	projectile_b.collision_exception(projectile_a)
	projectile_b.collision_exception(projectile_c)
	projectile_c.collision_exception(projectile_a)
	projectile_c.collision_exception(projectile_b)
	
	# HACK: Hardcode this value of weapon position, may consider escaping to a new class to get weapon pos
	print("ab1/position ", player.weapon.position)
	print("ab1/dir1 ", rad_to_deg(direction.angle()))
	print("ab1/dir1 ", rad_to_deg(Vector2.from_angle(direction.angle() + PI/6).normalized().angle()))
	print("ab1/dir1 ", rad_to_deg(Vector2.from_angle(direction.angle() - PI/6).normalized().angle()))
	projectile_a.summon_as_projectile(direction, player.weapon.position)
	projectile_b.summon_as_projectile(Vector2.from_angle(direction.angle() + deg_to_rad(30)).normalized(), player.weapon.position)
	projectile_c.summon_as_projectile(Vector2.from_angle(direction.angle() - deg_to_rad(30)).normalized(), player.weapon.position)
	super.release_ability(player, direction)
	return WeaponGlobals.ability1_cooldown
