## CraftingSystem — Recipes and crafting logic for the Blacksmith.
##
## Players collect materials from dungeon enemies/chests and combine
## them at the Blacksmith to create or upgrade equipment.
##
## MATERIALS: Dropped from enemies, stored in inventory like items.
## RECIPES: material requirements → output equipment piece.
## Recipes unlock as Blacksmith is upgraded (tier 1 → tier 2).

class_name CraftingSystem
extends RefCounted

## A recipe definition
## {"name": String, "materials": {mat_name: count, ...}, "gold_cost": int, "result": String, "tier": int}

static func get_recipes() -> Array[Dictionary]:
	## Returns all crafting recipes. Filtered by blacksmith tier at display time.
	return [
		# ─── TIER 1 RECIPES (Blacksmith built) ───────────────────
		{
			"name": "Steel Sword",
			"materials": {"Iron Ore": 3, "Coal": 1},
			"gold_cost": 30,
			"result": "Steel Sword",
			"tier": 1,
			"description": "A solid steel blade. +8 ATK",
		},
		{
			"name": "Chain Mail",
			"materials": {"Iron Ore": 2, "Leather": 2},
			"gold_cost": 35,
			"result": "Chain Mail",
			"tier": 1,
			"description": "Linked metal rings. +7 DEF",
		},
		{
			"name": "Mage Staff",
			"materials": {"Dark Crystal": 2, "Wood": 1},
			"gold_cost": 40,
			"result": "Mage Staff",
			"tier": 1,
			"description": "Channels arcane power. +7 MAG",
		},
		{
			"name": "Swift Boots",
			"materials": {"Leather": 3, "Wind Essence": 1},
			"gold_cost": 25,
			"result": "Swift Boots",
			"tier": 1,
			"description": "Featherlight footwear. +5 SPD",
		},
		# ─── TIER 2 RECIPES (Blacksmith upgraded) ────────────────
		{
			"name": "Flame Blade",
			"materials": {"Iron Ore": 3, "Fire Essence": 2, "Coal": 2},
			"gold_cost": 60,
			"result": "Flame Blade",
			"tier": 2,
			"description": "Burns on contact. +10 ATK, fire element",
		},
		{
			"name": "Shadow Cloak",
			"materials": {"Dark Crystal": 3, "Leather": 2},
			"gold_cost": 55,
			"result": "Shadow Cloak",
			"tier": 2,
			"description": "Bends light around you. +6 DEF +4 SPD",
		},
		{
			"name": "Crystal Shield",
			"materials": {"Iron Ore": 2, "Dark Crystal": 2, "Ice Shard": 1},
			"gold_cost": 50,
			"result": "Crystal Shield",
			"tier": 2,
			"description": "Reflects magic. +5 DEF +5 RES",
		},
		{
			"name": "Life Pendant",
			"materials": {"Fire Essence": 1, "Wind Essence": 1, "Ice Shard": 1},
			"gold_cost": 45,
			"result": "Life Pendant",
			"tier": 2,
			"description": "Pulses with vitality. +30 HP",
		},
	]


static func can_craft(recipe: Dictionary) -> bool:
	## Check if player has all materials and gold for a recipe.
	if GameManager.current_gold < recipe["gold_cost"]:
		return false
	
	var materials: Dictionary = recipe["materials"]
	for mat_name in materials:
		var needed: int = materials[mat_name]
		var item: ItemData = ItemDatabase.get_item(mat_name)
		if not item or GameManager.inventory.get_count(item) < needed:
			return false
	
	return true


static func craft(recipe: Dictionary) -> bool:
	## Consume materials and gold, produce the result item.
	## Returns false if can't afford.
	if not can_craft(recipe):
		return false
	
	# Consume gold
	GameManager.current_gold -= recipe["gold_cost"]
	
	# Consume materials
	var materials: Dictionary = recipe["materials"]
	for mat_name in materials:
		var item: ItemData = ItemDatabase.get_item(mat_name)
		if item:
			GameManager.inventory.remove_item(item, materials[mat_name])
	
	# Produce result
	var result_item: ItemData = ItemDatabase.get_item(recipe["result"])
	if result_item:
		GameManager.inventory.add_item(result_item)
		print("[Crafting] Created %s" % recipe["result"])
		return true
	
	push_error("[Crafting] Result item not found: " + recipe["result"])
	return false
