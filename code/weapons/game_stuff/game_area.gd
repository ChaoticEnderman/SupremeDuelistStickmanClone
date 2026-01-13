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
	GameState.clear_round.connect(_on_game_state_clear_round)
	GameState.game_tick.connect(_on_game_tick)
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
	add_child(collision_shape)
	
	self.collision_shape.owner = self

## Inject ProjectileData class if this class is considered a projectile
## (rarer than GameObject based projectiles)
func add_projectile_data(data: ProjectileData):
	self.projectile_data = data
	# Take the damage value from the projectile data
	self.damageable = Damageable.new(data.damage, player.ragdoll)
	add_child(damageable)
	self.damageable.owner = self

## Call to summon if this is a projectile and apply one time impulse to move it forward
func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	# Construct the node
	var collision : CollisionShape2D = CollisionShape2D.new()
	collision.shape = self.shape
	sprite.texture = projectile_data.sprite
	# HACK: Hardcoded the scale value for the sprite because it cannot be scaled down normally
	sprite.scale = Vector2(0.25, 0.25)
	# Adding projectile
	add_child(collision)
	
	# Set the hitbox and damagable to self, this is used for like checking if the owner of the hitbox has a node damageable
	sprite.owner = self
	collision.owner = self
	damageable.owner = self
	
	self.direction = direction
	self.position = position

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
		_on_destroy()
	# Same thing but the previous is_dead_check is like not reliable somehow
	if (not is_instance_valid(player)):
		return null
		_on_destroy()
	return player

func _on_game_tick(delta: float):
	self.colliding_bodies = get_overlapping_bodies()

## Get the colliding bodies of this area instead of accessing the value directly
func get_colliding_bodies():
	return colliding_bodies

## Standarlized function for any Damageable stuff
func get_damage():
	return damageable.damage_tick

## Automatically delete this object when the round end, unless otherwise configured
# TODO: Add this configuration as optional, maybe as a bool variable
func _on_game_state_clear_round():
	_on_destroy()

## Call to destroy the object
func _on_destroy():
	self.queue_free()
