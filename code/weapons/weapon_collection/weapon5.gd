## Fifth weapon, a gauntlet with abilities for either zapping or shooting a big ball
extends Weapon
class_name Weapon5

func init(player: Player, id: String) -> void:
	super.init(player, "5")
	
	abilities.append(Ability6.new())
	abilities.append(Ability7.new())
	
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
