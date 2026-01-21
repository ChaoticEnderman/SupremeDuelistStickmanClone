## First ability for the shield weapon3, zoom up and down after a while
extends Ability
class_name Ability4

var timer : int = 0

func _init(player: Player) -> void:
	super._init()
	self.player = player

func release_ability(player: Player, direction: Vector2):
	self.player = player
	player.weapon.hitbox.scale = Vector2(2.0, 2.0)
	player.weapon.sprite.scale = Vector2(0.4, 0.4)
	# HACK: Hardcoce this value, maybe escape this to somewhere like WeaponGlobals
	timer = Globals.TPS
	return WeaponGlobals.ability4_cooldown

func _on_game_tick(delta: float):
	super._on_game_tick(delta)
	timer -= 1
	if timer == 0:
		if super.is_player_valid():
			player.weapon.hitbox.scale = Vector2(1.0, 1.0)
			player.weapon.sprite.scale = Vector2(0.2, 0.2)
		return
