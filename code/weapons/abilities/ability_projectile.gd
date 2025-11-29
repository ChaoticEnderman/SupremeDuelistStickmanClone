## Base class for abilities that can shoot one or more projectiles
extends Ability
class_name AbilityProjectile

var projectile : Projectile
var projectile_id : String

func _init(projectile: Projectile, projectile_id: String) -> void:
	self.projectile = projectile
	self.projectile_id = projectile_id

## Base function to release the projectile
func release_ability(player, direction: Vector2) -> int:
	# To retrieve the projectile scene and data by the path given the id
	var projectile_data_path : String = "res://resources/projectile" + projectile_id + ".tres"
	
	projectile.summon(player, load(projectile_data_path), direction, player.hand_position)
	SystemManager.world.add_projectile(self.projectile)
	return WeaponGlobals.WEAPON_COOLDOWNS.SHORT
