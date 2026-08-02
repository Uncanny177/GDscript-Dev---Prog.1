## DungeonRenderer — Draws a generated dungeon floor as colored tiles.
## Creates collision bodies for wall tiles so the player's RayCast2D works.

extends Node2D

const TILE_SIZE: int = 32

const COLORS := {
	0: Color(0.12, 0.1, 0.18),    # Floor
	1: Color(0.25, 0.2, 0.15),    # Wall
	2: Color(0.4, 0.3, 0.15),     # Door
}

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
			var rect := Rect2(Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
			var color: Color = COLORS.get(tile, COLORS[1])
			draw_rect(rect, color, true)
			if tile != RoomTemplate.WALL:
				draw_rect(rect, Color(1.0, 1.0, 1.0, 0.03), false)
	
	# Chest markers
	for chest_pos in generator.chest_spawn_points:
		var chest_rect := Rect2(Vector2(chest_pos.x * TILE_SIZE + 4, chest_pos.y * TILE_SIZE + 4), Vector2(TILE_SIZE - 8, TILE_SIZE - 8))
		draw_rect(chest_rect, Color(0.9, 0.8, 0.2), true)
	
	# Exit marker
	if generator.exit_position != Vector2i.ZERO:
		var exit_rect := Rect2(Vector2(generator.exit_position.x * TILE_SIZE + 2, generator.exit_position.y * TILE_SIZE + 2), Vector2(TILE_SIZE - 4, TILE_SIZE - 4))
		draw_rect(exit_rect, Color(0.3, 0.9, 0.3), true)
