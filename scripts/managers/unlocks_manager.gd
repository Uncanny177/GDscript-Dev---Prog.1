## UnlocksManager — Tracks all permanent meta-progression.
##
## KEY CONCEPT: PERSISTENT STATE
## Everything in this manager survives death, runs, and game restarts
## (once we add save/load in Task 14). This is the "ratchet" —
## progress only goes forward, never backward.
##
## UNLOCK CATEGORIES:
## - Facilities: shop_tier, blacksmith, training_ground
## - Classes: additional classes beyond the starting three
## - Milestones: tracked achievements that gate unlocks
##
## HOW UNLOCKS WORK:
## 1. Player earns meta-crystals from dungeon runs
## 2. Player spends meta-crystals at the Town Hall NPC
## 3. UnlocksManager records what was purchased
## 4. Hub town reads this to decide what facilities to show
## 5. Guild reads this to decide what classes are available

extends Node

## ─── FACILITY LEVELS ────────────────────────────────────────────
## Each facility has a tier (0 = not built, 1+ = upgraded)

var shop_tier: int = 1         # Starts at 1 (shop always available)
var blacksmith_tier: int = 0   # 0 = not built yet
var training_ground_tier: int = 0  # 0 = not built yet

## ─── CLASS UNLOCKS ──────────────────────────────────────────────
## Which classes are available for recruitment (beyond starting 3)
## Starting classes (Warrior, Mage, Rogue) are always available

var unlocked_classes: Array[String] = ["Warrior", "Mage", "Rogue"]

## ─── MILESTONES ─────────────────────────────────────────────────
## Track achievements that gate certain unlocks

var highest_floor_reached: int = 0
var total_bosses_defeated: int = 0
var total_enemies_defeated: int = 0
var total_runs_completed: int = 0  # Victories only

## ─── UPGRADE COSTS ──────────────────────────────────────────────
## How many meta-crystals each upgrade costs

const UPGRADE_COSTS: Dictionary = {
	"shop_tier_2": 10,
	"shop_tier_3": 25,
	"blacksmith_1": 15,
	"blacksmith_2": 30,
	"training_ground_1": 20,
	"training_ground_2": 40,
}

## Class unlock costs
const CLASS_UNLOCK_COSTS: Dictionary = {
	# Add future classes here
	# "Paladin": 20,
	# "Archer": 15,
}


func _ready() -> void:
	print("[UnlocksManager] Initialized — Shop:%d BSmith:%d Train:%d" % [
		shop_tier, blacksmith_tier, training_ground_tier
	])


## ─── MILESTONE TRACKING ─────────────────────────────────────────

func record_floor_reached(floor_num: int) -> void:
	highest_floor_reached = maxi(highest_floor_reached, floor_num)


func record_boss_defeated() -> void:
	total_bosses_defeated += 1


func record_enemy_defeated() -> void:
	total_enemies_defeated += 1


func record_run_completed() -> void:
	total_runs_completed += 1


## ─── UPGRADE PURCHASING ─────────────────────────────────────────

func get_available_upgrades() -> Array[Dictionary]:
	## Returns a list of upgrades the player can currently purchase.
	## Each entry: {"id": String, "name": String, "cost": int, "description": String}
	var upgrades: Array[Dictionary] = []
	
	# Shop upgrades
	if shop_tier == 1:
		upgrades.append({
			"id": "shop_tier_2",
			"name": "Shop Expansion",
			"cost": UPGRADE_COSTS["shop_tier_2"],
			"description": "Unlock better potions and basic equipment in shop"
		})
	elif shop_tier == 2:
		upgrades.append({
			"id": "shop_tier_3",
			"name": "Shop Mastery",
			"cost": UPGRADE_COSTS["shop_tier_3"],
			"description": "Unlock elixirs and rare equipment in shop"
		})
	
	# Blacksmith
	if blacksmith_tier == 0:
		upgrades.append({
			"id": "blacksmith_1",
			"name": "Build Blacksmith",
			"cost": UPGRADE_COSTS["blacksmith_1"],
			"description": "A blacksmith appears in town (future crafting)"
		})
	elif blacksmith_tier == 1:
		upgrades.append({
			"id": "blacksmith_2",
			"name": "Upgrade Blacksmith",
			"cost": UPGRADE_COSTS["blacksmith_2"],
			"description": "Better recipes and rare crafting"
		})
	
	# Training Ground
	if training_ground_tier == 0:
		upgrades.append({
			"id": "training_ground_1",
			"name": "Build Training Ground",
			"cost": UPGRADE_COSTS["training_ground_1"],
			"description": "A training ground appears in town (future skill learning)"
		})
	elif training_ground_tier == 1:
		upgrades.append({
			"id": "training_ground_2",
			"name": "Upgrade Training Ground",
			"cost": UPGRADE_COSTS["training_ground_2"],
			"description": "Advanced skill training available"
		})
	
	return upgrades


func purchase_upgrade(upgrade_id: String) -> bool:
	## Attempt to purchase an upgrade. Returns false if can't afford.
	if not UPGRADE_COSTS.has(upgrade_id):
		push_error("[UnlocksManager] Unknown upgrade: " + upgrade_id)
		return false
	
	var cost: int = UPGRADE_COSTS[upgrade_id]
	if not GameManager.spend_meta_crystals(cost):
		return false  # Can't afford
	
	# Apply the upgrade
	match upgrade_id:
		"shop_tier_2":
			shop_tier = 2
		"shop_tier_3":
			shop_tier = 3
		"blacksmith_1":
			blacksmith_tier = 1
		"blacksmith_2":
			blacksmith_tier = 2
		"training_ground_1":
			training_ground_tier = 1
		"training_ground_2":
			training_ground_tier = 2
	
	print("[UnlocksManager] Purchased: %s (cost: %d crystals)" % [upgrade_id, cost])
	return true


func is_facility_unlocked(facility: String) -> bool:
	## Check if a facility exists (tier > 0).
	match facility:
		"shop": return shop_tier >= 1
		"blacksmith": return blacksmith_tier >= 1
		"training_ground": return training_ground_tier >= 1
		_: return false


## ─── SERIALIZATION (for save/load in Task 14) ───────────────────

func to_dict() -> Dictionary:
	## Serialize all unlock state to a dictionary for saving.
	return {
		"shop_tier": shop_tier,
		"blacksmith_tier": blacksmith_tier,
		"training_ground_tier": training_ground_tier,
		"unlocked_classes": unlocked_classes,
		"highest_floor_reached": highest_floor_reached,
		"total_bosses_defeated": total_bosses_defeated,
		"total_enemies_defeated": total_enemies_defeated,
		"total_runs_completed": total_runs_completed,
	}


func from_dict(data: Dictionary) -> void:
	## Load unlock state from a saved dictionary.
	shop_tier = data.get("shop_tier", 1)
	blacksmith_tier = data.get("blacksmith_tier", 0)
	training_ground_tier = data.get("training_ground_tier", 0)
	var loaded_classes: Array = data.get("unlocked_classes", ["Warrior", "Mage", "Rogue"])
	unlocked_classes = []
	for class_name_key in loaded_classes:
		if class_name_key is String:
			unlocked_classes.append(class_name_key)
	highest_floor_reached = data.get("highest_floor_reached", 0)
	total_bosses_defeated = data.get("total_bosses_defeated", 0)
	total_enemies_defeated = data.get("total_enemies_defeated", 0)
	total_runs_completed = data.get("total_runs_completed", 0)
