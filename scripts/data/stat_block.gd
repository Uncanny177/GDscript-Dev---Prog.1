## StatBlock — A reusable set of RPG stats.
##
## KEY CONCEPT: CUSTOM RESOURCES
## In Godot, a Resource is a data container that can be saved as a .tres file.
## Think of it like a struct in C++ or a dataclass in Python — it just holds data.
##
## WHY Resources instead of dictionaries?
##   1. Type safety — Godot knows the fields and their types (no typos!)
##   2. Editor integration — @export fields show up in the Inspector
##   3. Reusability — save as .tres, share between enemies/classes/items
##   4. Inheritance — extend Resource to make specialized data types
##
## HOW TO CREATE A .tres FILE:
##   In Godot editor: right-click a folder → New Resource → pick "StatBlock"
##   Or we create them in code (like we do in class_data.gd defaults)
##
## "class_name" REGISTERS this as a type Godot knows globally.
## After this, you can type "StatBlock" anywhere — as a variable type,
## in @export, or in the "New Resource" menu in the editor.

class_name StatBlock
extends Resource

## HP — Health Points. When this hits 0, the character/enemy is dead.
@export var max_hp: int = 100

## MP — Magic/Mana Points. Used to cast skills. No MP = can't use skills.
@export var max_mp: int = 20

## ATK — Attack power. Used in physical damage formula: ATK * multiplier - target's DEF
@export var atk: int = 10

## DEF — Defense. Reduces incoming physical damage.
@export var def_stat: int = 10  # "def" is a reserved word in some contexts, so we use def_stat

## MAG — Magic power. Used in magical damage formula: MAG * multiplier - target's RES
@export var mag: int = 10

## RES — Magic resistance. Reduces incoming magical damage.
@export var res_stat: int = 10  # "res" could conflict with resolution, so res_stat

## SPD — Speed. Determines turn order in combat. Higher = goes first.
@export var spd: int = 10


func get_stat(stat_name: String) -> int:
	## Look up a stat by name string. Useful for formulas that take stat names.
	## match is GDScript's version of switch/case (like Python's match or C++ switch).
	match stat_name:
		"max_hp": return max_hp
		"max_mp": return max_mp
		"atk": return atk
		"def": return def_stat
		"mag": return mag
		"res": return res_stat
		"spd": return spd
		_:
			push_error("Unknown stat: " + stat_name)
			return 0


func add(other: StatBlock) -> StatBlock:
	## Combines two stat blocks (base + modifier). Returns a NEW StatBlock.
	## Used for: base class stats + equipment bonuses = final stats.
	## We create a new one instead of modifying either input (immutability).
	var result := StatBlock.new()
	result.max_hp = max_hp + other.max_hp
	result.max_mp = max_mp + other.max_mp
	result.atk = atk + other.atk
	result.def_stat = def_stat + other.def_stat
	result.mag = mag + other.mag
	result.res_stat = res_stat + other.res_stat
	result.spd = spd + other.spd
	return result


func _to_string() -> String:
	## Overrides how this object prints (like __str__ in Python or operator<< in C++).
	## Useful for debugging: print(my_stats) shows something readable.
	return "HP:%d MP:%d ATK:%d DEF:%d MAG:%d RES:%d SPD:%d" % [
		max_hp, max_mp, atk, def_stat, mag, res_stat, spd
	]
