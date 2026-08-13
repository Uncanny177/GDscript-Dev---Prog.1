## PermadeathSystem — Manages permanent character death and insanity removal.
##
## When a character dies in combat or goes insane, they can be PERMANENTLY
## removed from the game. This is togglable — not yet finalized in design.
##
## IMPORTANT: Has a reset function to undo all permadeaths (for testing
## or if the design changes). Nothing is truly permanent until the
## system is finalized.
##
## Modes (configurable):
##   DISABLED — No permadeath, characters revive at hub (current default)
##   SOFT — Characters dead in combat stay dead for that run, revive next run
##   HARD — Characters are permanently gone (true permadeath)
##
## Insanity removal:
##   When sanity hits 0, character is flagged as insane.
##   In HARD mode: removed from all rosters permanently.
##   In SOFT mode: unavailable for 1 run, then recovers (shaken but alive).

extends Node

## Current permadeath mode
enum Mode { DISABLED, SOFT, HARD }
var current_mode: Mode = Mode.DISABLED  # Start disabled until design is final

## Graveyard — characters permanently lost (only in HARD mode)
## Stored as character names for save/load
var graveyard: Array[String] = []

## Characters temporarily unavailable (SOFT mode — return after 1 run)
var benched: Array[String] = []


func _ready() -> void:
	print("[Permadeath] Mode: %s | Graveyard: %d | Benched: %d" % [
		Mode.keys()[current_mode], graveyard.size(), benched.size()
	])


## ─── MODE CONTROL ───────────────────────────────────────────────

func set_mode(mode: Mode) -> void:
	current_mode = mode
	print("[Permadeath] Mode changed to: %s" % Mode.keys()[mode])


func is_enabled() -> bool:
	return current_mode != Mode.DISABLED


## ─── DEATH HANDLING ─────────────────────────────────────────────

func on_character_died(character: CharacterData) -> Dictionary:
	## Called when a character dies in combat.
	## Returns {"removed": bool, "message": String}
	
	match current_mode:
		Mode.DISABLED:
			# Character just stays dead for this combat, revives at hub
			return {"removed": false, "message": "%s fell in battle." % character.character_name}
		Mode.SOFT:
			# Benched for 1 run
			if character.character_name not in benched:
				benched.append(character.character_name)
			return {"removed": false, "message": "%s is shaken and needs rest. (Unavailable next run)" % character.character_name}
		Mode.HARD:
			# Permanently gone
			_permanently_remove(character)
			return {"removed": true, "message": "%s has been lost forever..." % character.character_name}
	
	return {"removed": false, "message": ""}


func on_character_insane(character: CharacterData) -> Dictionary:
	## Called when a character's sanity hits 0.
	
	match current_mode:
		Mode.DISABLED:
			# Sanity resets to 10 instead of removal
			character.sanity = 10
			return {"removed": false, "message": "%s teeters on the edge of madness..." % character.character_name}
		Mode.SOFT:
			character.sanity = 10
			if character.character_name not in benched:
				benched.append(character.character_name)
			return {"removed": false, "message": "%s has glimpsed something terrible. (Unavailable next run)" % character.character_name}
		Mode.HARD:
			_permanently_remove(character)
			return {"removed": true, "message": "%s has lost their mind completely. They are gone." % character.character_name}
	
	return {"removed": false, "message": ""}


## ─── RUN MANAGEMENT ─────────────────────────────────────────────

func on_run_start() -> void:
	## Called at the start of each run. Handles benched characters.
	if current_mode == Mode.SOFT:
		# Un-bench everyone (they had their rest)
		benched.clear()
		print("[Permadeath] Benched characters restored")


func on_run_end() -> void:
	## Called at end of run. In DISABLED mode, revive all dead characters.
	if current_mode == Mode.DISABLED:
		for member in PartyManager.active_party:
			if not member.is_alive:
				member.is_alive = true
				member.current_hp = member.get_stats().max_hp
		for member in PartyManager.reserve:
			if not member.is_alive:
				member.is_alive = true
				member.current_hp = member.get_stats().max_hp


func is_benched(character_name: String) -> bool:
	return character_name in benched


## ─── RESET (for testing / design changes) ───────────────────────

func reset_all() -> void:
	## UNDO ALL PERMADEATHS. Clears graveyard and bench.
	## Use this if the design changes or for testing.
	## Does NOT restore removed characters to the party (they'd need to be re-recruited).
	graveyard.clear()
	benched.clear()
	print("[Permadeath] ALL DEATHS RESET — graveyard and bench cleared")


func reset_graveyard() -> void:
	## Clear only the permanent graveyard.
	graveyard.clear()
	print("[Permadeath] Graveyard cleared")


## ─── INTERNAL ───────────────────────────────────────────────────

func _permanently_remove(character: CharacterData) -> void:
	## Remove a character from all rosters permanently.
	var char_name: String = character.character_name
	
	# Add to graveyard
	if char_name not in graveyard:
		graveyard.append(char_name)
	
	# Remove from active party
	for i in range(PartyManager.active_party.size() - 1, -1, -1):
		if PartyManager.active_party[i].character_name == char_name:
			PartyManager.active_party.remove_at(i)
	
	# Remove from reserve
	for i in range(PartyManager.reserve.size() - 1, -1, -1):
		if PartyManager.reserve[i].character_name == char_name:
			PartyManager.reserve.remove_at(i)
	
	print("[Permadeath] %s permanently removed" % char_name)


## ─── QUERIES ────────────────────────────────────────────────────

func get_graveyard_display() -> String:
	if graveyard.is_empty():
		return "No fallen heroes."
	var text: String = "── Fallen Heroes ──\n"
	for entry in graveyard:
		text += "  † %s\n" % entry
	return text


## ─── SERIALIZATION ──────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"mode": current_mode,
		"graveyard": graveyard,
		"benched": benched,
	}


func from_dict(data: Dictionary) -> void:
	current_mode = int(data.get("mode", Mode.DISABLED)) as Mode
	graveyard.clear()
	for entry in data.get("graveyard", []):
		if entry is String:
			graveyard.append(entry)
	benched.clear()
	for entry in data.get("benched", []):
		if entry is String:
			benched.append(entry)
