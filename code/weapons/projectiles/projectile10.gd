# Blue portal for portal gun weapon
extends GameArea
class_name Projectile10

var flying_time : int = 0

func _init(player: Player, direction: Vector2, position: Vector2):
	super._init(player, direction, position)
	super.add_projectile_data(load("res://resources/projectile10.tres"))
	super.add_collision_shape(projectile_data.hitbox)
	super.summon_as_projectile(direction, position)
	GameState.game_tick.connect(_on_game_tick)

func get_damage() -> float:
	return super.get_damage()

# Teleport back to the weapon and release instead of removing this
func summon():
	flying_time = Globals.TPS / 2

## Automatically return the vector displacement movement from this to the other portal
func get_other_portal_displacement() -> Vector2:
	if player.weapon.orange_portal == null or player.weapon.blue_portal == null:
		return Vector2.ZERO
	return player.weapon.orange_portal.position - player.weapon.blue_portal.position

func _on_game_tick(delta: float):
	if flying_time > 0:
		flying_time -= 1
		self.position += direction * projectile_data.speed
		for body in get_overlapping_bodies():
			if body is TileMapLayer:
				direction = Vector2(0.0, 0.0)
		player.weapon.blue_portal = self
	else:
		pass
		# Stay in place and wait until signal to remove

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(2)
	# 10th value from here
	data.append(float(flying_time))
	return data

func deserialize_object_data(data: PackedFloat32Array) -> bool:
	if super.deserialize_object_data(data):
		var i : int = 9
		flying_time = int(data.get(i))
		return true
	return false

func _on_weapon_next_blue():
	self.qfree()

func qfree():
	super.qfree()
	self.queue_free()
