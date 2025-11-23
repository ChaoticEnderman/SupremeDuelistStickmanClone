## Base class for abilities that can shoot one or more projectiles
extends Node2D
class_name AbilityProjectile

var projectile : Projectile

## Base function to release the projectile
func release_ability(player, direction: Vector2, projectile_id: String, projectile : Projectile) -> int:
	# To retrieve the projectile scene and data by the path given the id
	var projectile_data_path : String = "res://resources/projectile" + projectile_id + ".tres"
	self.projectile = projectile
	
	self.projectile.summon(player, load(projectile_data_path), direction, player.hand_position)
	SystemManager.world.add_projectile(self.projectile)
	return WeaponGlobals.WEAPON_COOLDOWNS.SHORT
