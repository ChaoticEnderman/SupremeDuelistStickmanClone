extends Camera2D
class_name Camera

var camera_position : Vector2
var camera_zoom : float
var player_distance : float

var pos1 : Vector2
var pos2 : Vector2

func _process(delta: float) -> void:
	pos1 = SystemManager.p1_position
	pos2 = SystemManager.p2_position
	camera_position = (pos1 + pos2) / 2
	player_distance = pos1.distance_to(pos2)
	
	# 800 is just a constant to make this rather natural
	camera_zoom = 800 / player_distance
	
	self.position = Vector2(0.0, 0.0)
	#self.position = camera_position
	# This to make the camera not zoom too close to the players
	#if camera_zoom < 1:
		#self.zoom = Vector2(camera_zoom, camera_zoom)
	#else:
		#self.zoom = Vector2(1.0, 1.0)
