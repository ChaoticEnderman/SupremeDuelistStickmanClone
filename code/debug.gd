extends Label

func _physics_process(delta: float) -> void:
	var text : String = ""
	if Input.is_action_just_pressed("Debug"):
		self.visible = not self.visible
	
	var entity_count : int = 0
	var object_count : int = 0
	var area_count : int = 0
	for c in SystemManager.active_world.get_children():
		if c is GameObject:
			entity_count += 1
			object_count += 1
		elif c is GameArea:
			entity_count += 1
			area_count += 1
	text += "Entity count: " + str(entity_count) + " object count: " + str(object_count) + " area count: " + str(area_count)
	
	
	
	
	
	
	
	
	
	
	
	self.text = text
