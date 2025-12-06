extends Weapon
class_name Weapon3

var hitbox_area : Area2D

func init(player: Player) -> void:
	super.init(player)
	
	var ability = Ability4.new()
	ability.owner = self
	abilities.append(ability)
	
	super.add_sprite(Sprite2D.new(), load("res://assets/weapon3.png"))
	super.set_hitbox("3")
	super.set_damage(Damageable.new(0.1))
	#super.set_cooldown(WeaponGlobals.WEAPON_COOLDOWNS.SHORT)
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)
