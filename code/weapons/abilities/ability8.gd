## Ability for the crossbow weapon to release the primary bullet
extends AbilityProjectile
class_name Ability8

func release_ability(player : Player, direction: Vector2) -> int:
	var projectile = Projectile5.new(player, super.get_projectile_data_by_id(5))
	SystemManager.world.add_child(projectile)
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	return WeaponGlobals.ability8_cooldown

func qfree():
	self.queue_free()
