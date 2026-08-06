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

	# ─── CRAFTING MATERIALS ──────────────────────────────────────
	
	var iron_ore := ItemData.new()
	iron_ore.item_name = "Iron Ore"
	iron_ore.description = "Raw metal. Used at the Blacksmith."
	iron_ore.item_type = ItemData.ItemType.KEY_ITEM
	iron_ore.buy_price = 8
	iron_ore.sellable = true
	items["Iron Ore"] = iron_ore
	
	var coal := ItemData.new()
	coal.item_name = "Coal"
	coal.description = "Fuel for the forge."
	coal.item_type = ItemData.ItemType.KEY_ITEM
	coal.buy_price = 5
	coal.sellable = true
	items["Coal"] = coal
	
	var leather := ItemData.new()
	leather.item_name = "Leather"
	leather.description = "Sturdy hide from dungeon creatures."
	leather.item_type = ItemData.ItemType.KEY_ITEM
	leather.buy_price = 7
	leather.sellable = true
	items["Leather"] = leather
	
	var dark_crystal := ItemData.new()
	dark_crystal.item_name = "Dark Crystal"
	dark_crystal.description = "A shard of condensed dark energy."
	dark_crystal.item_type = ItemData.ItemType.KEY_ITEM
	dark_crystal.buy_price = 12
	dark_crystal.sellable = true
	items["Dark Crystal"] = dark_crystal
	
	var fire_essence := ItemData.new()
	fire_essence.item_name = "Fire Essence"
	fire_essence.description = "Captured flame from the Inferno."
	fire_essence.item_type = ItemData.ItemType.KEY_ITEM
	fire_essence.buy_price = 15
	fire_essence.sellable = true
	items["Fire Essence"] = fire_essence
	
	var wind_essence := ItemData.new()
	wind_essence.item_name = "Wind Essence"
	wind_essence.description = "Bottled breeze. Light as air."
	wind_essence.item_type = ItemData.ItemType.KEY_ITEM
	wind_essence.buy_price = 12
	wind_essence.sellable = true
	items["Wind Essence"] = wind_essence
	
	var ice_shard := ItemData.new()
	ice_shard.item_name = "Ice Shard"
	ice_shard.description = "A frozen fragment that never melts."
	ice_shard.item_type = ItemData.ItemType.KEY_ITEM
	ice_shard.buy_price = 12
	ice_shard.sellable = true
	items["Ice Shard"] = ice_shard
	
	var wood := ItemData.new()
	wood.item_name = "Wood"
	wood.description = "A sturdy branch from the dungeon depths."
	wood.item_type = ItemData.ItemType.KEY_ITEM
	wood.buy_price = 4
	wood.sellable = true
	items["Wood"] = wood
	
	# ─── CRAFTED EQUIPMENT ───────────────────────────────────────
	
	var steel_sword := ItemData.new()
	steel_sword.item_name = "Steel Sword"
	steel_sword.description = "A solid steel blade. +8 ATK"
	steel_sword.item_type = ItemData.ItemType.EQUIPMENT
	steel_sword.equip_slot = ItemData.EquipSlot.WEAPON
	steel_sword.buy_price = 80
	var ss_stats := StatBlock.new()
	ss_stats.atk = 8
	steel_sword.stat_bonus = ss_stats
	items["Steel Sword"] = steel_sword
	
	var chain_mail := ItemData.new()
	chain_mail.item_name = "Chain Mail"
	chain_mail.description = "Linked metal rings. +7 DEF"
	chain_mail.item_type = ItemData.ItemType.EQUIPMENT
	chain_mail.equip_slot = ItemData.EquipSlot.ARMOR
	chain_mail.buy_price = 85
	var cm_stats := StatBlock.new()
	cm_stats.def_stat = 7
	chain_mail.stat_bonus = cm_stats
	items["Chain Mail"] = chain_mail
	
	var mage_staff := ItemData.new()
	mage_staff.item_name = "Mage Staff"
	mage_staff.description = "Channels arcane power. +7 MAG"
	mage_staff.item_type = ItemData.ItemType.EQUIPMENT
	mage_staff.equip_slot = ItemData.EquipSlot.WEAPON
	mage_staff.buy_price = 90
	var ms_stats := StatBlock.new()
	ms_stats.mag = 7
	mage_staff.stat_bonus = ms_stats
	items["Mage Staff"] = mage_staff
	
	var swift_boots := ItemData.new()
	swift_boots.item_name = "Swift Boots"
	swift_boots.description = "Featherlight footwear. +5 SPD"
	swift_boots.item_type = ItemData.ItemType.EQUIPMENT
	swift_boots.equip_slot = ItemData.EquipSlot.ACCESSORY
	swift_boots.buy_price = 70
	var sb_stats := StatBlock.new()
	sb_stats.spd = 5
	swift_boots.stat_bonus = sb_stats
	items["Swift Boots"] = swift_boots
	
	var flame_blade := ItemData.new()
	flame_blade.item_name = "Flame Blade"
	flame_blade.description = "Burns on contact. +10 ATK"
	flame_blade.item_type = ItemData.ItemType.EQUIPMENT
	flame_blade.equip_slot = ItemData.EquipSlot.WEAPON
	flame_blade.buy_price = 150
	var fb_stats := StatBlock.new()
	fb_stats.atk = 10
	flame_blade.stat_bonus = fb_stats
	items["Flame Blade"] = flame_blade
	
	var shadow_cloak := ItemData.new()
	shadow_cloak.item_name = "Shadow Cloak"
	shadow_cloak.description = "Bends light. +6 DEF +4 SPD"
	shadow_cloak.item_type = ItemData.ItemType.EQUIPMENT
	shadow_cloak.equip_slot = ItemData.EquipSlot.ARMOR
	shadow_cloak.buy_price = 140
	var sc_stats := StatBlock.new()
	sc_stats.def_stat = 6
	sc_stats.spd = 4
	shadow_cloak.stat_bonus = sc_stats
	items["Shadow Cloak"] = shadow_cloak
	
	var crystal_shield := ItemData.new()
	crystal_shield.item_name = "Crystal Shield"
	crystal_shield.description = "Reflects magic. +5 DEF +5 RES"
	crystal_shield.item_type = ItemData.ItemType.EQUIPMENT
	crystal_shield.equip_slot = ItemData.EquipSlot.ARMOR
	crystal_shield.buy_price = 130
	var cs_stats := StatBlock.new()
	cs_stats.def_stat = 5
	cs_stats.res_stat = 5
	crystal_shield.stat_bonus = cs_stats
	items["Crystal Shield"] = crystal_shield
	
	var life_pendant := ItemData.new()
	life_pendant.item_name = "Life Pendant"
	life_pendant.description = "Pulses with vitality. +30 HP"
	life_pendant.item_type = ItemData.ItemType.EQUIPMENT
	life_pendant.equip_slot = ItemData.EquipSlot.ACCESSORY
	life_pendant.buy_price = 120
	var lp_stats := StatBlock.new()
	lp_stats.max_hp = 30
	life_pendant.stat_bonus = lp_stats
	items["Life Pendant"] = life_pendant
