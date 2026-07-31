## ShopData — Manages the shop's inventory and buy/sell transactions.
##
## KEY CONCEPT: SHOP AS A STATE MACHINE
## The shop has its own inventory (what's for sale) separate from the
## player's inventory. Buying moves items shop → player. Selling does reverse.
##
## PRICING:
## - Buy price: defined on each ItemData
## - Sell price: half of buy price (standard RPG convention)
##
## SHOP TIERS:
## The shop's available items expand as the player unlocks upgrades.
## Tier 1 (start): basic potions
## Tier 2 (unlock): better potions + basic equipment
## Tier 3 (unlock): best potions + better equipment

class_name ShopData
extends RefCounted

## What's currently for sale: Array of ItemData
var stock: Array[ItemData] = []

## Current shop tier (affects what's available)
var tier: int = 1


func refresh_stock() -> void:
	## Rebuild the shop stock based on current tier.
	## Called when entering the shop or after upgrading.
	stock.clear()
	
	# Tier 1 — always available
	_add_if_exists("Health Potion")
	_add_if_exists("Mana Potion")
	
	# Tier 2
	if tier >= 2:
		_add_if_exists("Mega Potion")
		_add_if_exists("Iron Sword")
		_add_if_exists("Leather Armor")
	
	# Tier 3
	if tier >= 3:
		_add_if_exists("Elixir")
		_add_if_exists("Speed Ring")


func _add_if_exists(item_name: String) -> void:
	var item: ItemData = ItemDatabase.get_item(item_name)
	if item:
		stock.append(item)


func buy_item(item: ItemData, quantity: int = 1) -> bool:
	## Player buys from shop. Returns false if can't afford.
	var total_cost: int = item.buy_price * quantity
	
	if not GameManager.spend_gold(total_cost):
		return false  # Not enough gold
	
	GameManager.inventory.add_item(item, quantity)
	return true


func sell_item(item: ItemData, quantity: int = 1) -> bool:
	## Player sells to shop. Returns false if doesn't have the item.
	if not item.sellable:
		return false
	
	if GameManager.inventory.get_count(item) < quantity:
		return false  # Don't have enough
	
	GameManager.inventory.remove_item(item, quantity)
	var sell_price: int = item.get_sell_price() * quantity
	GameManager.add_gold(sell_price)
	return true


func get_stock_display() -> Array[Dictionary]:
	## Returns shop stock formatted for UI display.
	## Each entry: {"item": ItemData, "can_afford": bool}
	var display: Array[Dictionary] = []
	for item in stock:
		display.append({
			"item": item,
			"can_afford": GameManager.current_gold >= item.buy_price
		})
	return display
