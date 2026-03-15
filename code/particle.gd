## Misc class for making basic sprite2d-based particles
extends Sprite2D
class_name Particle

## Timer to automatically decay this after a short time
var timer : int

## Scale to decay every tick
var tick_scale_decay : Vector2

var tick_alpha_decay : float

func _init(texture: Texture2D) -> void:
	GameState.game_tick.connect(_on_game_tick)
	self.texture = texture
	timer = 60

## Scale linarly this particle from start_multi to end_multi
func scale_decay(start_multi: Vector2, end_multi: Vector2, duration: int):
	self.scale = start_multi
	tick_scale_decay = (end_multi - start_multi) / duration
	self.timer = duration

## Same but work neat when like scale x and y is the same 
func scale_decay_i(start_multi: float, end_multi: float, duration: int):
	self.scale = Vector2(start_multi, start_multi)
	tick_scale_decay.x = (end_multi - start_multi) / duration
	tick_scale_decay.y = (end_multi - start_multi) / duration
	self.timer = duration

## Decay transparency, linear unless specially configured
func alpha_decay(start_alpha: float, end_alpha: float, duration: int):
	self.modulate.a = start_alpha
	tick_alpha_decay = (end_alpha - start_alpha) / duration
	self.timer = duration

func _on_game_tick(delta: float):
	if timer == 0:
		self.queue_free()
	else:
		self.scale += tick_scale_decay
		self.modulate.a += tick_alpha_decay
				
		timer -= 1

func qfree():
	self.queue_free()
