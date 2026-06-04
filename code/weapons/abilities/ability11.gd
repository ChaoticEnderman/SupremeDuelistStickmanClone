# Ability to spawn blue portal from portal gun
extends AbilityProjectile
class_name Ability11

var portal : Projectile10

func _init() -> void:
	super._init()

func release_ability(player : Player, direction: Vector2) -> int:
	if portal == null:
		portal = Projectile10.new(player, Vector2.ZERO, player.weapon.position)
		player.weapon.blue_portal = portal
		SystemManager.active_world.add_child(portal)
	portal.direction = direction
	portal.position = player.weapon.position
	
	portal.summon()
	
	player.weapon.is_blue = not player.weapon.is_blue
	return WeaponGlobals.ability11_cooldown

func qfree():
	self.queue_free()
