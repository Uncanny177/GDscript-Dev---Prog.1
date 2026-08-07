## RitualAltar — Interactable dungeon object for performing rites.
##
## "Draw the circle with your own blood — it must be fresh.
##  Speak the name three times. The cost is always more than you expect.
##  The benefit... sometimes worth it."
##
## Altars are found in the dungeon and offer a choice:
##   - Pay a COST (HP, sanity, gold, items)
##   - Receive a BENEFIT (stats, knowledge, spells, healing, buffs)
##
## Each altar is dedicated to an elder god, which determines:
##   - What it offers
##   - What it costs
##   - Visual theme (for when we add art)
##
## Altars can also grant bestiary knowledge (ties into Task 47/52).

extends Node

## ─── ALTAR DATA ─────────────────────────────────────────────────

## Cost types for rituals
enum CostType { HP, SANITY, GOLD, MAX_HP, ITEM, PARTY_MEMBER_HP }

## Benefit types from rituals
enum BenefitType {
	STAT_BOOST,       # Permanent +stat
	HEAL_PARTY,       # Full heal all
	GRANT_KNOWLEDGE,  # Bestiary tier-up for an enemy
	LEARN_SKILL,      # New skill for a character
	BUFF,             # Temporary combat buff next fight
	GOLD,             # Gold reward
	REVEAL_MAP,       # Show current floor layout
	SANITY_RESTORE,   # Restore sanity
}

## A single ritual offering
class RitualOffering:
	var offering_name: String = ""
	var description: String = ""
	var patron_god: String = ""
	
	# Cost
	var cost_type: int = CostType.SANITY  # Use int for inner-class enum safety
	var cost_amount: int = 10
	var cost_description: String = ""
	
	# Benefit
	var benefit_type: int = BenefitType.STAT_BOOST
	var benefit_value: String = ""  # Interpreted based on benefit_type
	var benefit_amount: int = 0
	var benefit_description: String = ""
	
	# Requirements (optional)
	var requires_knowledge_of: String = ""  # Must have bestiary entry at tier 1+
	var requires_journal_entry: String = ""  # Must have found a specific journal
	var min_floor: int = 0  # Only appears on this floor or deeper


## ─── ALTAR GENERATION ───────────────────────────────────────────

## All possible ritual offerings organized by patron god
var _offering_pools: Dictionary = {}


func _ready() -> void:
	_build_offering_pools()
	print("[RitualAltar] %d gods, %d total offerings" % [
		_offering_pools.size(),
		_count_total_offerings()
	])


func generate_altar(floor_num: int, god_override: String = "") -> Dictionary:
	## Generate a random altar encounter for the given floor.
	## Returns a Dictionary with altar data for the event/room system.
	##
	## Structure: {
	##   "god": String,
	##   "offerings": Array[RitualOffering] (1-3 choices),
	##   "flavor_text": String,
	## }
	
	var god: String = god_override
	if god == "":
		god = _pick_random_god()
	
	var available: Array = _get_offerings_for_floor(god, floor_num)
	var num_choices: int = mini(available.size(), randi_range(1, 3))
	
	# Shuffle and pick
	available.shuffle()
	var offerings: Array = []
	for i in range(num_choices):
		offerings.append(available[i])
	
	return {
		"god": god,
		"offerings": offerings,
		"flavor_text": _get_altar_flavor(god),
	}


## ─── PERFORMING RITUALS ─────────────────────────────────────────

func perform_ritual(offering: RitualOffering, character: CharacterData) -> Dictionary:
	## Attempt to perform a ritual. Returns result dictionary.
	## {
	##   "success": bool,
	##   "message": String,
	##   "cost_paid": String,
	##   "benefit_gained": String,
	## }
	
	# Check requirements
	if not _meets_requirements(offering):
		return {
			"success": false,
			"message": "The altar remains silent. You lack the knowledge to perform this rite.",
			"cost_paid": "",
			"benefit_gained": "",
		}
	
	# Check if player can afford cost
	if not _can_afford(offering, character):
		return {
			"success": false,
			"message": "You cannot pay the price the altar demands.",
			"cost_paid": "",
			"benefit_gained": "",
		}
	
	# Pay the cost
	var cost_msg: String = _pay_cost(offering, character)
	
	# Grant the benefit
	var benefit_msg: String = _grant_benefit(offering, character)
	
	# Sanity hit from performing dark rituals (small additional cost)
	SanitySystem.lose_sanity(character, 3, "performed a dark ritual")
	
	return {
		"success": true,
		"message": "The ritual is complete. The god acknowledges your offering.",
		"cost_paid": cost_msg,
		"benefit_gained": benefit_msg,
	}


## ─── COST HANDLING ──────────────────────────────────────────────

func _can_afford(offering: RitualOffering, character: CharacterData) -> bool:
	match offering.cost_type:
		CostType.HP:
			return character.current_hp > offering.cost_amount
		CostType.SANITY:
			return character.sanity > offering.cost_amount
		CostType.GOLD:
			return GameManager.current_gold >= offering.cost_amount
		CostType.MAX_HP:
			# Can always sacrifice max HP (dangerous!)
			return character.current_hp > 1
		CostType.ITEM:
			# Check if party has any items
			return GameManager.inventory.get_total_items() > 0
		CostType.PARTY_MEMBER_HP:
			# Costs HP from ALL party members
			for member in PartyManager.active_party:
				if member.current_hp <= offering.cost_amount:
					return false
			return true
	return false


func _pay_cost(offering: RitualOffering, character: CharacterData) -> String:
	match offering.cost_type:
		CostType.HP:
			character.current_hp -= offering.cost_amount
			if character.current_hp < 1:
				character.current_hp = 1
			return "Lost %d HP" % offering.cost_amount
		CostType.SANITY:
			SanitySystem.lose_sanity(character, offering.cost_amount, "ritual sacrifice")
			return "Lost %d Sanity" % offering.cost_amount
		CostType.GOLD:
			GameManager.current_gold -= offering.cost_amount
			return "Paid %d gold" % offering.cost_amount
		CostType.MAX_HP:
			# Permanently reduce max HP (terrifying)
			if character.character_class and character.character_class.base_stats:
				character.character_class.base_stats.max_hp -= offering.cost_amount
				if character.current_hp > character.character_class.base_stats.max_hp:
					character.current_hp = character.character_class.base_stats.max_hp
			return "Permanently lost %d Max HP" % offering.cost_amount
		CostType.ITEM:
			# Remove a random item
			var removed: String = GameManager.inventory.remove_random_item()
			return "Sacrificed: %s" % removed
		CostType.PARTY_MEMBER_HP:
			for member in PartyManager.active_party:
				member.current_hp -= offering.cost_amount
				if member.current_hp < 1:
					member.current_hp = 1
			return "All party members lost %d HP" % offering.cost_amount
	return ""


## ─── BENEFIT HANDLING ───────────────────────────────────────────

func _grant_benefit(offering: RitualOffering, character: CharacterData) -> String:
	match offering.benefit_type:
		BenefitType.STAT_BOOST:
			return _apply_stat_boost(offering, character)
		BenefitType.HEAL_PARTY:
			for member in PartyManager.active_party:
				member.current_hp = member.get_stats().max_hp
				member.current_mp = member.get_stats().max_mp
			return "Party fully healed"
		BenefitType.GRANT_KNOWLEDGE:
			BestiarySystem.grant_knowledge(offering.benefit_value, KnowledgeTier.MASTERED)
			return "Gained mastery knowledge of %s" % offering.benefit_value
		BenefitType.LEARN_SKILL:
			# TODO: Implement skill learning from altars (Task 52+)
			return "Learned forbidden knowledge"
		BenefitType.BUFF:
			# Store a buff that applies at next combat start
			GameManager.set_meta("altar_buff_%s" % offering.benefit_value, offering.benefit_amount)
			return "+%d %s for next combat" % [offering.benefit_amount, offering.benefit_value]
		BenefitType.GOLD:
			GameManager.add_gold(offering.benefit_amount)
			return "Received %d gold" % offering.benefit_amount
		BenefitType.REVEAL_MAP:
			# Set a flag the minimap can check
			GameManager.set_meta("map_revealed", true)
			return "The floor layout is revealed"
		BenefitType.SANITY_RESTORE:
			SanitySystem.recover_sanity(character, offering.benefit_amount)
			return "Restored %d sanity" % offering.benefit_amount
	return ""


func _apply_stat_boost(offering: RitualOffering, character: CharacterData) -> String:
	var stat_name: String = offering.benefit_value
	var amount: int = offering.benefit_amount
	
	if character.stat_bonuses == null:
		character.stat_bonuses = StatBlock.new()
	
	match stat_name:
		"atk":
			character.stat_bonuses.atk += amount
		"def":
			character.stat_bonuses.def_stat += amount
		"mag":
			character.stat_bonuses.mag += amount
		"res":
			character.stat_bonuses.res_stat += amount
		"spd":
			character.stat_bonuses.spd += amount
		"max_hp":
			character.stat_bonuses.max_hp += amount
		"max_mp":
			character.stat_bonuses.max_mp += amount
	
	return "+%d %s (permanent)" % [amount, stat_name.to_upper()]


## ─── REQUIREMENTS ───────────────────────────────────────────────

func _meets_requirements(offering: RitualOffering) -> bool:
	if offering.requires_knowledge_of != "":
		if BestiarySystem.get_tier(offering.requires_knowledge_of) < 1:
			return false
	if offering.requires_journal_entry != "":
		if offering.requires_journal_entry not in BestiarySystem.journal:
			return false
		if not BestiarySystem.journal[offering.requires_journal_entry].discovered:
			return false
	return true


## ─── OFFERING POOLS ─────────────────────────────────────────────

func _build_offering_pools() -> void:
	## Define all ritual offerings per god.
	
	# ─── NETH'ZARR (The Void Father) — Knowledge at cost of sanity ───
	_offering_pools["Neth'zarr"] = _build_nethzarr_offerings()
	
	# ─── KAEL'THUN (The Frost That Thinks) — Defense at cost of HP ───
	_offering_pools["Kael'thun"] = _build_kaelthun_offerings()
	
	# ─── MOR'GHUL (The Flesh-Shaper) — HP/healing at cost of stats ───
	_offering_pools["Mor'ghul"] = _build_morghul_offerings()
	
	# ─── VHOR'AX (The Blood Drinker) — Attack at cost of blood ───
	_offering_pools["Vhor'ax"] = _build_vhorax_offerings()
	
	# ─── YITH'AEL (The Dream Keeper) — Magic at cost of sanity ───
	_offering_pools["Yith'ael"] = _build_yithael_offerings()
	
	# ─── XOTH'RA (The Plague Mother) — Debuffs/gold at random cost ───
	_offering_pools["Xoth'ra"] = _build_xothra_offerings()


func _build_nethzarr_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Whispered Secrets"
	o1.description = "The Void Father reveals an enemy's true nature."
	o1.patron_god = "Neth'zarr"
	o1.cost_type = CostType.SANITY
	o1.cost_amount = 15
	o1.cost_description = "15 Sanity"
	o1.benefit_type = BenefitType.GRANT_KNOWLEDGE
	o1.benefit_value = "cultist"  # Grants mastery of void cultist
	o1.benefit_description = "Master knowledge of an enemy"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Void Gaze"
	o2.description = "See beyond the walls. The dungeon's layout is laid bare."
	o2.patron_god = "Neth'zarr"
	o2.cost_type = CostType.SANITY
	o2.cost_amount = 20
	o2.cost_description = "20 Sanity"
	o2.benefit_type = BenefitType.REVEAL_MAP
	o2.benefit_description = "Reveal floor layout"
	o2.min_floor = 2
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Hollow Mind"
	o3.description = "Empty yourself. Become a vessel for forbidden magic."
	o3.patron_god = "Neth'zarr"
	o3.cost_type = CostType.SANITY
	o3.cost_amount = 25
	o3.cost_description = "25 Sanity"
	o3.benefit_type = BenefitType.STAT_BOOST
	o3.benefit_value = "mag"
	o3.benefit_amount = 5
	o3.benefit_description = "+5 MAG permanent"
	o3.min_floor = 3
	offerings.append(o3)
	
	return offerings


func _build_kaelthun_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Frozen Shell"
	o1.description = "Frost hardens your skin. You feel less... everything."
	o1.patron_god = "Kael'thun"
	o1.cost_type = CostType.HP
	o1.cost_amount = 20
	o1.cost_description = "20 HP"
	o1.benefit_type = BenefitType.STAT_BOOST
	o1.benefit_value = "def"
	o1.benefit_amount = 4
	o1.benefit_description = "+4 DEF permanent"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Winter's Embrace"
	o2.description = "The cold numbs pain. All wounds close under frost."
	o2.patron_god = "Kael'thun"
	o2.cost_type = CostType.GOLD
	o2.cost_amount = 50
	o2.cost_description = "50 Gold"
	o2.benefit_type = BenefitType.HEAL_PARTY
	o2.benefit_description = "Full party heal"
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Glacial Fortitude"
	o3.description = "Your blood runs cold. Your body endures more."
	o3.patron_god = "Kael'thun"
	o3.cost_type = CostType.SANITY
	o3.cost_amount = 10
	o3.cost_description = "10 Sanity"
	o3.benefit_type = BenefitType.STAT_BOOST
	o3.benefit_value = "max_hp"
	o3.benefit_amount = 10
	o3.benefit_description = "+10 Max HP permanent"
	o3.min_floor = 2
	offerings.append(o3)
	
	return offerings


func _build_morghul_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Flesh Reshaped"
	o1.description = "The Flesh-Shaper mends what was broken. It feels... wrong."
	o1.patron_god = "Mor'ghul"
	o1.cost_type = CostType.MAX_HP
	o1.cost_amount = 5
	o1.cost_description = "5 Max HP permanently"
	o1.benefit_type = BenefitType.HEAL_PARTY
	o1.benefit_description = "Full party heal"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Bone Reinforcement"
	o2.description = "New bones grow beneath your skin. They are not your own."
	o2.patron_god = "Mor'ghul"
	o2.cost_type = CostType.SANITY
	o2.cost_amount = 15
	o2.cost_description = "15 Sanity"
	o2.benefit_type = BenefitType.STAT_BOOST
	o2.benefit_value = "def"
	o2.benefit_amount = 3
	o2.benefit_description = "+3 DEF permanent"
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Visceral Knowledge"
	o3.description = "You understand flesh now. How it breaks. How it mends."
	o3.patron_god = "Mor'ghul"
	o3.cost_type = CostType.HP
	o3.cost_amount = 30
	o3.cost_description = "30 HP"
	o3.benefit_type = BenefitType.GRANT_KNOWLEDGE
	o3.benefit_value = "flesh_golem"
	o3.benefit_description = "Master knowledge of Flesh Golem"
	o3.requires_knowledge_of = "flesh_golem"
	o3.min_floor = 3
	offerings.append(o3)
	
	return offerings


func _build_vhorax_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Blood Offering"
	o1.description = "The altar drinks deep. Your veins sing with borrowed fury."
	o1.patron_god = "Vhor'ax"
	o1.cost_type = CostType.HP
	o1.cost_amount = 25
	o1.cost_description = "25 HP"
	o1.benefit_type = BenefitType.STAT_BOOST
	o1.benefit_value = "atk"
	o1.benefit_amount = 4
	o1.benefit_description = "+4 ATK permanent"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Crimson Tithe"
	o2.description = "Everyone bleeds. The Blood Drinker is generous in return."
	o2.patron_god = "Vhor'ax"
	o2.cost_type = CostType.PARTY_MEMBER_HP
	o2.cost_amount = 10
	o2.cost_description = "10 HP from ALL party"
	o2.benefit_type = BenefitType.GOLD
	o2.benefit_amount = 100
	o2.benefit_description = "100 Gold"
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Berserker's Pact"
	o3.description = "Sacrifice defense for overwhelming power."
	o3.patron_god = "Vhor'ax"
	o3.cost_type = CostType.MAX_HP
	o3.cost_amount = 10
	o3.cost_description = "10 Max HP permanently"
	o3.benefit_type = BenefitType.STAT_BOOST
	o3.benefit_value = "atk"
	o3.benefit_amount = 8
	o3.benefit_description = "+8 ATK permanent"
	o3.min_floor = 3
	offerings.append(o3)
	
	return offerings


func _build_yithael_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Dream Fragment"
	o1.description = "A sliver of the Dream Keeper's mind enters yours."
	o1.patron_god = "Yith'ael"
	o1.cost_type = CostType.SANITY
	o1.cost_amount = 20
	o1.cost_description = "20 Sanity"
	o1.benefit_type = BenefitType.STAT_BOOST
	o1.benefit_value = "max_mp"
	o1.benefit_amount = 10
	o1.benefit_description = "+10 Max MP permanent"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Nightmare Insight"
	o2.description = "Your dreams are no longer your own, but the power..."
	o2.patron_god = "Yith'ael"
	o2.cost_type = CostType.SANITY
	o2.cost_amount = 25
	o2.cost_description = "25 Sanity"
	o2.benefit_type = BenefitType.STAT_BOOST
	o2.benefit_value = "mag"
	o2.benefit_amount = 6
	o2.benefit_description = "+6 MAG permanent"
	o2.min_floor = 3
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Lucid Restoration"
	o3.description = "The Dream Keeper offers a rare kindness — dreamless sleep."
	o3.patron_god = "Yith'ael"
	o3.cost_type = CostType.GOLD
	o3.cost_amount = 75
	o3.cost_description = "75 Gold"
	o3.benefit_type = BenefitType.SANITY_RESTORE
	o3.benefit_amount = 30
	o3.benefit_description = "Restore 30 Sanity"
	offerings.append(o3)
	
	return offerings


func _build_xothra_offerings() -> Array:
	var offerings: Array = []
	
	var o1 := RitualOffering.new()
	o1.offering_name = "Plague's Gift"
	o1.description = "What doesn't kill you... changes you."
	o1.patron_god = "Xoth'ra"
	o1.cost_type = CostType.HP
	o1.cost_amount = 15
	o1.cost_description = "15 HP"
	o1.benefit_type = BenefitType.STAT_BOOST
	o1.benefit_value = "res"
	o1.benefit_amount = 5
	o1.benefit_description = "+5 RES permanent"
	offerings.append(o1)
	
	var o2 := RitualOffering.new()
	o2.offering_name = "Toxin Immunity"
	o2.description = "The Plague Mother inoculates her faithful. It hurts."
	o2.patron_god = "Xoth'ra"
	o2.cost_type = CostType.PARTY_MEMBER_HP
	o2.cost_amount = 8
	o2.cost_description = "8 HP from ALL party"
	o2.benefit_type = BenefitType.BUFF
	o2.benefit_value = "res"
	o2.benefit_amount = 10
	o2.benefit_description = "+10 RES next combat"
	offerings.append(o2)
	
	var o3 := RitualOffering.new()
	o3.offering_name = "Adaptive Flesh"
	o3.description = "Your body learns to fight infection. The lesson is agonizing."
	o3.patron_god = "Xoth'ra"
	o3.cost_type = CostType.SANITY
	o3.cost_amount = 12
	o3.cost_description = "12 Sanity"
	o3.benefit_type = BenefitType.STAT_BOOST
	o3.benefit_value = "spd"
	o3.benefit_amount = 3
	o3.benefit_description = "+3 SPD permanent"
	o3.min_floor = 2
	offerings.append(o3)
	
	return offerings


## ─── HELPERS ────────────────────────────────────────────────────

func _pick_random_god() -> String:
	var gods: Array = _offering_pools.keys()
	if gods.is_empty():
		return "Unknown"
	return gods[randi() % gods.size()]


func _get_offerings_for_floor(god: String, floor_num: int) -> Array:
	if god not in _offering_pools:
		return []
	var all_offerings: Array = _offering_pools[god]
	var available: Array = []
	for offering in all_offerings:
		if offering.min_floor <= floor_num:
			available.append(offering)
	return available


func _get_altar_flavor(god: String) -> String:
	match god:
		"Neth'zarr":
			return "A pillar of obsidian rises from the floor. The air around it hums with absence — as if sound itself is being consumed. Void sigils pulse with faint purple light."
		"Kael'thun":
			return "Frost crawls across the stone altar despite no cold in the air. Your breath does not mist. The ice seems to watch you, patient and eternal."
		"Mor'ghul":
			return "The altar is made of fused bone and sinew. It pulses like a heartbeat. Something beneath the surface shifts when you draw near."
		"Vhor'ax":
			return "Dark red channels are carved into the altar's surface, all flowing toward a central basin. The stone is warm to the touch. It thirsts."
		"Yith'ael":
			return "The altar shimmers, never quite solid. Looking at it directly makes your vision blur. From the corner of your eye, it appears to be dreaming."
		"Xoth'ra":
			return "Green-black fungal growths cover this altar. They release faint spores that glow in the dark. The air tastes of copper and decay."
	return "A strange altar stands before you, covered in ancient symbols you cannot read."


func _count_total_offerings() -> int:
	var total: int = 0
	for god in _offering_pools:
		total += _offering_pools[god].size()
	return total


## ─── INTEGRATION WITH EVENT SYSTEM ──────────────────────────────

## The KnowledgeTier constant for granting mastery (mirrors BestiarySystem)
const KnowledgeTier = 3  # MASTERED


func get_altar_event_data(floor_num: int) -> Dictionary:
	## Returns data formatted for the event/room system to display.
	## Call this when the player steps on an altar tile or enters an altar room.
	var altar: Dictionary = generate_altar(floor_num)
	
	var choices: Array[Dictionary] = []
	for offering in altar["offerings"]:
		choices.append({
			"text": "%s — Cost: %s | Reward: %s" % [
				offering.offering_name,
				offering.cost_description,
				offering.benefit_description,
			],
			"offering": offering,
		})
	
	# Always add "Leave" option
	choices.append({"text": "Leave the altar undisturbed.", "offering": null})
	
	return {
		"title": "Altar of %s" % altar["god"],
		"description": altar["flavor_text"],
		"choices": choices,
		"god": altar["god"],
	}
