## Bomb weapon small bomb projectile that can roll and explode
extends Projectile
class_name Projectile13

# How long it wait until it explode
var fuse : int

var is_big : bool

func _init(player: Player, projectile_data: ProjectileData, is_big: bool):
	super._init(player, load("res://resources/projectile13.tres"))
	var material = PhysicsMaterial.new()
	material.bounce = 0.5
	material.friction = 1.0
	physics_material_override = material
	
	self.is_big = is_big
	
	if is_big:
		fuse = Globals.TPS * 3
	else:
		fuse = Globals.TPS * 2

func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	super.summon_as_projectile(direction, position)
	if is_big:
		sprite.texture = load("res://assets/projectile/bomb_big.png")
		sprite.scale = Vector2(0.25, 0.25)
	else:
		sprite.texture = load("res://assets/projectile/bomb.png")
		sprite.scale = Vector2(0.25 , 0.25)

func _ready() -> void:
	super._ready()
	GameState.game_tick.connect(_on_game_tick)

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	fuse -= 1
	if fuse <= 0:
		print("p13/fused")
		var projectile = Projectile14.new(player, direction, position)
		projectile.summon_as_projectile(direction, position)
		projectile.shape = CircleShape2D.new()
		
		if is_big:
			projectile.sprite.scale = Vector2(1.5, 1.5)
			projectile.shape.radius = 300.0
			projectile.damageable.damage_tick *= 3
		else:
			
			projectile.sprite.scale = Vector2(0.4, 0.4)
			projectile.shape.radius = 80.0
		
		projectile.collision_shape.shape = projectile.shape
		
		# Other projectile doesnt need this but for some reason this require it
		SystemManager.active_world.add_child(projectile)
		
		self.qfree()

func get_damage() -> float:
	return super.get_damage()

## Overriding collision to keep the projectile not going through wall but not deleting when hitting the map either
func check_collision():
	for body in self.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			pass
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				if not is_big:
					fuse = 0

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = super.serialize_object_data(13)
	# 11th position
	data.append(float(fuse))
	data.append(1.0 if is_big else 0.0)
	return data

func deserialize_object_data(data: PackedFloat32Array):
	if super.deserialize_object_data(data):
		var i : int = 11
		self.fuse = data.get(i)
		self.is_big = true if data.get(i + 1) == 1.0 else false
		return true
	return false
	

func qfree():
	super.qfree()
	self.queue_free()
