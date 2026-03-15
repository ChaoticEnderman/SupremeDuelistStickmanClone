## Abstract class for abilities.
## Abilities are the in-between layer of weapon to act out abilities and attacks. This is to seperate and control some abilities that is just summoning projectile but can be more complicated. Also allow for reusing abilities 
extends Node
class_name Ability

var player : Player

func _init() -> void:
	GameState.game_tick.connect(_on_game_tick)

## Releasing the ability and return the cooldown
func release_ability(player: Player, direction: Vector2) -> int:
	self.player = player
	return 0

func is_player_valid():
	return player.is_dead_check()

## Checking every tick to also free the ability once the weapon is freed
func _on_game_tick(delta: float):
	pass

func qfree():
	self.queue_free()
