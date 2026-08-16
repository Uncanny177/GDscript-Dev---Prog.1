## SkillTree — Defines learnable skills per class at the Training Ground.
##
## Each class has additional skills beyond their starting set.
## Players spend meta-crystals to unlock new skills permanently.
## Requires the Training Ground facility (UnlocksManager).
##
## Skills unlock per-class (not per-character). Once unlocked,
## ALL characters of that class can use the skill.

class_name SkillTree
extends RefCounted

## Returns available skills to learn for a given class.
## Each entry: {"skill": SkillData, "cost": int, "level_req": int, "id": String}
## "id" is used to track which ones are unlocked.

static func get_learnable_skills(class_name_text: String) -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	
	match class_name_text:
		"Warrior":
			skills.append(_make_skill("warrior_war_cry", "War Cry", "Boosts own ATK for 3 turns.", 5, SkillData.TargetType.SELF, SkillData.DamageType.NONE, 0.0, "none", {"type": StatusEffect.Type.ATK_UP, "duration": 3, "potency": 25, "chance": 100}, 8, 3))
			skills.append(_make_skill("warrior_cleave", "Cleave", "Sweeps all enemies with a wide slash.", 8, SkillData.TargetType.ALL_ENEMIES, SkillData.DamageType.PHYSICAL, 0.8, "none", {}, 12, 5))
		"Mage":
			skills.append(_make_skill("mage_thunder", "Thunder", "Strikes one enemy with lightning.", 10, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.MAGICAL, 1.8, "light", {}, 10, 4))
			skills.append(_make_skill("mage_barrier", "Barrier", "Reduces damage to all allies for 2 turns.", 12, SkillData.TargetType.ALL_ALLIES, SkillData.DamageType.NONE, 0.0, "none", {}, 15, 6))
		"Rogue":
			skills.append(_make_skill("rogue_stun_strike", "Stun Strike", "A blow that stuns the target.", 6, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.PHYSICAL, 1.0, "none", {"type": StatusEffect.Type.STUN, "duration": 1, "potency": 0, "chance": 70}, 8, 3))
			skills.append(_make_skill("rogue_shadow_step", "Shadow Step", "Massive damage from the shadows.", 10, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.PHYSICAL, 2.5, "dark", {}, 14, 6))
		"Paladin":
			skills.append(_make_skill("paladin_smite", "Smite", "Holy damage to one enemy. Extra vs dark.", 7, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.MAGICAL, 1.6, "light", {}, 10, 4))
			skills.append(_make_skill("paladin_mass_heal", "Mass Heal", "Heals all allies.", 15, SkillData.TargetType.ALL_ALLIES, SkillData.DamageType.HEALING, 1.5, "light", {}, 18, 7))
		"Archer":
			skills.append(_make_skill("archer_cripple", "Crippling Shot", "Slows and weakens enemy DEF.", 5, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.PHYSICAL, 1.0, "none", {"type": StatusEffect.Type.DEF_DOWN, "duration": 3, "potency": 25, "chance": 85}, 8, 3))
			skills.append(_make_skill("archer_snipe", "Snipe", "Devastating single-target shot.", 8, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.PHYSICAL, 2.2, "none", {}, 12, 5))
		"Grimwalker":
			skills.append(_make_skill("grim_weaken", "Weaken", "Reduces all enemies' ATK.", 10, SkillData.TargetType.ALL_ENEMIES, SkillData.DamageType.NONE, 0.0, "dark", {"type": StatusEffect.Type.DEF_DOWN, "duration": 2, "potency": 20, "chance": 100}, 10, 4))
			skills.append(_make_skill("grim_doom", "Doom", "Massive dark damage + burn.", 18, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.MAGICAL, 2.0, "dark", {"type": StatusEffect.Type.BURN, "duration": 3, "potency": 12, "chance": 80}, 16, 7))
		"Dancer":
			skills.append(_make_skill("dancer_lullaby", "Lullaby", "A hypnotic dance that may stun all enemies.", 12, SkillData.TargetType.ALL_ENEMIES, SkillData.DamageType.NONE, 0.0, "none", {"type": StatusEffect.Type.STUN, "duration": 1, "potency": 0, "chance": 50}, 12, 5))
			skills.append(_make_skill("dancer_ovation", "Ovation", "An uplifting finale granting all allies regeneration.", 14, SkillData.TargetType.ALL_ALLIES, SkillData.DamageType.NONE, 0.0, "none", {"type": StatusEffect.Type.REGEN, "duration": 3, "potency": 12, "chance": 100}, 14, 6))
	
	return skills


static func _make_skill(id: String, skill_name: String, desc: String, mp_cost: int, target: SkillData.TargetType, dmg_type: SkillData.DamageType, mult: float, element: String, status: Dictionary, crystal_cost: int, level_req: int) -> Dictionary:
	var skill := SkillData.new()
	skill.skill_name = skill_name
	skill.description = desc
	skill.mp_cost = mp_cost
	skill.target_type = target
	skill.damage_type = dmg_type
	skill.power_multiplier = mult
	skill.element = element
	if not status.is_empty():
		skill.status_on_hit = status
	
	return {
		"id": id,
		"skill": skill,
		"cost": crystal_cost,
		"level_req": level_req,
	}


func restore_learned_skills_from_save() -> void:
	## Called on game load to re-apply all learned skills to class definitions.
	var learned: Array = UnlocksManager.unlocks.get("learned_skills", [])
	if learned.is_empty():
		return
	
	var all_classes: Array = ClassDatabase.get_all_classes()
	for class_data in all_classes:
		var learnable: Array[Dictionary] = get_learnable_skills(class_data.class_name_text)
		for entry in learnable:
			if entry["id"] in learned:
				var skill: SkillData = entry["skill"]
				if skill not in class_data.skills:
					class_data.skills.append(skill)
	
	print("[SkillTree] Restored %d learned skills from save" % learned.size())
