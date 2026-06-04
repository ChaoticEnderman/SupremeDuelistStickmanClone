## Sniper ability to shoot the bouncy bullets
extends AbilityProjectile
class_name Ability10

func release_ability(player : Player, direction: Vector2) -> int:
	var projectile = Projectile9.new(player, super.get_projectile_data_by_id(9))
	SystemManager.active_world.add_child(projectile)
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	# This weapon is always Weapon8 so no worry
	player.weapon.add_projectile_cooldown_signal(projectile)
	return WeaponGlobals.ability10_cooldown

func qfree():
	self.queue_free()
