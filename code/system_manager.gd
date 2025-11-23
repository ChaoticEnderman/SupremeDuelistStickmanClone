## The manager for the entire game, is loaded perpetually until the game close. 
## Will handle the game world, main menu, settings, ... on a general case
extends Node

## The world of the game, containing the main action space for fighting
var world : Node2D

## Start command to start the game world. Currently only called by the loader command
## Will be used to get in each game session in the future
func start() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
