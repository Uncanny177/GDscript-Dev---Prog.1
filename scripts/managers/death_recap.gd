## DeathRecap — Tracks combat data for the death screen.
##
## Records what happened during the fatal run so the player can
## learn from their mistakes. Shown after party wipe instead of
## going straight to hub.

class_name DeathRecap
extends RefCounted

## What killed the party
var killing_blow_source: String = ""
var killing_blow_skill: String = ""
var killing_blow_damage: int = 0
var last_victim: String = ""

## Run stats at time of death
var floor_reached: int = 0
var enemies_killed: int = 0
var gold_earned: int = 0
var turns_taken: int = 0
var damage_dealt_total: int = 0
var damage_taken_total: int = 0
var items_used: int = 0

## Party state at death
var party_states: Array[Dictionary] = []  # [{name, class, level, hp, max_hp, alive}]


func record_killing_blow(source_name: String, skill_name: String, damage: int, victim_name: String) -> void:
	killing_blow_source = source_name
	killing_blow_skill = skill_name
	killing_blow_damage = damage
	last_victim = victim_name


func record_run_stats(floor: int, kills: int, gold: int, turns: int, dmg_dealt: int, dmg_taken: int, items: int) -> void:
	floor_reached = floor
	enemies_killed = kills
	gold_earned = gold
	turns_taken = turns
	damage_dealt_total = dmg_dealt
	damage_taken_total = dmg_taken
	items_used = items


func record_party_state(party: Array) -> void:
	party_states.clear()
	for member in party:
		party_states.append({
			"name": member.character_name,
			"class": member.character_class.class_name_text if member.character_class else "Unknown",
			"level": member.level,
			"hp": member.current_hp,
			"max_hp": member.get_stats().max_hp,
			"alive": member.is_alive,
		})


func get_display_text() -> String:
	var text: String = "═══ RUN ENDED ═══\n\n"
	
	# Cause of death
	if killing_blow_source != "":
		text += "KILLED BY: %s\n" % killing_blow_source
		if killing_blow_skill != "":
			text += "  Using: %s (%d damage)\n" % [killing_blow_skill, killing_blow_damage]
		text += "  Last to fall: %s\n" % last_victim
	else:
		text += "The dungeon consumed your party.\n"
	
	text += "\n── Run Summary ──\n"
	text += "  Floor reached: %d\n" % floor_reached
	text += "  Enemies killed: %d\n" % enemies_killed
	text += "  Gold earned: %d\n" % gold_earned
	text += "  Turns in combat: %d\n" % turns_taken
	text += "  Damage dealt: %d\n" % damage_dealt_total
	text += "  Damage taken: %d\n" % damage_taken_total
	text += "  Items used: %d\n" % items_used
	
	text += "\n── Party Status ──\n"
	for state in party_states:
		var status: String = "DEAD" if not state["alive"] else "HP:%d/%d" % [state["hp"], state["max_hp"]]
		text += "  %s Lv%d (%s) — %s\n" % [state["name"], state["level"], state["class"], status]
	
	text += "\n[ENTER] Return to Hub"
	return text
