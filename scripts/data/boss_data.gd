## BossData — Defines a boss enemy with phases and special abilities.
##
## KEY CONCEPT: PHASE-BASED AI
## Unlike regular enemies that just pick random skills, bosses change
## behavior based on HP thresholds. Example:
##   Phase 1 (100%-50% HP): Normal attacks + occasional big skill
##   Phase 2 (<50% HP): Enraged — faster, harder hits, new abilities
##
## This makes boss fights feel dynamic. The player has to adapt their
## strategy mid-fight, which is more engaging than a stat-check.
##
## SUMMON MECHANIC:
## Some bosses can summon minions during phase transitions.
## This adds tactical pressure — do you focus the boss or clear adds?

class_name BossData
extends RefCounted

## Boss identity
var boss_name: String = "Unknown Boss"
var description: String = ""

## Base stats (higher than regular enemies)
var stats: StatBlock = null

## Placeholder color (until art)
var sprite_color: Color = Color(0.6, 0.1, 0.1)

## Phase thresholds — HP percentage where behavior changes
## Example: [0.5] means phase 2 starts at 50% HP
var phase_thresholds: Array[float] = [0.5]

## Skills for each phase. Index 0 = phase 1, index 1 = phase 2, etc.
## Each phase has an array of {skill: SkillData, weight: int}
var phase_skills: Array[Array] = []
var phase_weights: Array[Array] = []

## Can this boss summon minions? If so, which enemy?
var can_summon: bool = false
var summon_enemy_name: String = ""
var summon_count: int = 2
var has_summoned: bool = false  # Only summon once per fight

## Rewards
var gold_reward: int = 50
var meta_crystal_reward: int = 5

## Current phase during combat (tracked at runtime)
var current_phase: int = 0


func get_current_phase(current_hp: int) -> int:
	## Determine which phase the boss is in based on current HP.
	var max_hp: int = stats.max_hp if stats else 100
	var hp_ratio: float = float(current_hp) / float(max_hp)
	
	for i in range(phase_thresholds.size()):
		if hp_ratio <= phase_thresholds[i]:
			return i + 1  # Phase 2, 3, etc.
	
	return 0  # Phase 1 (above all thresholds)


func pick_skill(current_hp: int) -> SkillData:
	## Pick a skill based on current phase (weighted random within phase).
	var phase: int = get_current_phase(current_hp)
	phase = mini(phase, phase_skills.size() - 1)  # Clamp to available phases
	
	if phase < 0 or phase >= phase_skills.size():
		return null
	
	var skills: Array = phase_skills[phase]
	var weights: Array = phase_weights[phase]
	
	if skills.is_empty():
		return null
	
	# Weighted random selection
	var total_weight: int = 0
	for w in weights:
		total_weight += w
	
	if total_weight <= 0:
		return skills[0]
	
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return skills[i]
	
	return skills[0]


func should_summon(current_hp: int) -> bool:
	## Check if the boss should summon minions this turn.
	## Only summons once, when entering phase 2.
	if not can_summon or has_summoned:
		return false
	
	var phase: int = get_current_phase(current_hp)
	if phase >= 1:  # Entered phase 2+
		has_summoned = true
		return true
	
	return false
