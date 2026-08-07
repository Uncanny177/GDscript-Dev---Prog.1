## CharacterData — A specific character in your party.
##
## This is an INSTANCE — "Bob the Warrior" not "what is a Warrior."
## It references a ClassData for its base stats and skills,
## then layers on individual state (current HP, equipment, etc.)
##
## WHY SEPARATE FROM ClassData?
## You might have 3 Warriors in your party. They share the same ClassData
## (same base stats, same skill list) but have different:
##   - Names
##   - Current HP/MP (one might be damaged)
##   - Equipment (one has a better sword)
##   - Level/experience (eventually)
##
## This is the Flyweight pattern — shared template, individual state.

class_name CharacterData
extends Resource

## This character's name
@export var character_name: String = "Unnamed"

## What class are they? References a ClassData resource.
## This gives them their base stats and skill list.
@export var character_class: ClassData = null

## Current HP (can be less than max if damaged). Starts at max.
var current_hp: int = 0

## Current MP (depleted by using skills). Starts at max.
var current_mp: int = 0

## Is this character currently alive?
var is_alive: bool = true

## Level and XP
var level: int = 1
var xp: int = 0

## Sanity (0-100, drops from horror/dark magic, recovers at safe zones)
var sanity: int = 100

## Stat bonuses from leveling (added on top of base class stats)
var stat_bonuses: StatBlock = null

## Equipment slots (hold ItemData references — null = empty slot)
var weapon: ItemData = null
var armor: ItemData = null
var accessory: ItemData = null


func initialize() -> void:
	## Call this after setting character_class to fill in starting values.
	## Sets HP and MP to their max based on class stats.
	if character_class and character_class.base_stats:
		current_hp = character_class.base_stats.max_hp
		current_mp = character_class.base_stats.max_mp
		is_alive = true
		if stat_bonuses == null:
			stat_bonuses = StatBlock.new()  # Fresh per-instance stat bonuses
	else:
		push_error("[CharacterData] Cannot initialize — no class or stats assigned")


func get_stats() -> StatBlock:
	## Returns the character's EFFECTIVE stats (base + equipment bonuses).
	## Combines class base stats with all equipped item stat_bonus values.
	var base: StatBlock = null
	if character_class and character_class.base_stats:
		base = character_class.base_stats
	else:
		return StatBlock.new()
	
	# If no equipment and no level bonuses, just return base stats
	if not weapon and not armor and not accessory and (stat_bonuses == null or level <= 1):
		return base
	
	# Combine base + level bonuses + equipment bonuses
	var result := StatBlock.new()
	if stat_bonuses:
		result.max_hp = base.max_hp + stat_bonuses.max_hp
		result.max_mp = base.max_mp + stat_bonuses.max_mp
		result.atk = base.atk + stat_bonuses.atk
		result.def_stat = base.def_stat + stat_bonuses.def_stat
		result.mag = base.mag + stat_bonuses.mag
		result.res_stat = base.res_stat + stat_bonuses.res_stat
		result.spd = base.spd + stat_bonuses.spd
	else:
		result.max_hp = base.max_hp
		result.max_mp = base.max_mp
		result.atk = base.atk
		result.def_stat = base.def_stat
		result.mag = base.mag
		result.res_stat = base.res_stat
		result.spd = base.spd
	
	# Add weapon bonus
	if weapon and weapon.stat_bonus:
		result = result.add(weapon.stat_bonus)
	# Add armor bonus
	if armor and armor.stat_bonus:
		result = result.add(armor.stat_bonus)
	# Add accessory bonus
	if accessory and accessory.stat_bonus:
		result = result.add(accessory.stat_bonus)
	
	return result


func take_damage(amount: int) -> int:
	## Apply damage to this character. Returns actual damage dealt.
	## Clamps so HP never goes below 0.
	var actual_damage: int = mini(amount, current_hp)  # mini = min for ints
	current_hp -= actual_damage
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
	return actual_damage


func heal(amount: int) -> int:
	## Restore HP. Can't exceed max. Returns actual amount healed.
	var max_hp: int = get_stats().max_hp
	var actual_heal: int = mini(amount, max_hp - current_hp)
	current_hp += actual_heal
	return actual_heal


func use_mp(amount: int) -> bool:
	## Spend MP. Returns false if not enough (skill can't be used).
	if current_mp < amount:
		return false
	current_mp -= amount
	return true


func restore_mp(amount: int) -> int:
	## Restore MP. Can't exceed max. Returns actual amount restored.
	var max_mp: int = get_stats().max_mp
	var actual_restore: int = mini(amount, max_mp - current_mp)
	current_mp += actual_restore
	return actual_restore


func full_heal() -> void:
	## Fully restore HP and MP. Used between runs or at certain events.
	if character_class and character_class.base_stats:
		current_hp = character_class.base_stats.max_hp
		current_mp = character_class.base_stats.max_mp
		is_alive = true


func _to_string() -> String:
	var class_str: String = character_class.class_name_text if character_class else "No Class"
	return "%s Lv%d (%s) HP:%d/%d MP:%d/%d" % [
		character_name, level, class_str,
		current_hp, get_stats().max_hp,
		current_mp, get_stats().max_mp
	]
