# Pickaxe weapon for summoning stones
extends Weapon
class_name Weapon10

var hitbox_area : Area2D

func init(player: Player, id: String) -> void:
	super.init(player, "10")
	
	abilities.append(Ability13.new())
	
	super.set_damage(Damageable.new(0.1, player))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)

func qfree():
	super.qfree()
	self.queue_free()
