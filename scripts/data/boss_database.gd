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

	# ─── FLOOR 1 MINI-BOSS: SLIME KING ─────────────────────────
	var slime_king := BossData.new()
	slime_king.boss_name = "Slime King"
	slime_king.description = "A massive slime that splits when damaged."
	slime_king.sprite_color = Color(0.3, 0.8, 0.3)
	
	var sk_stats := StatBlock.new()
	sk_stats.max_hp = 120
	sk_stats.max_mp = 10
	sk_stats.atk = 10
	sk_stats.def_stat = 6
	sk_stats.mag = 4
	sk_stats.res_stat = 4
	sk_stats.spd = 5
	slime_king.stats = sk_stats
	
	var sk_slam := SkillData.new()
	sk_slam.skill_name = "Body Slam"
	sk_slam.mp_cost = 0
	sk_slam.target_type = SkillData.TargetType.SINGLE_ENEMY
	sk_slam.damage_type = SkillData.DamageType.PHYSICAL
	sk_slam.power_multiplier = 1.1
	
	var sk_acid := SkillData.new()
	sk_acid.skill_name = "Acid Splash"
	sk_acid.description = "Corrosive spray hits all enemies"
	sk_acid.mp_cost = 5
	sk_acid.target_type = SkillData.TargetType.ALL_ENEMIES
	sk_acid.damage_type = SkillData.DamageType.MAGICAL
	sk_acid.power_multiplier = 0.7
	sk_acid.status_on_hit = {"type": StatusEffect.Type.DEF_DOWN, "duration": 2, "potency": 15, "chance": 50}
	
	var sk_enrage := SkillData.new()
	sk_enrage.skill_name = "Enraged Slam"
	sk_enrage.mp_cost = 0
	sk_enrage.target_type = SkillData.TargetType.SINGLE_ENEMY
	sk_enrage.damage_type = SkillData.DamageType.PHYSICAL
	sk_enrage.power_multiplier = 1.6
	
	slime_king.phase_skills = [[sk_slam, sk_acid], [sk_enrage, sk_acid]]
	slime_king.phase_weights = [[3, 1], [2, 2]]
	slime_king.phase_thresholds = [0.5]
	slime_king.can_summon = true
	slime_king.summon_enemy_name = "Slime"
	slime_king.summon_count = 2
	slime_king.gold_reward = 20
	slime_king.meta_crystal_reward = 2
	
	bosses[1] = slime_king
	
	# ─── FLOOR 2 BOSS: CAVE WYRM ──────────────────────────────
	var cave_wyrm := BossData.new()
	cave_wyrm.boss_name = "Cave Wyrm"
	cave_wyrm.description = "A serpentine beast that coils through the tunnels."
	cave_wyrm.sprite_color = Color(0.4, 0.35, 0.25)
	
	var cw_stats := StatBlock.new()
	cw_stats.max_hp = 160
	cw_stats.max_mp = 20
	cw_stats.atk = 14
	cw_stats.def_stat = 10
	cw_stats.mag = 6
	cw_stats.res_stat = 6
	cw_stats.spd = 12
	cave_wyrm.stats = cw_stats
	
	var cw_bite := SkillData.new()
	cw_bite.skill_name = "Crushing Bite"
	cw_bite.mp_cost = 0
	cw_bite.target_type = SkillData.TargetType.SINGLE_ENEMY
	cw_bite.damage_type = SkillData.DamageType.PHYSICAL
	cw_bite.power_multiplier = 1.3
	
	var cw_coil := SkillData.new()
	cw_coil.skill_name = "Constrict"
	cw_coil.description = "Wraps around a target, stunning them"
	cw_coil.mp_cost = 8
	cw_coil.target_type = SkillData.TargetType.SINGLE_ENEMY
	cw_coil.damage_type = SkillData.DamageType.PHYSICAL
	cw_coil.power_multiplier = 1.0
	cw_coil.status_on_hit = {"type": StatusEffect.Type.STUN, "duration": 1, "potency": 0, "chance": 70}
	
	var cw_thrash := SkillData.new()
	cw_thrash.skill_name = "Thrash"
	cw_thrash.description = "Wildly attacks all enemies"
	cw_thrash.mp_cost = 10
	cw_thrash.target_type = SkillData.TargetType.ALL_ENEMIES
	cw_thrash.damage_type = SkillData.DamageType.PHYSICAL
	cw_thrash.power_multiplier = 0.9
	
	cave_wyrm.phase_skills = [[cw_bite, cw_coil], [cw_thrash, cw_bite, cw_coil]]
	cave_wyrm.phase_weights = [[3, 1], [2, 2, 1]]
	cave_wyrm.phase_thresholds = [0.4]
	cave_wyrm.can_summon = false
	cave_wyrm.gold_reward = 30
	cave_wyrm.meta_crystal_reward = 3
	
	bosses[2] = cave_wyrm
	
	# ─── FLOOR 4 BOSS: BONE LICH ──────────────────────────────
	var bone_lich := BossData.new()
	bone_lich.boss_name = "Bone Lich"
	bone_lich.description = "An undead sorcerer wreathed in necrotic energy."
	bone_lich.sprite_color = Color(0.6, 0.55, 0.8)
	
	var bl_stats := StatBlock.new()
	bl_stats.max_hp = 280
	bl_stats.max_mp = 80
	bl_stats.atk = 10
	bl_stats.def_stat = 12
	bl_stats.mag = 22
	bl_stats.res_stat = 18
	bl_stats.spd = 11
	bone_lich.stats = bl_stats
	
	var bl_bolt := SkillData.new()
	bl_bolt.skill_name = "Death Bolt"
	bl_bolt.mp_cost = 6
	bl_bolt.target_type = SkillData.TargetType.SINGLE_ENEMY
	bl_bolt.damage_type = SkillData.DamageType.MAGICAL
	bl_bolt.power_multiplier = 1.5
	bl_bolt.element = "dark"
	
	var bl_curse := SkillData.new()
	bl_curse.skill_name = "Mass Curse"
	bl_curse.description = "Curses all enemies, weakening their defense"
	bl_curse.mp_cost = 12
	bl_curse.target_type = SkillData.TargetType.ALL_ENEMIES
	bl_curse.damage_type = SkillData.DamageType.NONE
	bl_curse.power_multiplier = 0.0
	bl_curse.element = "dark"
	bl_curse.status_on_hit = {"type": StatusEffect.Type.DEF_DOWN, "duration": 3, "potency": 25, "chance": 100}
	
	var bl_drain := SkillData.new()
	bl_drain.skill_name = "Soul Harvest"
	bl_drain.description = "Drains life from all enemies"
	bl_drain.mp_cost = 15
	bl_drain.target_type = SkillData.TargetType.ALL_ENEMIES
	bl_drain.damage_type = SkillData.DamageType.MAGICAL
	bl_drain.power_multiplier = 1.2
	bl_drain.element = "dark"
	
	var bl_nova := SkillData.new()
	bl_nova.skill_name = "Necrotic Nova"
	bl_nova.description = "Massive dark explosion"
	bl_nova.mp_cost = 20
	bl_nova.target_type = SkillData.TargetType.ALL_ENEMIES
	bl_nova.damage_type = SkillData.DamageType.MAGICAL
	bl_nova.power_multiplier = 1.6
	bl_nova.element = "dark"
	bl_nova.status_on_hit = {"type": StatusEffect.Type.BURN, "duration": 2, "potency": 10, "chance": 60}
	
	bone_lich.phase_skills = [[bl_bolt, bl_curse], [bl_drain, bl_nova, bl_bolt]]
	bone_lich.phase_weights = [[3, 1], [2, 1, 2]]
	bone_lich.phase_thresholds = [0.5]
	bone_lich.can_summon = true
	bone_lich.summon_enemy_name = "Skeleton"
	bone_lich.summon_count = 3
	bone_lich.gold_reward = 60
	bone_lich.meta_crystal_reward = 5
	
	bosses[4] = bone_lich
