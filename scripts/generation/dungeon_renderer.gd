## DungeonRenderer — Draws a generated dungeon floor with improved visuals.

extends Node2D

const TILE_SIZE: int = 32

## Richer dungeon palette
const COLOR_FLOOR := Color(0.14, 0.12, 0.2)       # Dark purple-blue
const COLOR_FLOOR_ALT := Color(0.16, 0.13, 0.22)  # Subtle variation
const COLOR_WALL := Color(0.3, 0.22, 0.14)        # Warm brown stone
const COLOR_WALL_TOP := Color(0.36, 0.27, 0.17)   # Lighter top edge (fake 3D)
const COLOR_WALL_DARK := Color(0.2, 0.14, 0.08)   # Dark bottom edge
const COLOR_DOOR := Color(0.45, 0.35, 0.2)        # Golden brown door
const COLOR_GRID := Color(1.0, 1.0, 1.0, 0.02)    # Very subtle grid

var generator: FloorGenerator = null
var wall_bodies: Array[StaticBody2D] = []


func setup(gen: FloorGenerator) -> void:
	generator = gen
	_create_wall_collisions()
	queue_redraw()


func _create_wall_collisions() -> void:
	for body in wall_bodies:
		body.queue_free()
	wall_bodies.clear()
	
	if not generator:
		return
	
	for y in range(generator.floor_height):
		for x in range(generator.floor_width):
			if generator.get_tile(x, y) == RoomTemplate.WALL:
				var body := StaticBody2D.new()
				body.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE, TILE_SIZE)
				shape.shape = rect
				body.add_child(shape)
				add_child(body)
				wall_bodies.append(body)


func _draw() -> void:
	if not generator:
		return
	
	for y in range(generator.floor_height):
		for x in range(generator.floor_width):
			var tile: int = generator.get_tile(x, y)
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var rect := Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
			
			if tile == RoomTemplate.WALL:
				_draw_wall_tile(pos)
			elif tile == RoomTemplate.DOOR:
				draw_rect(rect, COLOR_DOOR, true)
				# Door frame edges
				draw_rect(Rect2(pos, Vector2(TILE_SIZE, 2)), COLOR_WALL_DARK, true)
				draw_rect(Rect2(pos + Vector2(0, TILE_SIZE - 2), Vector2(TILE_SIZE, 2)), COLOR_WALL_DARK, true)
			else:
				# Floor with subtle checkerboard pattern
				var use_alt: bool = (x + y) % 2 == 0
				draw_rect(rect, COLOR_FLOOR_ALT if use_alt else COLOR_FLOOR, true)
				draw_rect(rect, COLOR_GRID, false)
	
	# Chest markers — golden with dark outline
	for chest_pos in generator.chest_spawn_points:
		var cp := Vector2(chest_pos.x * TILE_SIZE + 6, chest_pos.y * TILE_SIZE + 6)
		var chest_rect := Rect2(cp, Vector2(TILE_SIZE - 12, TILE_SIZE - 12))
		draw_rect(chest_rect.grow(1), Color(0.4, 0.3, 0.0), true)  # Dark outline
		draw_rect(chest_rect, Color(0.95, 0.8, 0.2), true)         # Gold fill
		# Latch detail
		draw_rect(Rect2(cp + Vector2(7, 0), Vector2(6, 3)), Color(0.6, 0.5, 0.1), true)
	
	# Exit marker — glowing green stairs
	if generator.exit_position != Vector2i.ZERO:
		var ep := Vector2(generator.exit_position.x * TILE_SIZE + 4, generator.exit_position.y * TILE_SIZE + 4)
		var exit_rect := Rect2(ep, Vector2(TILE_SIZE - 8, TILE_SIZE - 8))
		draw_rect(exit_rect.grow(2), Color(0.1, 0.5, 0.1, 0.5), true)  # Glow
		draw_rect(exit_rect, Color(0.2, 0.9, 0.3), true)               # Bright green
		# Stair lines
		for i in range(3):
			var sy: float = ep.y + 6 + i * 6
			draw_rect(Rect2(Vector2(ep.x + 4, sy), Vector2(TILE_SIZE - 16, 2)), Color(0.1, 0.6, 0.2), true)


func _draw_wall_tile(pos: Vector2) -> void:
	## Draw a wall tile with fake 3D depth (lighter top, darker bottom).
	var rect := Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
	
	# Main fill
	draw_rect(rect, COLOR_WALL, true)
	
	# Top highlight (2px lighter strip)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 3)), COLOR_WALL_TOP, true)
	
	# Bottom shadow (2px darker strip)
	draw_rect(Rect2(pos + Vector2(0, TILE_SIZE - 3), Vector2(TILE_SIZE, 3)), COLOR_WALL_DARK, true)
	
	# Subtle brick pattern
	var brick_color := Color(0.0, 0.0, 0.0, 0.08)
	draw_rect(Rect2(pos + Vector2(0, TILE_SIZE / 2.0), Vector2(TILE_SIZE, 1)), brick_color, true)
	draw_rect(Rect2(pos + Vector2(TILE_SIZE / 2.0, 0), Vector2(1, TILE_SIZE / 2.0)), brick_color, true)
	draw_rect(Rect2(pos + Vector2(TILE_SIZE / 4.0, TILE_SIZE / 2.0), Vector2(1, TILE_SIZE / 2.0)), brick_color, true)
