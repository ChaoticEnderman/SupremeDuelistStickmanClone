## Base class for abilities that can shoot one or more projectiles
## The AbilityProjectile class manage all the projectile object reference and will free them recursively 

extends Ability
class_name AbilityProjectile

var projectiles : Array[Projectile]

## Utility function to get projectile data by id, used globally also instead of just this class and its subclasses
static func get_projectile_data_by_id(id: int) -> ProjectileData:
	return load("res://resources/projectile" + str(id) + ".tres")

## Add a projectile to the list
func add_projectile(projectile: Projectile):
	self.projectiles.append(projectile)

## Base function to release the projectile and add to the world.
func release_ability(player, direction: Vector2):
	pass

## Recursive queue free function from up, removing the projectiles
func qfree():
	for p in projectiles:
		p.qfree()
	self.queue_free()
