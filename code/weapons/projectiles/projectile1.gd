## First projectile of the gun weapon, this will not collide with its peer shotgun projectiles
extends Projectile
class_name Projectile1

func _init():
	super._init()

func summon(owner: Player, data: ProjectileData, direction: Vector2, position: Vector2) -> void:
	super.summon(owner, data, direction, position)

func collision_exception(projectile: Projectile):
	hitbox.add_collision_exception_with(projectile.hitbox)

func get_damage() -> int:
	return super.get_damage()

func tick():
	super.tick()
