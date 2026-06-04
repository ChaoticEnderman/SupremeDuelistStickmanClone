## Katana ability to summon the dragon
extends AbilityProjectile
class_name Ability9

signal reset_dragon

func release_ability(player : Player, direction: Vector2) -> int:
	reset_dragon.emit()
	var projectile = Projectile8.new(player, super.get_projectile_data_by_id(8), self)
	SystemManager.active_world.add_child(projectile)
	
	projectile.summon_as_projectile(direction, player.weapon.position)
	return WeaponGlobals.ability9_cooldown

func qfree():
	self.queue_free()
