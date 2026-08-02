## FloorGenerator — Procedurally assembles rooms into a dungeon floor.
## Graph-based: rooms placed on a grid via random walk, connected by corridors.

class_name FloorGenerator
extends RefCounted

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var placed_rooms: Array = []
var floor_tiles: Array = []
var floor_width: int = 0
var floor_height: int = 0
const GRID_CELL_SIZE: int = 14
const BASE_ROOM_COUNT: int = 5
const ROOMS_PER_FLOOR: int = 2

var enemy_spawn_points: Array[Vector2i] = []
var chest_spawn_points: Array[Vector2i] = []
var player_start: Vector2i = Vector2i.ZERO
var exit_position: Vector2i = Vector2i.ZERO


func generate_floor(floor_number: int, seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	
	var room_count: int = mini(BASE_ROOM_COUNT + floor_number * ROOMS_PER_FLOOR, 12)
	placed_rooms.clear()
	enemy_spawn_points.clear()
	chest_spawn_points.clear()
	
	_place_rooms(room_count, floor_number)
	_build_floor_tiles()
	
	print("[FloorGenerator] Generated floor %d: %d rooms, %dx%d tiles, seed=%d" % [
		floor_number, placed_rooms.size(), floor_width, floor_height, rng.seed
	])


func _place_rooms(count: int, floor_number: int) -> void:
	var grid_size: int = 7
	var occupied: Dictionary = {}
	
	var start_rooms: Array = RoomTemplatesData.get_start_rooms()
	var corridors: Array = RoomTemplatesData.get_corridor_rooms()
	var small_rooms: Array = RoomTemplatesData.get_small_rooms()
	var large_rooms: Array = RoomTemplatesData.get_large_rooms()
	var treasure_rooms: Array = RoomTemplatesData.get_treasure_rooms()
	var exit_rooms: Array = RoomTemplatesData.get_exit_rooms()
	var boss_rooms: Array = RoomTemplatesData.get_boss_rooms()
	
	var center := Vector2i(grid_size / 2, grid_size / 2)  # Integer division intentional
	var start_template: RoomTemplate = start_rooms[rng.randi() % start_rooms.size()]
	_place_room_at(start_template, center)
	occupied[center] = 0
	
	var current_pos: Vector2i = center
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var rooms_placed: int = 1
	var attempts: int = 0
	var max_attempts: int = count * 10
	
	while rooms_placed < count and attempts < max_attempts:
		attempts += 1
		var dir: Vector2i = directions[rng.randi() % directions.size()]
		var new_pos: Vector2i = current_pos + dir
		
		if new_pos.x < 0 or new_pos.x >= grid_size or new_pos.y < 0 or new_pos.y >= grid_size:
			continue
		if occupied.has(new_pos):
			current_pos = new_pos
			continue
		
		var template: RoomTemplate = _pick_room_template(rooms_placed, count, floor_number, corridors, small_rooms, large_rooms, treasure_rooms)
		_place_room_at(template, new_pos)
		occupied[new_pos] = placed_rooms.size() - 1
		current_pos = new_pos
		rooms_placed += 1
	
	var farthest_pos: Vector2i = _find_farthest_empty(center, occupied, grid_size)
	if farthest_pos == Vector2i(-1, -1):
		farthest_pos = current_pos + directions[rng.randi() % directions.size()]
		farthest_pos = farthest_pos.clamp(Vector2i.ZERO, Vector2i(grid_size - 1, grid_size - 1))
	
	var is_final_floor: bool = floor_number >= 5
	var end_template: RoomTemplate
	if is_final_floor and not boss_rooms.is_empty():
		end_template = boss_rooms[rng.randi() % boss_rooms.size()]
	else:
		end_template = exit_rooms[rng.randi() % exit_rooms.size()] if not exit_rooms.is_empty() else small_rooms[0]
	
	if not occupied.has(farthest_pos):
		_place_room_at(end_template, farthest_pos)
		occupied[farthest_pos] = placed_rooms.size() - 1


func _pick_room_template(index: int, total: int, _floor_num: int, corridors: Array, smalls: Array, larges: Array, treasures: Array) -> RoomTemplate:
	var roll: int = rng.randi() % 100
	if index <= 2:
		if roll < 40:
			return corridors[rng.randi() % corridors.size()]
		else:
			return smalls[rng.randi() % smalls.size()]
	elif index >= total - 2:
		if roll < 30 and not treasures.is_empty():
			return treasures[rng.randi() % treasures.size()]
		elif roll < 60 and not larges.is_empty():
			return larges[rng.randi() % larges.size()]
		else:
			return smalls[rng.randi() % smalls.size()]
	else:
		if roll < 20:
			return corridors[rng.randi() % corridors.size()]
		elif roll < 50:
			return smalls[rng.randi() % smalls.size()]
		elif roll < 75 and not larges.is_empty():
			return larges[rng.randi() % larges.size()]
		elif not treasures.is_empty():
			return treasures[rng.randi() % treasures.size()]
		else:
			return smalls[rng.randi() % smalls.size()]


func _place_room_at(template: RoomTemplate, grid_pos: Vector2i) -> void:
	var world_offset := Vector2i(grid_pos.x * GRID_CELL_SIZE, grid_pos.y * GRID_CELL_SIZE)
	placed_rooms.append({"template": template, "grid_pos": grid_pos, "world_offset": world_offset})


func _find_farthest_empty(from: Vector2i, occupied: Dictionary, grid_size: int) -> Vector2i:
	var best_pos := Vector2i(-1, -1)
	var best_dist: float = 0.0
	for y in range(grid_size):
		for x in range(grid_size):
			var pos := Vector2i(x, y)
			if occupied.has(pos):
				continue
			var adjacent_to_room: bool = false
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if occupied.has(pos + dir):
					adjacent_to_room = true
					break
			if not adjacent_to_room:
				continue
			var dist: float = from.distance_to(pos)
			if dist > best_dist:
				best_dist = dist
				best_pos = pos
	return best_pos


func _build_floor_tiles() -> void:
	var max_x: int = 0
	var max_y: int = 0
	for room in placed_rooms:
		var offset: Vector2i = room["world_offset"]
		var template: RoomTemplate = room["template"]
		max_x = maxi(max_x, offset.x + template.width)
		max_y = maxi(max_y, offset.y + template.height)
	
	floor_width = max_x + 2
	floor_height = max_y + 2
	
	floor_tiles.clear()
	for y in range(floor_height):
		var row: Array[int] = []
		for x in range(floor_width):
			row.append(RoomTemplate.WALL)
		floor_tiles.append(row)
	
	for room in placed_rooms:
		var offset: Vector2i = room["world_offset"]
		var template: RoomTemplate = room["template"]
		for y in range(template.height):
			for x in range(template.width):
				var tile: int = template.get_tile(x, y)
				var fx: int = offset.x + x
				var fy: int = offset.y + y
				if fx < floor_width and fy < floor_height:
					floor_tiles[fy][fx] = tile
					if tile == RoomTemplate.ENEMY:
						enemy_spawn_points.append(Vector2i(fx, fy))
						floor_tiles[fy][fx] = RoomTemplate.FLOOR
					elif tile == RoomTemplate.CHEST:
						chest_spawn_points.append(Vector2i(fx, fy))
						floor_tiles[fy][fx] = RoomTemplate.FLOOR
					elif tile == RoomTemplate.EVENT:
						if template.room_type == RoomTemplate.RoomType.EXIT or template.room_type == RoomTemplate.RoomType.BOSS:
							exit_position = Vector2i(fx, fy)
						floor_tiles[fy][fx] = RoomTemplate.FLOOR
	
	if placed_rooms.size() > 0:
		var start_room: Dictionary = placed_rooms[0]
		var offset: Vector2i = start_room["world_offset"]
		var template: RoomTemplate = start_room["template"]
		player_start = Vector2i(offset.x + template.width / 2, offset.y + template.height / 2)  # Integer division intentional
	
	_connect_rooms()


func _connect_rooms() -> void:
	for i in range(placed_rooms.size()):
		for j in range(i + 1, placed_rooms.size()):
			var room_a: Dictionary = placed_rooms[i]
			var room_b: Dictionary = placed_rooms[j]
			var grid_a: Vector2i = room_a["grid_pos"]
			var grid_b: Vector2i = room_b["grid_pos"]
			if grid_a.distance_to(grid_b) > 1.5:
				continue
			var dir: Vector2i = grid_b - grid_a
			var door_a: Vector2i = _find_door_facing(room_a, dir)
			var door_b: Vector2i = _find_door_facing(room_b, -dir)
			if door_a != Vector2i(-1, -1) and door_b != Vector2i(-1, -1):
				_carve_path(door_a, door_b)


func _find_door_facing(room: Dictionary, direction: Vector2i) -> Vector2i:
	var template: RoomTemplate = room["template"]
	var offset: Vector2i = room["world_offset"]
	for door_local in template.doors:
		var is_match: bool = false
		if direction == Vector2i.RIGHT and door_local.x == template.width - 1:
			is_match = true
		elif direction == Vector2i.LEFT and door_local.x == 0:
			is_match = true
		elif direction == Vector2i.DOWN and door_local.y == template.height - 1:
			is_match = true
		elif direction == Vector2i.UP and door_local.y == 0:
			is_match = true
		if is_match:
			return offset + door_local
	return Vector2i(-1, -1)


func _carve_path(from: Vector2i, to: Vector2i) -> void:
	var x: int = from.x
	var y: int = from.y
	var step_x: int = 1 if to.x > from.x else -1
	while x != to.x:
		if x >= 0 and x < floor_width and y >= 0 and y < floor_height:
			if floor_tiles[y][x] == RoomTemplate.WALL:
				floor_tiles[y][x] = RoomTemplate.FLOOR
		x += step_x
	var step_y: int = 1 if to.y > from.y else -1
	while y != to.y:
		if x >= 0 and x < floor_width and y >= 0 and y < floor_height:
			if floor_tiles[y][x] == RoomTemplate.WALL:
				floor_tiles[y][x] = RoomTemplate.FLOOR
		y += step_y
	if x >= 0 and x < floor_width and y >= 0 and y < floor_height:
		if floor_tiles[y][x] == RoomTemplate.WALL:
			floor_tiles[y][x] = RoomTemplate.FLOOR


func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= floor_width or y < 0 or y >= floor_height:
		return RoomTemplate.WALL
	return floor_tiles[y][x]
