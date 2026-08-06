## ItemData — Defines an item (consumable, equipment, or key item).
##
## Items serve multiple purposes in our game:
##   - Consumables: Health Potion, Mana Potion (used in combat or overworld)
##   - Equipment: Sword, Shield, Ring (modifies stats when equipped)
##   - Key Items: Boss Key, quest items (not usable, just tracked)
##
## We use one Resource class for all types to keep things simple.
## The "item_type" enum tells the game how to handle it.

class_name ItemData
extends Resource

## What category of item is this?
enum ItemType {
	CONSUMABLE,  # Use it, it's gone (potions, scrolls)
	EQUIPMENT,   # Equip to a slot, modifies stats
	KEY_ITEM     # Can't be used or sold, just exists in inventory
}

## Which equipment slot does this go in? (only matters for EQUIPMENT type)
enum EquipSlot {
	NONE,        # Not equippable
	WEAPON,      # ATK-focused
	ARMOR,       # DEF-focused
	ACCESSORY    # Misc bonuses (SPD, RES, etc.)
}

## Display name
@export var item_name: String = "Unknown Item"

## Description for tooltip/shop UI
@export var description: String = ""

## What kind of item?
@export var item_type: ItemType = ItemType.CONSUMABLE

## Equipment slot (ignored for consumables/key items)
@export var equip_slot: EquipSlot = EquipSlot.NONE

## Buy price in gold (sell price is usually half)
@export var buy_price: int = 10

## Can this be sold?
@export var sellable: bool = true

## ─── CONSUMABLE PROPERTIES ──────────────────────────────────

## How much HP does this restore? (0 = doesn't heal HP)
@export var heal_hp: int = 0

## How much MP does this restore? (0 = doesn't restore MP)
@export var heal_mp: int = 0

## ─── EQUIPMENT PROPERTIES ───────────────────────────────────

## Stat bonuses when equipped. Added to character's base stats.
@export var stat_bonus: StatBlock = null


func get_sell_price() -> int:
	## Sell price is half of buy price (standard RPG convention).
	## Using integer division — 11 / 2 = 5, not 5.5
	if not sellable:
		return 0
	return maxi(int(buy_price / 2.0), 1)


func _to_string() -> String:
	match item_type:
		ItemType.CONSUMABLE:
			return "%s (Consumable) +%dHP +%dMP" % [item_name, heal_hp, heal_mp]
		ItemType.EQUIPMENT:
			return "%s (Equipment: %s)" % [item_name, EquipSlot.keys()[equip_slot]]
		ItemType.KEY_ITEM:
			return "%s (Key Item)" % item_name
		_:
			return item_name
