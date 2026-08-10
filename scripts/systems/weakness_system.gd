## WeaknessSystem — Knowledge-based enemy weakness/resistance system.
##
## Core design: "Every enemy is a puzzle. Once solved, they're manageable."
##
## Each enemy has hidden weaknesses and resistances:
##   - WEAKNESS: Take extra damage from a specific attack type/element
##   - RESISTANCE: Take reduced damage from something
##   - SOLUTION: A specific strategy that dramatically increases damage
##
## Players discover weaknesses by:
##   - Reaching MASTERED tier in the bestiary (automatic reveal)
##   - Finding journal entries that hint at weaknesses
##   - Scholar NPCs in safe zones
##   - Ritual altar knowledge grants
##
## When weakness is KNOWN (bestiary mastered), the player sees it in combat UI.
## When weakness is EXPLOITED (correct element/type used), bonus damage applies.
##
## This is the roguelite meta-progression loop:
##   Run 1: Die to Bone Sentinel (don't know weakness)
##   Run 2: Mastered Bone Sentinel in bestiary → "Weak to Lightning"
##   Run 3: Bring lightning skills → Bone Sentinel is trivial

extends Node

## ─── WEAKNESS DATA ──────────────────────────────────────────────

class EnemyWeakness:
	var enemy_id: String = ""
	var weak_elements: Array[String] = []      # Elements that deal bonus damage
	var weak_damage_type: String = ""          # "physical" or "magical" (optional)
	var resist_elements: Array[String] = []    # Elements that deal reduced damage
	var solution_hint: String = ""             # Displayed when STUDIED
	var solution_detail: String = ""           # Displayed when MASTERED
	var weakness_multiplier: float = 1.75     # Bonus damage when exploiting weakness
	var resistance_multiplier: float = 0.5    # Reduced damage from resisted elements


## All weakness definitions keyed by enemy_id
var weaknesses: Dictionary = {}

## Bonus damage multiplier when player knows AND exploits a weakness
const KNOWLEDGE_BONUS: float = 1.25  # +25% damage on mastered enemies (general)


func _ready() -> void:
	_build_weakness_data()
	print("[WeaknessSystem] %d enemy weaknesses defined" % weaknesses.size())


## ─── DAMAGE MODIFICATION ────────────────────────────────────────

func get_damage_multiplier(attacker_enemy_id: String, skill: SkillData, target_enemy_id: String) -> float:
	## Returns the damage multiplier when attacking a specific enemy.
	## Called by DamageCalculator after base damage is computed.
	##
	## Returns > 1.0 for weakness exploitation, < 1.0 for resistance.
	## Returns 1.0 if no weakness data or weakness not known.
	
	if target_enemy_id == "" or target_enemy_id not in weaknesses:
		return 1.0
	
	var data: EnemyWeakness = weaknesses[target_enemy_id]
	
	# Check if player has mastered this enemy (knows weaknesses)
	var is_mastered: bool = BestiarySystem.is_weakness_known(target_enemy_id)
	
	var multiplier: float = 1.0
	
	# General knowledge bonus (mastered enemies take slightly more damage)
	if is_mastered:
		multiplier *= KNOWLEDGE_BONUS
	
	# Check elemental weakness
	if skill and skill.element != "" and skill.element != "none":
		if skill.element in data.weak_elements:
			multiplier *= data.weakness_multiplier
		elif skill.element in data.resist_elements:
			multiplier *= data.resistance_multiplier
	
	# Check damage type weakness
	if skill and data.weak_damage_type != "":
		match data.weak_damage_type:
			"physical":
				if skill.damage_type == SkillData.DamageType.PHYSICAL:
					multiplier *= 1.3
			"magical":
				if skill.damage_type == SkillData.DamageType.MAGICAL:
					multiplier *= 1.3
	
	return multiplier


func get_weakness_display(enemy_id: String) -> Dictionary:
	## Returns weakness info for combat UI display.
	## Only reveals info if player has sufficient bestiary knowledge.
	
	if enemy_id not in weaknesses:
		return {"known": false, "hint": "", "details": ""}
	
	var data: EnemyWeakness = weaknesses[enemy_id]
	var tier: int = BestiarySystem.get_tier(enemy_id)
	
	match tier:
		0, 1:  # UNKNOWN or ENCOUNTERED — no info
			return {"known": false, "hint": "", "details": ""}
		2:  # STUDIED — show hint only
			return {"known": false, "hint": data.solution_hint, "details": ""}
		3:  # MASTERED — full reveal
			return {
				"known": true,
				"hint": data.solution_hint,
				"details": data.solution_detail,
				"weak_to": data.weak_elements,
				"resists": data.resist_elements,
			}
	
	return {"known": false, "hint": "", "details": ""}


## ─── WEAKNESS DEFINITIONS ───────────────────────────────────────

func _build_weakness_data() -> void:
	## Define weaknesses for every enemy in the game.
	## Format: what they're weak to, what they resist, and the "solution."
	
	# ─── TIER 1 ENEMIES (Floors 1-2) ─────────────────────────────
	
	var slime := EnemyWeakness.new()
	slime.enemy_id = "slime"
	slime.weak_elements = ["fire"]
	slime.resist_elements = ["ice"]
	slime.weak_damage_type = "magical"
	slime.solution_hint = "It reacts strangely to heat..."
	slime.solution_detail = "Weak to FIRE magic. Resistant to ICE. Physical attacks pass through."
	weaknesses["slime"] = slime
	
	var goblin := EnemyWeakness.new()
	goblin.enemy_id = "goblin"
	goblin.weak_elements = ["light"]
	goblin.resist_elements = []
	goblin.weak_damage_type = "physical"
	goblin.solution_hint = "Cowardly creatures. They flinch from brightness."
	goblin.solution_detail = "Weak to LIGHT. Physical attacks most effective (low DEF)."
	weaknesses["goblin"] = goblin
	
	var cultist := EnemyWeakness.new()
	cultist.enemy_id = "cultist"
	cultist.weak_elements = ["light"]
	cultist.resist_elements = ["dark"]
	cultist.solution_hint = "Servants of the void. The void has an opposite..."
	cultist.solution_detail = "Weak to LIGHT. Resistant to DARK. They hollowed themselves — low HP."
	weaknesses["cultist"] = cultist
	
	var shadow_hound := EnemyWeakness.new()
	shadow_hound.enemy_id = "shadow_hound"
	shadow_hound.weak_elements = ["fire", "light"]
	shadow_hound.resist_elements = ["dark", "ice"]
	shadow_hound.solution_hint = "It shrinks from flame and fades in bright light."
	shadow_hound.solution_detail = "Weak to FIRE and LIGHT. Resists DARK and ICE. Fast but fragile."
	weaknesses["shadow_hound"] = shadow_hound
	
	# ─── TIER 2 ENEMIES (Floors 3-4) ─────────────────────────────
	
	var skeleton := EnemyWeakness.new()
	skeleton.enemy_id = "skeleton"
	skeleton.weak_elements = ["light"]
	skeleton.resist_elements = ["dark"]
	skeleton.weak_damage_type = "magical"
	skeleton.solution_hint = "Held together by dark magic. Disrupt the binding."
	skeleton.solution_detail = "Weak to LIGHT magic. Resists DARK. Holy spells shatter them instantly."
	weaknesses["skeleton"] = skeleton
	
	var dark_knight := EnemyWeakness.new()
	dark_knight.enemy_id = "dark_knight"
	dark_knight.weak_elements = ["light"]
	dark_knight.resist_elements = ["dark", "fire"]
	dark_knight.solution_hint = "Heavy armor, but slow. Something burns beneath."
	dark_knight.solution_detail = "Weak to LIGHT. Resists DARK and FIRE. Target with fast attackers (low SPD)."
	weaknesses["dark_knight"] = dark_knight
	
	var bone_sentinel := EnemyWeakness.new()
	bone_sentinel.enemy_id = "bone_sentinel"
	bone_sentinel.weak_elements = ["fire"]
	bone_sentinel.resist_elements = ["ice", "dark"]
	bone_sentinel.weak_damage_type = "magical"
	bone_sentinel.solution_hint = "Binding runes hold the bones together. Break the runes."
	bone_sentinel.solution_detail = "Weak to FIRE (burns runes). Resists ICE and DARK. Lightning shatters them."
	bone_sentinel.weakness_multiplier = 2.0  # Extra vulnerable when exploited
	weaknesses["bone_sentinel"] = bone_sentinel
	
	var mind_flayer := EnemyWeakness.new()
	mind_flayer.enemy_id = "mind_flayer"
	mind_flayer.weak_elements = ["fire"]
	mind_flayer.resist_elements = ["dark"]
	mind_flayer.weak_damage_type = "physical"
	mind_flayer.solution_hint = "Its power is mental. A strong body resists it."
	mind_flayer.solution_detail = "Weak to FIRE and PHYSICAL attacks. Resists DARK. Keep sanity high."
	weaknesses["mind_flayer"] = mind_flayer

	# ─── TIER 3 ENEMIES (Floor 5+) ───────────────────────────────
	
	var blood_priest := EnemyWeakness.new()
	blood_priest.enemy_id = "blood_priest"
	blood_priest.weak_elements = ["ice", "light"]
	blood_priest.resist_elements = ["fire", "dark"]
	blood_priest.solution_hint = "It draws power from warmth and blood. Deny it both."
	blood_priest.solution_detail = "Weak to ICE and LIGHT. Resists FIRE and DARK. Freeze the blood it feeds on."
	weaknesses["blood_priest"] = blood_priest
	
	var void_stalker := EnemyWeakness.new()
	void_stalker.enemy_id = "void_stalker"
	void_stalker.weak_elements = ["light"]
	void_stalker.resist_elements = ["dark"]
	void_stalker.weak_damage_type = "physical"
	void_stalker.solution_hint = "It phases between realities. Pin it in THIS one."
	void_stalker.solution_detail = "Weak to LIGHT and PHYSICAL (grounds it). Resists DARK. Strike when solid."
	weaknesses["void_stalker"] = void_stalker
	
	var flesh_golem := EnemyWeakness.new()
	flesh_golem.enemy_id = "flesh_golem"
	flesh_golem.weak_elements = ["fire"]
	flesh_golem.resist_elements = ["ice"]
	flesh_golem.weak_damage_type = "magical"
	flesh_golem.solution_hint = "Stitched flesh. It regenerates unless you cauterize."
	flesh_golem.solution_detail = "Weak to FIRE (prevents regeneration). Resists ICE. Burn the stitches."
	flesh_golem.weakness_multiplier = 2.0
	weaknesses["flesh_golem"] = flesh_golem
	
	var dream_weaver := EnemyWeakness.new()
	dream_weaver.enemy_id = "dream_weaver"
	dream_weaver.weak_elements = ["dark"]
	dream_weaver.resist_elements = ["light"]
	dream_weaver.weak_damage_type = "physical"
	dream_weaver.solution_hint = "Illusions break against harsh reality."
	dream_weaver.solution_detail = "Weak to DARK and PHYSICAL (reality). Resists LIGHT (it IS light). Punch through the dream."
	weaknesses["dream_weaver"] = dream_weaver
	
	var plague_bearer := EnemyWeakness.new()
	plague_bearer.enemy_id = "plague_bearer"
	plague_bearer.weak_elements = ["fire", "ice"]
	plague_bearer.resist_elements = []
	plague_bearer.solution_hint = "Extreme temperatures kill the parasites inside."
	plague_bearer.solution_detail = "Weak to FIRE and ICE (extreme temps). No resistances. Purge with heat or cold."
	weaknesses["plague_bearer"] = plague_bearer
	
	var crystal_horror := EnemyWeakness.new()
	crystal_horror.enemy_id = "crystal_horror"
	crystal_horror.weak_elements = ["dark"]
	crystal_horror.resist_elements = ["light"]
	crystal_horror.weak_damage_type = "physical"
	crystal_horror.solution_hint = "Perfect crystal. Perfect order. Introduce chaos."
	crystal_horror.solution_detail = "Weak to DARK (disorder) and PHYSICAL (shatter). Resists LIGHT (reinforces structure)."
	crystal_horror.weakness_multiplier = 2.0
	weaknesses["crystal_horror"] = crystal_horror
	
	var abyssal_maw := EnemyWeakness.new()
	abyssal_maw.enemy_id = "abyssal_maw"
	abyssal_maw.weak_elements = ["ice", "light"]
	abyssal_maw.resist_elements = ["fire", "dark"]
	abyssal_maw.solution_hint = "Endless hunger. Freeze it shut. Blind it with light."
	abyssal_maw.solution_detail = "Weak to ICE (slows jaws) and LIGHT (disrupts void). Resists FIRE and DARK."
	weaknesses["abyssal_maw"] = abyssal_maw
	
	var frost_wraith := EnemyWeakness.new()
	frost_wraith.enemy_id = "frost_wraith"
	frost_wraith.weak_elements = ["fire"]
	frost_wraith.resist_elements = ["ice", "dark"]
	frost_wraith.solution_hint = "Made of cold. Heat is its antithesis."
	frost_wraith.solution_detail = "Weak to FIRE (melts instantly). Immune to ICE. Resists DARK."
	frost_wraith.weakness_multiplier = 2.5  # Fire destroys it
	weaknesses["frost_wraith"] = frost_wraith
