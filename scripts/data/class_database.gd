## ClassDatabase — Creates and provides access to all character classes.
##
## WHY A DATABASE SCRIPT?
## Eventually, class definitions will be .tres files you edit in the Godot Inspector.
## For now (since we're building without the editor), we define them in code.
## This script creates all the classes on startup and makes them accessible.
##
## USAGE FROM OTHER SCRIPTS:
##   var warrior_class: ClassData = ClassDatabase.get_class_data("Warrior")
##   var all_classes: Array = ClassDatabase.get_all_classes()
##
## This is registered as an autoload in project.godot (we'll add it).

extends Node

## Dictionary of class_name → ClassData. Populated in _ready().
var classes: Dictionary = {}


func _ready() -> void:
	_create_warrior()
	_create_mage()
	_create_rogue()
	print("[ClassDatabase] Loaded %d classes" % classes.size())


func get_class_data(class_name_key: String) -> ClassData:
	## Look up a class by name. Returns null if not found.
	if classes.has(class_name_key):
		return classes[class_name_key]
	push_error("[ClassDatabase] Class not found: " + class_name_key)
	return null


func get_all_classes() -> Array[ClassData]:
	## Returns all available classes (for guild/recruitment UI).
	var result: Array[ClassData] = []
	for key in classes:
		result.append(classes[key])
	return result


# ─── CLASS DEFINITIONS ───────────────────────────────────────────

func _create_warrior() -> void:
	## WARRIOR — The tank. High HP, ATK, DEF. Low SPD and MAG.
	## Role: Takes hits, deals physical damage. Simple but reliable.
	
	var stats := StatBlock.new()
	stats.max_hp = 150
	stats.max_mp = 20
	stats.atk = 18
	stats.def_stat = 15
	stats.mag = 5
	stats.res_stat = 8
	stats.spd = 8
	
	# Warrior skills
	var power_strike := SkillData.new()
	power_strike.skill_name = "Power Strike"
	power_strike.description = "A mighty blow dealing 1.5x physical damage"
	power_strike.mp_cost = 5
	power_strike.target_type = SkillData.TargetType.SINGLE_ENEMY
	power_strike.damage_type = SkillData.DamageType.PHYSICAL
	power_strike.power_multiplier = 1.5
	
	var shield_bash := SkillData.new()
	shield_bash.skill_name = "Shield Bash"
	shield_bash.description = "Bashes with shield. Lower damage but hits hard against low DEF"
	shield_bash.mp_cost = 3
	shield_bash.target_type = SkillData.TargetType.SINGLE_ENEMY
	shield_bash.damage_type = SkillData.DamageType.PHYSICAL
	shield_bash.power_multiplier = 1.2
	
	var warrior := ClassData.new()
	warrior.class_name_text = "Warrior"
	warrior.description = "A sturdy fighter with high HP and physical power."
	warrior.base_stats = stats
	warrior.skills = [power_strike, shield_bash]
	warrior.sprite_color = Color(0.8, 0.2, 0.2)  # Red
	
	classes["Warrior"] = warrior


func _create_mage() -> void:
	## MAGE — The glass cannon / healer. High MAG and MP. Low HP and DEF.
	## Role: Deals magical AOE damage OR heals allies. Fragile.
	
	var stats := StatBlock.new()
	stats.max_hp = 80
	stats.max_mp = 60
	stats.atk = 5
	stats.def_stat = 6
	stats.mag = 20
	stats.res_stat = 14
	stats.spd = 10
	
	# Mage skills
	var fireball := SkillData.new()
	fireball.skill_name = "Fireball"
	fireball.description = "Hurls a ball of fire at all enemies"
	fireball.mp_cost = 12
	fireball.target_type = SkillData.TargetType.ALL_ENEMIES
	fireball.damage_type = SkillData.DamageType.MAGICAL
	fireball.power_multiplier = 1.3
	fireball.element = "fire"
	
	var heal := SkillData.new()
	heal.skill_name = "Heal"
	heal.description = "Restores HP to one ally"
	heal.mp_cost = 8
	heal.target_type = SkillData.TargetType.SINGLE_ALLY
	heal.damage_type = SkillData.DamageType.HEALING
	heal.power_multiplier = 2.0  # Heal amount = MAG * 2.0
	
	var ice_shard := SkillData.new()
	ice_shard.skill_name = "Ice Shard"
	ice_shard.description = "A sharp shard of ice pierces one enemy"
	ice_shard.mp_cost = 6
	ice_shard.target_type = SkillData.TargetType.SINGLE_ENEMY
	ice_shard.damage_type = SkillData.DamageType.MAGICAL
	ice_shard.power_multiplier = 1.5
	ice_shard.element = "ice"
	
	var mage := ClassData.new()
	mage.class_name_text = "Mage"
	mage.description = "A wielder of arcane power. Devastating magic but fragile."
	mage.base_stats = stats
	mage.skills = [fireball, heal, ice_shard]
	mage.sprite_color = Color(0.3, 0.3, 0.9)  # Blue
	
	classes["Mage"] = mage


func _create_rogue() -> void:
	## ROGUE — The speedster. High SPD and ATK. Low HP and DEF.
	## Role: Goes first, deals high single-target damage. Glass cannon melee.
	
	var stats := StatBlock.new()
	stats.max_hp = 90
	stats.max_mp = 30
	stats.atk = 16
	stats.def_stat = 8
	stats.mag = 8
	stats.res_stat = 10
	stats.spd = 18
	
	# Rogue skills
	var backstab := SkillData.new()
	backstab.skill_name = "Backstab"
	backstab.description = "A devastating strike from the shadows. Bonus from high SPD."
	backstab.mp_cost = 7
	backstab.target_type = SkillData.TargetType.SINGLE_ENEMY
	backstab.damage_type = SkillData.DamageType.PHYSICAL
	backstab.power_multiplier = 2.0  # High multiplier — rogue's signature
	
	var poison_strike := SkillData.new()
	poison_strike.skill_name = "Poison Strike"
	poison_strike.description = "Venomous attack that poisons the target."
	poison_strike.mp_cost = 4
	poison_strike.target_type = SkillData.TargetType.SINGLE_ENEMY
	poison_strike.damage_type = SkillData.DamageType.PHYSICAL
	poison_strike.power_multiplier = 1.2
	poison_strike.status_on_hit = {"type": StatusEffect.Type.POISON, "duration": 3, "potency": 10, "chance": 80}
	
	var rogue := ClassData.new()
	rogue.class_name_text = "Rogue"
	rogue.description = "A swift striker who moves first and hits hard."
	rogue.base_stats = stats
	rogue.skills = [backstab, poison_strike]
	rogue.sprite_color = Color(0.2, 0.8, 0.3)  # Green
	
	classes["Rogue"] = rogue
