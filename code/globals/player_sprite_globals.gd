## Class for the sprites of the player, controlling each limbs colors of the player and also the brush color
extends Node
class_name PlayerSpriteGlobal
# TODO: I feel like this is missing something

## List to contain left and right side limb colors, is indexed by only the LIMB_INDEX enum
static var l_limbs : Array[Color]
## Similiar to the left part
static var r_limbs : Array[Color]

## Texture for the hat of the players
static var l_hat : int
## Similiar to its left counterpart
static var r_hat : int

## Single paint color for one limb of the stickman
static var l_paint_color : Color
## Similiar to the left part
static var r_paint_color : Color

## List of hats, will be rather static
static var hat_list : Array[Texture2D]

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

## Load all hats resources into the hat array. Shoud just be called once at the start of the game because hats are not changed
func load_hats() -> void:
	var i : int = 0
	var path = "res://resources/hat" + str(i) + ".tres"
	while ResourceLoader.exists(path):
		hat_list.append(load(path).sprite)
		i += 1
		path = "res://resources/hat" + str(i) + ".tres"

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
	return null

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
	return null

## Set the hat and return it for the ReadyMenu hat thing
# TODO: Refactor this and the ReadyMenu class to seperate set and get hat
static func set_and_get_hat(hat_id: int, player: PLAYER) -> Texture2D:
	print("PSG/hat list ", hat_list, " thing ", hat_list[l_hat])
	if player == PLAYER.LEFT:
		l_hat = hat_id
		return hat_list[l_hat]
	elif player == PLAYER.RIGHT:
		r_hat = hat_id
		return hat_list[r_hat]
	print("PSG/returning null ", player)
	return null

## Get the hat sprite for player
static func get_hat(player: PLAYER) -> Texture2D:
	if player == PLAYER.LEFT:
		return hat_list[l_hat]
	elif player == PLAYER.RIGHT:
		return hat_list[r_hat]
	return null
