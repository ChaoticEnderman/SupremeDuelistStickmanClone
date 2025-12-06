extends Weapon
class_name Weapon1

var hitbox_area : Area2D

func init(player: Player) -> void:
	super.init(player)
	
	abilities.append(Ability1.new(Projectile1.new(), "1"))
	
	super.add_sprite(Sprite2D.new(), load("res://assets/weapon1.png"))
	super.set_hitbox("1")
	super.set_damage(Damageable.new(0.1))
	#super.set_cooldown(WeaponGlobals.WEAPON_COOLDOWNS.SHORT)
	
func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)
