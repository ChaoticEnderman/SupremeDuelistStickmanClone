## Second weapon, dagger, with dashes of different lengths
extends Weapon
class_name Weapon2

var hitbox_area : Area2D

func init(player: Player, id: String) -> void:
	super.init(player, "2")
	
	abilities.append(Ability2.new(1000.0))
	abilities.append(Ability3.new(2000.0))
	
	super.set_damage(Damageable.new(0.1))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)
