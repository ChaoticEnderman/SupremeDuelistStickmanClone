## Summon a short zap for the gauntlet
extends Ability
class_name Ability7

func release_ability(player : Player, direction: Vector2) -> int:
	var projectile = Projectile4.new(player, direction, player.weapon.position)
	SystemManager.world.add_child(projectile)
	
	return WeaponGlobals.ability7_cooldown

func qfree():
	self.queue_free()
