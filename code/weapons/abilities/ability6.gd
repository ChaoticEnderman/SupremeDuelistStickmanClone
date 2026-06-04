## Big thing projectile for the Gauntlet weapon. Will have a short delay
extends AbilityProjectile
class_name Ability6

## The delay to recharge and blow up the projectile after releasing the ability
var timer : int = 0

## Direction right at the moment of releasing the ability, will not be the direction when the projectile fire
var direction : Vector2

func release_ability(player : Player, direction: Vector2) -> int:
	self.player = player
	self.direction = direction
	super.release_ability(player, direction)
	GameState.game_tick.connect(_on_game_tick)
	timer = Globals.TPS
	return WeaponGlobals.ability6_cooldown

func _on_game_tick(delta: float):
	if timer == 0:
		return
	timer -= 1
	var test = (timer % 10) / 3
	if not is_instance_valid(player) or player == null:
		return
	player.weapon.sprite.modulate = Color(test, test, test)
	if timer == 1:
		var projectile = Projectile3.new(player, super.get_projectile_data_by_id(3))
		
		projectile.summon_as_projectile(direction, player.weapon.position)
		# Harcoding the value to make this projectile 3x bigger than normal
		projectile.sprite.scale = Vector2(0.75, 0.75)

func qfree():
	self.queue_free()
