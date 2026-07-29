## Dragon head for katana, work as projectile but also apply force to drive
extends Projectile
class_name Projectile8

var timer : int

var particles : Array[Particle] = []
var particle_texture : Texture2D

var prev_rotation : float

func _init(player: Player, projectile_data: ProjectileData, ability_ref: Ability9):
	if ability_ref != null:
		ability_ref.reset_dragon.connect(_on_reset_dragon)
	super._init(player, load("res://resources/projectile8.tres"))
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.CYAN)
	particle_texture = ImageTexture.create_from_image(img)
	self.rotation = player.weapon.sprite.rotation
	timer = Globals.TPS * 500
	set_collision_layer_value(Globals.collision_layer["NONCOLLISION"], true)

func _on_reset_dragon():
	qfree()

func _on_game_tick(delta: float):
	timer -= 1
	if timer == 0:
		qfree()
		
	# Angle limit is 360 degree per tick, if tps is 60 then 6 degree per tick
	var angle_limit = (0.5 * PI) / Globals.TPS
	
	self.rotation = player.weapon.sprite.rotation
	# Clamping the angles and limit rotation
	var shortest_rotation = wrap(self.rotation - prev_rotation, -PI, PI)
	if shortest_rotation > angle_limit:
		self.rotation = prev_rotation + angle_limit
	elif shortest_rotation < -angle_limit:
		self.rotation = prev_rotation - angle_limit
		
	self.direction = Vector2.from_angle(self.rotation - PI/2)
	apply_central_impulse(self.direction * projectile_data.speed * delta)
	
	prev_rotation = self.rotation
	
	var particle : Particle = Particle.new(particle_texture)
	particle.position = self.position
	particle.rotation = self.rotation
	particle.z_index = -100
	SystemManager.active_world.add_child(particle)
	particles.append(particle)
	particle.scale_decay_i(0.4, 0.0, Globals.TPS / 2)
	particle.alpha_decay(1.0, 0.0, Globals.TPS / 2)

func get_damage() -> float:
	return super.get_damage()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(8)
	# 11th position
	data.append(prev_rotation)
	if player.player_side == PlayerSpriteGlobal.PLAYER.LEFT:
		data.append(0.0)
	else:
		data.append(1.0)
	
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		self.prev_rotation = data.get(i)
		if data.get(i + 1) == 0.0:
			var ability : Ability9 = SystemManager.active_world.player1.weapon.abilities[0]
			ability.reset_dragon.connect(_on_reset_dragon)
		else:
			var ability : Ability9 = SystemManager.active_world.player1.weapon.abilities[0]
			ability.reset_dragon.connect(_on_reset_dragon)
		return true
	return false

func qfree():
	super.qfree()
	for p in particles:
		if is_instance_valid(p):
			p.qfree()
	self.queue_free()
