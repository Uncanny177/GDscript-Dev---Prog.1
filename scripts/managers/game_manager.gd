## GameManager — Global singleton (autoload) that persists across all scenes.
##
## KEY CONCEPT: AUTOLOADS
## In Godot, an "autoload" is a script/scene that:
##   1. Gets loaded ONCE when the game starts
##   2. NEVER gets destroyed, even when scenes change
##   3. Is accessible from ANYWHERE via its name (GameManager.some_function())
##
## Think of it like a global module in Python, or a static singleton in C++.
## It's the backbone of your game — tracks state that survives scene transitions.
##
## WHY WE NEED THIS:
## When you change scenes (hub → dungeon), the old scene is freed (destroyed).
## Without a persistent manager, all your data (party, gold, progress) would vanish.
## GameManager holds onto everything important.
##
## HOW TO ACCESS FROM OTHER SCRIPTS:
##   GameManager.current_gold  ← just use the autoload name directly
##   GameManager.change_scene("res://scenes/hub/hub.tscn")

extends Node

## ─── SIGNALS ────────────────────────────────────────────────────
## Signals let other nodes react to state changes without tight coupling.
## Any node can connect to these and respond when they fire.

signal scene_changed(scene_name: String)
signal gold_changed(new_amount: int)
signal meta_crystals_changed(new_amount: int)

## ─── GAME STATE ─────────────────────────────────────────────────
## These persist across ALL scene changes because the autoload never dies.

enum GameState { HUB, DUNGEON, COMBAT, MENU }

## What state are we in right now?
var current_state: GameState = GameState.HUB

## ─── RUN DATA (reset on death) ──────────────────────────────────

var current_gold: int = 0
var current_floor: int = 1
var current_dungeon_seed: int = -1
var dungeon_player_positions: Dictionary = {}
var is_run_active: bool = false
var inventory: Inventory = Inventory.new()  # Items carried during a run

## ─── META DATA (persists permanently) ───────────────────────────

var meta_crystals: int = 0
var total_runs: int = 0
var unlocks: Dictionary = {}  # Will track what's been unlocked

## ─── SCENE MANAGEMENT ───────────────────────────────────────────

## The scene we came FROM (so we know where to return to)
var previous_scene_path: String = ""


func _ready() -> void:
	## Called once when the autoload initializes (game start).
	## process_mode = ALWAYS means this node keeps running even if
	## the game is paused. Important for a manager that handles menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] Initialized")
	
	# Load saved meta data on startup (after one frame for other autoloads)
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for ClassDatabase/ItemDatabase
	await SaveManager.load_meta()


func _notification(what: int) -> void:
	## Called when the application is about to quit.
	## Save run state if player is mid-dungeon.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_run_active:
			SaveManager.save_run()
		SaveManager.save_meta()
		get_tree().quit()


func change_scene(scene_path: String) -> void:
	## Changes the current scene. This is the PRIMARY way to move between
	## hub, dungeon, and combat.
	##
	## get_tree() — returns the SceneTree, which manages all active nodes.
	## change_scene_to_file() — unloads current scene, loads new one.
	##
	## We store the previous scene so we can "go back" (e.g., combat → dungeon).
	
	previous_scene_path = get_tree().current_scene.scene_file_path
	
	var error: int = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("[GameManager] Failed to change scene to: " + scene_path)
		return
	
	# Extract a friendly name from the path for the signal
	var scene_name: String = scene_path.get_file().get_basename()
	scene_changed.emit(scene_name)
	print("[GameManager] Scene changed to: ", scene_name)


func go_back() -> void:
	## Returns to the previous scene. Useful for "exit combat" or "leave shop".
	if previous_scene_path.is_empty():
		push_warning("[GameManager] No previous scene to go back to")
		return
	change_scene(previous_scene_path)


## ─── RUN MANAGEMENT ─────────────────────────────────────────────

func start_run() -> void:
	## Called when the player enters the dungeon from the hub.
	## Resets run-specific data. Meta data is untouched.
	is_run_active = true
	current_gold = 0
	current_floor = 1
	dungeon_player_positions.clear()
	inventory = Inventory.new()  # Fresh inventory each run


func advance_to_next_floor() -> void:
	## Advance to the next dungeon floor and reset the floor seed.
	current_floor += 1
	current_dungeon_seed = -1
	current_state = GameState.DUNGEON
	print("[GameManager] Advanced to floor %d" % current_floor)
	
	# Give starter items for each run
	var health_pot: ItemData = ItemDatabase.get_item("Health Potion")
	var mana_pot: ItemData = ItemDatabase.get_item("Mana Potion")
	if health_pot:
		inventory.add_item(health_pot, 3)
	if mana_pot:
		inventory.add_item(mana_pot, 2)
	
	total_runs += 1
	current_state = GameState.DUNGEON
	StatsTracker.start_run()
	print("[GameManager] Run #%d started — %s" % [total_runs, str(inventory)])


func end_run(victory: bool) -> void:
	## Called on death or boss victory. Handles what carries over.
	is_run_active = false
	var _run_gold_before_reset: int = current_gold  # Capture for achievements
	
	# End daily challenge if active
	if DailyChallenge.is_challenge_active:
		DailyChallenge.end_challenge(
			current_floor,
			StatsTracker.current_run.get("enemies_killed", 0),
			current_gold
		)
	
	# Track milestones
	UnlocksManager.record_floor_reached(current_floor)
	
	if victory:
		# Keep run gold + bonus meta-crystals on victory
		meta_crystals += 5 + current_floor  # Bonus based on depth
		meta_crystals_changed.emit(meta_crystals)
		UnlocksManager.record_run_completed()
		UnlocksManager.record_boss_defeated()
		
		# Check if this is a full game clear (floor 5+ boss beaten)
		if current_floor >= 5:
			NewGamePlus.mark_game_cleared()
		
		print("[GameManager] Victory! Earned %d meta-crystals" % (5 + current_floor))
	else:
		# Lose run gold on death, still get some meta-crystals for progress
		var earned: int = current_floor  # 1 crystal per floor reached
		meta_crystals += earned
		meta_crystals_changed.emit(meta_crystals)
		current_gold = 0
		inventory.clear()  # Lose all run items on death
		gold_changed.emit(current_gold)
		print("[GameManager] Defeated on floor %d. Earned %d meta-crystals" % [current_floor, earned])
	
	current_state = GameState.HUB
	
	# Check achievements (use gold before reset for accurate tracking)
	Achievements.check_run_end(victory, current_floor, _run_gold_before_reset)
	Achievements.check_party()
	
	# Record run in stats tracker
	StatsTracker.end_run(victory, current_floor, current_gold, 5 + current_floor if victory else current_floor)
	
	# Auto-save meta progression on every return to hub
	SaveManager.save_meta()
	# Delete any mid-run save (run is over)
	SaveManager.delete_run_save()


## ─── CURRENCY ───────────────────────────────────────────────────

func set_dungeon_player_position(tile: Vector2i) -> void:
	## Remember the player's tile for the current floor so dungeon reloads resume there.
	dungeon_player_positions[current_floor] = tile


func get_dungeon_player_position_for_floor(floor_number: int) -> Vector2i:
	## Returns the saved tile for a floor if one exists, otherwise an invalid tile.
	if dungeon_player_positions.has(floor_number):
		var tile: Variant = dungeon_player_positions[floor_number]
		if tile is Vector2i:
			return tile
	return Vector2i(-1, -1)


func add_gold(amount: int) -> void:
	## Add run-gold (from enemies, chests). Only meaningful during a run.
	current_gold += amount
	gold_changed.emit(current_gold)


func spend_gold(amount: int) -> bool:
	## Try to spend gold. Returns false if insufficient funds.
	## This pattern (check → do → return success) prevents overspending.
	if current_gold < amount:
		return false
	current_gold -= amount
	gold_changed.emit(current_gold)
	return true


func spend_meta_crystals(amount: int) -> bool:
	## Try to spend meta-crystals on permanent upgrades.
	if meta_crystals < amount:
		return false
	meta_crystals -= amount
	meta_crystals_changed.emit(meta_crystals)
	return true
