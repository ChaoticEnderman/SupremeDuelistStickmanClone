# Ability to spawn orange portal from portal gun
extends AbilityProjectile
class_name Ability12

var portal : Projectile11

func _init() -> void:
	super._init()

func release_ability(player : Player, direction: Vector2) -> int:
	if portal == null:
		portal = Projectile11.new(player, Vector2.ZERO, player.weapon.position)
		player.weapon.orange_portal = portal
		SystemManager.active_world.add_child(portal)
	portal.direction = direction
	portal.position = player.weapon.position
	
	portal.summon()
	
	player.weapon.is_blue = not player.weapon.is_blue
	return WeaponGlobals.ability12_cooldown

func qfree():
	self.queue_free()
