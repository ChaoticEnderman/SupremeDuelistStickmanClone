# Global class that store the list of weapons and also weapon choices for the players
extends Node

## Weapon for the left player
var weapon_left : int
## Weapon for the right player
var weapon_right : int

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
var ability2_cooldown : int = Globals.TPS / 4
# Ability to dash long
var ability3_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon3 shield
# Ability to zoom up
var ability4_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon4 scythe
# Ability to shoot the wisp
var ability5_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon 5 Gauntlet
# Ability to summon big orb
var ability6_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
# Ability to shoot big zap
var ability7_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon 6 Crossbow
# Ability to shoot primary bullet
var ability8_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon 7 Katana
# Cooldown for the katana blue dragon
var ability9_cooldown : int = Globals.TPS * 5

# Weapon 8 Sniper
# Ability to shoot projectile
var ability10_cooldown : int = WEAPON_COOLDOWNS.LONG

# Weapon 9 Portal gun
# Ability for blue portal
var ability11_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
# Ability for orange portal
var ability12_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon 10 Pickaxe
# Ability for summoning the stone
var ability13_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

# Weapon 11 Bomb
# Ability to summon small bomb
var ability14_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
var ability15_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
var ability16_cooldown : int = WEAPON_COOLDOWNS.MEDIUM
var ability17_cooldown : int = WEAPON_COOLDOWNS.MEDIUM

func _init() -> void:
	load_weapons()

## Enum for the two sides of the player
enum PLAYER_SIDE {LEFT,	RIGHT}

## Load all weapons at the very start of the app, only the data for ready menu to use before actual game weapon
func load_weapons() -> void:
	# Load the random weapon first
	weapon_list.append(load("res://resources/weapon_random.tres"))
	
	var i : int = 1
	var path = "res://resources/weapon" + str(i) + ".tres"
	while ResourceLoader.exists(path):
		weapon_list.append(load(path))
		i += 1
		path = "res://resources/weapon" + str(i) + ".tres"

func set_weapon(weapon: PLAYER_SIDE, index: int):
	if weapon == PLAYER_SIDE.LEFT:
		weapon_left = index
	elif weapon == PLAYER_SIDE.RIGHT:
		weapon_right = index

func get_weapon(index: int) -> Weapon:
	match index:
		0:
			return null # This is for random weapon, the World class will handle null values here
		1:
			return Weapon1.new()
		2:
			return Weapon2.new()
		3:
			return Weapon3.new()
		4:
			return Weapon4.new()
		5:
			return Weapon5.new()
		6:
			return Weapon6.new()
		7:
			return Weapon7.new()
		8:
			return Weapon8.new()
		9:
			return Weapon9.new()
		10:
			return Weapon10.new()
		11:
			return Weapon11.new()
		#12:
			#return Weapon12.new()
		#13:
			#return Weapon13.new()
		#14:
			#return Weapon14.new()
		#15:
			#return Weapon15.new()
		#16:
			#return Weapon16.new()
		_:
			return null
