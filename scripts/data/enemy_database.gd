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
