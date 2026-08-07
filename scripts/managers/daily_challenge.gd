## DailyChallenge — Fixed-seed dungeon run that changes every day.
##
## Everyone who plays on the same day gets the same dungeon layout,
## same enemies, same loot. Compete for highest floor / fastest clear.
##
## The seed is derived from the current date (year + month + day).
## This means the challenge resets at midnight.
##
## Rules:
## - Fixed party (Warrior Lv3, Mage Lv3, Rogue Lv3)
## - No meta-crystal spending during the run
## - No items from inventory (start with 3 Health Potions only)
## - Score based on: floors cleared + enemies killed + gold earned
## - Best score saved per day

extends Node

const SAVE_PATH: String = "user://daily_challenge.json"

## Today's challenge data
var today_seed: int = 0
var today_date: String = ""
var best_score: int = 0
var best_floor: int = 0
var has_played_today: bool = false

## Current challenge run state
var is_challenge_active: bool = false
var challenge_score: int = 0

## Backup of player's real party (restored after challenge)
var _backup_party: Array = []
var _backup_reserve: Array = []


func _ready() -> void:
	_calculate_today()
	_load()
	print("[DailyChallenge] Today's seed: %d (%s)" % [today_seed, today_date])


func _calculate_today() -> void:
	## Generate today's seed from the date.
	var date: Dictionary = Time.get_date_dict_from_system()
	today_date = "%04d-%02d-%02d" % [date["year"], date["month"], date["day"]]
	today_seed = hash(today_date)  # Deterministic hash of date string


func get_today_seed() -> int:
	return today_seed


func start_challenge() -> void:
	## Begin a daily challenge run with fixed conditions.
	is_challenge_active = true
	challenge_score = 0
	has_played_today = true
	
	# Override GameManager state for challenge
	GameManager.is_run_active = true
	GameManager.current_gold = 0
	GameManager.current_floor = 1
	GameManager.current_state = GameManager.GameState.DUNGEON
	
	# Give minimal starter items
	GameManager.inventory = Inventory.new()
	var potion: ItemData = ItemDatabase.get_item("Health Potion")
	if potion:
		GameManager.inventory.add_item(potion, 3)
	
	# Set up a fixed party (override current party temporarily)
	_backup_party = PartyManager.active_party.duplicate()
	_backup_reserve = PartyManager.reserve.duplicate()
	_setup_challenge_party()
	
	print("[DailyChallenge] Challenge started — seed: %d" % today_seed)


func end_challenge(floor_reached: int, enemies_killed: int, gold_earned: int) -> void:
	## End the daily challenge and calculate score.
	is_challenge_active = false
	
	# Score formula: floors * 100 + kills * 10 + gold
	challenge_score = floor_reached * 100 + enemies_killed * 10 + gold_earned
	
	# Update best if improved
	if challenge_score > best_score:
		best_score = challenge_score
		best_floor = floor_reached
	
	# Restore player's real party
	if not _backup_party.is_empty():
		PartyManager.active_party = _backup_party
		PartyManager.reserve = _backup_reserve
		_backup_party = []
		_backup_reserve = []
	
	_save()
	print("[DailyChallenge] Challenge ended — Score: %d (Best: %d)" % [challenge_score, best_score])


func get_display_info() -> Dictionary:
	## Returns info for the UI to display.
	return {
		"date": today_date,
		"seed": today_seed,
		"best_score": best_score,
		"best_floor": best_floor,
		"has_played": has_played_today,
		"last_score": challenge_score,
	}


func _setup_challenge_party() -> void:
	## Create a fixed level 3 party for the challenge.
	PartyManager.active_party.clear()
	PartyManager.reserve.clear()
	
	var classes: Array[String] = ["Warrior", "Mage", "Rogue"]
	var names: Array[String] = ["Champion", "Arcana", "Shade"]
	
	for i in range(3):
		var character := CharacterData.new()
		character.character_name = names[i]
		character.character_class = ClassDatabase.get_class(classes[i])
		character.level = 3
		character.initialize()
		# Give some level bonuses manually (simulate being level 3)
		if character.stat_bonuses == null:
			character.stat_bonuses = StatBlock.new()
		character.stat_bonuses.max_hp = 20
		character.stat_bonuses.atk = 4
		character.stat_bonuses.def_stat = 3
		character.stat_bonuses.mag = 3
		character.stat_bonuses.spd = 2
		# Recalculate HP with bonuses
		character.current_hp = character.get_stats().max_hp
		character.current_mp = character.get_stats().max_mp
		PartyManager.active_party.append(character)


## ─── PERSISTENCE ────────────────────────────────────────────────

func _save() -> void:
	var data: Dictionary = {
		"date": today_date,
		"best_score": best_score,
		"best_floor": best_floor,
	}
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
			# Only load if it's today's data
			if data.get("date", "") == today_date:
				best_score = int(data.get("best_score", 0))
				best_floor = int(data.get("best_floor", 0))
				has_played_today = true
			else:
				# New day — reset
				best_score = 0
				best_floor = 0
				has_played_today = false
	file.close()
