## Sniper weapon for shooting a bouncy projectile
extends Weapon
class_name Weapon8

func init(player: Player, id: String) -> void:
	super.init(player, "8")
	
	abilities.append(Ability10.new())
		
	super.set_damage(Damageable.new(0.1, player))

func add_projectile_cooldown_signal(projectile: Projectile9):
	projectile.reduce_cooldown.connect(_on_projectile_reduce_cooldown)

func _on_projectile_reduce_cooldown():
	print("W8/receiving signal")
	self.set_cooldown(self.cooldown - Globals.TPS * 3)

func tick_rotation(rotation: Vector2):
	super.tick_rotation(rotation)

func tick_cooldown():
	super.tick_cooldown()

func tick_release_ability(direction: Vector2) -> bool:
	return super.tick_release_ability(direction)

func qfree():
	super.qfree()
	self.queue_free()
