## Base class for abilities that can shoot one or more projectiles
## The AbilityProjectile class manage all the projectile object reference and will free them recursively 

extends Ability
class_name AbilityProjectile

var projectiles : Array[Projectile]

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
