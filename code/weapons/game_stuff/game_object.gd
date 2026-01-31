## Base class for general game objects that isnt player or weapons
## Not for using directly, only make a subclass of this class like abilities
## Projectile objects are objects that work and move independently other than players and weapons
## Will runs on its own tick but still based on the the world tick event

# Because they use both rigid body2d as base
extends RigidBody2D
class_name GameObject

## Owner of this object if exist
var player: Player

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

## Dumb setting to set if the projectile is cleared when the round clear or not. Default to true now
var clear_object_on_round_clear : bool = true

## Initializing the object with basic data like player, direction and position
## Player is for calculating the optional Damageable object so it can be nulled if not needed
## Direction and position can be empty vectors
func _init(player: Player, direction: Vector2, position: Vector2) -> void:
	GameState.clear_round.connect(_on_game_state_clear_round)
	self.player = player
	var collision_shape : CollisionShape2D = CollisionShape2D.new()
	sprite = Sprite2D.new()
	collision_shape.shape = hitbox_shape
	add_child(collision_shape)
	add_child(sprite)
	
	self.direction = direction
	self.position = position

## Inject ProjectileData class if this class is considered a projectile
func add_projectile_data(data: ProjectileData):
	self.projectile_data = data
	# Seperate the projectile from the wall if it can pass
	if projectile_data.can_go_through_wall:
		self.add_collision_exception_with(SystemManager.game_map)
		self.set_collision_mask_value(3, false)
	# Take the damage value from the projectile data
	self.damageable = Damageable.new(data.damage, player.ragdoll)
	# Adding the hitbox to the class
	self.hitbox_shape = data.hitbox

## Add the hitbox shape area for this
func add_hitbox_shape_data(hitbox: Shape2D):
	self.hitbox = hitbox

## Call to summon if this is a projectile and apply one time impulse to move it forward
func summon_as_projectile(direction: Vector2, position: Vector2) -> void:
	# Construct the node
	var collision : CollisionShape2D = CollisionShape2D.new()
	collision.shape = self.hitbox_shape
	print("GO/set sprite ", projectile_data, " texture ", projectile_data.sprite)
	sprite.texture = projectile_data.sprite
	# HACK: Hardcoded the scale value for the sprite because it cannot be scaled down normally
	sprite.scale = Vector2(0.25, 0.25)
	# Adding projectile
	add_child(collision)
	damageable = Damageable.new(projectile_data.damage, player)
	add_child(damageable)
	
	# Set the hitbox and damagable to self, this is used for like checking if the owner of the hitbox has a node damageable
	sprite.owner = self
	collision.owner = self
	damageable.owner = self
	
	self.direction = direction
	self.position = position
	
	# Nullify the gravity if like its not affected
	if projectile_data.is_affected_by_gravity:
		self.gravity_scale = 0.5
	else:
		self.gravity_scale = 0.0
	
	# Enable collision detection
	self.contact_monitor = true
	self.max_contacts_reported = 100
		
	# Make the projectile doesnt touch the owner
	for child in damageable.owner_stickman.ragdoll.get_children():
		self.add_collision_exception_with(child)
	self.add_collision_exception_with(damageable.owner_stickman.weapon.hitbox)
	
	# Shooting the projectile
	self.apply_central_impulse(direction * projectile_data.speed)

func _ready() -> void:
	GameState.game_tick.connect(_on_game_tick)

func get_damage() -> int:
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
		_on_destroy()
	# Same thing but the previous is_dead_check is like not reliable somehow
	if (not is_instance_valid(player)):
		return null
		_on_destroy()
	return player

## Runs when the global physics tick is ticking
func _on_game_tick(delta: float):
	print("GO/delta is ", delta)
	pass

## Automatically delete this object when the round end, unless otherwise configured
func _on_game_state_clear_round():
	if clear_object_on_round_clear:
		_on_destroy()

## Call to destroy the object
func _on_destroy():
	self.queue_free()
