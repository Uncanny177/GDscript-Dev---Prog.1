## SaveManager — Handles all game persistence (save/load to JSON files).
##
## KEY CONCEPT: FILE I/O IN GODOT
## Godot uses FileAccess for reading/writing files. The "user://" path
## points to a persistent folder that survives game restarts:
##   Windows: %AppData%/Godot/app_userdata/Roguelite RPG/
##   Linux: ~/.local/share/godot/app_userdata/Roguelite RPG/
##   Mac: ~/Library/Application Support/Godot/app_userdata/Roguelite RPG/
##
## We store data as JSON because:
##   - Human-readable (you can open it in a text editor to debug)
##   - Easy to parse (Godot has built-in JSON class)
##   - Flexible (add new fields without breaking old saves)
##
## TWO SAVE FILES:
##   meta_save.json — Permanent data (unlocks, crystals, party roster)
##                    Saved on every return to hub. Never lost.
##   run_save.json  — Mid-run data (floor, HP, inventory)
##                    Created when quitting mid-dungeon. Deleted on load.
##
## CORRUPTION HANDLING:
## If a save file is corrupted (invalid JSON), we log an error and
## start fresh rather than crashing. Player loses progress but game works.

extends Node

const META_SAVE_PATH: String = "user://meta_save.json"
const RUN_SAVE_PATH: String = "user://run_save.json"


func _ready() -> void:
	print("[SaveManager] Initialized — save path: user://")


## ─── META SAVE (permanent progression) ──────────────────────────

func save_meta() -> void:
	## Save all permanent data: unlocks, meta-crystals, party roster, settings.
	## Called automatically when returning to hub.
	
	var data: Dictionary = {
		"version": 1,  # Save format version (for future migrations)
		"meta_crystals": GameManager.meta_crystals,
		"total_runs": GameManager.total_runs,
		"unlocks": UnlocksManager.to_dict(),
		"party": _serialize_party(),
	}
	
	_write_json(META_SAVE_PATH, data)
	print("[SaveManager] Meta saved — %d crystals, %d party members" % [
		GameManager.meta_crystals, PartyManager.active_party.size() + PartyManager.reserve.size()
	])


func load_meta() -> bool:
	## Load permanent data. Returns false if no save exists or it's corrupted.
	## Called on game startup.
	
	var data: Dictionary = _read_json(META_SAVE_PATH)
	if data.is_empty():
		print("[SaveManager] No meta save found — starting fresh")
		return false
	
	# Validate version
	var version: int = data.get("version", 0)
	if version < 1:
		push_warning("[SaveManager] Unknown save version: %d" % version)
		return false
	
	# Restore meta-crystals and run count
	GameManager.meta_crystals = data.get("meta_crystals", 0)
	GameManager.total_runs = data.get("total_runs", 0)
	
	# Restore unlocks
	var unlocks_data: Dictionary = data.get("unlocks", {})
	if not unlocks_data.is_empty():
		UnlocksManager.from_dict(unlocks_data)
	
	# Restore party
	var party_data: Dictionary = data.get("party", {})
	if not party_data.is_empty():
		await _deserialize_party(party_data)
	
	print("[SaveManager] Meta loaded — %d crystals, %d runs" % [
		GameManager.meta_crystals, GameManager.total_runs
	])
	return true


## ─── RUN SAVE (mid-dungeon resume) ─────────────────────────────

func save_run() -> void:
	## Save current run state for resume. Called when player quits mid-dungeon.
	
	if not GameManager.is_run_active:
		return  # Nothing to save if not in a run
	
	var data: Dictionary = {
		"version": 1,
		"current_floor": GameManager.current_floor,
		"current_gold": GameManager.current_gold,
		"party_state": _serialize_party_combat_state(),
		"inventory": _serialize_inventory(),
	}
	
	_write_json(RUN_SAVE_PATH, data)
	print("[SaveManager] Run saved — floor %d, %d gold" % [
		GameManager.current_floor, GameManager.current_gold
	])


func load_run() -> bool:
	## Load a saved run for resume. Returns false if no run save exists.
	## Deletes the run save after loading (one-time resume).
	
	var data: Dictionary = _read_json(RUN_SAVE_PATH)
	if data.is_empty():
		return false
	
	# Restore run state
	GameManager.current_floor = data.get("current_floor", 1)
	GameManager.current_gold = data.get("current_gold", 0)
	GameManager.is_run_active = true
	GameManager.current_state = GameManager.GameState.DUNGEON
	
	# Restore party HP/MP
	var party_state: Array = data.get("party_state", [])
	_deserialize_party_combat_state(party_state)
	
	# Restore inventory
	var inv_data: Array = data.get("inventory", [])
	_deserialize_inventory(inv_data)
	
	# Delete run save (one-time use — prevents save scumming)
	delete_run_save()
	
	print("[SaveManager] Run loaded — resuming floor %d" % GameManager.current_floor)
	return true


func has_run_save() -> bool:
	## Check if a run save exists (for "Continue" button on title/hub).
	return FileAccess.file_exists(RUN_SAVE_PATH)


func delete_run_save() -> void:
	## Remove the run save file. Called after loading or on death.
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)
		print("[SaveManager] Run save deleted")


## ─── SERIALIZATION HELPERS ──────────────────────────────────────

func _serialize_party() -> Dictionary:
	## Serialize all party members (active + reserve) for meta save.
	var active: Array[Dictionary] = []
	for member in PartyManager.active_party:
		active.append(_serialize_character(member))
	
	var reserve: Array[Dictionary] = []
	for member in PartyManager.reserve:
		reserve.append(_serialize_character(member))
	
	return {"active": active, "reserve": reserve}


func _serialize_character(character: CharacterData) -> Dictionary:
	## Serialize a single character to a dictionary.
	var data: Dictionary = {
		"name": character.character_name,
		"class": character.character_class.class_name_text if character.character_class else "Unknown",
		"current_hp": character.current_hp,
		"current_mp": character.current_mp,
		"is_alive": character.is_alive,
		"level": character.level,
		"xp": character.xp,
		"stat_bonuses": {
			"max_hp": character.stat_bonuses.max_hp,
			"max_mp": character.stat_bonuses.max_mp,
			"atk": character.stat_bonuses.atk,
			"def": character.stat_bonuses.def_stat,
			"mag": character.stat_bonuses.mag,
			"res": character.stat_bonuses.res_stat,
			"spd": character.stat_bonuses.spd,
		},
	}
	
	# Equipment
	data["weapon"] = character.weapon.item_name if character.weapon else ""
	data["armor"] = character.armor.item_name if character.armor else ""
	data["accessory"] = character.accessory.item_name if character.accessory else ""
	
	return data


func _deserialize_party(data: Dictionary) -> void:
	## Rebuild party from saved data.
	PartyManager.active_party.clear()
	PartyManager.reserve.clear()
	
	# Wait one frame to ensure ClassDatabase is ready
	await get_tree().process_frame
	
	var active_data: Array = data.get("active", [])
	for char_data in active_data:
		var character: CharacterData = _deserialize_character(char_data)
		if character:
			PartyManager.active_party.append(character)
	
	var reserve_data: Array = data.get("reserve", [])
	for char_data in reserve_data:
		var character: CharacterData = _deserialize_character(char_data)
		if character:
			PartyManager.reserve.append(character)
	
	# If party ended up empty (corrupted save), create default
	if PartyManager.active_party.is_empty():
		push_warning("[SaveManager] Party empty after load — creating default")
		# PartyManager._create_default_party() will handle this on its own


func _deserialize_character(data: Dictionary) -> CharacterData:
	## Rebuild a character from saved data.
	var character := CharacterData.new()
	character.character_name = data.get("name", "Unknown")
	
	var class_name_str: String = data.get("class", "Warrior")
	character.character_class = ClassDatabase.get_class(class_name_str)
	
	if not character.character_class:
		push_warning("[SaveManager] Unknown class '%s' — defaulting to Warrior" % class_name_str)
		character.character_class = ClassDatabase.get_class("Warrior")
	
	character.initialize()  # Sets HP/MP to max
	
	# Restore level and XP
	character.level = int(data.get("level", 1))
	character.xp = int(data.get("xp", 0))
	
	# Restore stat bonuses from leveling
	var bonuses: Dictionary = data.get("stat_bonuses", {})
	if not bonuses.is_empty():
		if character.stat_bonuses == null:
			character.stat_bonuses = StatBlock.new()
		character.stat_bonuses.max_hp = int(bonuses.get("max_hp", 0))
		character.stat_bonuses.max_mp = int(bonuses.get("max_mp", 0))
		character.stat_bonuses.atk = int(bonuses.get("atk", 0))
		character.stat_bonuses.def_stat = int(bonuses.get("def", 0))
		character.stat_bonuses.mag = int(bonuses.get("mag", 0))
		character.stat_bonuses.res_stat = int(bonuses.get("res", 0))
		character.stat_bonuses.spd = int(bonuses.get("spd", 0))
	
	# Override with saved HP/MP (might be damaged)
	character.current_hp = int(data.get("current_hp", character.get_stats().max_hp))
	character.current_mp = int(data.get("current_mp", character.get_stats().max_mp))
	character.is_alive = data.get("is_alive", true)
	
	# Restore equipment
	var weapon_name: String = data.get("weapon", "")
	if weapon_name != "":
		character.weapon = ItemDatabase.get_item(weapon_name)
	var armor_name: String = data.get("armor", "")
	if armor_name != "":
		character.armor = ItemDatabase.get_item(armor_name)
	var accessory_name: String = data.get("accessory", "")
	if accessory_name != "":
		character.accessory = ItemDatabase.get_item(accessory_name)
	
	return character


func _serialize_party_combat_state() -> Array:
	## Serialize just HP/MP/alive state for run save (lightweight).
	var result: Array = []
	for member in PartyManager.active_party:
		result.append({
			"current_hp": member.current_hp,
			"current_mp": member.current_mp,
			"is_alive": member.is_alive,
		})
	return result


func _deserialize_party_combat_state(data: Array) -> void:
	## Restore HP/MP/alive state from run save.
	for i in range(mini(data.size(), PartyManager.active_party.size())):
		var member: CharacterData = PartyManager.active_party[i]
		member.current_hp = data[i].get("current_hp", member.current_hp)
		member.current_mp = data[i].get("current_mp", member.current_mp)
		member.is_alive = data[i].get("is_alive", true)


func _serialize_inventory() -> Array:
	## Serialize inventory as array of {name, count}.
	var result: Array = []
	var items: Array = GameManager.inventory.get_all_items()
	for entry in items:
		var item: ItemData = entry["item"]
		result.append({"name": item.item_name, "count": entry["count"]})
	return result


func _deserialize_inventory(data: Array) -> void:
	## Rebuild inventory from saved data.
	GameManager.inventory.clear()
	for entry in data:
		var item_name: String = entry.get("name", "")
		var count: int = entry.get("count", 1)
		var item: ItemData = ItemDatabase.get_item(item_name)
		if item:
			GameManager.inventory.add_item(item, count)


## ─── FILE I/O ───────────────────────────────────────────────────

func _write_json(path: String, data: Dictionary) -> void:
	## Write a dictionary to a JSON file.
	var json_string: String = JSON.stringify(data, "\t")  # Pretty print with tabs
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open file for writing: " + path)
		return
	
	file.store_string(json_string)
	file.close()


func _read_json(path: String) -> Dictionary:
	## Read a JSON file and return as dictionary. Returns empty dict on failure.
	
	if not FileAccess.file_exists(path):
		return {}
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open file for reading: " + path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	if json_string.is_empty():
		return {}
	
	# Parse JSON
	var json := JSON.new()
	var parse_result: int = json.parse(json_string)
	if parse_result != OK:
		push_error("[SaveManager] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	
	var result = json.get_data()
	if result is Dictionary:
		return result
	
	push_error("[SaveManager] Save file is not a dictionary: " + path)
	return {}
