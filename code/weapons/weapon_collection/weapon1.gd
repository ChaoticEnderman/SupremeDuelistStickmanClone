extends Weapon
class_name Weapon1

var own_abilities : Array[AbilityProjectile]

func init(player: Player) -> void:
	super.init(player)
	
	# Demo for the first ability
	var test : AbilityProjectile = Ability1.new()
	own_abilities.append(test)
	
	super.set_abilities(self.own_abilities)
	super.add_sprite(Sprite2D.new(), load("res://assets/weapon1.png"))
	super.set_damage(Damageable.new(5))
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	
	if cooldown < 1:
		# Temporary code to just release the single ability
		cooldown = own_abilities.front().release_ability(player, direction, "1", null)
		return true
	else:
		return false
