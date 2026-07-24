## First projectile of the gun weapon, this will not collide with its peer shotgun projectiles
extends Projectile
class_name Projectile1

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, load("res://resources/projectile1.tres"))

## Since each time the ability is shot it will shoot 3 bullets, this is to make the bullets not touch eachother
func collision_exception(projectile: Projectile):
	self.add_collision_exception_with(projectile)

## Also remove when touching opponent weapon
func check_collision():
	for body in self.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			qfree()
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				qfree()
		if body is CharacterBody2D and body.get_owner() is Player:
			qfree()

func get_damage() -> float:
	return super.get_damage()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(1)
	# 11th position
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		return true
	return false

func qfree():
	super.qfree()
	self.queue_free()
