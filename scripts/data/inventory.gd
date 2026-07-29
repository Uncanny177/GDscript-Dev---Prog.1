## Inventory — Tracks items and their quantities.
##
## KEY CONCEPT: DICTIONARY AS A BAG
## An inventory is a "bag" — items with counts. We use a Dictionary
## mapping ItemData → quantity. This is simpler than arrays of slots
## and handles stacking automatically.
##
## WHY NOT JUST AN ARRAY?
## If you have 5 Health Potions, an array stores 5 references to the same item.
## A dictionary stores one reference with quantity=5. Cleaner, faster lookups,
## easier to display in UI.
##
## USAGE:
##   inventory.add_item(potion, 3)    # Add 3 potions
##   inventory.use_item(potion)       # Use 1, returns true if had one
##   inventory.get_count(potion)      # → 2
##   inventory.get_all_items()        # → [{item, count}, ...]

class_name Inventory
extends RefCounted

## Items stored as item_name → {item: ItemData, count: int}
## We key by name (String) because Resource identity can be tricky.
var items: Dictionary = {}


func add_item(item: ItemData, amount: int = 1) -> void:
	## Add item(s) to the inventory. Stacks if already present.
	var key: String = item.item_name
	if items.has(key):
		items[key]["count"] += amount
	else:
		items[key] = {"item": item, "count": amount}


func remove_item(item: ItemData, amount: int = 1) -> bool:
	## Remove item(s). Returns false if not enough to remove.
	var key: String = item.item_name
	if not items.has(key):
		return false
	if items[key]["count"] < amount:
		return false
	
	items[key]["count"] -= amount
	if items[key]["count"] <= 0:
		items.erase(key)
	return true


func use_item(item: ItemData) -> bool:
	## Use one of this item (consume it). Returns false if none available.
	## Does NOT apply the effect — the caller handles that.
	if item.item_type != ItemData.ItemType.CONSUMABLE:
		return false
	return remove_item(item, 1)


func get_count(item: ItemData) -> int:
	## How many of this item do we have?
	var key: String = item.item_name
	if items.has(key):
		return items[key]["count"]
	return 0


func has_item(item: ItemData) -> bool:
	## Do we have at least one?
	return get_count(item) > 0


func get_all_items() -> Array:
	## Returns array of {"item": ItemData, "count": int} for UI display.
	## Only returns items with count > 0.
	var result: Array = []
	for key in items:
		if items[key]["count"] > 0:
			result.append(items[key])
	return result


func get_consumables() -> Array:
	## Returns only consumable items (for combat item menu).
	var result: Array = []
	for key in items:
		var entry: Dictionary = items[key]
		if entry["count"] > 0 and entry["item"].item_type == ItemData.ItemType.CONSUMABLE:
			result.append(entry)
	return result


func clear() -> void:
	## Empty the entire inventory. Used on death (lose run items).
	items.clear()


func _to_string() -> String:
	var parts: Array = []
	for key in items:
		parts.append("%s x%d" % [key, items[key]["count"]])
	return "Inventory: " + ", ".join(parts) if parts.size() > 0 else "Inventory: (empty)"
