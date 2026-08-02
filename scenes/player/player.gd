## Player controller for grid-based movement.
##
## KEY CONCEPTS FOR YOU:
## - extends CharacterBody2D: This is Godot's physics-aware node for characters.
##   Think of it like inheriting from a base class that already handles collisions.
## - @export: Makes a variable editable in Godot's Inspector panel (like a public
##   property in Unity). Designers can tweak values without touching code.
## - @onready: Initializes when the node enters the scene tree. Similar to
##   __init__ running after the object is fully constructed and connected.
## - $NodeName: Shorthand for get_node("NodeName") — accesses child nodes by name.
##   Like self.child in a tree structure.
## - _physics_process(delta): Called every physics frame (~60fps). This is where
##   movement logic lives. `delta` is time since last frame (for framerate independence).
## - Input.is_action_just_pressed(): Checks if a key was pressed THIS frame only.
##   "just_pressed" vs "is_pressed" = single tap vs holding down.

extends CharacterBody2D

## How big each grid cell is in pixels. Our tiles are 32x32.
## @export lets us change this in the editor without editing code.
@export var tile_size: int = 32

## How fast the player visually slides between tiles (pixels per second).
## The movement is still grid-locked, but this makes it look smooth.
@export var move_speed: float = 200.0

## Are we currently sliding between tiles? If yes, ignore new inputs.
## This prevents the player from "queuing" moves while mid-step.
var is_moving: bool = false

## Where are we headed? Used during the tween (smooth slide).
var target_position: Vector2 = Vector2.ZERO

## Reference to the RayCast2D node that checks for walls ahead.
## @onready means this runs when the node is ready (child nodes exist).
## Without @onready, $RayCast2D would be null because children aren't loaded yet.
@onready var ray: RayCast2D = $RayCast2D


func _ready() -> void:
	## _ready() is called once when the node enters the scene tree.
	## Like __init__ but guaranteed all children are loaded.
	## Snap to tile CENTER (not edge). Tile centers are at n*32+16.
	## We offset by half-tile, snap to grid, then offset back.
	var half_tile := Vector2(tile_size / 2.0, tile_size / 2.0)
	position = (position - half_tile).snapped(Vector2(tile_size, tile_size)) + half_tile
	target_position = position


func _physics_process(_delta: float) -> void:
	## _physics_process runs every physics tick (~60fps by default).
	## We use it for movement because it syncs with the physics engine.
	## The underscore prefix on _delta means "I'm not using this parameter"
	## (GDScript convention, prevents unused variable warnings).
	
	if is_moving:
		return  # Already sliding to next tile, ignore input
	
	# Don't move if dialogue or UI is active
	# Check if any child node named "NPCInteraction" has an active dialogue or shop
	var interaction: Node = get_node_or_null("NPCInteraction")
	if interaction and interaction.dialogue_box and interaction.dialogue_box.is_active:
		return
	if interaction and interaction.shop_ui and interaction.shop_ui.is_active:
		return
	if interaction and interaction.guild_ui and interaction.guild_ui.is_active:
		return
	if interaction and interaction.town_hall_ui and interaction.town_hall_ui.is_active:
		return
	
	# Check for directional input — one direction at a time for clean grid movement
	var direction := _get_input_direction()
	
	if direction != Vector2.ZERO:
		_try_move(direction)


func _get_input_direction() -> Vector2:
	## Returns a unit vector for the pressed direction, or Vector2.ZERO if none.
	## We check one direction at a time (priority: up > down > left > right)
	## to prevent diagonal movement on a grid.
	##
	## Input.is_action_just_pressed() checks the input map we defined in
	## project.godot. This decouples the key binding from the code —
	## we can remap keys without changing scripts.
	
	if Input.is_action_just_pressed("move_up"):
		return Vector2.UP      # Vector2(0, -1) — Y is inverted in 2D!
	elif Input.is_action_just_pressed("move_down"):
		return Vector2.DOWN    # Vector2(0, 1)
	elif Input.is_action_just_pressed("move_left"):
		return Vector2.LEFT    # Vector2(-1, 0)
	elif Input.is_action_just_pressed("move_right"):
		return Vector2.RIGHT   # Vector2(1, 0)
	
	return Vector2.ZERO


func _try_move(direction: Vector2) -> void:
	## Attempts to move one tile in the given direction.
	## First checks for walls using a RayCast2D, then tweens to the target.
	##
	## RayCast2D: An invisible ray that detects collisions along a line.
	## We point it in our movement direction and ask "is anything there?"
	## This is how we check for walls WITHOUT actually moving into them.
	
	# Safety check — if ray node is missing, can't do collision detection
	if not ray:
		push_error("[Player] RayCast2D node not found — cannot check for walls")
		return
	
	# Point the raycast in the direction we want to move
	ray.target_position = direction * tile_size
	
	# force_raycast_update() makes the ray check RIGHT NOW instead of
	# waiting for the next physics frame. We need the result immediately.
	ray.force_raycast_update()
	
	# If the ray hit something (a wall tile), don't move
	if ray.is_colliding():
		return
	
	# No wall — initiate the move
	target_position = position + direction * tile_size
	is_moving = true
	
	# Tween = smooth interpolation over time.
	# Think of it as "animate this property from current value to target value".
	# create_tween() makes a new Tween attached to this node.
	var tween: Tween = create_tween()
	
	# tween_property(object, property, target_value, duration)
	# This smoothly moves our position to target_position over the calculated time.
	var move_duration: float = tile_size / move_speed
	tween.tween_property(self, "position", target_position, move_duration)
	
	# When the tween finishes, call _on_move_finished.
	# connect() with Callable is how you hook up signals in code.
	tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	## Called when the movement tween completes. Unlocks input for next move.
	## Snap to tile center to prevent floating-point drift.
	is_moving = false
	var half_tile := Vector2(tile_size / 2.0, tile_size / 2.0)
	position = (position - half_tile).snapped(Vector2(tile_size, tile_size)) + half_tile
