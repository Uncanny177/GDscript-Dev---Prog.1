## FloorGenerator — Procedurally assembles rooms into a dungeon floor.
## Graph-based: rooms placed on a grid via random walk, connected by corridors.
## FIXED: Guarantees all rooms are connected and exit is always reachable.

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
	exit_position = Vector2i.ZERO
	
	_place_rooms(room_count, floor_number)
	_build_floor_tiles()
	
	# Guarantee exit exists — if not placed from template, force one
	if exit_position == Vector2i.ZERO:
		_force_exit_position()
	
	print("[FloorGenerator] Generated floor %d: %d rooms, %dx%d tiles, exit=%s, seed=%d" % [
		floor_number, placed_rooms.size(), floor_width, floor_height, str(exit_position), rng.seed
	])


func _place_rooms(count: int, floor_number: int) -> void:
	var grid_size: int = 7
	var occupied: Dictionary = {}  # Vector2i → room index
	
	var start_rooms: Array = RoomTemplatesData.get_start_rooms()
	var corridors: Array = RoomTemplatesData.get_corridor_rooms()
	var small_rooms: Array = RoomTemplatesData.get_small_rooms()
	var large_rooms: Array = RoomTemplatesData.get_large_rooms()
	var treasure_rooms: Array = RoomTemplatesData.get_treasure_rooms()
	var exit_rooms: Array = RoomTemplatesData.get_exit_rooms()
	var boss_rooms: Array = RoomTemplatesData.get_boss_rooms()
	
	@warning_ignore("integer_division")
	var center := Vector2i(grid_size / 2, grid_size / 2)  # Integer division intentional
	var start_template: RoomTemplate = start_rooms[rng.randi() % start_rooms.size()]
	_place_room_at(start_template, center)
	occupied[center] = 0
	
	# Random walk to place rooms — each new room is always adjacent to the last
	var current_pos: Vector2i = center
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var rooms_placed: int = 1
	var attempts: int = 0
	var max_attempts: int = count * 20  # More attempts to ensure placement
	
	while rooms_placed < count and attempts < max_attempts:
		attempts += 1
		var dir: Vector2i = directions[rng.randi() % directions.size()]
		var new_pos: Vector2i = current_pos + dir
		
		if new_pos.x < 0 or new_pos.x >= grid_size or new_pos.y < 0 or new_pos.y >= grid_size:
			continue
		if occupied.has(new_pos):
			current_pos = new_pos  # Walk to it (helps explore the grid)
			continue
		
		var template: RoomTemplate = _pick_room_template(rooms_placed, count, floor_number, corridors, small_rooms, large_rooms, treasure_rooms)
		_place_room_at(template, new_pos)
		occupied[new_pos] = placed_rooms.size() - 1
		current_pos = new_pos
		rooms_placed += 1
	
	# Place exit/boss room — find farthest empty cell ADJACENT to an occupied cell
	var farthest_pos: Vector2i = _find_farthest_empty(center, occupied, grid_size)
	
	# Fallback: if no empty adjacent cell, use the last placed position as exit
	if farthest_pos == Vector2i(-1, -1):
		# Replace the last placed room with the exit room
		farthest_pos = current_pos
		# Remove the last room and replace it
		if placed_rooms.size() > 1:
			placed_rooms.pop_back()
			occupied.erase(farthest_pos)
	
	var is_final_floor: bool = floor_number >= 5
	var end_template: RoomTemplate
	if is_final_floor and not boss_rooms.is_empty():
		end_template = boss_rooms[rng.randi() % boss_rooms.size()]
	elif not exit_rooms.is_empty():
		end_template = exit_rooms[rng.randi() % exit_rooms.size()]
	else:
		end_template = small_rooms[0]
	
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
		@warning_ignore("integer_division")
		var desired := Vector2i(offset.x + template.width / 2, offset.y + template.height / 2)
		# Ensure the spawn is actually on a FLOOR tile (not a wall/feature).
		player_start = _find_nearest_floor(desired)
	
	_connect_rooms()


func _find_nearest_floor(from: Vector2i) -> Vector2i:
	## Find the closest FLOOR tile to a target position using expanding rings.
	## Prevents spawning inside walls when a room's center isn't walkable.
	if _is_floor_tile(from):
		return from
	# Expand outward in rings until we hit a floor tile
	for radius in range(1, 20):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				# Only check the ring edge, not the filled interior
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var check := Vector2i(from.x + dx, from.y + dy)
				if _is_floor_tile(check):
					return check
	return from  # Fallback (shouldn't happen)


func _is_floor_tile(pos: Vector2i) -> bool:
	## True if the tile at pos is a walkable FLOOR tile within bounds.
	if pos.y < 0 or pos.y >= floor_tiles.size():
		return false
	if pos.x < 0 or pos.x >= floor_tiles[pos.y].size():
		return false
	return floor_tiles[pos.y][pos.x] == RoomTemplate.FLOOR


func _connect_rooms() -> void:
	## Connect ALL adjacent rooms by carving corridors between their doors.
	## Also ensures connectivity by connecting any disconnected rooms to their
	## nearest neighbor via straight-line carve.
	
	# First pass: connect rooms that are grid-adjacent and have matching doors
	for i in range(placed_rooms.size()):
		for j in range(i + 1, placed_rooms.size()):
			var room_a: Dictionary = placed_rooms[i]
			var room_b: Dictionary = placed_rooms[j]
			var grid_a: Vector2i = room_a["grid_pos"]
			var grid_b: Vector2i = room_b["grid_pos"]
			
			# Only connect directly adjacent rooms (manhattan distance 1)
			var manhattan: int = absi(grid_b.x - grid_a.x) + absi(grid_b.y - grid_a.y)
			if manhattan != 1:
				continue
			
			var dir: Vector2i = grid_b - grid_a
			var door_a: Vector2i = _find_door_facing(room_a, dir)
			var door_b: Vector2i = _find_door_facing(room_b, -dir)
			
			if door_a != Vector2i(-1, -1) and door_b != Vector2i(-1, -1):
				_carve_path(door_a, door_b)
			else:
				# No matching doors — force a connection through room centers
				var center_a := Vector2i(
					room_a["world_offset"].x + room_a["template"].width / 2,
					room_a["world_offset"].y + room_a["template"].height / 2
				)
				var center_b := Vector2i(
					room_b["world_offset"].x + room_b["template"].width / 2,
					room_b["world_offset"].y + room_b["template"].height / 2
				)
				_carve_path(center_a, center_b)
	
	# Second pass: ensure ALL rooms are reachable from the start room
	# Using flood fill to detect disconnected rooms
	var reachable: Array[int] = _flood_fill_rooms()
	if reachable.size() < placed_rooms.size():
		# Some rooms are disconnected — connect them
		for i in range(placed_rooms.size()):
			if i in reachable:
				continue
			# Connect disconnected room to nearest reachable room
			var disconnected: Dictionary = placed_rooms[i]
			var nearest_idx: int = _find_nearest_reachable(i, reachable)
			if nearest_idx >= 0:
				var nearest: Dictionary = placed_rooms[nearest_idx]
				var center_a := Vector2i(
					disconnected["world_offset"].x + disconnected["template"].width / 2,
					disconnected["world_offset"].y + disconnected["template"].height / 2
				)
				var center_b := Vector2i(
					nearest["world_offset"].x + nearest["template"].width / 2,
					nearest["world_offset"].y + nearest["template"].height / 2
				)
				_carve_path(center_a, center_b)
				reachable.append(i)


func _flood_fill_rooms() -> Array[int]:
	## Returns indices of all rooms reachable from room 0 via floor tiles.
	if placed_rooms.is_empty():
		return []
	
	var start: Vector2i = player_start
	var visited: Dictionary = {}  # Vector2i → true
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	
	# BFS through floor tiles
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = pos + dir
			if visited.has(next):
				continue
			if next.x < 0 or next.x >= floor_width or next.y < 0 or next.y >= floor_height:
				continue
			if floor_tiles[next.y][next.x] != RoomTemplate.WALL:
				visited[next] = true
				queue.append(next)
	
	# Check which rooms have their center reachable
	var reachable: Array[int] = []
	for i in range(placed_rooms.size()):
		var room: Dictionary = placed_rooms[i]
		var center := Vector2i(
			room["world_offset"].x + room["template"].width / 2,
			room["world_offset"].y + room["template"].height / 2
		)
		if visited.has(center):
			reachable.append(i)
	
	return reachable


func _find_nearest_reachable(room_idx: int, reachable: Array[int]) -> int:
	## Find the closest reachable room to the given disconnected room.
	var room: Dictionary = placed_rooms[room_idx]
	var room_grid: Vector2i = room["grid_pos"]
	var best_idx: int = -1
	var best_dist: float = 999.0
	
	for idx in reachable:
		var other_grid: Vector2i = placed_rooms[idx]["grid_pos"]
		var dist: float = room_grid.distance_to(other_grid)
		if dist < best_dist:
			best_dist = dist
			best_idx = idx
	
	return best_idx


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
	## Carve an L-shaped corridor between two points.
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
	# Final tile
	if x >= 0 and x < floor_width and y >= 0 and y < floor_height:
		if floor_tiles[y][x] == RoomTemplate.WALL:
			floor_tiles[y][x] = RoomTemplate.FLOOR


func _force_exit_position() -> void:
	## If no exit was placed via template EVENT tiles, force one.
	## Places exit in the last room's center (farthest from start).
	if placed_rooms.size() < 2:
		# Only one room — put exit at opposite corner from player
		exit_position = Vector2i(player_start.x + 5, player_start.y + 5)
		exit_position = exit_position.clamp(Vector2i.ONE, Vector2i(floor_width - 2, floor_height - 2))
		floor_tiles[exit_position.y][exit_position.x] = RoomTemplate.FLOOR
		return
	
	# Use the last placed room's center as exit
	var last_room: Dictionary = placed_rooms[placed_rooms.size() - 1]
	var offset: Vector2i = last_room["world_offset"]
	var template: RoomTemplate = last_room["template"]
	@warning_ignore("integer_division")
	exit_position = Vector2i(offset.x + template.width / 2, offset.y + template.height / 2)  # Integer division intentional
	
	# Ensure exit tile is floor
	if exit_position.x >= 0 and exit_position.x < floor_width and exit_position.y >= 0 and exit_position.y < floor_height:
		floor_tiles[exit_position.y][exit_position.x] = RoomTemplate.FLOOR


func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= floor_width or y < 0 or y >= floor_height:
		return RoomTemplate.WALL
	return floor_tiles[y][x]
