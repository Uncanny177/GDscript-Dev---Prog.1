## LevelSystem — Handles XP, leveling, and stat growth.
##
## Each character earns XP from combat. When they hit the threshold,
## they level up and gain stat bonuses based on their class.
##
## XP CURVE: Each level requires more XP than the last.
##   Level 2: 20 XP
##   Level 3: 50 XP
##   Level 5: 140 XP
##   Level 10: 500 XP
##
## STAT GROWTH: Each class has growth rates (how much stats increase per level).
## Warriors gain more HP/DEF, Mages gain more MAG/MP, Rogues gain more SPD/ATK.

class_name LevelSystem
extends RefCounted

## Maximum level cap
const MAX_LEVEL: int = 20

## XP required for each level (index = level - 1, so index 0 = level 1→2)
## Formula: base * level^1.5
static func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(20.0 * pow(float(level - 1), 1.5))


static func xp_for_next_level(current_level: int) -> int:
	## How much TOTAL XP needed to reach the next level.
	return xp_for_level(current_level + 1)


static func check_level_up(character: CharacterData) -> bool:
	## Check if a character has enough XP to level up. If so, level them up.
	## Returns true if a level up occurred.
	if character.level >= MAX_LEVEL:
		return false
	
	var needed: int = xp_for_next_level(character.level)
	if character.xp >= needed:
		character.xp -= needed
		character.level += 1
		_apply_stat_growth(character)
		print("[Level] %s leveled up to %d!" % [character.character_name, character.level])
		return true
	
	return false


static func grant_xp(character: CharacterData, amount: int) -> Array[String]:
	## Give XP to a character. Returns messages for any level ups that occur.
	var messages: Array[String] = []
	character.xp += amount
	
	# Check for multiple level ups (unlikely but possible with large XP gains)
	var leveled: bool = true
	while leveled:
		leveled = check_level_up(character)
		if leveled:
			messages.append("%s reached level %d!" % [character.character_name, character.level])
	
	return messages


static func _apply_stat_growth(character: CharacterData) -> void:
	## Apply stat increases based on class growth rates.
	if not character.character_class or not character.character_class.base_stats:
		return
	
	# Ensure stat_bonuses exists
	if character.stat_bonuses == null:
		character.stat_bonuses = StatBlock.new()
	
	var growth: Dictionary = _get_growth_rates(character.character_class.class_name_text)
	
	character.stat_bonuses.max_hp += growth.get("hp", 5)
	character.stat_bonuses.max_mp += growth.get("mp", 2)
	character.stat_bonuses.atk += growth.get("atk", 1)
	character.stat_bonuses.def_stat += growth.get("def", 1)
	character.stat_bonuses.mag += growth.get("mag", 1)
	character.stat_bonuses.res_stat += growth.get("res", 1)
	character.stat_bonuses.spd += growth.get("spd", 1)
	
	# Heal to new max on level up
	var stats: StatBlock = character.get_stats()
	character.current_hp = stats.max_hp
	character.current_mp = stats.max_mp


static func _get_growth_rates(class_name_text: String) -> Dictionary:
	## Per-level stat increases for each class.
	match class_name_text:
		"Warrior":
			return {"hp": 12, "mp": 2, "atk": 3, "def": 3, "mag": 0, "res": 1, "spd": 1}
		"Mage":
			return {"hp": 5, "mp": 8, "atk": 0, "def": 1, "mag": 4, "res": 2, "spd": 1}
		"Rogue":
			return {"hp": 7, "mp": 3, "atk": 3, "def": 1, "mag": 1, "res": 1, "spd": 3}
		"Paladin":
			return {"hp": 10, "mp": 4, "atk": 2, "def": 3, "mag": 2, "res": 2, "spd": 0}
		"Archer":
			return {"hp": 6, "mp": 3, "atk": 3, "def": 1, "mag": 0, "res": 1, "spd": 3}
		"Necromancer":
			return {"hp": 4, "mp": 9, "atk": 0, "def": 0, "mag": 4, "res": 3, "spd": 1}
		_:
			return {"hp": 5, "mp": 3, "atk": 2, "def": 2, "mag": 2, "res": 2, "spd": 1}
