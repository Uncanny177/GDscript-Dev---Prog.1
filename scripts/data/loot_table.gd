## LootTable — Weighted random drop table for enemies and chests.
##
## KEY CONCEPT: WEIGHTED RANDOM SELECTION
## Each entry has a "weight" — higher weight = more likely to drop.
## Weights don't need to add up to 100. They're relative:
##   weight 3 vs weight 1 = 75% vs 25% chance
##   weight 10 vs weight 5 vs weight 1 = 62.5% vs 31.25% vs 6.25%
##
## WHY A RESOURCE?
## Loot tables are data — you'd want to tweak drop rates without
## changing code. Making them Resources means:
##   - Editable in Godot Inspector
##   - Saveable as .tres files
##   - Swappable per enemy/chest/floor
##
## USAGE:
##   var table := LootTable.new()
##   table.add_entry(LootTable.LootType.GOLD, 10, 3, "")  # 10 gold, weight 3
##   table.add_entry(LootTable.LootType.ITEM, 1, 1, "Health Potion")  # 1 potion, weight 1
##   table.add_entry(LootTable.LootType.NOTHING, 0, 2, "")  # nothing, weight 2
##   var drop = table.roll()  # → {"type": ..., "amount": ..., "item_name": ...}

class_name LootTable
extends RefCounted

## What kind of loot can drop
enum LootType {
	NOTHING,       # No drop (empty roll)
	GOLD,          # Run-currency gold
	ITEM,          # A specific item by name
	META_CRYSTAL   # Permanent meta-currency
}

## Each entry in the table
## {"type": LootType, "amount": int, "weight": int, "item_name": String}
var entries: Array[Dictionary] = []

## Total weight (cached for performance)
var total_weight: int = 0


func add_entry(type: LootType, amount: int, weight: int, item_name: String = "") -> void:
	## Add a loot entry to the table.
	entries.append({
		"type": type,
		"amount": amount,
		"weight": weight,
		"item_name": item_name
	})
	total_weight += weight


func roll() -> Dictionary:
	## Roll the loot table once. Returns the selected entry.
	## Uses weighted random selection.
	
	if entries.is_empty() or total_weight <= 0:
		return {"type": LootType.NOTHING, "amount": 0, "item_name": ""}
	
	var roll_value: int = randi() % total_weight
	var cumulative: int = 0
	
	for entry in entries:
		cumulative += entry["weight"]
		if roll_value < cumulative:
			return entry
	
	# Fallback (shouldn't reach here)
	return entries[entries.size() - 1]


func roll_multiple(count: int) -> Array[Dictionary]:
	## Roll the table multiple times. Returns array of results.
	var results: Array[Dictionary] = []
	for i in range(count):
		results.append(roll())
	return results


static func create_enemy_table(floor_number: int) -> LootTable:
	## Factory: creates a standard enemy loot table scaled by floor.
	var table := LootTable.new()
	
	# Nothing (decreases with floor)
	var nothing_weight: int = maxi(4 - floor_number, 1)
	table.add_entry(LootType.NOTHING, 0, nothing_weight)
	
	# Gold (scales with floor)
	var gold_amount: int = 5 + floor_number * 3
	table.add_entry(LootType.GOLD, gold_amount, 4)
	
	# Health Potion (common drop)
	table.add_entry(LootType.ITEM, 1, 2, "Health Potion")
	
	# Mana Potion (less common)
	table.add_entry(LootType.ITEM, 1, 1, "Mana Potion")
	
	# Meta crystal (rare)
	if floor_number >= 2:
		table.add_entry(LootType.META_CRYSTAL, 1, 1)
	
	# Crafting materials (biome-appropriate)
	if floor_number <= 2:
		# Cave: basic materials
		table.add_entry(LootType.ITEM, 1, 2, "Iron Ore")
		table.add_entry(LootType.ITEM, 1, 1, "Coal")
		table.add_entry(LootType.ITEM, 1, 1, "Leather")
		table.add_entry(LootType.ITEM, 1, 1, "Wood")
	elif floor_number <= 4:
		# Crypt: dark materials
		table.add_entry(LootType.ITEM, 1, 2, "Dark Crystal")
		table.add_entry(LootType.ITEM, 1, 1, "Iron Ore")
		table.add_entry(LootType.ITEM, 1, 1, "Ice Shard")
	else:
		# Inferno: fire materials
		table.add_entry(LootType.ITEM, 1, 2, "Fire Essence")
		table.add_entry(LootType.ITEM, 1, 1, "Wind Essence")
		table.add_entry(LootType.ITEM, 1, 1, "Iron Ore")
	
	return table


static func create_chest_table(floor_number: int) -> LootTable:
	## Factory: creates a chest loot table (guaranteed something good).
	var table := LootTable.new()
	
	# Gold (generous from chests)
	var gold_amount: int = 10 + floor_number * 5
	table.add_entry(LootType.GOLD, gold_amount, 3)
	
	# Health Potion
	table.add_entry(LootType.ITEM, 1, 2, "Health Potion")
	
	# Mana Potion
	table.add_entry(LootType.ITEM, 1, 2, "Mana Potion")
	
	# Mega Potion (floor 3+)
	if floor_number >= 3:
		table.add_entry(LootType.ITEM, 1, 1, "Mega Potion")
	
	# Elixir (floor 4+)
	if floor_number >= 4:
		table.add_entry(LootType.ITEM, 1, 1, "Elixir")
	
	# Meta crystals
	var crystal_amount: int = 1 + int(floor_number / 2.0)
	table.add_entry(LootType.META_CRYSTAL, crystal_amount, 1)
	
	return table


static func create_boss_table(floor_number: int) -> LootTable:
	## Factory: boss drops are always generous.
	var table := LootTable.new()
	
	# Guaranteed gold
	table.add_entry(LootType.GOLD, 30 + floor_number * 10, 3)
	
	# Guaranteed meta crystals
	table.add_entry(LootType.META_CRYSTAL, 3 + floor_number, 3)
	
	# Good items
	table.add_entry(LootType.ITEM, 1, 2, "Mega Potion")
	table.add_entry(LootType.ITEM, 1, 1, "Elixir")
	
	return table
