## Generates a test room with walls for movement testing.
##
## WHY THIS EXISTS:
## Tilemaps are normally painted in Godot's editor (visual drag-and-drop).
## Since we're setting up the project from code files, we generate a simple
## room programmatically. Once you open this in Godot, you can replace this
## with a hand-painted TileMap and delete this script.
##
## KEY CONCEPT: Node2D and _draw()
## Every Node2D can override _draw() to render custom graphics.
## This is Godot's equivalent of "immediate mode" drawing.
## We use it here to draw colored rectangles as our placeholder tiles.

extends Node2D

## Room dimensions in tiles
@export var room_width: int = 15
@export var room_height: int = 11
@export var tile_size: int = 32

## Colors for our placeholder tiles
const FLOOR_COLOR := Color(0.15, 0.15, 0.2, 1.0)   # Dark blue-gray
const WALL_COLOR := Color(0.4, 0.3, 0.2, 1.0)      # Brown
const OBSTACLE_COLOR := Color(0.3, 0.25, 0.15, 1.0) # Darker brown

## Store which tiles are walls (for collision with player's raycast)
var wall_bodies: Array[StaticBody2D] = []


func _ready() -> void:
	_generate_room()
	_spawn_player()


func _spawn_player() -> void:
	## Load and instantiate the player scene, then add it to this scene.
	## preload() loads the resource at compile time (fast, no runtime delay).
	## instantiate() creates a live instance of the packed scene.
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if not player_scene:
		push_error("[TestRoom] Failed to load player scene")
		return
	var player: Node = player_scene.instantiate()
	player.position = Vector2(160, 160)  # Start in the middle-ish of the room
	get_parent().add_child(player)  # Add to parent (TestMovement node) not self


func _generate_room() -> void:
	## Builds a simple room: floor everywhere, walls on borders, a few obstacles.
	## Each wall gets a StaticBody2D so the player's RayCast2D can detect them.
	##
	## StaticBody2D: A physics body that doesn't move but blocks other bodies.
	## Think of it like a wall in a physics simulation — it's there, it's solid,
	## but it never moves on its own.
	
	for y in range(room_height):
		for x in range(room_width):
			var is_wall: bool = _is_wall_tile(x, y)
			
			if is_wall:
				_create_wall(x, y)


func _is_wall_tile(x: int, y: int) -> bool:
	## Determines if a tile should be a wall.
	## Border tiles are always walls. A few interior tiles too for obstacles.
	
	# Border walls
	if x == 0 or x == room_width - 1:
		return true
	if y == 0 or y == room_height - 1:
		return true
	
	# Interior obstacles — just some hardcoded positions for testing
	var obstacles := [
		Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5),  # Vertical wall
		Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6), # Horizontal wall
		Vector2i(3, 8), Vector2i(7, 2),                    # Single blocks
	]
	
	return Vector2i(x, y) in obstacles


func _create_wall(x: int, y: int) -> void:
	## Creates a visible wall tile with a collision body.
	##
	## Node hierarchy for each wall:
	##   StaticBody2D (physics — blocks raycasts and movement)
	##     └── CollisionShape2D (defines the shape of the collision)
	##
	## We also use _draw() below to render all tiles visually.
	
	var body := StaticBody2D.new()  # .new() = instantiate (like Python's ClassName())
	body.position = Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0)
	
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile_size, tile_size)
	shape.shape = rect
	
	body.add_child(shape)    # Parent-child relationship (scene tree composition)
	add_child(body)          # Add to our node so it's in the scene tree
	wall_bodies.append(body)


func _draw() -> void:
	## _draw() renders custom visuals every frame (when queue_redraw() is called)
	## or once on ready. We draw the floor and wall tiles as colored rectangles.
	##
	## draw_rect(Rect2, Color, filled) — draws a rectangle at a position.
	## Rect2(position, size) defines a rectangle in 2D space.
	
	for y in range(room_height):
		for x in range(room_width):
			var rect := Rect2(
				Vector2(x * tile_size, y * tile_size),
				Vector2(tile_size, tile_size)
			)
			
			if _is_wall_tile(x, y):
				draw_rect(rect, WALL_COLOR, true)
				# Draw a slightly smaller inner rect for visual depth
				var inner := rect.grow(-2)
				draw_rect(inner, OBSTACLE_COLOR, true)
			else:
				draw_rect(rect, FLOOR_COLOR, true)
				# Draw subtle grid lines
				draw_rect(rect, Color(0.2, 0.2, 0.25, 1.0), false)
