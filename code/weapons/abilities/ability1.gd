extends AbilityProjectile
class_name Ability1

func release_ability(player, direction: Vector2) -> int:
	# The first ever weapon will release 3 bullets in a rather shotgun pattern, like sds gun
	
	var projectile_a = Projectile1.new()
	var projectile_b = Projectile1.new()
	var projectile_c = Projectile1.new()
	
	projectile_a.collision_exception(projectile_b)
	projectile_a.collision_exception(projectile_c)
	projectile_b.collision_exception(projectile_a)
	projectile_b.collision_exception(projectile_c)
	projectile_c.collision_exception(projectile_a)
	projectile_c.collision_exception(projectile_b)
	
	projectile = projectile_a
	super.release_ability(player, direction)
	
	projectile = projectile_b
	super.release_ability(player, Vector2.from_angle(direction.angle() + deg_to_rad(30)).normalized())
	
	projectile = projectile_c
	super.release_ability(player, Vector2.from_angle(direction.angle() - deg_to_rad(30)).normalized())
	
	return WeaponGlobals.ability1_cooldown
