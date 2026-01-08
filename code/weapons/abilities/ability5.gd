## Ability of the scythe weapon to summon the wisp
# TODO: About to need to be refactored
extends Ability
class_name Ability5

func release_ability(player, direction: Vector2) -> int:
	var projectile = Projectile2.new(player, direction, player.weapon.position)
	
	super.release_ability(player, direction)
	return WeaponGlobals.ability5_cooldown
