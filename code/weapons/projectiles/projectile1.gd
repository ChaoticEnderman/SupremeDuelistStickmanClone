## First projectile of the gun weapon, this will not collide with its peer shotgun projectiles
extends Projectile
class_name Projectile1

func _physics_process(delta: float) -> void:
	#print("Pro1/test pos ", self.position)
	pass

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)

## Since each time the ability is shot it will shoot 3 bullets, this is to make the bullets not touch eachother
func collision_exception(projectile: Projectile):
	self.add_collision_exception_with(projectile)

func get_damage() -> int:
	return super.get_damage()
