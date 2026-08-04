## EnemyDatabase — Creates and provides access to all enemy types.
##
## Same pattern as ClassDatabase — defines enemies in code for now,
## eventually these become .tres files editable in the Godot Inspector.
##
## Enemies are organized by "tier" (difficulty). The dungeon generator
## will pick enemies appropriate to the current floor.

extends Node

## Dictionary of enemy_name → EnemyData
var enemies: Dictionary = {}

## Enemies grouped by floor difficulty tier
var tier_1: Array[EnemyData] = []  # Floors 1-2
var tier_2: Array[EnemyData] = []  # Floors 3-4
var tier_3: Array[EnemyData] = []  # Floor 5 / boss floor regular enemies


func _ready() -> void:
	_create_enemies()
	print("[EnemyDatabase] Loaded %d enemies" % enemies.size())


func get_enemy(enemy_name: String) -> EnemyData:
	## Get an enemy definition by name.
	if enemies.has(enemy_name):
		return enemies[enemy_name]
	push_error("[EnemyDatabase] Enemy not found: " + enemy_name)
	return null


func get_enemies_for_floor(floor_number: int) -> Array[EnemyData]:
	## Returns the enemy pool appropriate for the given floor.
	if floor_number <= 2:
		return tier_1
	elif floor_number <= 4:
		return tier_2
	else:
		return tier_3


func _create_enemies() -> void:
	# ─── TIER 1: Weak enemies for floors 1-2 ───────────────────
	
	# SLIME — The classic starter enemy. Barely a threat.
	var slime_stats := StatBlock.new()
	slime_stats.max_hp = 30
	slime_stats.max_mp = 0
	slime_stats.atk = 8
	slime_stats.def_stat = 4
	slime_stats.mag = 3
	slime_stats.res_stat = 3
	slime_stats.spd = 5
	
	var slime_attack := SkillData.new()
	slime_attack.skill_name = "Tackle"
	slime_attack.mp_cost = 0
	slime_attack.target_type = SkillData.TargetType.SINGLE_ENEMY
	slime_attack.damage_type = SkillData.DamageType.PHYSICAL
	slime_attack.power_multiplier = 1.0
	
	var slime := EnemyData.new()
	slime.enemy_name = "Slime"
	slime.stats = slime_stats
	slime.skills = [slime_attack]
	slime.skill_weights = [1]
	slime.gold_reward = 3
	slime.xp_reward = 5
	slime.sprite_color = Color(0.2, 0.8, 0.2)  # Green
	
	enemies["Slime"] = slime
	tier_1.append(slime)
	
	# GOBLIN — Slightly tougher, faster than slime.
	var goblin_stats := StatBlock.new()
	goblin_stats.max_hp = 45
	goblin_stats.max_mp = 5
	goblin_stats.atk = 12
	goblin_stats.def_stat = 6
	goblin_stats.mag = 4
	goblin_stats.res_stat = 5
	goblin_stats.spd = 12
	
	var goblin_stab := SkillData.new()
	goblin_stab.skill_name = "Stab"
	goblin_stab.mp_cost = 0
	goblin_stab.target_type = SkillData.TargetType.SINGLE_ENEMY
	goblin_stab.damage_type = SkillData.DamageType.PHYSICAL
	goblin_stab.power_multiplier = 1.0
	
	var goblin := EnemyData.new()
	goblin.enemy_name = "Goblin"
	goblin.stats = goblin_stats
	goblin.skills = [goblin_stab]
	goblin.skill_weights = [1]
	goblin.gold_reward = 5
	goblin.xp_reward = 8
	goblin.sprite_color = Color(0.6, 0.5, 0.2)  # Yellowish brown
	
	enemies["Goblin"] = goblin
	tier_1.append(goblin)
	
	# ─── TIER 2: Medium enemies for floors 3-4 ─────────────────
	
	# SKELETON — Moderate stats, can sometimes hit hard.
	var skeleton_stats := StatBlock.new()
	skeleton_stats.max_hp = 70
	skeleton_stats.max_mp = 10
	skeleton_stats.atk = 15
	skeleton_stats.def_stat = 12
	skeleton_stats.mag = 6
	skeleton_stats.res_stat = 4  # Weak to magic
	skeleton_stats.spd = 9
	
	var bone_slash := SkillData.new()
	bone_slash.skill_name = "Bone Slash"
	bone_slash.mp_cost = 0
	bone_slash.target_type = SkillData.TargetType.SINGLE_ENEMY
	bone_slash.damage_type = SkillData.DamageType.PHYSICAL
	bone_slash.power_multiplier = 1.0
	
	var bone_throw := SkillData.new()
	bone_throw.skill_name = "Bone Throw"
	bone_throw.description = "Hurls a bone at a random target"
	bone_throw.mp_cost = 3
	bone_throw.target_type = SkillData.TargetType.SINGLE_ENEMY
	bone_throw.damage_type = SkillData.DamageType.PHYSICAL
	bone_throw.power_multiplier = 1.4
	
	var skeleton := EnemyData.new()
	skeleton.enemy_name = "Skeleton"
	skeleton.stats = skeleton_stats
	skeleton.skills = [bone_slash, bone_throw]
	skeleton.skill_weights = [3, 1]  # 75% basic attack, 25% bone throw
	skeleton.gold_reward = 10
	skeleton.xp_reward = 15
	skeleton.sprite_color = Color(0.9, 0.9, 0.85)  # Off-white
	
	enemies["Skeleton"] = skeleton
	tier_2.append(skeleton)
	
	# ─── TIER 3: Tough enemies for floor 5 ─────────────────────
	
	# DARK KNIGHT — A strong enemy guarding the boss floor.
	var dk_stats := StatBlock.new()
	dk_stats.max_hp = 120
	dk_stats.max_mp = 20
	dk_stats.atk = 20
	dk_stats.def_stat = 18
	dk_stats.mag = 8
	dk_stats.res_stat = 12
	dk_stats.spd = 7
	
	var heavy_slash := SkillData.new()
	heavy_slash.skill_name = "Heavy Slash"
	heavy_slash.mp_cost = 0
	heavy_slash.target_type = SkillData.TargetType.SINGLE_ENEMY
	heavy_slash.damage_type = SkillData.DamageType.PHYSICAL
	heavy_slash.power_multiplier = 1.0
	
	var dark_cleave := SkillData.new()
	dark_cleave.skill_name = "Dark Cleave"
	dark_cleave.description = "Sweeps all enemies with dark energy"
	dark_cleave.mp_cost = 8
	dark_cleave.target_type = SkillData.TargetType.ALL_ENEMIES
	dark_cleave.damage_type = SkillData.DamageType.PHYSICAL
	dark_cleave.power_multiplier = 1.2
	
	var dark_knight := EnemyData.new()
	dark_knight.enemy_name = "Dark Knight"
	dark_knight.stats = dk_stats
	dark_knight.skills = [heavy_slash, dark_cleave]
	dark_knight.skill_weights = [2, 1]  # 66% basic, 33% AOE
	dark_knight.gold_reward = 20
	dark_knight.xp_reward = 30
	dark_knight.sprite_color = Color(0.2, 0.1, 0.3)  # Dark purple
	
	enemies["Dark Knight"] = dark_knight
	tier_3.append(dark_knight)


	# ─── CAVE BIOME: New enemies ───────────────────────────────────
	
	# CAVE BAT — Fast, weak. Annoyance enemy.
	var bat_stats := StatBlock.new()
	bat_stats.max_hp = 20
	bat_stats.max_mp = 0
	bat_stats.atk = 7
	bat_stats.def_stat = 3
	bat_stats.mag = 2
	bat_stats.res_stat = 2
	bat_stats.spd = 15
	
	var bat_bite := SkillData.new()
	bat_bite.skill_name = "Bite"
	bat_bite.mp_cost = 0
	bat_bite.target_type = SkillData.TargetType.SINGLE_ENEMY
	bat_bite.damage_type = SkillData.DamageType.PHYSICAL
	bat_bite.power_multiplier = 1.0
	
	var bat := EnemyData.new()
	bat.enemy_name = "Cave Bat"
	bat.stats = bat_stats
	bat.skills = [bat_bite]
	bat.skill_weights = [1]
	bat.gold_reward = 2
	bat.xp_reward = 3
	bat.sprite_color = Color(0.3, 0.2, 0.35)
	
	enemies["Cave Bat"] = bat
	tier_1.append(bat)
	
	# MUSHROOM — Poisonous, slow. Can apply poison.
	var mush_stats := StatBlock.new()
	mush_stats.max_hp = 35
	mush_stats.max_mp = 10
	mush_stats.atk = 6
	mush_stats.def_stat = 8
	mush_stats.mag = 5
	mush_stats.res_stat = 6
	mush_stats.spd = 4
	
	var spore_cloud := SkillData.new()
	spore_cloud.skill_name = "Spore Cloud"
	spore_cloud.mp_cost = 0
	spore_cloud.target_type = SkillData.TargetType.SINGLE_ENEMY
	spore_cloud.damage_type = SkillData.DamageType.PHYSICAL
	spore_cloud.power_multiplier = 0.8
	spore_cloud.status_on_hit = {"type": StatusEffect.Type.POISON, "duration": 3, "potency": 8, "chance": 50}
	
	var mushroom := EnemyData.new()
	mushroom.enemy_name = "Mushroom"
	mushroom.stats = mush_stats
	mushroom.skills = [spore_cloud]
	mushroom.skill_weights = [1]
	mushroom.gold_reward = 4
	mushroom.xp_reward = 6
	mushroom.sprite_color = Color(0.5, 0.3, 0.6)
	
	enemies["Mushroom"] = mushroom
	tier_1.append(mushroom)
	
	# ─── CRYPT BIOME: New enemies ──────────────────────────────────
	
	# GHOST — Magical, partially resistant to physical. High RES.
	var ghost_stats := StatBlock.new()
	ghost_stats.max_hp = 50
	ghost_stats.max_mp = 20
	ghost_stats.atk = 8
	ghost_stats.def_stat = 4
	ghost_stats.mag = 14
	ghost_stats.res_stat = 14
	ghost_stats.spd = 12
	
	var spectral_touch := SkillData.new()
	spectral_touch.skill_name = "Spectral Touch"
	spectral_touch.mp_cost = 0
	spectral_touch.target_type = SkillData.TargetType.SINGLE_ENEMY
	spectral_touch.damage_type = SkillData.DamageType.MAGICAL
	spectral_touch.power_multiplier = 1.1
	
	var ghost := EnemyData.new()
	ghost.enemy_name = "Ghost"
	ghost.stats = ghost_stats
	ghost.skills = [spectral_touch]
	ghost.skill_weights = [1]
	ghost.gold_reward = 8
	ghost.xp_reward = 12
	ghost.sprite_color = Color(0.7, 0.7, 0.85, 0.7)
	
	enemies["Ghost"] = ghost
	tier_2.append(ghost)
	
	# ZOMBIE — Slow, tanky, hits hard. Low SPD.
	var zombie_stats := StatBlock.new()
	zombie_stats.max_hp = 90
	zombie_stats.max_mp = 0
	zombie_stats.atk = 16
	zombie_stats.def_stat = 10
	zombie_stats.mag = 2
	zombie_stats.res_stat = 4
	zombie_stats.spd = 4
	
	var zombie_slam := SkillData.new()
	zombie_slam.skill_name = "Slam"
	zombie_slam.mp_cost = 0
	zombie_slam.target_type = SkillData.TargetType.SINGLE_ENEMY
	zombie_slam.damage_type = SkillData.DamageType.PHYSICAL
	zombie_slam.power_multiplier = 1.2
	
	var zombie := EnemyData.new()
	zombie.enemy_name = "Zombie"
	zombie.stats = zombie_stats
	zombie.skills = [zombie_slam]
	zombie.skill_weights = [1]
	zombie.gold_reward = 9
	zombie.xp_reward = 14
	zombie.sprite_color = Color(0.35, 0.5, 0.3)
	
	enemies["Zombie"] = zombie
	tier_2.append(zombie)
	
	# BONE MAGE — Caster skeleton. AOE magic.
	var bm_stats := StatBlock.new()
	bm_stats.max_hp = 55
	bm_stats.max_mp = 30
	bm_stats.atk = 6
	bm_stats.def_stat = 8
	bm_stats.mag = 16
	bm_stats.res_stat = 12
	bm_stats.spd = 10
	
	var bone_bolt := SkillData.new()
	bone_bolt.skill_name = "Bone Bolt"
	bone_bolt.mp_cost = 5
	bone_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	bone_bolt.damage_type = SkillData.DamageType.MAGICAL
	bone_bolt.power_multiplier = 1.3
	
	var death_wave := SkillData.new()
	death_wave.skill_name = "Death Wave"
	death_wave.mp_cost = 10
	death_wave.target_type = SkillData.TargetType.ALL_ENEMIES
	death_wave.damage_type = SkillData.DamageType.MAGICAL
	death_wave.power_multiplier = 0.9
	death_wave.element = "dark"
	
	var bone_mage := EnemyData.new()
	bone_mage.enemy_name = "Bone Mage"
	bone_mage.stats = bm_stats
	bone_mage.skills = [bone_bolt, death_wave]
	bone_mage.skill_weights = [3, 1]
	bone_mage.gold_reward = 12
	bone_mage.xp_reward = 18
	bone_mage.sprite_color = Color(0.8, 0.8, 0.6)
	
	enemies["Bone Mage"] = bone_mage
	tier_2.append(bone_mage)
	
	# ─── INFERNO BIOME: New enemies ────────────────────────────────
	
	# FIRE IMP — Small, fast, burns.
	var imp_stats := StatBlock.new()
	imp_stats.max_hp = 60
	imp_stats.max_mp = 15
	imp_stats.atk = 10
	imp_stats.def_stat = 8
	imp_stats.mag = 14
	imp_stats.res_stat = 12
	imp_stats.spd = 14
	
	var fireball_imp := SkillData.new()
	fireball_imp.skill_name = "Fire Spit"
	fireball_imp.mp_cost = 3
	fireball_imp.target_type = SkillData.TargetType.SINGLE_ENEMY
	fireball_imp.damage_type = SkillData.DamageType.MAGICAL
	fireball_imp.power_multiplier = 1.2
	fireball_imp.element = "fire"
	fireball_imp.status_on_hit = {"type": StatusEffect.Type.BURN, "duration": 2, "potency": 6, "chance": 40}
	
	var fire_imp := EnemyData.new()
	fire_imp.enemy_name = "Fire Imp"
	fire_imp.stats = imp_stats
	fire_imp.skills = [fireball_imp]
	fire_imp.skill_weights = [1]
	fire_imp.gold_reward = 15
	fire_imp.xp_reward = 22
	fire_imp.sprite_color = Color(1.0, 0.4, 0.1)
	
	enemies["Fire Imp"] = fire_imp
	tier_3.append(fire_imp)
	
	# LAVA HOUND — Beefy fire beast.
	var hound_stats := StatBlock.new()
	hound_stats.max_hp = 110
	hound_stats.max_mp = 10
	hound_stats.atk = 18
	hound_stats.def_stat = 14
	hound_stats.mag = 10
	hound_stats.res_stat = 16
	hound_stats.spd = 8
	
	var flame_bite := SkillData.new()
	flame_bite.skill_name = "Flame Bite"
	flame_bite.mp_cost = 0
	flame_bite.target_type = SkillData.TargetType.SINGLE_ENEMY
	flame_bite.damage_type = SkillData.DamageType.PHYSICAL
	flame_bite.power_multiplier = 1.3
	flame_bite.status_on_hit = {"type": StatusEffect.Type.BURN, "duration": 2, "potency": 8, "chance": 50}
	
	var lava_hound := EnemyData.new()
	lava_hound.enemy_name = "Lava Hound"
	lava_hound.stats = hound_stats
	lava_hound.skills = [flame_bite]
	lava_hound.skill_weights = [1]
	lava_hound.gold_reward = 18
	lava_hound.xp_reward = 28
	lava_hound.sprite_color = Color(0.8, 0.3, 0.05)
	
	enemies["Lava Hound"] = lava_hound
	tier_3.append(lava_hound)
	
	# DEMON — High stats all around. Mini-boss feel.
	var demon_stats := StatBlock.new()
	demon_stats.max_hp = 140
	demon_stats.max_mp = 25
	demon_stats.atk = 20
	demon_stats.def_stat = 16
	demon_stats.mag = 15
	demon_stats.res_stat = 14
	demon_stats.spd = 10
	
	var demon_claw := SkillData.new()
	demon_claw.skill_name = "Demon Claw"
	demon_claw.mp_cost = 0
	demon_claw.target_type = SkillData.TargetType.SINGLE_ENEMY
	demon_claw.damage_type = SkillData.DamageType.PHYSICAL
	demon_claw.power_multiplier = 1.4
	
	var hellfire := SkillData.new()
	hellfire.skill_name = "Hellfire"
	hellfire.mp_cost = 10
	hellfire.target_type = SkillData.TargetType.ALL_ENEMIES
	hellfire.damage_type = SkillData.DamageType.MAGICAL
	hellfire.power_multiplier = 1.1
	hellfire.element = "fire"
	hellfire.status_on_hit = {"type": StatusEffect.Type.BURN, "duration": 3, "potency": 10, "chance": 70}
	
	var demon := EnemyData.new()
	demon.enemy_name = "Demon"
	demon.stats = demon_stats
	demon.skills = [demon_claw, hellfire]
	demon.skill_weights = [3, 1]
	demon.gold_reward = 25
	demon.xp_reward = 35
	demon.sprite_color = Color(0.5, 0.1, 0.15)
	
	enemies["Demon"] = demon
	tier_3.append(demon)
