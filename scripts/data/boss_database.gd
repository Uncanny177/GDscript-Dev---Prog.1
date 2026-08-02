## BossDatabase — Defines all boss encounters.
##
## Each floor's boss is different. Floor 5 has the final boss.
## Bosses are harder versions of regular enemies with phase mechanics.

extends Node

var bosses: Dictionary = {}


func _ready() -> void:
	_create_bosses()
	print("[BossDatabase] Loaded %d bosses" % bosses.size())


func get_boss_for_floor(floor_number: int) -> BossData:
	## Get the boss for a specific floor. Returns the final boss for floor 5+.
	if bosses.has(floor_number):
		return bosses[floor_number]
	# Default: return final boss for any floor beyond defined ones
	if bosses.has(5):
		return bosses[5]
	return null


func _create_bosses() -> void:
	# ─── FLOOR 3 MINI-BOSS: GOBLIN KING ────────────────────────
	var goblin_king := BossData.new()
	goblin_king.boss_name = "Goblin King"
	goblin_king.description = "A massive goblin wearing a crude crown."
	goblin_king.sprite_color = Color(0.7, 0.5, 0.1)
	
	var gk_stats := StatBlock.new()
	gk_stats.max_hp = 200
	gk_stats.max_mp = 30
	gk_stats.atk = 18
	gk_stats.def_stat = 12
	gk_stats.mag = 8
	gk_stats.res_stat = 8
	gk_stats.spd = 10
	goblin_king.stats = gk_stats
	
	# Phase 1 skills (above 50% HP)
	var gk_slash := SkillData.new()
	gk_slash.skill_name = "Royal Slash"
	gk_slash.mp_cost = 0
	gk_slash.target_type = SkillData.TargetType.SINGLE_ENEMY
	gk_slash.damage_type = SkillData.DamageType.PHYSICAL
	gk_slash.power_multiplier = 1.2
	
	var gk_roar := SkillData.new()
	gk_roar.skill_name = "War Cry"
	gk_roar.description = "Boosts own attack power"
	gk_roar.mp_cost = 5
	gk_roar.target_type = SkillData.TargetType.SELF
	gk_roar.damage_type = SkillData.DamageType.NONE
	gk_roar.power_multiplier = 0.0
	
	# Phase 2 skills (below 50% HP — enraged)
	var gk_frenzy := SkillData.new()
	gk_frenzy.skill_name = "Frenzied Strike"
	gk_frenzy.mp_cost = 0
	gk_frenzy.target_type = SkillData.TargetType.SINGLE_ENEMY
	gk_frenzy.damage_type = SkillData.DamageType.PHYSICAL
	gk_frenzy.power_multiplier = 1.8
	
	var gk_sweep := SkillData.new()
	gk_sweep.skill_name = "Wild Sweep"
	gk_sweep.description = "Attacks all enemies in a frenzy"
	gk_sweep.mp_cost = 10
	gk_sweep.target_type = SkillData.TargetType.ALL_ENEMIES
	gk_sweep.damage_type = SkillData.DamageType.PHYSICAL
	gk_sweep.power_multiplier = 1.0
	
	goblin_king.phase_skills = [[gk_slash, gk_roar], [gk_frenzy, gk_sweep]]
	goblin_king.phase_weights = [[3, 1], [2, 1]]
	goblin_king.phase_thresholds = [0.5]
	goblin_king.can_summon = true
	goblin_king.summon_enemy_name = "Goblin"
	goblin_king.summon_count = 2
	goblin_king.gold_reward = 40
	goblin_king.meta_crystal_reward = 3
	
	bosses[3] = goblin_king
	
	# ─── FLOOR 5 FINAL BOSS: SHADOW LORD ───────────────────────
	var shadow_lord := BossData.new()
	shadow_lord.boss_name = "Shadow Lord"
	shadow_lord.description = "A towering figure wreathed in darkness."
	shadow_lord.sprite_color = Color(0.2, 0.05, 0.3)
	
	var sl_stats := StatBlock.new()
	sl_stats.max_hp = 350
	sl_stats.max_mp = 60
	sl_stats.atk = 22
	sl_stats.def_stat = 16
	sl_stats.mag = 20
	sl_stats.res_stat = 14
	sl_stats.spd = 12
	shadow_lord.stats = sl_stats
	
	# Phase 1 skills (above 50% HP — balanced)
	var sl_strike := SkillData.new()
	sl_strike.skill_name = "Shadow Strike"
	sl_strike.mp_cost = 0
	sl_strike.target_type = SkillData.TargetType.SINGLE_ENEMY
	sl_strike.damage_type = SkillData.DamageType.PHYSICAL
	sl_strike.power_multiplier = 1.3
	
	var sl_bolt := SkillData.new()
	sl_bolt.skill_name = "Dark Bolt"
	sl_bolt.mp_cost = 8
	sl_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	sl_bolt.damage_type = SkillData.DamageType.MAGICAL
	sl_bolt.power_multiplier = 1.5
	sl_bolt.element = "dark"
	
	# Phase 2 skills (below 50% HP — all-out magical assault)
	var sl_nova := SkillData.new()
	sl_nova.skill_name = "Shadow Nova"
	sl_nova.description = "Dark energy explodes outward hitting all"
	sl_nova.mp_cost = 15
	sl_nova.target_type = SkillData.TargetType.ALL_ENEMIES
	sl_nova.damage_type = SkillData.DamageType.MAGICAL
	sl_nova.power_multiplier = 1.4
	sl_nova.element = "dark"
	
	var sl_drain := SkillData.new()
	sl_drain.skill_name = "Life Drain"
	sl_drain.description = "Steals life force from a target"
	sl_drain.mp_cost = 10
	sl_drain.target_type = SkillData.TargetType.SINGLE_ENEMY
	sl_drain.damage_type = SkillData.DamageType.MAGICAL
	sl_drain.power_multiplier = 1.6
	sl_drain.element = "dark"
	
	shadow_lord.phase_skills = [[sl_strike, sl_bolt], [sl_nova, sl_drain, sl_strike]]
	shadow_lord.phase_weights = [[3, 2], [2, 2, 1]]
	shadow_lord.phase_thresholds = [0.5]
	shadow_lord.can_summon = true
	shadow_lord.summon_enemy_name = "Skeleton"
	shadow_lord.summon_count = 2
	shadow_lord.gold_reward = 100
	shadow_lord.meta_crystal_reward = 8
	
	bosses[5] = shadow_lord
