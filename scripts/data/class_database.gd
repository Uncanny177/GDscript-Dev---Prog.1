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
	_create_inquisitor()
	_create_demon_hunter()
	_create_necromancer()
	_create_occultist()
	_create_blood_mage()
	_create_summoner()
	_create_engineer()
	_create_alchemist()
	_create_monk()
	_create_psion()
	_create_knight()
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


func _create_inquisitor() -> void:
	## INQUISITOR — Anti-heresy tank/healer. Hunts cultists, resists dark magic.
	## Role: Tank that dispels and heals. High RES. Specializes against dark enemies.
	
	var stats := StatBlock.new()
	stats.max_hp = 135
	stats.max_mp = 35
	stats.atk = 13
	stats.def_stat = 15
	stats.mag = 12
	stats.res_stat = 16
	stats.spd = 8
	
	var purifying_strike := SkillData.new()
	purifying_strike.skill_name = "Purifying Strike"
	purifying_strike.description = "A consecrated blow that burns the unholy."
	purifying_strike.mp_cost = 5
	purifying_strike.target_type = SkillData.TargetType.SINGLE_ENEMY
	purifying_strike.damage_type = SkillData.DamageType.PHYSICAL
	purifying_strike.power_multiplier = 1.5
	purifying_strike.element = "light"
	
	var shield_of_faith := SkillData.new()
	shield_of_faith.skill_name = "Shield of Faith"
	shield_of_faith.description = "Ward an ally against dark magic and madness."
	shield_of_faith.mp_cost = 8
	shield_of_faith.target_type = SkillData.TargetType.SINGLE_ALLY
	shield_of_faith.damage_type = SkillData.DamageType.HEALING
	shield_of_faith.power_multiplier = 1.5
	
	var judgment := SkillData.new()
	judgment.skill_name = "Judgment"
	judgment.description = "Pass judgment on all enemies. Holy damage."
	judgment.mp_cost = 12
	judgment.target_type = SkillData.TargetType.ALL_ENEMIES
	judgment.damage_type = SkillData.DamageType.MAGICAL
	judgment.power_multiplier = 1.1
	judgment.element = "light"
	
	var inquisitor := ClassData.new()
	inquisitor.class_name_text = "Inquisitor"
	inquisitor.description = "Judge, jury, and executioner. Purges darkness and protects the faithful."
	inquisitor.base_stats = stats
	inquisitor.skills = [purifying_strike, shield_of_faith, judgment]
	inquisitor.sprite_color = Color(0.9, 0.85, 0.3)  # Gold
	
	classes["Inquisitor"] = inquisitor


func _create_demon_hunter() -> void:
	## DEMON HUNTER — Specialist in tracking and hunting monsters.
	## Role: High single-target damage. Bonus against bestiary-known enemies. Fast.
	
	var stats := StatBlock.new()
	stats.max_hp = 100
	stats.max_mp = 35
	stats.atk = 18
	stats.def_stat = 9
	stats.mag = 7
	stats.res_stat = 10
	stats.spd = 15
	
	var hunter_mark := SkillData.new()
	hunter_mark.skill_name = "Hunter's Mark"
	hunter_mark.description = "Mark a target. Next attacks deal bonus damage."
	hunter_mark.mp_cost = 5
	hunter_mark.target_type = SkillData.TargetType.SINGLE_ENEMY
	hunter_mark.damage_type = SkillData.DamageType.PHYSICAL
	hunter_mark.power_multiplier = 1.3
	
	var silver_bolt := SkillData.new()
	silver_bolt.skill_name = "Silver Bolt"
	silver_bolt.description = "A bolt blessed to harm abominations. Extra damage to dark creatures."
	silver_bolt.mp_cost = 8
	silver_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	silver_bolt.damage_type = SkillData.DamageType.PHYSICAL
	silver_bolt.power_multiplier = 2.0
	silver_bolt.element = "light"
	
	var trap_snare := SkillData.new()
	trap_snare.skill_name = "Binding Snare"
	trap_snare.description = "Lay a trap that slows all enemies."
	trap_snare.mp_cost = 10
	trap_snare.target_type = SkillData.TargetType.ALL_ENEMIES
	trap_snare.damage_type = SkillData.DamageType.PHYSICAL
	trap_snare.power_multiplier = 0.7
	
	var demon_hunter := ClassData.new()
	demon_hunter.class_name_text = "Demon Hunter"
	demon_hunter.description = "Trained to track, trap, and kill the things that lurk in the dark."
	demon_hunter.base_stats = stats
	demon_hunter.skills = [hunter_mark, silver_bolt, trap_snare]
	demon_hunter.sprite_color = Color(0.3, 0.2, 0.1)  # Dark brown
	
	classes["Demon Hunter"] = demon_hunter


func _create_necromancer() -> void:
	## NECROMANCER — Dark magic caster. High MAG, debuffs enemies.
	## Role: Deals magic damage and weakens enemies with status effects.
	
	var stats := StatBlock.new()
	stats.max_hp = 75
	stats.max_mp = 65
	stats.atk = 5
	stats.def_stat = 6
	stats.mag = 22
	stats.res_stat = 16
	stats.spd = 9
	
	# Necromancer skills
	var shadow_bolt := SkillData.new()
	shadow_bolt.skill_name = "Shadow Bolt"
	shadow_bolt.description = "A bolt of dark energy strikes one enemy."
	shadow_bolt.mp_cost = 6
	shadow_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	shadow_bolt.damage_type = SkillData.DamageType.MAGICAL
	shadow_bolt.power_multiplier = 1.5
	shadow_bolt.element = "dark"
	
	var curse := SkillData.new()
	curse.skill_name = "Curse"
	curse.description = "Weakens an enemy's defense."
	curse.mp_cost = 8
	curse.target_type = SkillData.TargetType.SINGLE_ENEMY
	curse.damage_type = SkillData.DamageType.NONE
	curse.power_multiplier = 0.0
	curse.status_on_hit = {"type": StatusEffect.Type.DEF_DOWN, "duration": 3, "potency": 30, "chance": 100}
	
	var drain_life := SkillData.new()
	drain_life.skill_name = "Drain Life"
	drain_life.description = "Steals HP from an enemy to heal yourself."
	drain_life.mp_cost = 12
	drain_life.target_type = SkillData.TargetType.SINGLE_ENEMY
	drain_life.damage_type = SkillData.DamageType.MAGICAL
	drain_life.power_multiplier = 1.3
	drain_life.element = "dark"
	
	var soul_fire := SkillData.new()
	soul_fire.skill_name = "Soul Fire"
	soul_fire.description = "Burns all enemies with ghostly flames."
	soul_fire.mp_cost = 15
	soul_fire.target_type = SkillData.TargetType.ALL_ENEMIES
	soul_fire.damage_type = SkillData.DamageType.MAGICAL
	soul_fire.power_multiplier = 1.2
	soul_fire.element = "dark"
	soul_fire.status_on_hit = {"type": StatusEffect.Type.BURN, "duration": 2, "potency": 8, "chance": 60}
	
	var necromancer := ClassData.new()
	necromancer.class_name_text = "Necromancer"
	necromancer.description = "A dark mage who drains life and curses foes."
	necromancer.base_stats = stats
	necromancer.skills = [shadow_bolt, curse, drain_life, soul_fire]
	necromancer.sprite_color = Color(0.4, 0.1, 0.5)  # Dark purple
	
	classes["Necromancer"] = necromancer


func _create_occultist() -> void:
	## OCCULTIST — Channels elder god magic directly. High MAG, costs sanity.
	## Role: Powerful caster with dark/void spells. Risky — some skills drain sanity.
	
	var stats := StatBlock.new()
	stats.max_hp = 85
	stats.max_mp = 55
	stats.atk = 5
	stats.def_stat = 7
	stats.mag = 22
	stats.res_stat = 15
	stats.spd = 9
	
	var void_bolt := SkillData.new()
	void_bolt.skill_name = "Void Bolt"
	void_bolt.description = "A lance of nothingness that ignores resistance"
	void_bolt.mp_cost = 8
	void_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	void_bolt.damage_type = SkillData.DamageType.MAGICAL
	void_bolt.power_multiplier = 1.6
	void_bolt.element = "dark"
	
	var eldritch_blast := SkillData.new()
	eldritch_blast.skill_name = "Eldritch Blast"
	eldritch_blast.description = "Blasts all enemies with alien energy. Costs sanity."
	eldritch_blast.mp_cost = 15
	eldritch_blast.target_type = SkillData.TargetType.ALL_ENEMIES
	eldritch_blast.damage_type = SkillData.DamageType.MAGICAL
	eldritch_blast.power_multiplier = 1.4
	eldritch_blast.element = "dark"
	
	var whisper := SkillData.new()
	whisper.skill_name = "Whispered Knowledge"
	whisper.description = "The gods reveal an enemy's weakness. Lowers RES."
	whisper.mp_cost = 10
	whisper.target_type = SkillData.TargetType.SINGLE_ENEMY
	whisper.damage_type = SkillData.DamageType.MAGICAL
	whisper.power_multiplier = 0.5
	
	var occultist := ClassData.new()
	occultist.class_name_text = "Occultist"
	occultist.description = "A scholar of forbidden truths. Channels elder god power at great personal cost."
	occultist.base_stats = stats
	occultist.skills = [void_bolt, eldritch_blast, whisper]
	occultist.sprite_color = Color(0.3, 0.0, 0.4)  # Deep violet
	
	classes["Occultist"] = occultist


func _create_blood_mage() -> void:
	## BLOOD MAGE — Spells cost HP instead of MP. High power, self-destructive.
	## Role: Burst damage dealer who sacrifices health. Synergizes with healers.
	
	var stats := StatBlock.new()
	stats.max_hp = 110
	stats.max_mp = 20
	stats.atk = 8
	stats.def_stat = 8
	stats.mag = 18
	stats.res_stat = 10
	stats.spd = 11
	
	var blood_lance := SkillData.new()
	blood_lance.skill_name = "Blood Lance"
	blood_lance.description = "Crystallize your blood into a piercing lance. Costs HP."
	blood_lance.mp_cost = 0
	blood_lance.hp_cost = 15
	blood_lance.target_type = SkillData.TargetType.SINGLE_ENEMY
	blood_lance.damage_type = SkillData.DamageType.MAGICAL
	blood_lance.power_multiplier = 2.0
	blood_lance.element = "dark"
	
	var crimson_wave := SkillData.new()
	crimson_wave.skill_name = "Crimson Wave"
	crimson_wave.description = "Spray blood-fire across all enemies. Costs HP."
	crimson_wave.mp_cost = 0
	crimson_wave.hp_cost = 25
	crimson_wave.target_type = SkillData.TargetType.ALL_ENEMIES
	crimson_wave.damage_type = SkillData.DamageType.MAGICAL
	crimson_wave.power_multiplier = 1.5
	crimson_wave.element = "fire"
	
	var life_tap := SkillData.new()
	life_tap.skill_name = "Life Tap"
	life_tap.description = "Convert HP to MP for the party."
	life_tap.mp_cost = 0
	life_tap.hp_cost = 20
	life_tap.target_type = SkillData.TargetType.ALL_ALLIES
	life_tap.damage_type = SkillData.DamageType.HEALING
	life_tap.power_multiplier = 1.0
	
	var blood_mage := ClassData.new()
	blood_mage.class_name_text = "Blood Mage"
	blood_mage.description = "Fuels devastating magic with their own lifeforce. Power demands sacrifice."
	blood_mage.base_stats = stats
	blood_mage.skills = [blood_lance, crimson_wave, life_tap]
	blood_mage.sprite_color = Color(0.6, 0.0, 0.0)  # Dark red
	
	classes["Blood Mage"] = blood_mage


func _create_summoner() -> void:
	## SUMMONER — Summons cute but ferocious creatures to fight alongside them.
	## Role: Minion-based damage/support. Summons do the fighting.
	
	var stats := StatBlock.new()
	stats.max_hp = 85
	stats.max_mp = 55
	stats.atk = 6
	stats.def_stat = 8
	stats.mag = 17
	stats.res_stat = 13
	stats.spd = 10
	
	var summon_chomper := SkillData.new()
	summon_chomper.skill_name = "Summon Chomper"
	summon_chomper.description = "Call a tiny fanged blob that bites an enemy viciously."
	summon_chomper.mp_cost = 10
	summon_chomper.target_type = SkillData.TargetType.SINGLE_ENEMY
	summon_chomper.damage_type = SkillData.DamageType.PHYSICAL
	summon_chomper.power_multiplier = 1.7
	
	var summon_spark := SkillData.new()
	summon_spark.skill_name = "Summon Spark Swarm"
	summon_spark.description = "Release a swarm of crackling sprites that zap all enemies."
	summon_spark.mp_cost = 14
	summon_spark.target_type = SkillData.TargetType.ALL_ENEMIES
	summon_spark.damage_type = SkillData.DamageType.MAGICAL
	summon_spark.power_multiplier = 1.2
	summon_spark.element = "light"
	
	var summon_shell := SkillData.new()
	summon_shell.skill_name = "Summon Shell Buddy"
	summon_shell.description = "A tiny armored creature shields an ally, healing them."
	summon_shell.mp_cost = 12
	summon_shell.target_type = SkillData.TargetType.SINGLE_ALLY
	summon_shell.damage_type = SkillData.DamageType.HEALING
	summon_shell.power_multiplier = 2.0
	
	var summoner := ClassData.new()
	summoner.class_name_text = "Summoner"
	summoner.description = "Calls forth adorable yet deadly creatures. They do the biting so you don't have to."
	summoner.base_stats = stats
	summoner.skills = [summon_chomper, summon_spark, summon_shell]
	summoner.sprite_color = Color(0.5, 0.8, 0.4)  # Lime green
	
	classes["Summoner"] = summoner


func _create_engineer() -> void:
	## ENGINEER — Gadgets, traps, and mechanical support. Non-magical utility.
	## Role: Debuffer and utility. Traps, turrets, shields.
	
	var stats := StatBlock.new()
	stats.max_hp = 95
	stats.max_mp = 40
	stats.atk = 12
	stats.def_stat = 12
	stats.mag = 6
	stats.res_stat = 8
	stats.spd = 10
	
	var deploy_turret := SkillData.new()
	deploy_turret.skill_name = "Deploy Turret"
	deploy_turret.description = "Set up a crossbow turret that fires at all enemies."
	deploy_turret.mp_cost = 12
	deploy_turret.target_type = SkillData.TargetType.ALL_ENEMIES
	deploy_turret.damage_type = SkillData.DamageType.PHYSICAL
	deploy_turret.power_multiplier = 0.8
	
	var flash_bomb := SkillData.new()
	flash_bomb.skill_name = "Flash Bomb"
	flash_bomb.description = "Blind enemies, reducing their accuracy."
	flash_bomb.mp_cost = 8
	flash_bomb.target_type = SkillData.TargetType.ALL_ENEMIES
	flash_bomb.damage_type = SkillData.DamageType.PHYSICAL
	flash_bomb.power_multiplier = 0.3
	
	var repair_kit := SkillData.new()
	repair_kit.skill_name = "Repair Kit"
	repair_kit.description = "Field repairs restore HP to one ally."
	repair_kit.mp_cost = 10
	repair_kit.target_type = SkillData.TargetType.SINGLE_ALLY
	repair_kit.damage_type = SkillData.DamageType.HEALING
	repair_kit.power_multiplier = 1.5
	
	var engineer := ClassData.new()
	engineer.class_name_text = "Engineer"
	engineer.description = "If magic can't solve it, applied engineering will. Traps, turrets, and practical solutions."
	engineer.base_stats = stats
	engineer.skills = [deploy_turret, flash_bomb, repair_kit]
	engineer.sprite_color = Color(0.7, 0.5, 0.2)  # Bronze/copper
	
	classes["Engineer"] = engineer


func _create_alchemist() -> void:
	## ALCHEMIST — Brews potions in combat, throws acids, buffs via concoctions.
	## Role: Flexible support/debuffer. Can heal, damage, or buff depending on need.
	
	var stats := StatBlock.new()
	stats.max_hp = 90
	stats.max_mp = 45
	stats.atk = 9
	stats.def_stat = 8
	stats.mag = 14
	stats.res_stat = 12
	stats.spd = 11
	
	var acid_flask := SkillData.new()
	acid_flask.skill_name = "Acid Flask"
	acid_flask.description = "Throw a flask of corrosive acid at one enemy."
	acid_flask.mp_cost = 7
	acid_flask.target_type = SkillData.TargetType.SINGLE_ENEMY
	acid_flask.damage_type = SkillData.DamageType.MAGICAL
	acid_flask.power_multiplier = 1.4
	
	var healing_draught := SkillData.new()
	healing_draught.skill_name = "Healing Draught"
	healing_draught.description = "Brew and administer a healing potion to one ally."
	healing_draught.mp_cost = 9
	healing_draught.target_type = SkillData.TargetType.SINGLE_ALLY
	healing_draught.damage_type = SkillData.DamageType.HEALING
	healing_draught.power_multiplier = 1.8
	
	var volatile_mixture := SkillData.new()
	volatile_mixture.skill_name = "Volatile Mixture"
	volatile_mixture.description = "An unstable bomb that damages all enemies."
	volatile_mixture.mp_cost = 14
	volatile_mixture.target_type = SkillData.TargetType.ALL_ENEMIES
	volatile_mixture.damage_type = SkillData.DamageType.MAGICAL
	volatile_mixture.power_multiplier = 1.2
	volatile_mixture.element = "fire"
	
	var alchemist := ClassData.new()
	alchemist.class_name_text = "Alchemist"
	alchemist.description = "Science is just magic with better documentation. Brews solutions to every problem."
	alchemist.base_stats = stats
	alchemist.skills = [acid_flask, healing_draught, volatile_mixture]
	alchemist.sprite_color = Color(0.1, 0.7, 0.6)  # Teal
	
	classes["Alchemist"] = alchemist


func _create_monk() -> void:
	## MONK — Unarmed martial artist. Self-sufficient, high SPD, sanity-resistant.
	## Role: Fast physical DPS with self-healing. Balanced and reliable.
	
	var stats := StatBlock.new()
	stats.max_hp = 105
	stats.max_mp = 30
	stats.atk = 14
	stats.def_stat = 11
	stats.mag = 8
	stats.res_stat = 13
	stats.spd = 15
	
	var flurry := SkillData.new()
	flurry.skill_name = "Flurry of Blows"
	flurry.description = "A rapid series of strikes against one enemy."
	flurry.mp_cost = 6
	flurry.target_type = SkillData.TargetType.SINGLE_ENEMY
	flurry.damage_type = SkillData.DamageType.PHYSICAL
	flurry.power_multiplier = 1.6
	
	var meditate := SkillData.new()
	meditate.skill_name = "Meditate"
	meditate.description = "Center the mind. Restores HP and calms the spirit."
	meditate.mp_cost = 8
	meditate.target_type = SkillData.TargetType.SELF
	meditate.damage_type = SkillData.DamageType.HEALING
	meditate.power_multiplier = 2.0
	
	var pressure_point := SkillData.new()
	pressure_point.skill_name = "Pressure Point"
	pressure_point.description = "Strike a nerve cluster. High crit chance."
	pressure_point.mp_cost = 10
	pressure_point.target_type = SkillData.TargetType.SINGLE_ENEMY
	pressure_point.damage_type = SkillData.DamageType.PHYSICAL
	pressure_point.power_multiplier = 2.2
	
	var monk := ClassData.new()
	monk.class_name_text = "Monk"
	monk.description = "Discipline of body and mind. Where others break, the Monk endures."
	monk.base_stats = stats
	monk.skills = [flurry, meditate, pressure_point]
	monk.sprite_color = Color(0.9, 0.7, 0.2)  # Saffron/gold
	
	classes["Monk"] = monk


func _create_psion() -> void:
	## PSION — Pure mind powers. Devastating but drains sanity heavily.
	## Role: Highest magic damage in the game. Glass cannon with sanity cost.
	
	var stats := StatBlock.new()
	stats.max_hp = 70
	stats.max_mp = 65
	stats.atk = 4
	stats.def_stat = 5
	stats.mag = 24
	stats.res_stat = 16
	stats.spd = 12
	
	var mind_crush := SkillData.new()
	mind_crush.skill_name = "Mind Crush"
	mind_crush.description = "Collapse an enemy's thoughts. Devastating psychic damage."
	mind_crush.mp_cost = 12
	mind_crush.target_type = SkillData.TargetType.SINGLE_ENEMY
	mind_crush.damage_type = SkillData.DamageType.MAGICAL
	mind_crush.power_multiplier = 2.0
	
	var psychic_scream := SkillData.new()
	psychic_scream.skill_name = "Psychic Scream"
	psychic_scream.description = "A wave of mental anguish hits all enemies."
	psychic_scream.mp_cost = 18
	psychic_scream.target_type = SkillData.TargetType.ALL_ENEMIES
	psychic_scream.damage_type = SkillData.DamageType.MAGICAL
	psychic_scream.power_multiplier = 1.5
	
	var thought_shield := SkillData.new()
	thought_shield.skill_name = "Thought Shield"
	thought_shield.description = "Project a mental barrier around one ally."
	thought_shield.mp_cost = 10
	thought_shield.target_type = SkillData.TargetType.SINGLE_ALLY
	thought_shield.damage_type = SkillData.DamageType.HEALING
	thought_shield.power_multiplier = 1.5
	
	var psion := ClassData.new()
	psion.class_name_text = "Psion"
	psion.description = "The mind is the deadliest weapon. Also the most fragile."
	psion.base_stats = stats
	psion.skills = [mind_crush, psychic_scream, thought_shield]
	psion.sprite_color = Color(0.6, 0.2, 0.8)  # Purple/magenta
	
	classes["Psion"] = psion


func _create_knight() -> void:
	## KNIGHT — Armored frontline protector. Highest DEF, shield skills.
	## Role: Pure tank. Draws aggro, protects allies, counter-attacks.
	
	var stats := StatBlock.new()
	stats.max_hp = 150
	stats.max_mp = 20
	stats.atk = 12
	stats.def_stat = 20
	stats.mag = 4
	stats.res_stat = 10
	stats.spd = 6
	
	var shield_bash := SkillData.new()
	shield_bash.skill_name = "Shield Bash"
	shield_bash.description = "Slam your shield into an enemy. Stuns briefly."
	shield_bash.mp_cost = 5
	shield_bash.target_type = SkillData.TargetType.SINGLE_ENEMY
	shield_bash.damage_type = SkillData.DamageType.PHYSICAL
	shield_bash.power_multiplier = 1.3
	
	var iron_wall := SkillData.new()
	iron_wall.skill_name = "Iron Wall"
	iron_wall.description = "Brace yourself. Reduces all incoming damage this turn."
	iron_wall.mp_cost = 8
	iron_wall.target_type = SkillData.TargetType.SELF
	iron_wall.damage_type = SkillData.DamageType.HEALING
	iron_wall.power_multiplier = 1.0  # Self-heal representing damage reduction
	
	var rallying_cry := SkillData.new()
	rallying_cry.skill_name = "Rallying Cry"
	rallying_cry.description = "Inspire the party. Heals all allies slightly."
	rallying_cry.mp_cost = 10
	rallying_cry.target_type = SkillData.TargetType.ALL_ALLIES
	rallying_cry.damage_type = SkillData.DamageType.HEALING
	rallying_cry.power_multiplier = 0.8
	
	var knight := ClassData.new()
	knight.class_name_text = "Knight"
	knight.description = "An immovable wall of steel. Where the Knight stands, none shall pass."
	knight.base_stats = stats
	knight.skills = [shield_bash, iron_wall, rallying_cry]
	knight.sprite_color = Color(0.5, 0.5, 0.6)  # Steel grey
	
	classes["Knight"] = knight
