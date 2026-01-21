## Abstract class for abilities
extends Node
class_name Ability

var player : Player

func _init() -> void:
	GameState.game_tick.connect(_on_game_tick)

## Releasing the ability and return the cooldown
func release_ability(player: Player, direction: Vector2) -> int:
	self.player = player
	return 0

## Checking every tick to also free the ability once the weapon is freed
func _on_game_tick(delta: float):
	pass

## Check if player valid, will be useful for abilities that affect the player. Automatically queue free if player is removed
func is_player_valid() -> bool:
	if is_instance_valid(player):
		return true
	self.queue_free()
	return false
