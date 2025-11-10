## Composition class for anything that can damage that player
## Can be a zone, can be a projectile, or a melee weapon
extends Node2D
class_name Damageable

## The damage that it can deal per each game tick
var damage_tick : int

var owner_stickman : Node2D

func _init(damage: int) -> void:
	damage_tick = damage

func get_damage() -> int:
	return damage_tick
