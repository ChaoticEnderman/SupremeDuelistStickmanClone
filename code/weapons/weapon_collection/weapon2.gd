extends Weapon
class_name Weapon2

var hitbox_area : Area2D

func init(player: Player) -> void:
	super.init(player)
	
	abilities.append(Ability2.new(1000.0))
	abilities.append(Ability3.new(2000.0))
	
	super.add_sprite(Sprite2D.new(), load("res://assets/weapon2.png"))
	super.set_hitbox("2")
	super.set_damage(Damageable.new(0.1))
	#super.set_cooldown(WeaponGlobals.WEAPON_COOLDOWNS.SHORT)
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	var not_in_cooldown : bool = super.tick_release_ability(direction)
	return not_in_cooldown
