## AchievementSystem — Tracks and awards achievements for milestones.
##
## Achievements are permanent unlocks that display progress.
## Some grant meta-crystal rewards when first earned.
## Persisted to user://achievements.json.

extends Node

const SAVE_PATH: String = "user://achievements.json"

## All unlocked achievement IDs
var unlocked: Array[String] = []

## Achievement definitions
## {"id", "name", "description", "reward_crystals", "condition_func"}
var definitions: Array[Dictionary] = []


func _ready() -> void:
	_define_achievements()
	_load()
	print("[Achievements] %d/%d unlocked" % [unlocked.size(), definitions.size()])


func _define_achievements() -> void:
	definitions = [
		# ─── PROGRESSION ─────────────────────────────────────────
		{"id": "first_run", "name": "First Steps", "description": "Complete your first dungeon run.", "reward": 1},
		{"id": "first_victory", "name": "Victorious", "description": "Defeat the Shadow Lord.", "reward": 5},
		{"id": "floor_3", "name": "Deeper Down", "description": "Reach floor 3.", "reward": 2},
		{"id": "floor_5", "name": "The Depths", "description": "Reach floor 5.", "reward": 3},
		{"id": "ng_plus_1", "name": "Again and Again", "description": "Enter New Game+.", "reward": 5},
		{"id": "ng_plus_3", "name": "Endless Cycle", "description": "Reach NG+3.", "reward": 10},
		
		# ─── COMBAT ──────────────────────────────────────────────
		{"id": "kill_50", "name": "Monster Slayer", "description": "Defeat 50 enemies total.", "reward": 2},
		{"id": "kill_200", "name": "Massacre", "description": "Defeat 200 enemies total.", "reward": 5},
		{"id": "no_damage_boss", "name": "Untouchable", "description": "Beat a boss without taking damage.", "reward": 8},
		{"id": "all_bosses", "name": "Boss Rush", "description": "Defeat all 5 bosses in one run.", "reward": 5},
		{"id": "one_hit_kill", "name": "Overkill", "description": "Deal 100+ damage in a single hit.", "reward": 3},
		
		# ─── COLLECTION ──────────────────────────────────────────
		{"id": "full_party", "name": "Full House", "description": "Have 4 active party members.", "reward": 2},
		{"id": "all_classes", "name": "Jack of All Trades", "description": "Recruit one of every class.", "reward": 5},
		{"id": "first_craft", "name": "Apprentice Smith", "description": "Craft your first item.", "reward": 2},
		{"id": "10_crafts", "name": "Master Smith", "description": "Craft 10 items total.", "reward": 5},
		{"id": "legendary_equip", "name": "Legendary Collector", "description": "Equip a legendary item.", "reward": 3},
		
		# ─── ECONOMY ─────────────────────────────────────────────
		{"id": "earn_100g", "name": "Pocket Change", "description": "Earn 100 gold in a single run.", "reward": 1},
		{"id": "earn_500g", "name": "Rich Adventurer", "description": "Earn 500 gold in a single run.", "reward": 3},
		{"id": "spend_50_crystals", "name": "Investor", "description": "Spend 50 meta-crystals on upgrades.", "reward": 3},
		{"id": "max_shop", "name": "Preferred Customer", "description": "Upgrade the shop to tier 3.", "reward": 3},
		
		# ─── MISC ────────────────────────────────────────────────
		{"id": "daily_challenge", "name": "Daily Grind", "description": "Complete a daily challenge.", "reward": 2},
		{"id": "level_10", "name": "Veteran", "description": "Reach level 10 with any character.", "reward": 5},
		{"id": "10_runs", "name": "Persistent", "description": "Complete 10 runs (win or lose).", "reward": 2},
		{"id": "50_runs", "name": "Dedicated", "description": "Complete 50 runs.", "reward": 5},
	]


func try_unlock(achievement_id: String) -> bool:
	## Attempt to unlock an achievement. Returns true if newly unlocked.
	if achievement_id in unlocked:
		return false  # Already have it
	
	unlocked.append(achievement_id)
	
	# Grant crystal reward
	var def: Dictionary = _get_definition(achievement_id)
	if not def.is_empty() and def.get("reward", 0) > 0:
		GameManager.meta_crystals += def["reward"]
		print("[Achievement] UNLOCKED: %s (+%d crystals)" % [def["name"], def["reward"]])
	
	_save()
	return true


func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked


func get_all_display() -> String:
	## Returns formatted text for UI display.
	var text: String = "═══ ACHIEVEMENTS (%d/%d) ═══\n\n" % [unlocked.size(), definitions.size()]
	
	for def in definitions:
		var status: String = "[✓]" if def["id"] in unlocked else "[ ]"
		text += "%s %s\n" % [status, def["name"]]
		text += "    %s" % def["description"]
		if def["id"] not in unlocked:
			text += " (+%d crystals)" % def["reward"]
		text += "\n"
	
	return text


func get_progress_text() -> String:
	return "%d/%d achievements" % [unlocked.size(), definitions.size()]


func _get_definition(achievement_id: String) -> Dictionary:
	for def in definitions:
		if def["id"] == achievement_id:
			return def
	return {}


## ─── AUTO-CHECK (called from game events) ───────────────────────

func check_run_end(victory: bool, floor_reached: int, gold_earned: int) -> void:
	## Called at end of every run to check relevant achievements.
	try_unlock("first_run")
	
	if victory:
		try_unlock("first_victory")
	if floor_reached >= 3:
		try_unlock("floor_3")
	if floor_reached >= 5:
		try_unlock("floor_5")
	if gold_earned >= 100:
		try_unlock("earn_100g")
	if gold_earned >= 500:
		try_unlock("earn_500g")
	if GameManager.total_runs >= 10:
		try_unlock("10_runs")
	if GameManager.total_runs >= 50:
		try_unlock("50_runs")
	if NewGamePlus.ng_plus_tier >= 1:
		try_unlock("ng_plus_1")
	if NewGamePlus.ng_plus_tier >= 3:
		try_unlock("ng_plus_3")


func check_combat(damage_dealt: int, enemies_killed_total: int) -> void:
	if damage_dealt >= 100:
		try_unlock("one_hit_kill")
	if enemies_killed_total >= 50:
		try_unlock("kill_50")
	if enemies_killed_total >= 200:
		try_unlock("kill_200")


func check_party() -> void:
	if PartyManager.active_party.size() >= 4:
		try_unlock("full_party")
	# Check all classes recruited
	var classes_found: Array[String] = []
	for member in PartyManager.active_party:
		if member.character_class and member.character_class.class_name_text not in classes_found:
			classes_found.append(member.character_class.class_name_text)
	for member in PartyManager.reserve:
		if member.character_class and member.character_class.class_name_text not in classes_found:
			classes_found.append(member.character_class.class_name_text)
	if classes_found.size() >= 6:
		try_unlock("all_classes")


func check_level(level: int) -> void:
	if level >= 10:
		try_unlock("level_10")


func check_shop_tier(tier: int) -> void:
	if tier >= 3:
		try_unlock("max_shop")


## ─── PERSISTENCE ────────────────────────────────────────────────

func _save() -> void:
	var data: Dictionary = {"unlocked": unlocked}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.get_data()
		if data is Dictionary:
			var saved: Array = data.get("unlocked", [])
			unlocked.clear()
			for id in saved:
				if id is String:
					unlocked.append(id)
	file.close()
