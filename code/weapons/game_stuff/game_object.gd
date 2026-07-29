## Base class for general game objects that isnt player or weapons
## Not for using directly, only make a subclass of this class like abilities
## Projectile objects are objects that work and move independently other than players and weapons
## Will runs on its own tick but still based on the the world tick event

# Because they use both rigid body2d as base
extends RigidBody2D
class_name GameObject

## Owner of this object if exist
var player : Player

## The resource data of this projectile, containing some serializable variant data and the nodepaths
var projectile_data : ProjectileData
## This damageable object will be used for the damage of the projectile
var damageable : Damageable

## Hitbox shape of this object
var hitbox_shape : Shape2D
## Initial direction
var direction : Vector2
## Optional sprite
var sprite : Sprite2D

## Only for online mode to update the object data instead of creating new object each time
var multiplayer_id : int

## Initializing the object with basic data like player, direction and position
## Player is for calculating the optional Damageable object so it can be nulled if not needed
## Direction and position can be empty vectors
func _init(player: Player, direction: Vector2, position: Vector2) -> void:
	GameState.clear_round.connect(_on_game_state_clear_round)
	if SystemManager.active_world.world_type == World.WORLD_TYPE.SERVER:
		multiplayer_id = MultiplayerGlobal.get_id()
	else:
		multiplayer_id = -1
	
	self.player = player
	
	self.direction = direction
	self.position = position

## Inject ProjectileData class if this class is considered a projectile
func add_projectile_data(data: ProjectileData):
	print("GO/adding projectile data")
	self.projectile_data = data
	# Seperate the projectile from the wall if it can pass
	if projectile_data.can_go_through_wall:
		self.set_collision_mask_value(Globals.collision_layer["MAP"], false)
	# Take the damage value from the projectile data
	self.damageable = Damageable.new(data.damage, player.ragdoll)
	# Adding the hitbox to the class
	self.hitbox_shape = data.hitbox
	# Scale up gravity
	self.gravity_scale = projectile_data.gravity_scale
	
	# Enable collision detection
	self.contact_monitor = true
	self.max_contacts_reported = 100
		

func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)
	# Construct the node
	sprite = Sprite2D.new()
	var collision : CollisionShape2D = CollisionShape2D.new()
	collision.shape = self.hitbox_shape
	sprite.texture = projectile_data.sprite
	# HACK: Hardcoded the scale value for the sprite because it cannot be scaled down by scene tree
	sprite.scale = Vector2(0.25, 0.25)
	
	add_child(sprite)
	add_child(collision)
	damageable = Damageable.new(projectile_data.damage, player)
	add_child(damageable)
	
	# Set the hitbox and damagable to self, this is used for like checking if the owner of the hitbox has a node damageable
	sprite.owner = self
	collision.owner = self
	damageable.owner = self

## Call to summon if this is a projectile and apply one time impulse to move it forward
func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	self.direction = direction
	self.position = position
	
	# Shooting the projectile
	self.apply_central_impulse(direction * projectile_data.speed)
	print("P2/direction ", direction)

func get_damage() -> float:
	print("GO/damage is ", damageable.damage_tick)
	return damageable.damage_tick

## Function to test if player exist and return the weapon, particularly useful for objects that reference the player weapon
## Also useful for other stuff too.
## If player is non-existence, i.e the GameObject isnt owned by a player, it will return null.
## If player is dead and is moving to next round, it will return empty vector and queue this object to remove itself.
## This is because GameObjects that have a player attribute is tied to a player instance.
func get_dependent_player() -> Player:
	if player == null:
		return null
	# If player is dead then remove self
	if player.is_dead_check():
		return null
		qfree()
	# Same thing but the previous is_dead_check is like not reliable somehow
	if (not is_instance_valid(player)):
		return null
		qfree()
	return player

## Runs when the global physics tick is ticking
func _on_game_tick(delta: float):
	print("GO/delta is ", delta)
	if damageable.owner_stickman != null:
		# Make the projectile doesnt touch the owner
		for child in damageable.owner_stickman.ragdoll.get_children():
			self.add_collision_exception_with(child)
		self.add_collision_exception_with(damageable.owner_stickman.weapon.hitbox)

## Automatically delete this object when the round end, unless otherwise configured
func _on_game_state_clear_round():
	qfree()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = PackedFloat32Array()
	data.append(SystemManager.PACKET_TYPE.GAME_OBJECT)
	data.append(float(multiplayer_id))
	# this is id to identify the class name of the projectile, will need to be set by the child classes
	data.append(float(id))
	
	data.append(self.position.x)
	data.append(self.position.y)
	data.append(self.rotation)
	data.append(self.linear_velocity.x)
	data.append(self.linear_velocity.y)
	data.append(self.angular_velocity)
	
	# TODO: 9th value for player, will finish later on
	if player.player_side == PlayerSpriteGlobal.PLAYER.LEFT:
		data.append(0.0)
	else:
		data.append(1.0)
	return data

func deserialize_object_data(data: PackedFloat32Array) -> bool:
	if data.get(0) != SystemManager.PACKET_TYPE.GAME_OBJECT:
		return false
	if int(data.get(1)) != self.multiplayer_id:
		return false
	
	var id : int = int(data.get(2))
	#if projectile_data != null:
	#	add_projectile_data(load("res://resources/projectile" + str(id) + ".tres"))
	
	var i : int = 3
	self.position.x = data.get(i)
	self.position.y = data.get(i + 1)
	self.rotation = data.get(i + 2)
	self.linear_velocity.x = data.get(i + 3)
	self.linear_velocity.y = data.get(i + 4)
	self.angular_velocity = data.get(i + 5)
	i = 9
	if data.get(9) == 0.0:
		player = SystemManager.active_world.player1
	elif data.get(9) == 1.0:
		player = SystemManager.active_world.player2
 
	#data.get(i) then do something for player
	
	return true


## Call to destroy the object
func qfree():
	SystemManager.active_world.remove_child(self)
	self.queue_free()
