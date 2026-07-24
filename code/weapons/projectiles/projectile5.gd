## Primary projectile for crossbow ability to shoot 6 bullets after a short distance
extends Projectile
class_name Projectile5

## Timer in ticks, will spread out after 1 second
var timer : int = 0

var sub_projectiles : Array[Projectile] = []

func _init(player: Player, projectile_data: ProjectileData):
	GameState.game_tick.connect(_on_game_tick)
	super._init(player, load("res://resources/projectile5.tres"))

func get_damage() -> float:
	return super.get_damage()

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	timer += 1
	if timer == Globals.TPS:
		spread()

## Spread out the projectiles to the 6 bullets, and does not immediately queue_free() this since it need to keep the reference and clear the sub-projectiles also 
func spread():
	for i in range(6):
		var projectile : Projectile = Projectile6.new(player, null)
		projectile.rotation_degrees = 60 * i + 90
		# Spread the sub projectiles a bit based on direction initially
		projectile.summon_as_projectile(Vector2.from_angle(deg_to_rad(60 * i)), 
		position + Vector2.from_angle(deg_to_rad(60 * i)) * 5)
		sub_projectiles.append(projectile)
	self.sprite.texture = null
	self.freeze = true

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(5)
	# 11th position
	data.append(float(timer))
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		timer = int(data.get(i))
		return true
	return false

## This is called when clearing the world tree for making a new match
func qfree():
	for p in sub_projectiles:
		if is_instance_valid(p):
			p.qfree()
	super.qfree()
	self.queue_free()
