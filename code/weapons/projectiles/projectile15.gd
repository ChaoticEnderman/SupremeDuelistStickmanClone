## Bomb big projectile weapon
class_name Projectile15
extends Projectile

# How long it wait until it explode
var fuse : int


func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)
	var material = PhysicsMaterial.new()
	material.bounce = 0.5
	material.friction = 1.0
	physics_material_override = material
	
	fuse = Globals.TPS * 2

func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	fuse -= 1
	if fuse <= 0:
		print("p13/fused")
		var projectile = Projectile14.new(player, direction, position)
		projectile.summon_as_projectile(direction, position)
		
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
				fuse = 0

func qfree():
	super.qfree()
	self.queue_free()
