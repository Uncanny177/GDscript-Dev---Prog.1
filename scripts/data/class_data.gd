## ClassData — Defines a character class (Warrior, Mage, Rogue, etc.)
##
## A class determines:
##   - Base stat distribution (Warriors have high HP/ATK, Mages have high MAG/MP)
##   - What skills the character can learn
##   - Display info (name, description, color for placeholder sprites)
##
## IMPORTANT DISTINCTION:
##   ClassData = the template/blueprint ("what IS a Warrior?")
##   CharacterData = an instance ("Bob the Warrior with 3 XP and a rusty sword")
##
## This is like the difference between a class and an object in OOP:
##   ClassData → class definition
##   CharacterData → instance of that class

class_name ClassData
extends Resource

## Name shown in menus and UI
@export var class_name_text: String = "Unknown"  # "class_name" is reserved by Godot

## Short description for class selection screen
@export var description: String = ""

## Base stats for this class. Characters of this class start with these.
@export var base_stats: StatBlock = null

## Skills this class can use. Array of SkillData resources.
## As the game grows, this could become level-gated (learn Fireball at level 3).
@export var skills: Array[SkillData] = []

## Placeholder sprite color (until we have real art)
@export var sprite_color: Color = Color.WHITE


func _to_string() -> String:
	var stats_str: String = str(base_stats) if base_stats else "no stats"
	return "%s [%s] — %d skills" % [class_name_text, stats_str, skills.size()]
