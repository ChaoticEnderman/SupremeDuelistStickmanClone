extends Weapon
class_name Weapon1

var own_abilities : Array[AbilityProjectile]

func init(player: Player) -> void:
	super.init(player)
	
	var test : AbilityProjectile = Ability1.new()
	own_abilities.append(test)
	
	super.set_abilities(self.own_abilities)
	super.add_sprite(Sprite2D.new(), load("res://assets/weapon1.png"))
	super.set_damage(Damageable.new(5))
	#super.set_cooldown(WeaponGlobals.WEAPON_COOLDOWNS.SHORT)
	
func tick(rotation: Vector2):
	super.tick(rotation)

func tick_release_ability(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	world = get_tree().get_root().get_node("World")
	
	if cooldown < 1:
		cooldown = own_abilities.front().release_ability(world, player, direction, "1", null)
		return true
	else:
		return false
