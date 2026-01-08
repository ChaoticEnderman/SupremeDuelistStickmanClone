# First weapon, a gun like sds gun with the ability to shoot a single bullet
extends Weapon
class_name Weapon1

var hitbox_area : Area2D

func init(player: Player, id: String) -> void:
	super.init(player, "1")
	
	abilities.append(Ability1.new())
	
	super.set_damage(Damageable.new(0.1, player))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)
