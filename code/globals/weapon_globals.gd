# Global class that store the list of weapons and also weapon choices for the players
extends Node

## Weapon for the first player
var weapon1 : Weapon
var weapon2 : Weapon

var weapon_list : Array[WeaponData] = []

## Default weapon cooldowns, measured in ticks. 2, 3, 5 seconds for short, medium, long cooldown respectively
enum WEAPON_COOLDOWNS {SHORT = 60 * 2, MEDIUM = 60 * 3, LONG = 60 * 5}

# This is bad but not too bad lol, like we wont need to do like >100 abilities later on
# TODO: Make like resources for abilities
const ability1_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability2_cooldown : int = 15
const ability3_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability4_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability5_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability6_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability7_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
const ability8_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

## Load all weapons at the very start of the app, only the data for ready menu to use before actual game weapon
func load_weapons() -> void:
	for i in range(1,4):
		weapon_list.append(load("res://resources/weapon" + str(i) + ".tres"))

func set_weapon(weapon: int, index: int):
	var w : Weapon
	# TODO: Some way to make this more compact, so like map class name by strings
	match index:
		1:
			w = Weapon1.new()
		2:
			w = Weapon2.new()
		3:
			w = Weapon3.new()
			
			
		_:
			w = WeaponRandom.new()
	
	if weapon == 1:
		weapon1 = w
	elif weapon == 2:
		weapon2 = w
	
