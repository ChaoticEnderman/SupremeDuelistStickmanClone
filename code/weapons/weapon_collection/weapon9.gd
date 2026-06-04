# Portal gun weapon to summon portals to teleport
extends Weapon
class_name Weapon9

var blue_portal : Projectile10
var orange_portal : Projectile11

var is_blue : bool

func init(player: Player, id: String) -> void:
	super.init(player, "9")
	
	abilities.append(Ability11.new())
	abilities.append(Ability12.new())
	
	super.set_damage(Damageable.new(0.1, player))

func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()
	if cooldown > 0:
		sprite.texture = weapon_data.sprite_cooldown
	elif is_blue:
		sprite.texture = load("res://assets/weapon/portal_gun_blue.png")
	elif not is_blue:
		sprite.texture = load("res://assets/weapon/portal_gun_orange.png")

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)

func qfree():
	super.qfree()
	self.queue_free()
