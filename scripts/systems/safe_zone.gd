## SafeZone — Manages safe room encounters in the dungeon.
##
## "The blue sigils mean safety. Someone — or something — marked these rooms
##  long ago. The creatures will not enter. I do not know why."
##
## Safe zones appear every 2-3 floors and offer:
##   - REST: Heal HP/MP, recover sanity
##   - TALK: Party member conversations (relationship building)
##   - NPC: Wandering merchants, scholars, other explorers
##   - ALTAR: Sometimes a ritual altar is in the safe zone
##   - JOURNAL: Lore books can be found here
##
## No combat can occur in safe zones. They are a reprieve.

extends Node

## ─── SAFE ZONE TYPES ────────────────────────────────────────────

enum ZoneType { REST_CAMP, MERCHANT, SCHOLAR, SHRINE, LIBRARY, SURVIVOR }

## How much HP/MP/Sanity is restored by resting
const REST_HP_PERCENT: float = 0.3   # 30% of max HP
const REST_MP_PERCENT: float = 0.5   # 50% of max MP
const REST_SANITY_AMOUNT: int = 10   # Flat sanity recovery

## How often safe zones appear (every N floors guaranteed)
const SAFE_ZONE_INTERVAL: int = 2

## ─── NPC DATA ───────────────────────────────────────────────────

class SafeZoneNPC:
	var npc_name: String = ""
	var npc_type: String = ""  # merchant, scholar, survivor, shrine_keeper
	var dialogue: Array[String] = []
	var shop_items: Array[Dictionary] = []  # {item_name, price} for merchants
	var knowledge_grants: Array[String] = []  # enemy_ids for scholars
	var journal_grants: Array[String] = []  # journal_ids for libraries


## ─── STATE ──────────────────────────────────────────────────────

## Track which safe zones the player has visited this run
var visited_zones: Array[int] = []  # Floor numbers

## Track rest uses this run (limit to prevent abuse)
var rests_used_this_run: int = 0
const MAX_RESTS_PER_ZONE: int = 1  # Can only rest once per safe zone visit

signal safe_zone_entered(floor_num: int, zone_type: int)
signal party_rested(hp_healed: int, mp_healed: int, sanity_restored: int)
signal npc_interaction(npc_name: String, npc_type: String)


func _ready() -> void:
	print("[SafeZone] System ready")


func on_run_start() -> void:
	## Reset safe zone tracking for new run.
	visited_zones.clear()
	rests_used_this_run = 0


## ─── ZONE GENERATION ────────────────────────────────────────────

func should_have_safe_zone(floor_num: int) -> bool:
	## Returns true if this floor should contain a safe zone.
	## Guaranteed every SAFE_ZONE_INTERVAL floors, with small random chance otherwise.
	if floor_num <= 1:
		return false  # Never on floor 1 (too early)
	if floor_num % SAFE_ZONE_INTERVAL == 0:
		return true  # Guaranteed
	return randf() < 0.15  # 15% chance on other floors


func generate_safe_zone(floor_num: int) -> Dictionary:
	## Generate a safe zone encounter for the given floor.
	## Returns data for the room/event system to display.
	var zone_type: ZoneType = _pick_zone_type(floor_num)
	var zone_data: Dictionary = {
		"type": zone_type,
		"type_name": ZoneType.keys()[zone_type],
		"floor": floor_num,
		"title": _get_zone_title(zone_type),
		"description": _get_zone_description(zone_type),
		"options": _get_zone_options(zone_type, floor_num),
		"npc": null,
		"has_altar": false,
		"has_journal": false,
	}

	# Add NPC based on zone type
	if zone_type in [ZoneType.MERCHANT, ZoneType.SCHOLAR, ZoneType.SURVIVOR]:
		zone_data["npc"] = _generate_npc(zone_type, floor_num)
	
	# Chance for altar or journal in safe zone
	if randf() < 0.3:
		zone_data["has_altar"] = true
	if randf() < 0.4:
		zone_data["has_journal"] = true
		zone_data["journal_id"] = _pick_random_journal()
	
	visited_zones.append(floor_num)
	safe_zone_entered.emit(floor_num, zone_type)
	return zone_data


## ─── ACTIONS ────────────────────────────────────────────────────

func rest_party() -> Dictionary:
	## Rest the party — heal HP/MP and restore sanity.
	## Returns summary of what was healed.
	rests_used_this_run += 1
	
	var total_hp: int = 0
	var total_mp: int = 0
	var total_sanity: int = 0
	
	for member in PartyManager.active_party:
		if not member.is_alive:
			continue
		
		# Heal HP
		var max_hp: int = member.get_stats().max_hp
		var hp_heal: int = int(max_hp * REST_HP_PERCENT)
		var old_hp: int = member.current_hp
		member.current_hp = mini(member.current_hp + hp_heal, max_hp)
		total_hp += member.current_hp - old_hp
		
		# Heal MP
		var max_mp: int = member.get_stats().max_mp
		var mp_heal: int = int(max_mp * REST_MP_PERCENT)
		var old_mp: int = member.current_mp
		member.current_mp = mini(member.current_mp + mp_heal, max_mp)
		total_mp += member.current_mp - old_mp
		
		# Recover sanity
		var old_sanity: int = member.sanity
		SanitySystem.recover_sanity(member, REST_SANITY_AMOUNT)
		total_sanity += member.sanity - old_sanity
	
	party_rested.emit(total_hp, total_mp, total_sanity)
	print("[SafeZone] Party rested: +%d HP, +%d MP, +%d Sanity" % [total_hp, total_mp, total_sanity])
	
	return {
		"hp_healed": total_hp,
		"mp_healed": total_mp,
		"sanity_restored": total_sanity,
		"message": "The party rests by the blue light. Wounds close. Minds settle.\n+%d HP | +%d MP | +%d Sanity" % [total_hp, total_mp, total_sanity],
	}


func talk_to_party_member(member: CharacterData) -> Dictionary:
	## Interact with a party member in the safe zone.
	## Recovers a small amount of sanity and builds relationship.
	SanitySystem.recover_sanity(member, 5)
	
	# Pick a dialogue line based on their sanity state
	var dialogue: String = _get_party_dialogue(member)
	
	npc_interaction.emit(member.character_name, "party_member")
	return {
		"character": member.character_name,
		"dialogue": dialogue,
		"sanity_restored": 5,
	}


func buy_from_merchant(npc_data: SafeZoneNPC, item_index: int) -> Dictionary:
	## Purchase an item from a merchant NPC.
	if item_index < 0 or item_index >= npc_data.shop_items.size():
		return {"success": false, "message": "Invalid item."}
	
	var shop_entry: Dictionary = npc_data.shop_items[item_index]
	var price: int = int(shop_entry["price"])
	
	if GameManager.current_gold < price:
		return {"success": false, "message": "Not enough gold. Need %d, have %d." % [price, GameManager.current_gold]}
	
	var item: ItemData = ItemDatabase.get_item(shop_entry["item_name"])
	if not item:
		return {"success": false, "message": "Item not available."}
	
	GameManager.current_gold -= price
	GameManager.inventory.add_item(item)
	
	return {
		"success": true,
		"message": "Purchased %s for %d gold." % [item.item_name, price],
		"item": item.item_name,
		"gold_remaining": GameManager.current_gold,
	}


func consult_scholar(npc_data: SafeZoneNPC) -> Dictionary:
	## Get knowledge from a scholar NPC. Grants bestiary info.
	var granted: Array[String] = []
	for enemy_id in npc_data.knowledge_grants:
		if BestiarySystem.get_tier(enemy_id) < 2:  # Only if not already Studied+
			BestiarySystem.grant_knowledge(enemy_id, 2)  # Grant STUDIED tier
			granted.append(enemy_id)
	
	if granted.is_empty():
		return {"message": "\"I have nothing new to teach you. You already know what I know.\""}
	
	return {
		"message": "\"Listen carefully... I have studied these creatures.\"\nGained knowledge of: %s" % ", ".join(granted),
		"enemies_learned": granted,
	}


## ─── ZONE TYPE SELECTION ────────────────────────────────────────

func _pick_zone_type(floor_num: int) -> ZoneType:
	## Pick a zone type based on floor and randomness.
	var weights: Array[Dictionary] = [
		{"type": ZoneType.REST_CAMP, "weight": 30},
		{"type": ZoneType.MERCHANT, "weight": 25},
		{"type": ZoneType.SCHOLAR, "weight": 15},
		{"type": ZoneType.SHRINE, "weight": 10},
		{"type": ZoneType.LIBRARY, "weight": 10},
		{"type": ZoneType.SURVIVOR, "weight": 10},
	]
	
	# Scholars more common on deeper floors
	if floor_num >= 3:
		weights[2]["weight"] = 25
	
	var total_weight: int = 0
	for w in weights:
		total_weight += int(w["weight"])
	
	var roll: int = randi() % total_weight
	var running: int = 0
	for w in weights:
		running += int(w["weight"])
		if roll < running:
			return w["type"] as ZoneType
	
	return ZoneType.REST_CAMP


## ─── NPC GENERATION ─────────────────────────────────────────────

func _generate_npc(zone_type: ZoneType, floor_num: int) -> SafeZoneNPC:
	var npc := SafeZoneNPC.new()
	
	match zone_type:
		ZoneType.MERCHANT:
			npc.npc_name = _pick_merchant_name()
			npc.npc_type = "merchant"
			npc.dialogue = [
				"\"Goods for sale. Don't ask how I got down here.\"",
				"\"Trade? Yes, yes. Gold still works, even in this place.\"",
				"\"I've been here longer than I'd like. Buy something, keep me sane.\"",
			]
			npc.shop_items = _generate_shop(floor_num)
		
		ZoneType.SCHOLAR:
			npc.npc_name = _pick_scholar_name()
			npc.npc_type = "scholar"
			npc.dialogue = [
				"\"I came here to study them. Now I can't leave.\"",
				"\"Knowledge is the only weapon that works reliably down here.\"",
				"\"Let me tell you what I've learned about the creatures...\"",
			]
			npc.knowledge_grants = _pick_knowledge_grants(floor_num)
		
		ZoneType.SURVIVOR:
			npc.npc_name = _pick_survivor_name()
			npc.npc_type = "survivor"
			npc.dialogue = [
				"\"My party... they didn't make it. I've been hiding here for days.\"",
				"\"The blue light keeps them out. Don't know why. Don't care.\"",
				"\"Take this. I won't need it where I'm going.\"",
			]
	
	return npc


## ─── SHOP GENERATION ────────────────────────────────────────────

func _generate_shop(floor_num: int) -> Array[Dictionary]:
	## Generate merchant inventory based on floor depth.
	var shop: Array[Dictionary] = []
	
	# Basic healing items always available
	shop.append({"item_name": "Health Potion", "price": 30})
	shop.append({"item_name": "Mana Potion", "price": 25})
	
	# Floor-scaled items
	if floor_num >= 2:
		shop.append({"item_name": "Antidote", "price": 20})
		shop.append({"item_name": "Smoke Bomb", "price": 40})
	if floor_num >= 3:
		shop.append({"item_name": "Elixir", "price": 75})
		shop.append({"item_name": "Sanity Salve", "price": 50})
	if floor_num >= 4:
		shop.append({"item_name": "Phoenix Down", "price": 150})
		shop.append({"item_name": "Warding Charm", "price": 80})
	
	return shop


## ─── KNOWLEDGE GRANTS ───────────────────────────────────────────

func _pick_knowledge_grants(floor_num: int) -> Array[String]:
	## Pick which enemy knowledge the scholar can teach.
	var possible: Array[String] = []
	
	if floor_num <= 2:
		possible = ["slime", "goblin", "cultist", "shadow_hound"]
	elif floor_num <= 4:
		possible = ["skeleton", "dark_knight", "bone_sentinel", "mind_flayer"]
	else:
		possible = ["blood_priest", "void_stalker", "flesh_golem", "dream_weaver"]
	
	# Pick 1-2 random ones
	possible.shuffle()
	var count: int = mini(possible.size(), randi_range(1, 2))
	var result: Array[String] = []
	for i in range(count):
		result.append(possible[i])
	return result


func _pick_random_journal() -> String:
	## Pick a random undiscovered journal entry.
	var undiscovered: Array[String] = []
	for entry_id in BestiarySystem.journal:
		if not BestiarySystem.journal[entry_id].discovered:
			undiscovered.append(entry_id)
	if undiscovered.is_empty():
		return ""
	return undiscovered[randi() % undiscovered.size()]


## ─── DISPLAY TEXT ───────────────────────────────────────────────

func _get_zone_title(zone_type: ZoneType) -> String:
	match zone_type:
		ZoneType.REST_CAMP:
			return "Safe Haven"
		ZoneType.MERCHANT:
			return "Wandering Trader"
		ZoneType.SCHOLAR:
			return "Scholar's Refuge"
		ZoneType.SHRINE:
			return "Blue Sigil Shrine"
		ZoneType.LIBRARY:
			return "Forgotten Archive"
		ZoneType.SURVIVOR:
			return "Lone Survivor"
	return "Safe Zone"


func _get_zone_description(zone_type: ZoneType) -> String:
	match zone_type:
		ZoneType.REST_CAMP:
			return "Blue sigils pulse softly on the walls. The air here is still — the oppressive feeling of the dungeon fades at the threshold. You can rest here safely."
		ZoneType.MERCHANT:
			return "A figure sits against the wall surrounded by packs and bundles. How they got here — and why — is unclear. But their wares are real."
		ZoneType.SCHOLAR:
			return "Pages and notes are pinned to every surface. Someone has been studying the dungeon from within. They look up as you enter."
		ZoneType.SHRINE:
			return "An ancient shrine stands in the center of the room. The blue protective sigils originate from it — they carved into the very stone."
		ZoneType.LIBRARY:
			return "Shelves of books line the walls, impossibly preserved. The knowledge of ages sits here untouched by the dungeon's corruption."
		ZoneType.SURVIVOR:
			return "A lone figure huddles in the corner, eyes wide. They clutch a weapon but lower it when they see you are human. Or at least... appear to be."
	return "A safe room. The creatures cannot enter here."


func _get_zone_options(zone_type: ZoneType, _floor_num: int) -> Array[Dictionary]:
	## Generate available actions for this safe zone.
	var options: Array[Dictionary] = []
	
	# Rest is always available
	options.append({
		"id": "rest",
		"text": "Rest (Heal 30% HP, 50% MP, +10 Sanity)",
		"enabled": rests_used_this_run < MAX_RESTS_PER_ZONE,
	})
	
	# Talk to party members
	options.append({
		"id": "talk",
		"text": "Talk to party members",
		"enabled": PartyManager.active_party.size() > 0,
	})
	
	# Type-specific options
	match zone_type:
		ZoneType.MERCHANT:
			options.append({"id": "shop", "text": "Browse wares", "enabled": true})
		ZoneType.SCHOLAR:
			options.append({"id": "consult", "text": "Consult the scholar", "enabled": true})
		ZoneType.LIBRARY:
			options.append({"id": "read", "text": "Search the bookshelves", "enabled": true})
		ZoneType.SURVIVOR:
			options.append({"id": "help", "text": "Help the survivor", "enabled": true})
		ZoneType.SHRINE:
			options.append({"id": "pray", "text": "Pray at the shrine (+20 Sanity)", "enabled": true})
	
	# Leave is always last
	options.append({"id": "leave", "text": "Continue deeper into the dungeon", "enabled": true})
	
	return options


## ─── ACTION HANDLERS ────────────────────────────────────────────

func handle_action(action_id: String, zone_data: Dictionary, _character: CharacterData) -> Dictionary:
	## Handle a player choice in the safe zone. Returns result for UI.
	match action_id:
		"rest":
			return rest_party()
		"talk":
			# Returns list of party members to talk to (UI picks one)
			var members: Array[String] = []
			for member in PartyManager.active_party:
				if member.is_alive:
					members.append(member.character_name)
			return {"action": "show_party_list", "members": members}
		"shop":
			if zone_data["npc"]:
				return {"action": "show_shop", "npc": zone_data["npc"]}
			return {"message": "No merchant here."}
		"consult":
			if zone_data["npc"]:
				return consult_scholar(zone_data["npc"])
			return {"message": "No scholar here."}
		"read":
			return _search_library(zone_data)
		"help":
			return _help_survivor(zone_data)
		"pray":
			return _pray_at_shrine()
		"leave":
			return {"action": "leave", "message": "You leave the safety of the blue light behind."}
	
	return {"message": "Nothing happens."}


func _search_library(zone_data: Dictionary) -> Dictionary:
	## Search library for a journal entry.
	var journal_id: String = zone_data.get("journal_id", "")
	if journal_id == "":
		return {"message": "The shelves are empty. Someone was here before you."}
	
	BestiarySystem.discover_journal_entry(journal_id)
	var entry = BestiarySystem.journal.get(journal_id)
	if entry and entry.discovered:
		return {
			"message": "You find a worn journal and carefully read it.",
			"journal_title": entry.title,
			"journal_content": entry.content,
		}
	return {"message": "Nothing useful remains."}


func _help_survivor(zone_data: Dictionary) -> Dictionary:
	## Help the lone survivor — they may give you an item or knowledge.
	if zone_data["npc"] == null:
		return {"message": "There's nobody here."}
	
	# Survivor gives a random small reward
	var roll: float = randf()
	if roll < 0.4:
		# Give gold
		var gold: int = randi_range(20, 50)
		GameManager.add_gold(gold)
		return {"message": "\"Thank you... take this. It's all I have.\"\n+%d gold" % gold}
	elif roll < 0.7:
		# Give sanity (comforting conversation)
		for member in PartyManager.active_party:
			SanitySystem.recover_sanity(member, 8)
		return {"message": "\"Just... talking helps. Thank you for stopping.\"\n+8 Sanity (all party)"}
	else:
		# Give knowledge
		var enemy_id: String = ["slime", "goblin", "skeleton", "cultist"][randi() % 4]
		BestiarySystem.grant_knowledge(enemy_id, 1)
		return {"message": "\"I saw one of those things up close. Let me tell you what I noticed...\"\nGained knowledge about: %s" % enemy_id}


func _pray_at_shrine() -> Dictionary:
	## Pray at the blue sigil shrine for sanity recovery.
	for member in PartyManager.active_party:
		SanitySystem.recover_sanity(member, 20)
	return {
		"message": "You kneel before the shrine. The blue light intensifies, wrapping around you like a warm blanket. For a moment, the madness recedes.\n+20 Sanity (all party)",
		"sanity_restored": 20,
	}


## ─── PARTY DIALOGUE ─────────────────────────────────────────────

func _get_party_dialogue(member: CharacterData) -> String:
	## Get dialogue based on character state.
	var sanity: int = member.sanity
	var hp_percent: float = float(member.current_hp) / float(member.get_stats().max_hp)
	
	if sanity <= 10:
		return _pick_random([
			"*%s stares at the wall, muttering something incomprehensible.*" % member.character_name,
			"\"I can hear them. Even here. Even behind the blue light.\"",
			"*%s rocks back and forth, clutching their head.*" % member.character_name,
		])
	elif sanity <= 30:
		return _pick_random([
			"\"This place... it's getting to me. I can feel it changing how I think.\"",
			"\"Did you see that shadow? No? ...I keep seeing things.\"",
			"\"I'm fine. I'm fine. I'm fine. ...Am I saying that out loud?\"",
		])
	elif hp_percent < 0.3:
		return _pick_random([
			"\"I need rest. Badly. I can barely stand.\"",
			"*%s winces as they shift position.* \"Everything hurts.\"" % member.character_name,
			"\"If we get into another fight right now, I don't know if I'll make it.\"",
		])
	else:
		return _pick_random([
			"\"Good to rest for a moment. I almost forgot what silence sounds like.\"",
			"\"We should keep moving soon. This place doesn't stay safe forever.\"",
			"\"I wonder how deep this goes. Do you think there's actually an end?\"",
			"\"The others... they're holding up. For now. Keep an eye on them.\"",
			"\"At least the blue light is warm. Small mercies down here.\"",
		])


## ─── NAME POOLS ─────────────────────────────────────────────────

func _pick_merchant_name() -> String:
	return _pick_random(["Grift", "Old Mara", "The Peddler", "Scratch", "Bones McGee"])

func _pick_scholar_name() -> String:
	return _pick_random(["Dr. Vasquez", "The Archivist", "Professor Holt", "Ada the Wise", "Inkwell"])

func _pick_survivor_name() -> String:
	return _pick_random(["A frightened explorer", "A wounded soldier", "A lost scholar", "A child (somehow)", "A former cultist"])


## ─── UTILITY ────────────────────────────────────────────────────

func _pick_random(arr: Array) -> String:
	if arr.is_empty():
		return ""
	return arr[randi() % arr.size()]
