## Stone projectile for the pickaxe
# TODO: change the type to static body and not frozen rigid body so it can 
extends Projectile
class_name Projectile12

var health : int = 100

var locked_position : Vector2

func _init(player: Player, projectile_data: ProjectileData):
	super._init(player, projectile_data)
	# Stay for 10 seconds and stop
	timeout = Globals.TPS * 10
	self.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	# Make the stone very hard to move but not impossible
	linear_damp = 5000.0
	angular_damp = 50.0
	

func get_damage() -> float:
	return super.get_damage()

func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	super.summon_as_projectile(direction, position)

## Change the collision mechanism to reduce the health instead of instant destruction
func check_collision():
	# Also locking in the position
	
	for body in self.get_colliding_bodies():
		
		if body is TileMapLayer and not projectile_data.can_go_through_wall:
			timeout -= 1
		if body is RigidBody2D and body.get_owner() is Player:
			if not (body.get_owner() == damageable.owner_stickman):
				print("p12/stone hitting ", body)
				timeout -= 1

func qfree():
	super.qfree()
	self.queue_free()
