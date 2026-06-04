# First ability for pickaxe, summon the stone block
extends AbilityProjectile
class_name Ability13

func release_ability(player : Player, direction: Vector2) -> int:
	var projectile = Projectile12.new(player, super.get_projectile_data_by_id(12))
	SystemManager.active_world.add_child(projectile)
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	return WeaponGlobals.ability13_cooldown

func qfree():
	self.queue_free()
