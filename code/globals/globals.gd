## Contain global constants and utility methods
extends Node

signal setting_reloaded

## Values for Godot's built-in damping value for the ragdolls
const LINEAR_DAMP : int = 6
const ANGULAR_DAMP : int = 15

## The movement force of the ragdoll, including several types of movement
const RAGDOLL_MOVE_FORCE : float = 2000.0 
## Jump force of the ragdoll
const RAGDOLL_JUMP_FORCE : float = 300.0 
## Torque force for a custom angular limit system
const RAGDOLL_TORQUE_FORCE : float = 100.0
## Angle for the legs to aim to seperate toward during the walking animation
const RAGDOLL_WALK_ANGLE : float = 30.0

## Baseline tps for the game, that is the number of physics tick per second
var TPS : int = Engine.physics_ticks_per_second

## The time that it need to wait right after a jump
var JUMP_COOLDOWN : int = 15
## The angle a is the range from a to -a that the joystick direction is considered a jumping range
## For example 45.0 jumping angle will call a jump when the joystick direction is between -45.0 and 45.0
const JUMPING_ANGLE_DEGREES : float = 45.0

## The hp that players begin with
const STARTING_HP : float = 100.0

## Scale for the joysticks for all players
var JOYSTICK_SCALE : float = 2.0

## List of all 4 possible positions for the joystick
enum JOYSTICK_POSITION {TOP_LEFT, BOTTOM_LEFT, TOP_RIGHT, BOTTOM_RIGHT}

## Damage multiplier
var DAMAGE_MULTIPLIER : float = 1.0
## Weapon cooldown multiplier in multiplier, not percentage
var WEAPON_COOLDOWN_MULTIPLIER : float = 1.0
## The number of repeating succession that the ragdoll will jump
var JUMP_HEIGHT : int = 12
## Measured in ticks, so this is equivalent to one second
var JUMP_TIME : int = 60

var KEYBOARD_INPUT_ENABLED : bool = false

var collision_layer : Dictionary = {
	"MAP" : 1,
	"PLAYER" : 2,
	"RESERVER" : 3,
	"INSTANT" : 4,
	"COLLISION" : 5,
	"NONCOLLISION" : 6
}

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

## Receiving signal from the setting controller and use this global class to propagate through all game components that change when the settings change
func reload_settings():
	setting_reloaded.emit()
