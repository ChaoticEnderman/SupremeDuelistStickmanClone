## Base composition class for anything that can damage that player
## Can be a zone, can be a projectile, or a melee weapon
extends Node2D
class_name Damageable

## The damage that it can deal per each game tick
var damage_tick : float

## The owner of the damage, to ignore the damage on that entity. Can be a stickman or null (not recommended)
var owner_stickman : Node2D

func _init(damage: float) -> void:
	damage_tick = damage
