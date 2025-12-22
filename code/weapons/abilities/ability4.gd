extends Ability
class_name Ability4

var timer : int = 0
var player : Player

func _init(player: Player) -> void:
	self.player = player
	GameState.game_tick.connect(_on_game_tick)

func release_ability(player: Player, direction: Vector2):
	self.player = player
	player.weapon.hitbox.scale = Vector2(2.0, 2.0)
	player.weapon.sprite.scale = Vector2(0.4, 0.4)
	timer = 30
	return WeaponGlobals.ability4_cooldown

func _on_game_tick():
	timer -= 1
	if timer == 0:
		player.weapon.hitbox.scale = Vector2(1.0, 1.0)
		player.weapon.sprite.scale = Vector2(0.2, 0.2)
		return
