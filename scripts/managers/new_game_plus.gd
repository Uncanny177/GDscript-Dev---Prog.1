## NewGamePlus — Harder loop after first clear with scaling difficulty.
##
## After beating the Shadow Lord (floor 5), the player can choose to
## enter NG+ which:
## - Keeps all unlocks, classes, learned skills, party levels
## - Resets dungeon progress (back to floor 1)
## - Scales all enemy stats by a multiplier per NG+ tier
## - Adds new modifiers (more enemies, faster encounters, boss buffs)
## - Tracks NG+ tier (NG+1, NG+2, NG+3, etc.)
##
## Each successive NG+ tier gets harder. There's no cap — it just
## keeps scaling until the player can't survive anymore.

extends Node

## Current NG+ tier (0 = normal, 1 = NG+1, 2 = NG+2, etc.)
var ng_plus_tier: int = 0

## Has the player beaten the game at least once?
var has_cleared_game: bool = false

## Stat multiplier per tier (enemies get this much stronger per NG+ level)
const STAT_SCALE_PER_TIER: float = 0.3  # +30% per tier

## Extra enemies per encounter per tier
const EXTRA_ENEMIES_PER_TIER: int = 1

## Encounter rate boost per tier
const ENCOUNTER_RATE_BOOST: float = 0.05


func _ready() -> void:
	print("[NG+] Tier: %d | Cleared: %s" % [ng_plus_tier, str(has_cleared_game)])


## ─── SCALING FUNCTIONS (called by combat/dungeon) ───────────────

func get_enemy_stat_multiplier() -> float:
	## Returns the multiplier to apply to all enemy stats.
	## Tier 0 = 1.0x, Tier 1 = 1.3x, Tier 2 = 1.6x, etc.
	return 1.0 + ng_plus_tier * STAT_SCALE_PER_TIER


func get_extra_enemy_count() -> int:
	## How many extra enemies to add per encounter in NG+.
	return ng_plus_tier * EXTRA_ENEMIES_PER_TIER


func get_encounter_rate_bonus() -> float:
	## Additional encounter chance added to base rate.
	return ng_plus_tier * ENCOUNTER_RATE_BOOST


func get_xp_multiplier() -> float:
	## NG+ gives bonus XP to offset increased difficulty.
	return 1.0 + ng_plus_tier * 0.2  # +20% XP per tier


func get_gold_multiplier() -> float:
	## NG+ gives bonus gold.
	return 1.0 + ng_plus_tier * 0.25  # +25% gold per tier


## ─── PROGRESSION ────────────────────────────────────────────────

func mark_game_cleared() -> void:
	## Called when the player defeats the final boss for the first time.
	has_cleared_game = true


func enter_new_game_plus() -> void:
	## Start the next NG+ tier. Keeps progression, resets dungeon.
	ng_plus_tier += 1
	
	# Reset run-specific stuff
	GameManager.current_gold = 0
	GameManager.current_floor = 1
	GameManager.is_run_active = false
	GameManager.inventory = Inventory.new()
	
	# Heal party fully for the new challenge
	PartyManager.heal_all()
	
	# Save the new tier
	SaveManager.save_meta()
	
	print("[NG+] Entered NG+%d! Enemy scaling: x%.1f" % [ng_plus_tier, get_enemy_stat_multiplier()])


func get_tier_display() -> String:
	## Display string for UI.
	if ng_plus_tier <= 0:
		return ""
	return "NG+%d" % ng_plus_tier


## ─── SERIALIZATION ──────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"ng_plus_tier": ng_plus_tier,
		"has_cleared_game": has_cleared_game,
	}


func from_dict(data: Dictionary) -> void:
	ng_plus_tier = int(data.get("ng_plus_tier", 0))
	has_cleared_game = data.get("has_cleared_game", false)
