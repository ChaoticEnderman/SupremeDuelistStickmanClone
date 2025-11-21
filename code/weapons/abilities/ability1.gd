extends AbilityProjectile
class_name Ability1

func release_ability(world, player, direction: Vector2, projectile_id: String, projectile: Projectile) -> int:
	# The first ever weapon will release 3 bullets in a rather shotgun pattern, like sds gun
	var temp_direction: Vector2 = direction
	
	var projectile_a = Projectile1.new()
	var projectile_b = Projectile1.new()
	var projectile_c = Projectile1.new()
	
	if temp_direction == Vector2.ZERO:
		print("!!! null direction")
	print()
	print("start")
	
	super.release_ability(world, player, temp_direction, projectile_id, projectile_a)
	
	temp_direction = Vector2.from_angle(direction.angle() + deg_to_rad(30)).normalized()
	super.release_ability(world, player, temp_direction, projectile_id, projectile_b)
	
	temp_direction = Vector2.from_angle(direction.angle() - deg_to_rad(30)).normalized()
	super.release_ability(world, player, temp_direction, projectile_id, projectile_c)
	
	projectile_a.collision_exception(projectile_b)
	projectile_a.collision_exception(projectile_c)
	projectile_b.collision_exception(projectile_a)
	projectile_b.collision_exception(projectile_c)
	projectile_c.collision_exception(projectile_a)
	projectile_c.collision_exception(projectile_b)
	return WeaponGlobals.WEAPON_COOLDOWNS.SHORT
