## Base class for abilities that can shoot one or more projectiles
# TODO: Refactor this
extends Ability
class_name AbilityProjectile

var projectile : Projectile

func get_projectile_data_by_id(id: int) -> ProjectileData:
	return load("res://resources/projectile" + str(id) + ".tres")

## Base function to release the projectile and add to the world.
func release_ability(player, direction: Vector2):
	SystemManager.world.add_projectile(self.projectile)
