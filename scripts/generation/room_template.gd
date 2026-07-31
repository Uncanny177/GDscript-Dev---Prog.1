## RoomTemplate — Defines a single room's layout as tile data.
##
## KEY CONCEPT: DATA-DRIVEN LEVEL DESIGN
## Instead of generating random noise, we hand-craft small rooms and then
## PROCEDURALLY ARRANGE them into a floor. This gives us:
##   - Control over individual room quality (no ugly random artifacts)
##   - Variety through recombination (7 rooms → hundreds of unique floors)
##   - Easy to add new content (make a new room template, add to pool)
##
## Each room is a 2D grid of tile types with defined entry/exit points
## (doors) that the generator uses to connect rooms together.
##
## TILE TYPES:
##   0 = Floor (walkable)
##   1 = Wall (solid, blocks movement)
##   2 = Door (connection point to other rooms)
##   3 = Chest spawn point
##   4 = Enemy spawn point
##   5 = Event/special tile

class_name RoomTemplate
extends RefCounted

## Tile type constants
const FLOOR: int = 0
const WALL: int = 1
const DOOR: int = 2
const CHEST: int = 3
const ENEMY: int = 4
const EVENT: int = 5

## Room category — used by the generator to pick appropriate rooms
enum RoomType {
	START,
	CORRIDOR,
	SMALL,
	LARGE,
	TREASURE,
	BOSS,
	EXIT
}

## The room's tile grid (2D array of ints matching constants above)
var tiles: Array = []

## Room dimensions
var width: int = 0
var height: int = 0

## What type of room this is
var room_type: RoomType = RoomType.SMALL

## Door positions (Vector2i) — where this room can connect to others
var doors: Array[Vector2i] = []

## Human-readable name for debugging
var template_name: String = "unnamed"


func set_from_strings(lines: Array[String], type: RoomType, p_name: String) -> void:
	## Parse a room from an array of strings (visual/readable format).
	## Characters: . = floor, # = wall, D = door, C = chest, E = enemy, ? = event
	
	template_name = p_name
	room_type = type
	tiles.clear()
	doors.clear()
	
	height = lines.size()
	width = lines[0].length() if height > 0 else 0
	
	for y in range(height):
		var row: Array[int] = []
		for x in range(lines[y].length()):
			var ch: String = lines[y][x]
			var tile: int = _char_to_tile(ch)
			row.append(tile)
			if tile == DOOR:
				doors.append(Vector2i(x, y))
		tiles.append(row)


func get_tile(x: int, y: int) -> int:
	## Get tile at position. Returns WALL if out of bounds.
	if x < 0 or x >= width or y < 0 or y >= height:
		return WALL
	return tiles[y][x]


func _char_to_tile(ch: String) -> int:
	match ch:
		".": return FLOOR
		"#": return WALL
		"D": return DOOR
		"C": return CHEST
		"E": return ENEMY
		"?": return EVENT
		_: return WALL


func _to_string() -> String:
	return "%s (%dx%d, %d doors)" % [template_name, width, height, doors.size()]
