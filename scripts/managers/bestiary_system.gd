## BestiarySystem — Tracks discovered enemies, lore entries, and knowledge progression.
##
## Core mechanic: knowledge-based progression. Players learn enemy weaknesses,
## lore about the elder gods, and dungeon secrets by encountering them.
##
## Three sections:
##   1. BESTIARY — Enemy entries (unlock by encountering/defeating)
##   2. JOURNAL — Lore entries (found in books, journals, altars)
##   3. KNOWLEDGE — Specific tactical info (weaknesses, immunities, patterns)
##
## Knowledge tiers per enemy:
##   0 = Unknown (silhouette, "???")
##   1 = Encountered (name, basic appearance)
##   2 = Studied (HP range, attack types visible)
##   3 = Mastered (weaknesses, resistances, drop table revealed)
##
## Persists across runs (this is the roguelite meta-progression).

extends Node

## ─── DATA STRUCTURES ────────────────────────────────────────────

## Enemy knowledge tiers
enum KnowledgeTier { UNKNOWN, ENCOUNTERED, STUDIED, MASTERED }

## A single bestiary entry
class BestiaryEntry:
	var enemy_id: String = ""
	var enemy_name: String = "???"
	var tier: int = KnowledgeTier.UNKNOWN
	var times_encountered: int = 0
	var times_defeated: int = 0
	var first_seen_floor: int = 0
	var patron_god: String = ""  # Which elder god this enemy serves
	var notes: Array[String] = []  # Player-discoverable notes
	
	func to_dict() -> Dictionary:
		return {
			"enemy_id": enemy_id,
			"enemy_name": enemy_name,
			"tier": tier,
			"times_encountered": times_encountered,
			"times_defeated": times_defeated,
			"first_seen_floor": first_seen_floor,
			"patron_god": patron_god,
			"notes": notes,
		}
	
	func from_dict(data: Dictionary) -> void:
		enemy_id = data.get("enemy_id", "")
		enemy_name = data.get("enemy_name", "???")
		tier = int(data.get("tier", KnowledgeTier.UNKNOWN))
		times_encountered = int(data.get("times_encountered", 0))
		times_defeated = int(data.get("times_defeated", 0))
		first_seen_floor = int(data.get("first_seen_floor", 0))
		patron_god = data.get("patron_god", "")
		notes.clear()
		for note in data.get("notes", []):
			if note is String:
				notes.append(note)


## A lore/journal entry
class JournalEntry:
	var entry_id: String = ""
	var title: String = ""
	var content: String = ""
	var category: String = "general"  # general, god_lore, dungeon, character
	var discovered: bool = false
	var discovery_run: int = 0  # Which run it was found on
	
	func to_dict() -> Dictionary:
		return {
			"entry_id": entry_id,
			"title": title,
			"content": content,
			"category": category,
			"discovered": discovered,
			"discovery_run": discovery_run,
		}
	
	func from_dict(data: Dictionary) -> void:
		entry_id = data.get("entry_id", "")
		title = data.get("title", "")
		content = data.get("content", "")
		category = data.get("category", "general")
		discovered = data.get("discovered", false)
		discovery_run = int(data.get("discovery_run", 0))


## ─── STATE ──────────────────────────────────────────────────────

## All bestiary entries keyed by enemy_id
var entries: Dictionary = {}

## All journal/lore entries keyed by entry_id
var journal: Dictionary = {}

## Total unique enemies discovered
var total_discovered: int = 0

## Total journal entries found
var total_journal_found: int = 0

## Signals for UI updates
signal enemy_discovered(enemy_id: String, tier: int)
signal enemy_tier_up(enemy_id: String, new_tier: int)
signal journal_entry_found(entry_id: String, title: String)


func _ready() -> void:
	_register_all_enemies()
	_register_all_journal_entries()
	print("[Bestiary] %d enemies registered | %d journal entries" % [entries.size(), journal.size()])


## ─── ENEMY TRACKING ─────────────────────────────────────────────

func on_enemy_encountered(enemy_id: String, floor_num: int = 0) -> void:
	## Called when player enters combat with an enemy.
	if enemy_id not in entries:
		_create_entry(enemy_id)
	
	var entry: BestiaryEntry = entries[enemy_id]
	entry.times_encountered += 1
	
	if entry.tier == KnowledgeTier.UNKNOWN:
		entry.tier = KnowledgeTier.ENCOUNTERED
		entry.first_seen_floor = floor_num
		total_discovered += 1
		enemy_discovered.emit(enemy_id, entry.tier)
		print("[Bestiary] New enemy discovered: %s" % entry.enemy_name)


func on_enemy_defeated(enemy_id: String) -> void:
	## Called when player defeats an enemy. May increase knowledge tier.
	if enemy_id not in entries:
		_create_entry(enemy_id)
	
	var entry: BestiaryEntry = entries[enemy_id]
	entry.times_defeated += 1
	
	# Auto-tier-up based on defeats
	var old_tier: int = entry.tier
	if entry.times_defeated >= 5 and entry.tier < KnowledgeTier.MASTERED:
		entry.tier = KnowledgeTier.MASTERED
	elif entry.times_defeated >= 2 and entry.tier < KnowledgeTier.STUDIED:
		entry.tier = KnowledgeTier.STUDIED
	
	if entry.tier > old_tier:
		enemy_tier_up.emit(enemy_id, entry.tier)
		print("[Bestiary] %s knowledge upgraded to %s" % [
			entry.enemy_name, KnowledgeTier.keys()[entry.tier]
		])


func grant_knowledge(enemy_id: String, tier: int) -> void:
	## Manually grant knowledge (from books, altars, NPCs).
	if enemy_id not in entries:
		_create_entry(enemy_id)
	
	var entry: BestiaryEntry = entries[enemy_id]
	if tier > entry.tier:
		var was_unknown: bool = entry.tier == KnowledgeTier.UNKNOWN
		entry.tier = tier
		if was_unknown:
			total_discovered += 1
			enemy_discovered.emit(enemy_id, tier)
		else:
			enemy_tier_up.emit(enemy_id, tier)
		print("[Bestiary] %s knowledge granted: %s" % [
			entry.enemy_name, KnowledgeTier.keys()[tier]
		])


func add_enemy_note(enemy_id: String, note: String) -> void:
	## Add a discoverable note to an enemy entry.
	if enemy_id not in entries:
		return
	var entry: BestiaryEntry = entries[enemy_id]
	if note not in entry.notes:
		entry.notes.append(note)


func get_tier(enemy_id: String) -> int:
	if enemy_id in entries:
		return entries[enemy_id].tier
	return KnowledgeTier.UNKNOWN


func is_weakness_known(enemy_id: String) -> bool:
	## Returns true if player has MASTERED this enemy (knows weaknesses).
	return get_tier(enemy_id) >= KnowledgeTier.MASTERED


## ─── JOURNAL / LORE ─────────────────────────────────────────────

func discover_journal_entry(entry_id: String) -> void:
	## Called when player finds a book, journal page, or lore tablet.
	if entry_id not in journal:
		return
	
	var entry: JournalEntry = journal[entry_id]
	if not entry.discovered:
		entry.discovered = true
		entry.discovery_run = GameManager.total_runs
		total_journal_found += 1
		journal_entry_found.emit(entry_id, entry.title)
		print("[Journal] Entry found: '%s'" % entry.title)


func get_discovered_journal_entries(category: String = "") -> Array:
	## Returns all discovered journal entries, optionally filtered by category.
	var results: Array = []
	for entry_id in journal:
		var entry: JournalEntry = journal[entry_id]
		if entry.discovered:
			if category == "" or entry.category == category:
				results.append(entry)
	return results


func get_journal_completion() -> Dictionary:
	## Returns {found: int, total: int, percent: float}
	var total: int = journal.size()
	if total == 0:
		return {"found": 0, "total": 0, "percent": 0.0}
	return {
		"found": total_journal_found,
		"total": total,
		"percent": float(total_journal_found) / float(total) * 100.0,
	}


## ─── DISPLAY HELPERS ────────────────────────────────────────────

func get_bestiary_display(enemy_id: String) -> Dictionary:
	## Returns display-ready info based on current knowledge tier.
	if enemy_id not in entries:
		return {"name": "???", "description": "Unknown creature.", "tier": 0}
	
	var entry: BestiaryEntry = entries[enemy_id]
	var info: Dictionary = {
		"name": entry.enemy_name if entry.tier >= KnowledgeTier.ENCOUNTERED else "???",
		"tier": entry.tier,
		"times_encountered": entry.times_encountered,
		"times_defeated": entry.times_defeated,
	}
	
	match entry.tier:
		KnowledgeTier.UNKNOWN:
			info["description"] = "You have not encountered this creature."
		KnowledgeTier.ENCOUNTERED:
			info["description"] = "You have seen this creature but know little about it."
		KnowledgeTier.STUDIED:
			info["description"] = "You have fought this creature enough to understand its patterns."
			info["patron_god"] = entry.patron_god
		KnowledgeTier.MASTERED:
			info["description"] = "You have mastered knowledge of this creature's weaknesses."
			info["patron_god"] = entry.patron_god
			info["notes"] = entry.notes
	
	return info


func get_completion() -> Dictionary:
	## Returns {discovered: int, total: int, mastered: int, percent: float}
	var total: int = entries.size()
	var mastered: int = 0
	for entry_id in entries:
		if entries[entry_id].tier >= KnowledgeTier.MASTERED:
			mastered += 1
	if total == 0:
		return {"discovered": 0, "total": 0, "mastered": 0, "percent": 0.0}
	return {
		"discovered": total_discovered,
		"total": total,
		"mastered": mastered,
		"percent": float(total_discovered) / float(total) * 100.0,
	}


## ─── REGISTRATION (all known enemies/journal entries) ───────────

func _register_all_enemies() -> void:
	## Register every enemy that exists in EnemyDatabase.
	## Waits until EnemyDatabase is ready, then pulls from it.
	## Also registers story enemies that may not be in the DB yet.
	
	# Register from EnemyDatabase (actual gameplay enemies)
	if EnemyDatabase and EnemyDatabase.enemies.size() > 0:
		for enemy_name in EnemyDatabase.enemies:
			var enemy_data: EnemyData = EnemyDatabase.enemies[enemy_name]
			var eid: String = enemy_data.get_id()
			if eid not in entries:
				var entry := BestiaryEntry.new()
				entry.enemy_id = eid
				entry.enemy_name = enemy_data.enemy_name
				entries[eid] = entry
	
	# Register story/lore enemies (may not be in EnemyDatabase yet)
	# These connect to the elder god pantheon for narrative purposes
	var story_enemies: Array[Dictionary] = [
		{"id": "cultist", "name": "Void Cultist", "god": "Neth'zarr"},
		{"id": "shadow_hound", "name": "Shadow Hound", "god": "Kael'thun"},
		{"id": "bone_sentinel", "name": "Bone Sentinel", "god": "Mor'ghul"},
		{"id": "mind_flayer", "name": "Mind Flayer", "god": "Yith'ael"},
		{"id": "blood_priest", "name": "Blood Priest", "god": "Vhor'ax"},
		{"id": "void_stalker", "name": "Void Stalker", "god": "Neth'zarr"},
		{"id": "flesh_golem", "name": "Flesh Golem", "god": "Mor'ghul"},
		{"id": "dream_weaver", "name": "Dream Weaver", "god": "Yith'ael"},
		{"id": "plague_bearer", "name": "Plague Bearer", "god": "Xoth'ra"},
		{"id": "frost_wraith", "name": "Frost Wraith", "god": "Kael'thun"},
		{"id": "crystal_horror", "name": "Crystal Horror", "god": "Shal'tek"},
		{"id": "abyssal_maw", "name": "Abyssal Maw", "god": "Vhor'ax"},
	]
	
	for def in story_enemies:
		var eid: String = def["id"]
		if eid not in entries:
			var entry := BestiaryEntry.new()
			entry.enemy_id = eid
			entry.enemy_name = def["name"]
			entry.patron_god = def["god"]
			entries[eid] = entry
		else:
			# Already registered from DB — just add god info
			entries[eid].patron_god = def["god"]


func _register_all_journal_entries() -> void:
	## Register all lore entries in the game.
	## Content can be expanded as story develops.
	var lore_defs: Array[Dictionary] = [
		{"id": "journal_001", "title": "A Scholar's Warning", "category": "dungeon",
		 "content": "To whomever finds this — turn back. The geometry here defies reason. I have walked the same corridor for what feels like days, yet my pocket watch shows only minutes have passed."},
		{"id": "journal_002", "title": "The Twelve Who Slumber", "category": "god_lore",
		 "content": "They are not dead, nor truly alive. The Old Ones exist between states — dreaming in frequencies our minds cannot process. Their agents walk these halls with singular purpose."},
		{"id": "journal_003", "title": "Rites of Neth'zarr", "category": "god_lore",
		 "content": "The Void Father demands nothing less than complete surrender of self. His cultists hollow themselves willingly, becoming vessels for his whispered commands."},
		{"id": "journal_004", "title": "Blood Pact Instructions", "category": "general",
		 "content": "Draw the circle with your own blood — it must be fresh. Speak the name three times. The cost is always more than you expect. The benefit... sometimes worth it."},
		{"id": "journal_005", "title": "Safe Room Markings", "category": "dungeon",
		 "content": "The blue sigils mean safety. Someone — or something — marked these rooms long ago. The creatures will not enter. I do not know why, and I am afraid to ask."},
		{"id": "journal_006", "title": "On the Nature of the Dungeon", "category": "dungeon",
		 "content": "It grows. Not like a plant — like a thought. Someone built the foundations, yes, but the dungeon thinks now. It reshapes itself according to rules we cannot fathom."},
		{"id": "journal_007", "title": "Kael'thun's Domain", "category": "god_lore",
		 "content": "The Frost That Thinks. His realm is silence made physical. Those who serve him lose their warmth first, then their voice, then their will."},
		{"id": "journal_008", "title": "Party Member Notes: The Soldier", "category": "character",
		 "content": "He came here for redemption. Something happened at the border — something he won't speak of. The dungeon calls to guilt like a moth to flame."},
		{"id": "journal_009", "title": "Weakness of the Bone Sentinels", "category": "general",
		 "content": "Lightning shatters the binding runes that hold them together. Without those runes, they are merely piles of old bone. Strike fast — they reform quickly."},
		{"id": "journal_010", "title": "The Exit That Isn't", "category": "dungeon",
		 "content": "I found the exit once. Walked right through the door, felt sunlight on my face. Then I blinked and I was three floors deeper. The dungeon does not let go easily."},
		{"id": "journal_011", "title": "Mor'ghul the Flesh-Shaper", "category": "god_lore",
		 "content": "He was once a healer — or so the oldest texts claim. Now he reshapes living things like clay. His creations are functional but wrong. Always wrong."},
		{"id": "journal_012", "title": "The Knowledge Paradox", "category": "general",
		 "content": "The more you learn about the dungeon, the more it learns about you. Every secret has a cost. Every answer breeds three questions. And yet — we cannot stop seeking."},
	]
	
	for def in lore_defs:
		var entry := JournalEntry.new()
		entry.entry_id = def["id"]
		entry.title = def["title"]
		entry.content = def["content"]
		entry.category = def["category"]
		journal[def["id"]] = entry


func _create_entry(enemy_id: String) -> void:
	## Create a blank entry for an unknown enemy (encountered but not pre-registered).
	var entry := BestiaryEntry.new()
	entry.enemy_id = enemy_id
	entry.enemy_name = enemy_id.replace("_", " ").capitalize()
	entries[enemy_id] = entry


## ─── SERIALIZATION ──────────────────────────────────────────────

func to_dict() -> Dictionary:
	var entries_data: Dictionary = {}
	for enemy_id in entries:
		entries_data[enemy_id] = entries[enemy_id].to_dict()
	
	var journal_data: Dictionary = {}
	for entry_id in journal:
		journal_data[entry_id] = journal[entry_id].to_dict()
	
	return {
		"entries": entries_data,
		"journal": journal_data,
		"total_discovered": total_discovered,
		"total_journal_found": total_journal_found,
	}


func from_dict(data: Dictionary) -> void:
	# Reload enemy entries (merge with registered ones to preserve new additions)
	var saved_entries: Dictionary = data.get("entries", {})
	for enemy_id in saved_entries:
		if enemy_id in entries:
			entries[enemy_id].from_dict(saved_entries[enemy_id])
		else:
			var entry := BestiaryEntry.new()
			entry.from_dict(saved_entries[enemy_id])
			entries[enemy_id] = entry
	
	# Reload journal entries
	var saved_journal: Dictionary = data.get("journal", {})
	for entry_id in saved_journal:
		if entry_id in journal:
			journal[entry_id].from_dict(saved_journal[entry_id])
		else:
			var entry := JournalEntry.new()
			entry.from_dict(saved_journal[entry_id])
			journal[entry_id] = entry
	
	total_discovered = int(data.get("total_discovered", 0))
	total_journal_found = int(data.get("total_journal_found", 0))
