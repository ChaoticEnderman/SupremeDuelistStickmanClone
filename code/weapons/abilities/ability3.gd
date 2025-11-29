extends AbilityDash
class_name Ability3

func release_ability(player, direction: Vector2) -> int:
	super.release_ability(player, direction)
	return WeaponGlobals.ability3_cooldown
