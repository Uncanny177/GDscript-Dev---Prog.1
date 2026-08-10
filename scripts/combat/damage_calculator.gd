## DamageCalculator — Pure functions for calculating combat damage.
##
## KEY CONCEPT: PURE FUNCTIONS
## These functions take inputs and return outputs without modifying any state.
## No side effects. Easy to test and reason about.
## You could test these in the sandbox with just print() calls.
##
## DAMAGE FORMULA (from our GDD):
##   Physical: ATK * multiplier - DEF (minimum 1)
##   Magical:  MAG * multiplier - RES (minimum 1)
##   Healing:  MAG * multiplier (no resistance)

class_name DamageCalculator
extends RefCounted


static func calculate_physical(attacker: Combatant, target: Combatant, multiplier: float = 1.0) -> int:
	## Physical damage: ATK * multiplier - DEF, minimum 1.
	var raw: float = maxf(attacker.get_atk() * multiplier - target.get_def(), 1.0)
	return int(round(raw))


static func calculate_magical(attacker: Combatant, target: Combatant, multiplier: float = 1.0) -> int:
	## Magical damage: MAG * multiplier - RES, minimum 1.
	var raw: float = maxf(attacker.get_mag() * multiplier - target.get_res(), 1.0)
	return int(round(raw))


static func calculate_healing(caster: Combatant, multiplier: float = 1.0) -> int:
	## Healing amount: MAG * multiplier. No resistance check.
	var raw: float = maxf(caster.get_mag() * multiplier, 1.0)
	return int(round(raw))


static func calculate_skill_damage(attacker: Combatant, target: Combatant, skill: SkillData) -> int:
	## Calculate damage for a specific skill based on its type.
	## Applies elemental multiplier if skill has an element.
	var base_damage: int = 0
	match skill.damage_type:
		SkillData.DamageType.PHYSICAL:
			base_damage = calculate_physical(attacker, target, skill.power_multiplier)
		SkillData.DamageType.MAGICAL:
			base_damage = calculate_magical(attacker, target, skill.power_multiplier)
		SkillData.DamageType.HEALING:
			return calculate_healing(attacker, skill.power_multiplier)
		_:
			return 0
	
	# Apply elemental multiplier
	var element_mult: float = ElementSystem.get_multiplier(skill.element, target.element)
	base_damage = int(round(float(base_damage) * element_mult))
	return maxi(base_damage, 1)
