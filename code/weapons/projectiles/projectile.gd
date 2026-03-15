## Base class for all simple projectiles that can be summoned by abilities
## This is intended to be summoned by the abilities and its subclass
## Not for using directly, only make a subclass of this class
## Projectile are simple GameObject that are trigger to move once in one direction and disappear in one hit
## This is dependent on the player and will be freed when the player is freed
extends GameObject
class_name Projectile

## Initialize the parent class and also some important data
func _init(player: Player, projectile_data: ProjectileData) -> void:
	GameState.game_tick.connect(_on_game_tick)
	super._init(player, Vector2(0.0, 0.0), Vector2(0.0, 0.0))
	super.add_projectile_data(projectile_data)
	SystemManager.world.add_child(self)

## Helper function to shorten the length of the code to getting the damage value
func get_damage() -> float:
	print("pro/damage ", super.get_damage())
	return super.get_damage()

func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	super.summon_as_projectile(direction, position)
	
## Runs each physics tick to check collision and other stuff
func _on_game_tick(delta: float):
	self.check_collision()

## Internal method that is not supposed to be called from children, just call tick() instead
func check_collision():
	for body in self.get_colliding_bodies():
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			queue_free()
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				queue_free()

func qfree():
	self.queue_free()
