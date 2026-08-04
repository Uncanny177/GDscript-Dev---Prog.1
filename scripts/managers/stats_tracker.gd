## StatsTracker — Records run history and lifetime statistics.
##
## Tracks two things:
## 1. Run History — a log of every completed run (last 20)
## 2. Lifetime Stats — cumulative totals across all runs
##
## Accessible from title screen or hub via a "Stats" option.
## Persisted to user://stats.json alongside other saves.

extends Node

const SAVE_PATH: String = "user://stats.json"
const MAX_HISTORY: int = 20  # Keep last 20 runs

## ─── LIFETIME STATS ─────────────────────────────────────────────

var lifetime: Dictionary = {
	"total_runs": 0,
	"total_victories": 0,
	"total_deaths": 0,
	"total_floors_explored": 0,
	"total_enemies_killed": 0,
	"total_gold_earned": 0,
	"total_gold_spent": 0,
	"total_crystals_earned": 0,
	"total_crystals_spent": 0,
	"total_items_used": 0,
	"total_damage_dealt": 0,
	"total_damage_taken": 0,
	"total_heals": 0,
	"highest_floor_ever": 0,
	"most_gold_single_run": 0,
	"fastest_victory_floors": 99,  # Fewest floors to beat the game (always 5 but tracks)
	"longest_run_floors": 0,
}

## ─── RUN HISTORY ────────────────────────────────────────────────
## Each entry: {"run_number", "result", "floors", "gold", "crystals", "enemies", "party"}

var history: Array[Dictionary] = []

## ─── CURRENT RUN TRACKING ───────────────────────────────────────
## Accumulated during a run, committed to history on run end.

var current_run: Dictionary = {}


func _ready() -> void:
	_load()
	print("[StatsTracker] Loaded — %d runs in history" % history.size())


## ─── RUN LIFECYCLE ──────────────────────────────────────────────

func start_run() -> void:
	## Call at the start of each dungeon run.
	current_run = {
		"enemies_killed": 0,
		"gold_earned": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"items_used": 0,
		"heals": 0,
		"floors_explored": 0,
	}


func end_run(victory: bool, floor_reached: int, gold_earned: int, crystals_earned: int) -> void:
	## Call when a run ends (death or victory). Records to history and lifetime.
	
	lifetime["total_runs"] += 1
	if victory:
		lifetime["total_victories"] += 1
	else:
		lifetime["total_deaths"] += 1
	
	lifetime["total_floors_explored"] += floor_reached
	lifetime["total_gold_earned"] += gold_earned
	lifetime["total_crystals_earned"] += crystals_earned
	lifetime["total_enemies_killed"] += current_run.get("enemies_killed", 0)
	lifetime["total_damage_dealt"] += current_run.get("damage_dealt", 0)
	lifetime["total_damage_taken"] += current_run.get("damage_taken", 0)
	lifetime["total_items_used"] += current_run.get("items_used", 0)
	lifetime["total_heals"] += current_run.get("heals", 0)
	
	# Records
	lifetime["highest_floor_ever"] = maxi(lifetime["highest_floor_ever"], floor_reached)
	lifetime["most_gold_single_run"] = maxi(lifetime["most_gold_single_run"], gold_earned)
	lifetime["longest_run_floors"] = maxi(lifetime["longest_run_floors"], floor_reached)
	
	# Build history entry
	var party_names: Array[String] = []
	for member in PartyManager.active_party:
		party_names.append(member.character_name)
	
	var entry: Dictionary = {
		"run_number": lifetime["total_runs"],
		"result": "Victory" if victory else "Defeated",
		"floors": floor_reached,
		"gold": gold_earned,
		"crystals": crystals_earned,
		"enemies": current_run.get("enemies_killed", 0),
		"party": party_names,
	}
	
	history.append(entry)
	if history.size() > MAX_HISTORY:
		history.pop_front()
	
	current_run = {}
	_save()


## ─── MID-RUN TRACKING (called by combat/dungeon) ───────────────

func record_enemy_killed() -> void:
	if current_run.has("enemies_killed"):
		current_run["enemies_killed"] += 1


func record_damage_dealt(amount: int) -> void:
	if current_run.has("damage_dealt"):
		current_run["damage_dealt"] += amount


func record_damage_taken(amount: int) -> void:
	if current_run.has("damage_taken"):
		current_run["damage_taken"] += amount


func record_item_used() -> void:
	if current_run.has("items_used"):
		current_run["items_used"] += 1


func record_heal(amount: int) -> void:
	if current_run.has("heals"):
		current_run["heals"] += amount


func record_gold_spent(amount: int) -> void:
	lifetime["total_gold_spent"] += amount


func record_crystals_spent(amount: int) -> void:
	lifetime["total_crystals_spent"] += amount


func record_floor_explored() -> void:
	if current_run.has("floors_explored"):
		current_run["floors_explored"] += 1


## ─── DISPLAY DATA ───────────────────────────────────────────────

func get_lifetime_display() -> String:
	var text: String = ""
	text += "Total Runs: %d (%d wins, %d losses)\n" % [lifetime["total_runs"], lifetime["total_victories"], lifetime["total_deaths"]]
	var winrate: String = "%.0f%%" % (float(lifetime["total_victories"]) / float(maxi(lifetime["total_runs"], 1)) * 100.0)
	text += "Win Rate: %s\n" % winrate
	text += "Highest Floor: %d\n" % lifetime["highest_floor_ever"]
	text += "Floors Explored: %d\n" % lifetime["total_floors_explored"]
	text += "Enemies Killed: %d\n" % lifetime["total_enemies_killed"]
	text += "Damage Dealt: %d\n" % lifetime["total_damage_dealt"]
	text += "Damage Taken: %d\n" % lifetime["total_damage_taken"]
	text += "Total Heals: %d\n" % lifetime["total_heals"]
	text += "Items Used: %d\n" % lifetime["total_items_used"]
	text += "Gold Earned: %d (Spent: %d)\n" % [lifetime["total_gold_earned"], lifetime["total_gold_spent"]]
	text += "Crystals Earned: %d (Spent: %d)\n" % [lifetime["total_crystals_earned"], lifetime["total_crystals_spent"]]
	text += "Best Single Run Gold: %d\n" % lifetime["most_gold_single_run"]
	return text


func get_history_display() -> String:
	if history.is_empty():
		return "No runs recorded yet.\n"
	
	var text: String = ""
	# Show most recent first
	var display_list: Array = history.duplicate()
	display_list.reverse()
	
	for entry in display_list:
		var result_color: String = entry["result"]
		text += "Run #%d — %s | Floor %d | %dG | %d kills\n" % [
			entry["run_number"], result_color, entry["floors"],
			entry["gold"], entry["enemies"]
		]
		text += "  Party: %s\n" % ", ".join(entry["party"])
	
	return text


## ─── PERSISTENCE ────────────────────────────────────────────────

func _save() -> void:
	var data: Dictionary = {
		"lifetime": lifetime,
		"history": history,
	}
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) == OK:
		var data = json.get_data()
		if data is Dictionary:
			# Merge lifetime (preserves new keys)
			var saved_lifetime: Dictionary = data.get("lifetime", {})
			for key in saved_lifetime:
				if lifetime.has(key):
					lifetime[key] = saved_lifetime[key]
			# Load history
			var saved_history: Array = data.get("history", [])
			history.clear()
			for entry in saved_history:
				history.append(entry)
