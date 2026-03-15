## Secondary projectile for the crossbow, summon by the primary projectile
extends Projectile
class_name Projectile6

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)

func get_damage() -> float:
	return super.get_damage()

func qfree():
	super.qfree()
	self.queue_free()
