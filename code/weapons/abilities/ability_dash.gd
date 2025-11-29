## Base class to implement the dash of the daggers and other weapons
extends Ability
class_name AbilityDash

var dash_power : float

func _init(dash_power: float) -> void:
	self.dash_power = dash_power

## Base function to make the stickman dash
func release_ability(player, direction: Vector2) -> int:
	player.ragdoll.move_entire_ragdoll_impulse(direction, dash_power)
	return WeaponGlobals.WEAPON_COOLDOWNS.SHORT
