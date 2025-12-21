## Class for the sprites of the player, controlling each limbs colors of the player and also the brush color
extends Node
class_name PlayerSpriteGlobal
# TODO: I feel like this is missing something

## List to contain left and right side limb colors, is indexed by only the LIMB_INDEX enum
static var l_limbs : Array[Color]
## Similiar to the left part
static var r_limbs : Array[Color]

## Single paint color for one limb of the stickman
static var l_paint_color : Color
## Similiar to the left part
static var r_paint_color : Color

## Enum for the body parts of the stickman, can also be converted to int to index the array 
enum LIMB_INDEX {HEAD, TORSO, STOMACH, L_THIGH, L_SHIN, R_THIGH, R_SHIN, L_ARM, L_FOREARM, R_ARM, R_FOREARM}
## The sides of the player
enum PLAYER {LEFT, RIGHT}

## Set default color to all white, might be changed later to read from file
func set_default_color() -> void:
	l_limbs.resize(11)
	r_limbs.resize(11)
	for i in range(11):
		l_limbs[i] = Color(1,1,1,1)
		r_limbs[i] = Color(1,1,1,1)

static func set_brush_color(player: PLAYER, color: Color):
	if player == PLAYER.LEFT:
		l_paint_color = color
	elif player == PLAYER.RIGHT:
		r_paint_color = color

static func get_brush_color(player: PLAYER):
	if player == PLAYER.LEFT:
		return l_paint_color
	elif player == PLAYER.RIGHT:
		return r_paint_color

## Update a specific limb to the current paint color
static func set_limb(limb_id: LIMB_INDEX, player: PLAYER):
	if player == PLAYER.LEFT:
		l_limbs[limb_id] = l_paint_color
	elif player == PLAYER.RIGHT:
		r_limbs[limb_id] = r_paint_color

static func get_limb(limb_id: LIMB_INDEX, player: PLAYER):
	if player == PLAYER.LEFT:
		return l_limbs[limb_id]
	elif player == PLAYER.RIGHT:
		return r_limbs[limb_id]
