## Third weapon, a shield that can enlarge
extends Weapon
class_name Weapon3

var hitbox_area : Area2D

func init(player: Player, id: String) -> void:
	super.init(player, "3")
	
	var ability = Ability4.new()
	ability.owner = self
	abilities.append(ability)
	
	super.set_damage(Damageable.new(0.1))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)
