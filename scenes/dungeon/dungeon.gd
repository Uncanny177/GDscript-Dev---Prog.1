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

## Track player's last tile to detect movement
var last_player_tile: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	_apply_difficulty_scaling()
	_generate_and_render_floor()
	_spawn_visible_enemies()
	_update_ui()
	_add_message("Floor %d — %s" % [GameManager.current_floor, _get_floor_description()])


func _apply_difficulty_scaling() -> void:
	var floor_num: int = GameManager.current_floor
	encounter_check_interval = maxi(6 - floor_num, 3)
	encounter_chance = minf(0.20 + floor_num * 0.05, 0.45)
	print("[Dungeon] Floor %d difficulty — check every %d steps, %.0f%% chance" % [
		floor_num, encounter_check_interval, encounter_chance * 100
	])


func _get_floor_description() -> String:
	match GameManager.current_floor:
		1: return "The entrance is damp and cold..."
		2: return "You descend deeper into darkness."
		3: return "Strange sounds echo from below."
		4: return "The air grows thick with danger."
		5: return "The boss awaits on this floor!"
		_: return "Uncharted depths..."


func _generate_and_render_floor() -> void:
	floor_gen = FloorGenerator.new()
	current_seed = randi()
	floor_gen.generate_floor(GameManager.current_floor, current_seed)
	
	var renderer_script: Script = load("res://scripts/generation/dungeon_renderer.gd")
	if renderer_script:
		dungeon_renderer = Node2D.new()
		dungeon_renderer.name = "DungeonRenderer"
		dungeon_renderer.set_script(renderer_script)
		add_child(dungeon_renderer)
		dungeon_renderer.setup(floor_gen)
	
	_spawn_player()


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if not player_scene:
		push_error("[Dungeon] Failed to load player scene")
		return
	
	player_node = player_scene.instantiate()
	var start_pos: Vector2i = floor_gen.player_start if floor_gen else Vector2i(5, 5)
	player_node.position = Vector2(start_pos.x * 32 + 16, start_pos.y * 32 + 16)
	add_child(player_node)
	last_player_tile = start_pos


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
	var visual := ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.9, 0.2, 0.2, 0.8)
	marker.add_child(visual)
	add_child(marker)
	enemy_markers.append(marker)


func _process(_delta: float) -> void:
	if not player_node or not floor_gen or transitioning:
		return
	var player_tile := Vector2i(
		floori(player_node.position.x / 32.0),
		floori(player_node.position.y / 32.0)
	)
	if player_tile != last_player_tile:
		last_player_tile = player_tile
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
	GameManager.current_floor += 1
	if GameManager.current_floor > 5:
		GameManager.end_run(true)
		GameManager.change_scene("res://scenes/hub/hub.tscn")
	else:
		GameManager.change_scene("res://scenes/dungeon/dungeon.tscn")


func _on_reach_chest(chest_pos: Vector2i) -> void:
	floor_gen.chest_spawn_points.erase(chest_pos)
	var floor_mult: int = GameManager.current_floor
	var loot_roll: int = randi() % 100
	
	if loot_roll < 35:
		var gold: int = randi_range(5, 15) * floor_mult
		GameManager.add_gold(gold)
		_add_message("Chest: +%d gold!" % gold)
	elif loot_roll < 55:
		var potion: ItemData = ItemDatabase.get_item("Health Potion")
		if potion:
			GameManager.inventory.add_item(potion)
			_add_message("Chest: +1 Health Potion!")
	elif loot_roll < 70:
		var mana_pot: ItemData = ItemDatabase.get_item("Mana Potion")
		if mana_pot:
			GameManager.inventory.add_item(mana_pot)
			_add_message("Chest: +1 Mana Potion!")
	elif loot_roll < 85:
		var item_name: String = "Mega Potion" if floor_mult >= 3 else "Health Potion"
		var item: ItemData = ItemDatabase.get_item(item_name)
		if item:
			GameManager.inventory.add_item(item)
			_add_message("Chest: +1 %s!" % item_name)
	else:
		var crystals: int = 1 + floor_mult / 2
		GameManager.meta_crystals += crystals
		_add_message("Chest: +%d Meta-Crystal%s!" % [crystals, "s" if crystals > 1 else ""])
	
	if dungeon_renderer:
		dungeon_renderer.queue_redraw()
	_update_ui()


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
