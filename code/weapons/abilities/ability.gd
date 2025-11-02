extends Node

class_name Ability

# This function must be overridden in child classes
func activate(user, direction):
	push_error("activate() not implemented in subclass!")
