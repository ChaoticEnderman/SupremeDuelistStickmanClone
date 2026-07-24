## Base class for general game areas. Can be moving area, damaging area, static areas, jump bounces, ...
## Not for using directly, only make a subclass of this class 
## Will runs on its own tick but still based on the the world tick event
## This is mostly similiar to the GameObject class but is an area instead
extends Area2D
class_name GameArea

## Owner of this object if exist
var player: Player

## The resource data of this projectile, containing some serializable variant data and the nodepaths
var projectile_data : ProjectileData
## This damageable object will be used for the damage of the projectile
var damageable : Damageable

## Initial direction
var direction : Vector2
## Optional sprite
var sprite : Sprite2D

## Only for online mode to update the object data instead of creating new object each time
var multiplayer_id : int

## Core collision shape of this area to contain a Shape2D. By design this will only have one CollisionShape unlike how Area2D node is designed
var collision_shape : CollisionShape2D
## Shape of the collision shape
var shape : Shape2D

## List of colliding rigid bodies and other bodies to this area
var colliding_bodies

## Initializing the object with basic data like player, direction and position
## Player is for calculating the optional Damageable object that doesnt affect the player. Setting player to null will make this damage everyone
## Direction and position can be empty vectors
func _init(player: Player, direction: Vector2, position: Vector2) -> void:
	GameState.game_tick.connect(_on_game_tick)
	if SystemManager.active_world.world_type == World.WORLD_TYPE.SERVER:
		multiplayer_id = MultiplayerGlobal.get_id()
	else:
		multiplayer_id = -1
	
	self.player = player
	collision_shape = CollisionShape2D.new()
	sprite = Sprite2D.new()
	add_child(collision_shape)
	add_child(sprite)
	
	self.direction = direction
	self.position = position

## Add a shape (or overwriting current one, not recommended in most cases)
## for the collision shape children, will be limited to one for each game area
func add_collision_shape(shape: Shape2D):
	collision_shape.shape = shape
	
	self.collision_shape.owner = self

## Inject ProjectileData class if this class is considered a projectile
## (rarer than GameObject based projectiles)
func add_projectile_data(data: ProjectileData):
	self.projectile_data = data
	# Take the damage value from the projectile data
	self.damageable = Damageable.new(data.damage, player.ragdoll)
	add_child(damageable)
	self.damageable.owner = self
	
	# Construct the node
	sprite.texture = projectile_data.sprite
	# HACK: Hardcoded the scale value for the sprite because it cannot be scaled down normally
	sprite.scale = Vector2(0.25, 0.25)
	
	# Set the hitbox and damagable to self, this is used for like checking if the owner of the hitbox has a node damageable
	sprite.owner = self
	collision_shape.owner = self
	damageable.owner = self

## Call to summon if this is a projectile and apply one time impulse to move it forward
func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	self.direction = direction
	self.position = position
	sprite.rotation = direction.angle()
	collision_shape.rotation = direction.angle()

## (Copied from GameObject class)
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

func _on_game_tick(delta: float):
	self.colliding_bodies = get_overlapping_bodies()

func serialize_object_data(id: int) -> PackedFloat32Array:
	var data : PackedFloat32Array = PackedFloat32Array()
	data.append(SystemManager.PACKET_TYPE.GAME_AREA)
	data.append(float(multiplayer_id))
	# this is id to identify the class name of the projectile, will need to be set by the child classes
	data.append(float(id))
	
	data.append(self.position.x)
	data.append(self.position.y)
	data.append(self.rotation)
	data.append(direction.x)
	data.append(direction.y)
	
	# TODO: 9th value for player, will finish later on
	data.append(0.0)
	return data

func deserialize_object_data(data: PackedFloat32Array) -> bool:
	if data.get(0) != SystemManager.PACKET_TYPE.GAME_AREA:
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
	self.direction.x = data.get(i + 3)
	self.direction.y = data.get(i + 4)
	i = 8
	#data.get(i) then do something for player
	
	return true

## Get the colliding bodies of this area instead of accessing the value directly
func get_colliding_bodies():
	return colliding_bodies

## Standarlized function for any Damageable stuff
func get_damage():
	return damageable.damage_tick

func qfree():
	self.queue_free()
