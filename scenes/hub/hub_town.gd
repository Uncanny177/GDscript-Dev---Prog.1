## HubTown — Generates the hub town layout and spawns NPCs.
##
## This works like test_room_generator.gd — draws the town with colored
## rectangles and places collision bodies for walls. Later, you'd replace
## this with a hand-painted TileMap in the editor.
##
## NEW CONCEPTS IN THIS TASK:
## - Area2D: A detection zone (like a trigger volume in Unity/Unreal).
##   Doesn't block movement, just detects when something enters/exits.
## - Signals with connections: We connect Area2D.body_entered to know
##   when the player walks near an NPC.
## - CanvasLayer: UI layer that doesn't move with the camera.
##   Perfect for dialogue boxes, HUD, menus.

extends Node2D

## Town dimensions in tiles
const TILE_SIZE: int = 32
const TOWN_WIDTH: int = 20
const TOWN_HEIGHT: int = 15

## Tile types for the town map
enum Tile { FLOOR, WALL, BUILDING, PATH, DOOR }

## The town layout as a 2D array. Built in _ready().
var town_map: Array = []

## Colors for each tile type
const COLORS := {
	Tile.FLOOR: Color(0.2, 0.35, 0.15),     # Green (grass)
	Tile.WALL: Color(0.35, 0.25, 0.15),      # Brown (fences/walls)
	Tile.BUILDING: Color(0.3, 0.3, 0.35),    # Gray (buildings)
	Tile.PATH: Color(0.4, 0.35, 0.25),       # Tan (dirt path)
	Tile.DOOR: Color(0.5, 0.3, 0.1),         # Orange-brown (doors)
}


func _ready() -> void:
	_build_town_map()
	_create_walls()
	_spawn_npcs()
	_spawn_player()


func _build_town_map() -> void:
	## Define the town layout. This is a simple grid where each cell
	## is a tile type. Walls block movement, everything else is walkable.
	
	# Fill with grass
	for y in range(TOWN_HEIGHT):
		var row: Array = []
		for x in range(TOWN_WIDTH):
			row.append(Tile.FLOOR)
		town_map.append(row)
	
	# Border walls
	for x in range(TOWN_WIDTH):
		town_map[0][x] = Tile.WALL
		town_map[TOWN_HEIGHT - 1][x] = Tile.WALL
	for y in range(TOWN_HEIGHT):
		town_map[y][0] = Tile.WALL
		town_map[y][TOWN_WIDTH - 1] = Tile.WALL
	
	# Main path (horizontal through center)
	for x in range(1, TOWN_WIDTH - 1):
		town_map[7][x] = Tile.PATH
		town_map[8][x] = Tile.PATH
	
	# Vertical path to dungeon entrance (top)
	for y in range(1, 8):
		town_map[y][10] = Tile.PATH
		town_map[y][11] = Tile.PATH
	
	# SHOP building (top-left area)
	for y in range(2, 5):
		for x in range(2, 7):
			town_map[y][x] = Tile.BUILDING
	town_map[5][4] = Tile.DOOR  # Shop entrance
	
	# GUILD building (top-right area)
	for y in range(2, 5):
		for x in range(14, 19):
			town_map[y][x] = Tile.BUILDING
	town_map[5][16] = Tile.DOOR  # Guild entrance
	
	# BLACKSMITH area (bottom-left, just a small structure)
	for y in range(10, 13):
		for x in range(2, 6):
			town_map[y][x] = Tile.BUILDING
	town_map[10][4] = Tile.DOOR  # Blacksmith entrance
	
	# DUNGEON ENTRANCE marker (top center — a gap in the wall)
	town_map[0][10] = Tile.PATH
	town_map[0][11] = Tile.PATH


func _create_walls() -> void:
	## Create StaticBody2D collision for every non-walkable tile.
	## The player's RayCast2D will detect these to prevent walking through.
	
	for y in range(TOWN_HEIGHT):
		for x in range(TOWN_WIDTH):
			if town_map[y][x] == Tile.WALL or town_map[y][x] == Tile.BUILDING:
				var body := StaticBody2D.new()
				body.position = Vector2(
					x * TILE_SIZE + TILE_SIZE / 2,
					y * TILE_SIZE + TILE_SIZE / 2
				)
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE, TILE_SIZE)
				shape.shape = rect
				body.add_child(shape)
				add_child(body)


func _spawn_npcs() -> void:
	## Create NPC instances at specific positions.
	## Each NPC is an Area2D with a visual (ColorRect) and dialogue data.
	
	_create_npc("Shopkeeper", Vector2(4, 6), Color(0.9, 0.7, 0.2), [
		"Welcome to my shop!",
		"I sell potions and basic equipment.",
		"Come back after your dungeon run — you'll need supplies!"
	])
	
	_create_npc("Guild Master", Vector2(16, 6), Color(0.6, 0.2, 0.8), [
		"Welcome to the Adventurer's Guild!",
		"Here you can recruit new party members.",
		"Each class brings unique skills to your team."
	])
	
	_create_npc("Blacksmith", Vector2(4, 9), Color(0.7, 0.4, 0.2), [
		"*clang clang*",
		"Bring me materials from the dungeon...",
		"...and I'll forge you something special."
	])
	
	_create_npc("Old Man", Vector2(15, 10), Color(0.6, 0.6, 0.7), [
		"The dungeon entrance is to the north.",
		"Be careful — each floor gets harder.",
		"If you fall, you'll lose your gold... but not your progress."
	])
	
	# Dungeon entrance trigger
	_create_npc("Dungeon Gate", Vector2(10, 1), Color(0.3, 0.1, 0.1), [
		"[The dungeon entrance looms before you...]",
		"Press ENTER to begin a dungeon run."
	], true)  # is_dungeon_entrance = true


func _create_npc(npc_name: String, grid_pos: Vector2, color: Color, dialogue: Array, is_dungeon_entrance: bool = false) -> void:
	## Creates an NPC node with:
	##   - Area2D (detects player proximity)
	##   - ColorRect (visual placeholder)
	##   - CollisionShape2D (detection zone, larger than the sprite)
	##   - Metadata (name, dialogue lines)
	##
	## Area2D vs StaticBody2D:
	##   StaticBody2D = solid, blocks movement
	##   Area2D = transparent, detects overlap (like a trigger zone)
	
	var npc := Area2D.new()
	npc.name = npc_name.replace(" ", "")  # Node names can't have spaces
	npc.position = Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2
	)
	
	# Store dialogue as metadata on the node
	# set_meta() lets you attach arbitrary data to any node
	npc.set_meta("npc_name", npc_name)
	npc.set_meta("dialogue", dialogue)
	npc.set_meta("is_dungeon_entrance", is_dungeon_entrance)
	
	# Visual — colored square for the NPC
	var visual := ColorRect.new()
	visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	visual.position = Vector2(-(TILE_SIZE - 4) / 2, -(TILE_SIZE - 4) / 2)
	visual.color = color
	npc.add_child(visual)
	
	# Detection zone — slightly larger than one tile so player triggers it
	# when adjacent (not just overlapping)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE * 1.5, TILE_SIZE * 1.5)
	collision.shape = shape
	npc.add_child(collision)
	
	# Also make the NPC a solid body so player can't walk through it
	# (unless it's the dungeon entrance)
	if not is_dungeon_entrance:
		var blocker := StaticBody2D.new()
		var blocker_shape := CollisionShape2D.new()
		var blocker_rect := RectangleShape2D.new()
		blocker_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		blocker_shape.shape = blocker_rect
		blocker.add_child(blocker_shape)
		blocker.position = Vector2.ZERO  # Same position as parent NPC
		npc.add_child(blocker)
	
	add_child(npc)
	
	# Add to "npcs" group so NPC interaction script can find all NPCs
	npc.add_to_group("npcs")


func _spawn_player() -> void:
	## Load and spawn the player at the town center.
	## Also attaches the NPC interaction script and dialogue box.
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if player_scene:
		var player: Node = player_scene.instantiate()
		player.position = Vector2(10 * TILE_SIZE + TILE_SIZE / 2, 8 * TILE_SIZE + TILE_SIZE / 2)
		get_parent().add_child(player)
		
		# Attach NPC interaction system to the player
		var interaction_script: Script = load("res://scenes/hub/npc_interaction.gd")
		var interaction := Node.new()
		interaction.name = "NPCInteraction"
		interaction.set_script(interaction_script)
		player.add_child(interaction)
		
		# Create dialogue box UI and give it to the interaction system
		var dialogue_script: Script = load("res://scenes/hub/dialogue_box.gd")
		var dialogue_box := CanvasLayer.new()
		dialogue_box.name = "DialogueBox"
		dialogue_box.set_script(dialogue_script)
		get_parent().add_child(dialogue_box)
		
		# Connect interaction system to dialogue box
		interaction.dialogue_box = dialogue_box
	else:
		push_error("[HubTown] Failed to load player scene")


func _draw() -> void:
	## Draw all tiles as colored rectangles.
	for y in range(TOWN_HEIGHT):
		for x in range(TOWN_WIDTH):
			var tile_type: int = town_map[y][x]
			var rect := Rect2(Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
			draw_rect(rect, COLORS[tile_type], true)
			
			# Grid lines for clarity
			draw_rect(rect, Color(0.0, 0.0, 0.0, 0.15), false)
	
	# Draw labels above buildings
	# (We can't easily draw text in _draw, so we'll use Label nodes instead)
	_draw_building_labels()


func _draw_building_labels() -> void:
	## Draw text labels above buildings using draw_string.
	## This shows the player what each building is.
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12
	
	draw_string(font, Vector2(2 * TILE_SIZE, 2 * TILE_SIZE - 4), "SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(14 * TILE_SIZE, 2 * TILE_SIZE - 4), "GUILD", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(2 * TILE_SIZE, 10 * TILE_SIZE - 4), "BLACKSMITH", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(9 * TILE_SIZE, 1 * TILE_SIZE - 4), "DUNGEON", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.3, 0.3))
