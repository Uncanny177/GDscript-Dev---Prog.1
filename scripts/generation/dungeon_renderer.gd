## DungeonRenderer — Draws a generated dungeon floor with improved visuals.

extends Node2D

const TILE_SIZE: int = 32

## Biome-specific colors (set from dungeon.gd based on floor)
var floor_color: Color = Color(0.14, 0.12, 0.2)
var floor_alt_color: Color = Color(0.16, 0.13, 0.22)
var wall_color: Color = Color(0.3, 0.22, 0.14)
var wall_top_color: Color = Color(0.36, 0.27, 0.17)
var wall_dark_color: Color = Color(0.2, 0.14, 0.08)
var door_color: Color = Color(0.45, 0.35, 0.2)

var generator: FloorGenerator = null
var wall_bodies: Array[StaticBody2D] = []


func setup(gen: FloorGenerator, biome: BiomeData = null) -> void:
	generator = gen
	if biome:
		floor_color = biome.floor_color
		floor_alt_color = biome.floor_alt_color
		wall_color = biome.wall_color
		wall_top_color = biome.wall_top_color
		wall_dark_color = biome.wall_dark_color
		door_color = biome.door_color
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
				draw_rect(rect, door_color, true)
				draw_rect(Rect2(pos, Vector2(TILE_SIZE, 2)), wall_dark_color, true)
				draw_rect(Rect2(pos + Vector2(0, TILE_SIZE - 2), Vector2(TILE_SIZE, 2)), wall_dark_color, true)
			else:
				var use_alt: bool = (x + y) % 2 == 0
				draw_rect(rect, floor_alt_color if use_alt else floor_color, true)
				draw_rect(rect, Color(1.0, 1.0, 1.0, 0.02), false)
	
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
	var rect := Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE))
	draw_rect(rect, wall_color, true)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 3)), wall_top_color, true)
	draw_rect(Rect2(pos + Vector2(0, TILE_SIZE - 3), Vector2(TILE_SIZE, 3)), wall_dark_color, true)
	var brick_color := Color(0.0, 0.0, 0.0, 0.08)
	draw_rect(Rect2(pos + Vector2(0, TILE_SIZE / 2.0), Vector2(TILE_SIZE, 1)), brick_color, true)
	draw_rect(Rect2(pos + Vector2(TILE_SIZE / 2.0, 0), Vector2(1, TILE_SIZE / 2.0)), brick_color, true)
	draw_rect(Rect2(pos + Vector2(TILE_SIZE / 4.0, TILE_SIZE / 2.0), Vector2(1, TILE_SIZE / 2.0)), brick_color, true)
