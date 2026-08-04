## SkillData — Defines a single skill/ability a character can use in combat.
##
## Each skill has:
##   - A name and description (for UI display)
##   - An MP cost (how much mana it uses)
##   - A target type (who does it affect?)
##   - A power multiplier (plugged into the damage/heal formula)
##   - Whether it's physical or magical (determines which stats are used)
##
## DESIGN PATTERN: Data-Driven Design
## Instead of hardcoding skills in combat logic like:
##   if skill_name == "Fireball": do_damage(mag * 1.5 - target.res)
##
## We define skills as data, and the combat system reads the data:
##   damage = caster.mag * skill.power_multiplier - target.res
##
## This means adding a new skill = creating a new .tres file.
## No code changes needed. Designers (or you later) can tweak numbers
## without touching the combat engine.

class_name SkillData
extends Resource

## Possible targets for a skill
enum TargetType {
	SINGLE_ENEMY,    # Pick one enemy
	ALL_ENEMIES,     # Hits every enemy (AOE)
	SINGLE_ALLY,     # Pick one party member (for heals/buffs)
	ALL_ALLIES,      # Heals/buffs entire party
	SELF             # Only affects the caster
}

## Whether damage scales off ATK or MAG
enum DamageType {
	PHYSICAL,   # Uses ATK vs DEF
	MAGICAL,    # Uses MAG vs RES
	HEALING,    # Restores HP (uses MAG for amount)
	NONE        # Utility skill (buff/debuff, no direct damage)
}

## Display name shown in battle menu
@export var skill_name: String = "Unnamed Skill"

## Flavor text / tooltip
@export var description: String = ""

## MP cost to use this skill. 0 = free (basic attack could be a "skill" with 0 cost)
@export var mp_cost: int = 5

## Who can this skill target?
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

## Physical or magical? Determines which stats feed the formula.
@export var damage_type: DamageType = DamageType.PHYSICAL

## Multiplier applied to the relevant attack stat.
## Formula: stat * power_multiplier - target_defense (minimum 1)
## Example: ATK=15, multiplier=1.5 → 22.5 raw power, minus DEF
@export var power_multiplier: float = 1.0

## Optional: element type for future elemental weakness system
@export var element: String = "none"

## Optional: status effect applied on hit
## Format: {"type": StatusEffect.Type, "duration": int, "potency": int, "chance": int}
## chance = percentage (0-100) that the effect applies on hit
var status_on_hit: Dictionary = {}


func can_afford(current_mp: int) -> bool:
	## Check if the caster has enough MP to use this skill.
	return current_mp >= mp_cost


func get_target_description() -> String:
	## Human-readable target type for UI tooltips.
	match target_type:
		TargetType.SINGLE_ENEMY: return "One Enemy"
		TargetType.ALL_ENEMIES: return "All Enemies"
		TargetType.SINGLE_ALLY: return "One Ally"
		TargetType.ALL_ALLIES: return "All Allies"
		TargetType.SELF: return "Self"
		_: return "Unknown"


func _to_string() -> String:
	return "%s (MP:%d, x%.1f %s)" % [skill_name, mp_cost, power_multiplier, DamageType.keys()[damage_type]]
