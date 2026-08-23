## Dungeon Scene — Procedurally generated floors with exploration.
##
## ENCOUNTER TYPES:
## 1. Visible encounters — enemy sprites on the map. Walk into them = combat.
## 2. Random encounters — step-based chance (classic JRPG style).

extends Node2D

## UI
@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var floor_label: Label = $CanvasLayer/FloorLabel

## Generation components
var floor_gen: FloorGenerator = null
var dungeon_renderer: Node2D = null
var player_node: Node = null

## Visible enemy nodes on the map
var enemy_markers: Array[Node2D] = []

## Step counter for random encounters
var steps_taken: int = 0

## Difficulty scaling
var encounter_check_interval: int = 5
var encounter_chance: float = 0.25

## Prevent double-triggering during scene transitions
var transitioning: bool = false

## Floor seed for reproducibility
var current_seed: int = 0

## Boss fight flag
var is_boss_fight: bool = false
var boss_combatant: BossCombatant = null

## Event system
var event_ui: Node = null
var event_tiles: Array[Vector2i] = []

## Minimap
var minimap: Node = null  # Track event tile positions

## Track player's last tile to detect movement
var last_player_tile: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	_apply_difficulty_scaling()
	_generate_and_render_floor()
	_spawn_visible_enemies()
	_create_event_ui()
	_create_minimap()
	_update_ui()
	_add_message("Floor %d — %s" % [GameManager.current_floor, _get_floor_description()])
	_show_transition_flash()


func _apply_difficulty_scaling() -> void:
	var floor_num: int = GameManager.current_floor
	encounter_check_interval = maxi(8 - floor_num, 6)
	encounter_chance = minf(0.08 + floor_num * 0.04, 0.20)
	print("[Dungeon] Floor %d difficulty — check every %d steps, %.0f%% chance" % [
		floor_num, encounter_check_interval, encounter_chance * 100
	])


func _get_floor_description() -> String:
	var biome: BiomeData = BiomeDatabase.get_biome_for_floor(GameManager.current_floor)
	if biome:
		return biome.description
	return "Uncharted depths..."


func _generate_and_render_floor() -> void:
	floor_gen = FloorGenerator.new()
	# Use daily challenge seed if active, otherwise GameManager seed
	if DailyChallenge.is_challenge_active:
		current_seed = DailyChallenge.get_today_seed() + GameManager.current_floor
	elif GameManager.current_dungeon_seed < 0:
		GameManager.current_dungeon_seed = randi()
		current_seed = GameManager.current_dungeon_seed
	else:
		current_seed = GameManager.current_dungeon_seed
	floor_gen.generate_floor(GameManager.current_floor, current_seed)
	
	var renderer_script: Script = load("res://scripts/generation/dungeon_renderer.gd")
	if renderer_script:
		dungeon_renderer = Node2D.new()
		dungeon_renderer.name = "DungeonRenderer"
		dungeon_renderer.set_script(renderer_script)
		add_child(dungeon_renderer)
		dungeon_renderer.setup(floor_gen, BiomeDatabase.get_biome_for_floor(GameManager.current_floor))
	
	_spawn_player()


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if not player_scene:
		push_error("[Dungeon] Failed to load player scene")
		return
	
	player_node = player_scene.instantiate()
	var start_pos: Vector2i = GameManager.get_dungeon_player_position_for_floor(GameManager.current_floor)
	# Validate the saved position against the CURRENT floor — it may be stale
	# (floors regenerate) which would spawn the player in a wall or outside the map.
	if start_pos == Vector2i(-1, -1) or not _is_valid_spawn(start_pos):
		start_pos = floor_gen.player_start if floor_gen else Vector2i(5, 5)
	player_node.position = Vector2(start_pos.x * 32 + 16, start_pos.y * 32 + 16)
	add_child(player_node)
	last_player_tile = start_pos
	GameManager.set_dungeon_player_position(start_pos)


func _is_valid_spawn(tile: Vector2i) -> bool:
	## True if the tile is a walkable FLOOR tile in the current generated floor.
	if not floor_gen:
		return false
	if tile.y < 0 or tile.y >= floor_gen.floor_tiles.size():
		return false
	if tile.x < 0 or tile.x >= floor_gen.floor_tiles[tile.y].size():
		return false
	return floor_gen.floor_tiles[tile.y][tile.x] == RoomTemplate.FLOOR


func _spawn_visible_enemies() -> void:
	if not floor_gen:
		return
	var spawn_points: Array[Vector2i] = floor_gen.enemy_spawn_points
	var count: int = mini(2 + GameManager.current_floor, spawn_points.size())
	var shuffled: Array[Vector2i] = spawn_points.duplicate()
	shuffled.shuffle()
	for i in range(count):
		if i >= shuffled.size():
			break
		_create_enemy_marker(shuffled[i])


func _create_enemy_marker(tile_pos: Vector2i) -> void:
	var marker := Node2D.new()
	marker.name = "EnemyMarker_%d_%d" % [tile_pos.x, tile_pos.y]
	marker.position = Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32 + 16)
	marker.set_meta("tile_pos", tile_pos)
	
	# Shadow under the enemy
	var shadow := ColorRect.new()
	shadow.size = Vector2(18, 8)
	shadow.position = Vector2(-9, 2)
	shadow.color = Color(0.0, 0.0, 0.0, 0.3)
	marker.add_child(shadow)
	
	# Body — reddish enemy blob
	var body := ColorRect.new()
	body.size = Vector2(16, 18)
	body.position = Vector2(-8, -12)
	body.color = Color(0.85, 0.15, 0.15, 0.9)
	marker.add_child(body)
	
	# Eyes — two small white dots
	var eye_l := ColorRect.new()
	eye_l.size = Vector2(3, 3)
	eye_l.position = Vector2(-5, -8)
	eye_l.color = Color(1.0, 1.0, 1.0, 0.9)
	marker.add_child(eye_l)
	
	var eye_r := ColorRect.new()
	eye_r.size = Vector2(3, 3)
	eye_r.position = Vector2(2, -8)
	eye_r.color = Color(1.0, 1.0, 1.0, 0.9)
	marker.add_child(eye_r)
	
	add_child(marker)
	enemy_markers.append(marker)


func _create_event_ui() -> void:
	## Create the event UI overlay and collect event tile positions.
	var event_script: Script = load("res://scenes/dungeon/event_ui.gd")
	if event_script:
		event_ui = CanvasLayer.new()
		event_ui.name = "EventUI"
		event_ui.set_script(event_script)
		add_child(event_ui)
		event_ui.event_resolved.connect(_on_event_resolved)
	
	# Collect event tile positions from the generator
	# (Event tiles that aren't the exit — exit is handled separately)
	if floor_gen:
		for room in floor_gen.placed_rooms:
			var template: RoomTemplate = room["template"]
			var offset: Vector2i = room["world_offset"]
			# Only non-exit/non-boss rooms have interactive events
			if template.room_type == RoomTemplate.RoomType.LARGE:
				# Find ? tiles in this room
				for y in range(template.height):
					for x in range(template.width):
						if template.get_tile(x, y) == RoomTemplate.EVENT:
							var world_pos := Vector2i(offset.x + x, offset.y + y)
							if world_pos != floor_gen.exit_position:
								event_tiles.append(world_pos)


func _process(_delta: float) -> void:
	if not player_node or not floor_gen or transitioning:
		return
	if event_ui and event_ui.is_active:
		return  # Don't process movement/events during event display
	var player_tile := Vector2i(
		floori(player_node.position.x / 32.0),
		floori(player_node.position.y / 32.0)
	)
	if player_tile != last_player_tile:
		last_player_tile = player_tile
		GameManager.set_dungeon_player_position(player_tile)
		_check_tile_events(player_tile)
		_check_visible_enemy_contact(player_tile)


func _check_tile_events(player_tile: Vector2i) -> void:
	if transitioning:
		return
	if player_tile == floor_gen.exit_position and floor_gen.exit_position != Vector2i.ZERO:
		_on_reach_exit()
		return
	if player_tile in floor_gen.chest_spawn_points:
		_on_reach_chest(player_tile)
		return
	if player_tile in event_tiles:
		_on_reach_event(player_tile)


func _check_visible_enemy_contact(player_tile: Vector2i) -> void:
	if transitioning:
		return
	for marker in enemy_markers:
		var enemy_tile: Vector2i = marker.get_meta("tile_pos")
		if player_tile == enemy_tile:
			enemy_markers.erase(marker)
			marker.queue_free()
			transitioning = true
			_add_message("Enemy spotted!")
			GameManager.current_state = GameManager.GameState.COMBAT
			GameManager.change_scene("res://scenes/combat/combat.tscn")
			return


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if transitioning:
		return
	if event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		steps_taken += 1
		if steps_taken % encounter_check_interval == 0:
			_check_random_encounter()
		_update_ui()


func _check_random_encounter() -> void:
	if transitioning:
		return
	if randf() < encounter_chance:
		transitioning = true
		_add_message("Ambush!")
		GameManager.current_state = GameManager.GameState.COMBAT
		GameManager.change_scene("res://scenes/combat/combat.tscn")


func _on_reach_exit() -> void:
	transitioning = true
	GameManager.advance_to_next_floor()
	if GameManager.current_floor > 5:
		GameManager.end_run(true)
		TransitionManager.transition_to("res://scenes/hub/hub.tscn")
	else:
		# Check if there's a boss defined for this floor
		var boss_check: BossData = BossDatabase.get_boss_for_floor(GameManager.current_floor)
		if boss_check:
			GameManager.current_state = GameManager.GameState.COMBAT
			GameManager.set_meta("boss_fight", true)
			GameManager.change_scene("res://scenes/combat/combat.tscn")
		else:
			GameManager.change_scene("res://scenes/dungeon/dungeon.tscn")


func _on_reach_chest(chest_pos: Vector2i) -> void:
	floor_gen.chest_spawn_points.erase(chest_pos)
	
	# Use loot table for chest drops
	var chest_table: LootTable = LootTable.create_chest_table(GameManager.current_floor)
	var drop: Dictionary = chest_table.roll()
	
	match drop["type"]:
		LootTable.LootType.GOLD:
			GameManager.add_gold(drop["amount"])
			_add_message("Chest: +%d gold!" % drop["amount"])
		LootTable.LootType.ITEM:
			var item: ItemData = ItemDatabase.get_item(drop["item_name"])
			if item:
				GameManager.inventory.add_item(item, drop["amount"])
				_add_message("Chest: +%d %s!" % [drop["amount"], drop["item_name"]])
		LootTable.LootType.META_CRYSTAL:
			GameManager.meta_crystals += drop["amount"]
			_add_message("Chest: +%d Meta-Crystal%s!" % [drop["amount"], "s" if drop["amount"] > 1 else ""])
		_:
			_add_message("Chest: Empty...")
	
	if dungeon_renderer:
		dungeon_renderer.queue_redraw()
	_update_ui()


func _create_minimap() -> void:
	## Create the minimap overlay.
	var minimap_script: Script = load("res://scripts/generation/minimap.gd")
	if minimap_script and floor_gen and player_node:
		minimap = CanvasLayer.new()
		minimap.name = "Minimap"
		minimap.set_script(minimap_script)
		add_child(minimap)
		minimap.setup(floor_gen, player_node)


func _on_reach_event(event_pos: Vector2i) -> void:
	## Player stepped on an event tile. Trigger a random event.
	event_tiles.erase(event_pos)  # Don't trigger again
	
	var event: DungeonEvent = EventDatabase.get_random_event()
	if event and event_ui:
		event_ui.show_event(event)


func _on_event_resolved(result: Dictionary) -> void:
	## Called when the player finishes an event choice.
	_update_ui()
	
	# If the event triggered an ambush, start combat
	if result.get("type", "") == "ambush":
		transitioning = true
		_add_message("Ambush!")
		GameManager.current_state = GameManager.GameState.COMBAT
		GameManager.change_scene("res://scenes/combat/combat.tscn")


func _show_transition_flash() -> void:
	var overlay := ColorRect.new()
	overlay.name = "FloorTransitionFlash"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.anchor_left = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_top = 0.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.25, 0.08)
	tween.tween_property(overlay, "color:a", 0.0, 0.18)
	tween.tween_callback(overlay.queue_free)


func _add_message(text: String) -> void:
	if info_label:
		info_label.text = text
	print("[Dungeon] " + text)


func _update_ui() -> void:
	if not floor_label:
		return
	var party_hp: String = ""
	for member in PartyManager.active_party:
		if member.is_alive:
			party_hp += "%s:%d " % [member.character_name.left(3), member.current_hp]
		else:
			party_hp += "%s:X " % member.character_name.left(3)
	floor_label.text = "F%d | %dG | %s" % [
		GameManager.current_floor, GameManager.current_gold, party_hp.strip_edges()
	]
