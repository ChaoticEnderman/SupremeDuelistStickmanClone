## Summon a short zap for the gauntlet
extends Ability
class_name Ability7

func release_ability(player : Player, direction: Vector2) -> int:
	GameState.game_tick.connect(_on_game_tick)
	
	var projectile = Projectile4.new(player, direction, player.weapon.position)
	SystemManager.world.add_child(projectile)
	
	return WeaponGlobals.ability7_cooldown
