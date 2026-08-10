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
	_create_paladin()
	_create_archer()
	_create_necromancer()
	_create_occultist()
	_create_blood_mage()
	_create_druid()
	_create_engineer()
	_create_alchemist()
	_create_monk()
	_create_psion()
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


func _create_paladin() -> void:
	## PALADIN — The holy knight. Balanced tank/healer hybrid.
	## Role: Absorbs damage like Warrior but can heal allies. Lower ATK.
	
	var stats := StatBlock.new()
	stats.max_hp = 140
	stats.max_mp = 35
	stats.atk = 14
	stats.def_stat = 16
	stats.mag = 12
	stats.res_stat = 14
	stats.spd = 7
	
	# Paladin skills
	var holy_strike := SkillData.new()
	holy_strike.skill_name = "Holy Strike"
	holy_strike.description = "A blessed attack that deals physical and light damage."
	holy_strike.mp_cost = 5
	holy_strike.target_type = SkillData.TargetType.SINGLE_ENEMY
	holy_strike.damage_type = SkillData.DamageType.PHYSICAL
	holy_strike.power_multiplier = 1.4
	holy_strike.element = "light"
	
	var divine_shield := SkillData.new()
	divine_shield.skill_name = "Divine Shield"
	divine_shield.description = "Blesses an ally, reducing damage taken."
	divine_shield.mp_cost = 8
	divine_shield.target_type = SkillData.TargetType.SINGLE_ALLY
	divine_shield.damage_type = SkillData.DamageType.NONE
	divine_shield.power_multiplier = 0.0
	
	var lay_on_hands := SkillData.new()
	lay_on_hands.skill_name = "Lay on Hands"
	lay_on_hands.description = "Heals an ally with holy power."
	lay_on_hands.mp_cost = 10
	lay_on_hands.target_type = SkillData.TargetType.SINGLE_ALLY
	lay_on_hands.damage_type = SkillData.DamageType.HEALING
	lay_on_hands.power_multiplier = 1.8
	
	var paladin := ClassData.new()
	paladin.class_name_text = "Paladin"
	paladin.description = "A holy knight who protects allies and smites evil."
	paladin.base_stats = stats
	paladin.skills = [holy_strike, divine_shield, lay_on_hands]
	paladin.sprite_color = Color(0.9, 0.85, 0.3)  # Gold
	
	classes["Paladin"] = paladin


func _create_archer() -> void:
	## ARCHER — Ranged attacker. High SPD and ATK, low DEF.
	## Role: Hits hard and fast from range. Multi-target and crit skills.
	
	var stats := StatBlock.new()
	stats.max_hp = 95
	stats.max_mp = 30
	stats.atk = 17
	stats.def_stat = 7
	stats.mag = 6
	stats.res_stat = 8
	stats.spd = 16
	
	# Archer skills
	var precise_shot := SkillData.new()
	precise_shot.skill_name = "Precise Shot"
	precise_shot.description = "A carefully aimed shot. High damage to one target."
	precise_shot.mp_cost = 4
	precise_shot.target_type = SkillData.TargetType.SINGLE_ENEMY
	precise_shot.damage_type = SkillData.DamageType.PHYSICAL
	precise_shot.power_multiplier = 1.7
	
	var volley := SkillData.new()
	volley.skill_name = "Arrow Volley"
	volley.description = "Rain arrows on all enemies."
	volley.mp_cost = 10
	volley.target_type = SkillData.TargetType.ALL_ENEMIES
	volley.damage_type = SkillData.DamageType.PHYSICAL
	volley.power_multiplier = 0.9
	
	var poison_arrow := SkillData.new()
	poison_arrow.skill_name = "Poison Arrow"
	poison_arrow.description = "A toxic arrow that poisons the target."
	poison_arrow.mp_cost = 6
	poison_arrow.target_type = SkillData.TargetType.SINGLE_ENEMY
	poison_arrow.damage_type = SkillData.DamageType.PHYSICAL
	poison_arrow.power_multiplier = 1.1
	poison_arrow.status_on_hit = {"type": StatusEffect.Type.POISON, "duration": 3, "potency": 12, "chance": 90}
	
	var archer := ClassData.new()
	archer.class_name_text = "Archer"
	archer.description = "A swift marksman who strikes from afar."
	archer.base_stats = stats
	archer.skills = [precise_shot, volley, poison_arrow]
	archer.sprite_color = Color(0.2, 0.7, 0.3)  # Forest green
	
	classes["Archer"] = archer


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


func _create_druid() -> void:
	## DRUID — Nature magic healer/support. Regeneration, barriers, poison.
	## Role: Sustained healing and nature damage over time.
	
	var stats := StatBlock.new()
	stats.max_hp = 100
	stats.max_mp = 50
	stats.atk = 7
	stats.def_stat = 10
	stats.mag = 16
	stats.res_stat = 14
	stats.spd = 9
	
	var regrowth := SkillData.new()
	regrowth.skill_name = "Regrowth"
	regrowth.description = "Nature's embrace mends wounds over time."
	regrowth.mp_cost = 10
	regrowth.target_type = SkillData.TargetType.SINGLE_ALLY
	regrowth.damage_type = SkillData.DamageType.HEALING
	regrowth.power_multiplier = 2.2
	
	var thorn_burst := SkillData.new()
	thorn_burst.skill_name = "Thorn Burst"
	thorn_burst.description = "Thorny vines erupt beneath all enemies."
	thorn_burst.mp_cost = 12
	thorn_burst.target_type = SkillData.TargetType.ALL_ENEMIES
	thorn_burst.damage_type = SkillData.DamageType.MAGICAL
	thorn_burst.power_multiplier = 1.1
	
	var bark_skin := SkillData.new()
	bark_skin.skill_name = "Bark Skin"
	bark_skin.description = "Harden an ally's skin like ancient wood. Boosts DEF."
	bark_skin.mp_cost = 8
	bark_skin.target_type = SkillData.TargetType.SINGLE_ALLY
	bark_skin.damage_type = SkillData.DamageType.HEALING
	bark_skin.power_multiplier = 0.5  # Small heal + buff (buff logic TODO)
	
	var druid := ClassData.new()
	druid.class_name_text = "Druid"
	druid.description = "Channels the memory of nature in a place that has forgotten it."
	druid.base_stats = stats
	druid.skills = [regrowth, thorn_burst, bark_skin]
	druid.sprite_color = Color(0.2, 0.5, 0.1)  # Forest green
	
	classes["Druid"] = druid


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
