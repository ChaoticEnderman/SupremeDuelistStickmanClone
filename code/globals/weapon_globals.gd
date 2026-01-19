# Global class that store the list of weapons and also weapon choices for the players
extends Node

## Weapon ids for the first player
var weapon1 : int
var weapon2 : int

var weapon_list : Array[WeaponData] = []

## Default weapon cooldowns, measured in ticks. 2, 3, 5 seconds for short, medium, long cooldown respectively
var WEAPON_COOLDOWNS = {
	SHORT = Globals.TPS * 2,
	MEDIUM = Globals.TPS * 3,
	LONG = Globals.TPS * 5
}

# This is bad but not too bad lol, like we wont need to do like >100 abilities later on
# TODO: Make like resources for abilities

# Weapon1 gun
# Ability to shoot 3 bullets
var ability1_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon2 dagger
# Ability to dash short
var ability2_cooldown : int = 15
# Ability to dash long
var ability3_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon3 shield
# Ability to zoom up
var ability4_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon4 scythe
# Ability to shoot the wisp
var ability5_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

var ability6_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
var ability7_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
var ability8_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

func _init() -> void:
	load_weapons()

## Load all weapons at the very start of the app, only the data for ready menu to use before actual game weapon
func load_weapons() -> void:
	var i : int = 1
	var path = "res://resources/weapon" + str(i) + ".tres"
	while ResourceLoader.exists(path):
		weapon_list.append(load(path))
		i += 1
		path = "res://resources/weapon" + str(i) + ".tres"

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
