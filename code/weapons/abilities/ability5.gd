## Ability of the scythe weapon to summon the wisp
# TODO: About to need to be refactored
extends Ability
class_name Ability5

## Timer to release several scythe orbs in one succession
var timer : int = 1000

## Reference to the player that summon this
var player : Player

## Reference to the initial direction of the weapon to shoot several objects in succession
var direction : Vector2

func _init() -> void:
	GameState.game_tick.connect(_on_game_tick)

func release_ability(player, direction: Vector2) -> int:
	var projectile = Projectile2.new(player, direction, player.weapon.position)
	self.player = player
	self.direction = direction
	
	super.release_ability(player, direction)
	timer = 0
	return WeaponGlobals.ability5_cooldown

func _on_game_tick(delta: float):
	timer = timer + 1
	
	var projectile : Projectile2
	
	if timer == 5:
		projectile = Projectile2.new(player, direction, player.weapon.position)
		super.release_ability(player, direction)
	if timer == 10:
		projectile = Projectile2.new(player, direction, player.weapon.position)
		super.release_ability(player, direction)
