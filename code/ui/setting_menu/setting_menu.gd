extends Node2D

# Path for the innermost container
@onready var container = get_node("Control/ScrollContainer/VBoxContainer")

# Labels and input data
@onready var damage_multiplier_label = container.get_node("DamageMultiplierLabel")
@onready var damage_multiplier = container.get_node("DamageMultiplier")
@onready var cooldown_label = container.get_node("CooldownLabel")
@onready var cooldown = container.get_node("Cooldown")
@onready var jump_height_label = container.get_node("JumpHeightLabel")
@onready var jump_height = container.get_node("JumpHeight")
@onready var jump_time_label = container.get_node("JumpTimeLabel")
@onready var jump_time = container.get_node("JumpTime")

@onready var gravity = container.get_node("Gravity")

@onready var engine_tps_label = container.get_node("EngineTPSLabel")
@onready var engine_tps = container.get_node("EngineTPS")

func _ready() -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)
	self.visible = false
	update_labels()

## Function to update all labels everytime something is updated
func update_labels():
	damage_multiplier_label.text = "Damage multiplier: " + str(damage_multiplier.value) + "x"
	cooldown_label.text = "Cooldown percentage of weapons: " + str(cooldown.value) + "%"
	jump_height_label.text = "Jump height: " + str(int(jump_height.value))
	jump_time_label.text = "Jump time in tick: " + str(int(jump_time.value))
	engine_tps_label.text = "TPS (Physics tick per second): " + str(engine_tps.value)

## Hide when the setting menu disappear
func _on_game_state_changed(state):
	self.visible = (state == GameState.GAME_STATE.PAUSING_SETTING)

## Only need to update values when it go back to the main game state
func _on_back_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATE.RUNNING)
	Globals.DAMAGE_MULTIPLIER = damage_multiplier.value
	Globals.WEAPON_COOLDOWN_MULTIPLIER = cooldown.value / 100
	Globals.JUMP_HEIGHT = int(jump_height.value)
	Globals.JUMP_TIME = int(jump_time.value)
	
	var gravity_status = Vector2.DOWN if gravity.pressed else Vector2.ZERO
	PhysicsServer2D.area_set_param(get_viewport().find_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, gravity_status)
	
	Engine.physics_ticks_per_second = engine_tps.value

# Update labels once something changes
func _on_damage_multiplier_value_changed(value: float) -> void:
	update_labels()
func _on_cooldown_value_changed(value: float) -> void:
	update_labels()
func _on_jump_height_value_changed(value: float) -> void:
	update_labels()
func _on_jump_time_value_changed(value: float) -> void:
	update_labels()
func _on_gravity_pressed() -> void:
	update_labels()
func _on_engine_tps_value_changed(value: float) -> void:
	update_labels()
