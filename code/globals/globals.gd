## Contain global constants and utility methods
extends Node

## Values for Godot's built-in damping value for the ragdolls
const LINEAR_DAMP := 3.0
const ANGULAR_DAMP := 3.0

## The movement force of the ragdoll, including several types of movement
const RAGDOLL_MOVE_FORCE : float = 10000.0 
## Jump force of the ragdoll
const RAGDOLL_JUMP_FORCE : float = 80000.0 
## Torque force for a custom angular limit system
const RAGDOLL_TORQUE_FORCE : float = 500.0

## Baseline tps for the game, that is the number of physics tick per second
const TPS : int = 60 

## Measured in ticks, so this is equivalent to one second
const JUMP_TIME : int = 60 
## The time that it need to wait right after a jump
const JUMP_COOLDOWN : int = 15
## The angle a is the range from a to -a that the joystick direction is considered a jumping range
## For example 45.0 jumping angle will call a jump when the joystick direction is between -45.0 and 45.0
const JUMPING_ANGLE_DEGREES : float = 45.0

## List of all 4 possible positions for the joystick
enum JOYSTICK_POSITION {TOP_LEFT, BOTTOM_LEFT, TOP_RIGHT, BOTTOM_RIGHT}

## Change the range of angles from -180 <= x <= 180 to 0 <= x <= 360
func angle_to_360(angle_degree: float) -> float:
	if angle_degree < 0.0:
		angle_degree += 360.0
	return angle_degree

## Change the range of angles from 0 <= x <= 360 to -180 <= x <= 180
func angle_to_180(angle_degree: float) -> float:
	if angle_degree > 180.0:
		angle_degree -= 360.0
	return angle_degree
