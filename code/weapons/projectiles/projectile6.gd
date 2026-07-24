## Secondary projectile for the crossbow, summon by the primary projectile
extends Projectile
class_name Projectile6

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, load("res://resources/projectile6.tres"))

func get_damage() -> float:
	return super.get_damage()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(6)
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
