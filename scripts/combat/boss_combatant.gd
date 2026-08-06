## BossCombatant — A specialized Combatant that uses phase-based AI.
##
## Extends the regular Combatant concept with:
## - Phase detection based on HP thresholds
## - Different skill pools per phase
## - Summoning minions on phase transition
## - Phase transition announcements (for UI feedback)
##
## The combat scene checks if an enemy is a boss and uses this
## instead of the basic random-target AI.

class_name BossCombatant
extends RefCounted

## The boss data definition
var boss_data: BossData = null

## Standard combatant fields (mirrors Combatant)
var is_player: bool = false
var current_hp: int = 0
var current_mp: int = 0
var is_alive: bool = true
var is_defending: bool = false
var display_name: String = "???"
var sprite_color: Color = Color.RED

## Phase tracking
var last_phase: int = 0


static func from_boss(data: BossData) -> BossCombatant:
	## Create a boss combatant from BossData.
	var bc := BossCombatant.new()
	bc.boss_data = data
	bc.is_player = false
	bc.current_hp = data.stats.max_hp
	bc.current_mp = data.stats.max_mp
	bc.is_alive = true
	bc.display_name = data.boss_name
	bc.sprite_color = data.sprite_color
	bc.last_phase = 0
	data.has_summoned = false  # Reset summon flag for this fight
	return bc


## ─── STAT ACCESSORS (same interface as Combatant) ───────────────

func get_max_hp() -> int:
	return boss_data.stats.max_hp if boss_data and boss_data.stats else 1

func get_max_mp() -> int:
	return boss_data.stats.max_mp if boss_data and boss_data.stats else 0

func get_atk() -> int:
	return boss_data.stats.atk if boss_data and boss_data.stats else 1

func get_def() -> int:
	return boss_data.stats.def_stat if boss_data and boss_data.stats else 0

func get_mag() -> int:
	return boss_data.stats.mag if boss_data and boss_data.stats else 1

func get_res() -> int:
	return boss_data.stats.res_stat if boss_data and boss_data.stats else 0

func get_spd() -> int:
	return boss_data.stats.spd if boss_data and boss_data.stats else 1


## ─── COMBAT ACTIONS ─────────────────────────────────────────────

func take_damage(amount: int) -> int:
	var actual: int = amount
	if is_defending:
		actual = maxi(int(actual / 2.0), 1)
	actual = mini(actual, current_hp)
	current_hp -= actual
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
	return actual


func defend() -> void:
	is_defending = true


func clear_defend() -> void:
	is_defending = false


## ─── BOSS AI ────────────────────────────────────────────────────

func pick_action() -> Dictionary:
	## Boss AI: pick a skill based on current phase.
	## Returns {"type": "attack"/"skill"/"summon", "skill": SkillData or null}
	
	if not boss_data:
		return {"type": "attack", "skill": null}
	
	# Check for phase transition summon
	if boss_data.should_summon(current_hp):
		return {"type": "summon", "skill": null}
	
	# Pick a skill from current phase
	var skill: SkillData = boss_data.pick_skill(current_hp)
	if skill:
		return {"type": "skill", "skill": skill}
	
	# Fallback: basic attack
	return {"type": "attack", "skill": null}


func check_phase_transition() -> bool:
	## Check if the boss entered a new phase since last check.
	## Returns true if phase changed (for UI announcement).
	if not boss_data:
		return false
	
	var new_phase: int = boss_data.get_current_phase(current_hp)
	if new_phase != last_phase:
		last_phase = new_phase
		return true
	return false


func _to_string() -> String:
	var phase_str: String = "P%d" % (last_phase + 1)
	return "%s [%s] HP:%d/%d" % [display_name, phase_str, current_hp, get_max_hp()]
