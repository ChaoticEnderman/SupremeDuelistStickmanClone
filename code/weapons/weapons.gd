extends Node2D
class_name Weapon

@export var hitbox : CollisionShape2D

@export var abilities : Array[String] = []
@export var ability_cycle : int = 0
@export var ability_cycle_max : int

func _ready() -> void:
	ability_cycle_max = abilities.size()
