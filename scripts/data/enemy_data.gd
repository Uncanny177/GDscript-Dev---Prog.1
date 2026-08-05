## EnemyData — Defines an enemy type (Slime, Goblin, Skeleton, etc.)
##
## Similar to ClassData but for enemies. Enemies don't have "classes" or
## equipment — they just have flat stats and a list of skills they might use.
##
## ENEMY AI (simplified for now):
## Each skill has a "weight" — higher weight = more likely to use it.
## A Slime with Attack(weight 3) and Heal(weight 1) will attack 75% of the time.
## We'll flesh out AI behavior (phases, targeting) in later tasks.

class_name EnemyData
extends Resource

## Display name in combat UI
@export var enemy_name: String = "Unknown Enemy"

## Base stats (same structure as characters — HP, ATK, DEF, etc.)
@export var stats: StatBlock = null

## Skills this enemy can use, with weights for AI selection.
## Format: Array of dictionaries with "skill" (SkillData) and "weight" (int)
## Higher weight = more likely to be chosen.
@export var skills: Array[SkillData] = []
@export var skill_weights: Array[int] = []  # Parallel array — weight[i] matches skills[i]

## Experience and gold rewards for defeating this enemy
@export var gold_reward: int = 5
@export var xp_reward: int = 10

## Placeholder sprite color (until we have art)
@export var sprite_color: Color = Color.RED

## Elemental affinity of this enemy (determines weakness/resistance)
## "none", "fire", "ice", "dark", "light"
@export var element: String = "none"

## How many meta-crystals this enemy drops (usually 0, bosses drop more)
@export var meta_crystal_drop: int = 0


func pick_skill() -> SkillData:
	## Weighted random skill selection for enemy AI.
	##
	## HOW WEIGHTED RANDOM WORKS:
	## If weights are [3, 1, 1], total is 5.
	## Roll random 0-4:
	##   0,1,2 → pick skill 0 (weight 3 = 3/5 chance = 60%)
	##   3     → pick skill 1 (weight 1 = 1/5 chance = 20%)
	##   4     → pick skill 2 (weight 1 = 1/5 chance = 20%)
	##
	## This is a super common game dev pattern for loot tables, AI, spawn rates, etc.
	
	if skills.is_empty():
		return null
	
	# If no weights defined, equal chance for all skills
	if skill_weights.is_empty() or skill_weights.size() != skills.size():
		return skills[randi() % skills.size()]
	
	# Calculate total weight
	var total_weight: int = 0
	for w in skill_weights:
		total_weight += w
	
	# Roll a random number from 0 to total_weight - 1
	var roll: int = randi() % total_weight
	
	# Walk through skills, subtracting weights until roll goes negative
	var cumulative: int = 0
	for i in range(skills.size()):
		cumulative += skill_weights[i]
		if roll < cumulative:
			return skills[i]
	
	# Fallback (shouldn't reach here, but safety first)
	return skills[0]


func _to_string() -> String:
	var stats_str: String = str(stats) if stats else "no stats"
	return "%s [%s] — %d skills, %d gold" % [enemy_name, stats_str, skills.size(), gold_reward]
