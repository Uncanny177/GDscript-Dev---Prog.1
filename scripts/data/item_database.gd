## ItemDatabase — Defines all available items and provides lookup.
##
## Same pattern as ClassDatabase / EnemyDatabase.
## Creates item definitions on startup, accessible globally.

extends Node

## All items keyed by name
var items: Dictionary = {}


func _ready() -> void:
	_create_items()
	print("[ItemDatabase] Loaded %d items" % items.size())


func get_item(item_name: String) -> ItemData:
	if items.has(item_name):
		return items[item_name]
	push_error("[ItemDatabase] Item not found: " + item_name)
	return null


func _create_items() -> void:
	# ─── CONSUMABLES ─────────────────────────────────────────────
	
	var health_potion := ItemData.new()
	health_potion.item_name = "Health Potion"
	health_potion.description = "Restores 50 HP to one ally."
	health_potion.item_type = ItemData.ItemType.CONSUMABLE
	health_potion.buy_price = 20
	health_potion.heal_hp = 50
	items["Health Potion"] = health_potion
	
	var mana_potion := ItemData.new()
	mana_potion.item_name = "Mana Potion"
	mana_potion.description = "Restores 25 MP to one ally."
	mana_potion.item_type = ItemData.ItemType.CONSUMABLE
	mana_potion.buy_price = 30
	mana_potion.heal_mp = 25
	items["Mana Potion"] = mana_potion
	
	var mega_potion := ItemData.new()
	mega_potion.item_name = "Mega Potion"
	mega_potion.description = "Restores 120 HP to one ally."
	mega_potion.item_type = ItemData.ItemType.CONSUMABLE
	mega_potion.buy_price = 60
	mega_potion.heal_hp = 120
	items["Mega Potion"] = mega_potion
	
	var elixir := ItemData.new()
	elixir.item_name = "Elixir"
	elixir.description = "Restores 50 HP and 20 MP to one ally."
	elixir.item_type = ItemData.ItemType.CONSUMABLE
	elixir.buy_price = 80
	elixir.heal_hp = 50
	elixir.heal_mp = 20
	items["Elixir"] = elixir
	
	# ─── EQUIPMENT (for future tasks) ────────────────────────────
	
	var iron_sword := ItemData.new()
	iron_sword.item_name = "Iron Sword"
	iron_sword.description = "A basic sword. +5 ATK"
	iron_sword.item_type = ItemData.ItemType.EQUIPMENT
	iron_sword.equip_slot = ItemData.EquipSlot.WEAPON
	iron_sword.buy_price = 50
	var sword_stats := StatBlock.new()
	sword_stats.atk = 5
	iron_sword.stat_bonus = sword_stats
	items["Iron Sword"] = iron_sword
	
	var leather_armor := ItemData.new()
	leather_armor.item_name = "Leather Armor"
	leather_armor.description = "Basic protection. +4 DEF"
	leather_armor.item_type = ItemData.ItemType.EQUIPMENT
	leather_armor.equip_slot = ItemData.EquipSlot.ARMOR
	leather_armor.buy_price = 40
	var armor_stats := StatBlock.new()
	armor_stats.def_stat = 4
	leather_armor.stat_bonus = armor_stats
	items["Leather Armor"] = leather_armor
	
	var speed_ring := ItemData.new()
	speed_ring.item_name = "Speed Ring"
	speed_ring.description = "Grants swiftness. +3 SPD"
	speed_ring.item_type = ItemData.ItemType.EQUIPMENT
	speed_ring.equip_slot = ItemData.EquipSlot.ACCESSORY
	speed_ring.buy_price = 45
	var ring_stats := StatBlock.new()
	ring_stats.spd = 3
	speed_ring.stat_bonus = ring_stats
	items["Speed Ring"] = speed_ring
