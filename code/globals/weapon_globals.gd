# Global class that store the list of weapons and also weapon choices for the players
extends Node

## Weapon ids for the first player
var weapon1 : int
var weapon2 : int

var weapon_list : Array[WeaponData] = []

## Default weapon cooldowns, measured in ticks. 2, 3, 5 seconds for short, medium, long cooldown respectively
enum WEAPON_COOLDOWNS {SHORT = 60 * 2, MEDIUM = 60 * 3, LONG = 60 * 5}

# This is bad but not too bad lol, like we wont need to do like >100 abilities later on
# TODO: Make like resources for abilities

# Weapon1 gun
# Ability to shoot 3 bullets
const ability1_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon2 dagger
# Ability to dash short
const ability2_cooldown : int = 15
# Ability to dash long
const ability3_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon3 shield
# Ability to zoom up
const ability4_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon4 scythe
# Ability to shoot the wisp
const ability5_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

const ability6_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability7_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability8_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

func _init() -> void:
	load_weapons()

## Load all weapons at the very start of the app, only the data for ready menu to use before actual game weapon
func load_weapons() -> void:
	for i in range(1,5):
		weapon_list.append(load("res://resources/weapon" + str(i) + ".tres"))

func set_weapon(weapon: int, index: int):
	# TODO: Make an enum of this
	if weapon == 1:
		weapon1 = index
	elif weapon == 2:
		weapon2 = index

func get_weapon(index: int) -> Weapon:
	match index:
		1:
			return Weapon1.new()
		2:
			return Weapon2.new()
		3:
			return Weapon3.new()
		4:
			return Weapon4.new()
		
		
		_:
			return null
