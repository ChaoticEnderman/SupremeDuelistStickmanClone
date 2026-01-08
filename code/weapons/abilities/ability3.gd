## First ability for the dagger weapon, dash longer
extends AbilityDash
class_name Ability3

func _init(dash_power: float) -> void:
	self.dash_power = dash_power

func release_ability(player, direction: Vector2) -> int:
	super.release_ability(player, direction)
	return WeaponGlobals.ability3_cooldown
