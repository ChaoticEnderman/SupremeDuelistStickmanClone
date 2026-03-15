## Katana ability to summon the dragon
extends AbilityProjectile
class_name Ability9

func release_ability(player : Player, direction: Vector2) -> int:
	var projectile = Projectile8.new(player, super.get_projectile_data_by_id(8))
	SystemManager.world.add_child(projectile)
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	return WeaponGlobals.ability9_cooldown

func qfree():
	self.queue_free()
