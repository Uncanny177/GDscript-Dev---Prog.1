## EventDatabase — All dungeon events defined here.
##
## Events are encounters with choices that don't involve combat.
## They add variety and narrative to dungeon exploration.

extends Node

var events: Array[DungeonEvent] = []


func _ready() -> void:
	_create_events()
	print("[EventDatabase] Loaded %d events" % events.size())


func get_random_event() -> DungeonEvent:
	if events.is_empty():
		return null
	return events[randi() % events.size()]


func _create_events() -> void:
	
	# ─── MYSTERIOUS FOUNTAIN ─────────────────────────────────────
	events.append(DungeonEvent.create(
		"Mysterious Fountain",
		"You discover a fountain filled with glowing blue water.\nIt hums with an unknown energy.",
		[
			{
				"text": "Drink from it",
				"outcomes": [
					{"weight": 6, "type": "heal_party", "value": 30, "message": "The water heals your wounds! Party restored 30 HP each."},
					{"weight": 2, "type": "poison_party", "value": 10, "message": "The water burns! Your party is poisoned!"},
					{"weight": 2, "type": "restore_mp", "value": 20, "message": "Magical energy flows through you! +20 MP each."},
				]
			},
			{
				"text": "Toss a coin in (10G)",
				"outcomes": [
					{"weight": 5, "type": "gold", "value": 30, "message": "The fountain shimmers... 30 gold coins appear!"},
					{"weight": 3, "type": "item", "value": "Mega Potion", "message": "A potion floats to the surface!"},
					{"weight": 2, "type": "nothing", "value": 0, "message": "The coin sinks. Nothing happens."},
				]
			},
			{
				"text": "Walk away",
				"outcomes": [
					{"weight": 1, "type": "nothing", "value": 0, "message": "You leave the fountain undisturbed."},
				]
			},
		]
	))
	
	# ─── WOUNDED TRAVELER ────────────────────────────────────────
	events.append(DungeonEvent.create(
		"Wounded Traveler",
		"A traveler lies wounded against the wall.\n\"Please... help me...\" they whisper.",
		[
			{
				"text": "Help them (use Health Potion)",
				"outcomes": [
					{"weight": 7, "type": "gold", "value": 25, "message": "\"Thank you! Take this gold.\" They hand you 25G before vanishing."},
					{"weight": 3, "type": "item", "value": "Elixir", "message": "\"You're kind... take this.\" They give you an Elixir!"},
				]
			},
			{
				"text": "Search their pockets",
				"outcomes": [
					{"weight": 4, "type": "gold", "value": 15, "message": "You find 15 gold in their pack."},
					{"weight": 3, "type": "nothing", "value": 0, "message": "Their pockets are empty."},
					{"weight": 3, "type": "ambush", "value": 0, "message": "It was a trap! Enemies attack!"},
				]
			},
			{
				"text": "Walk away",
				"outcomes": [
					{"weight": 1, "type": "nothing", "value": 0, "message": "You leave them behind."},
				]
			},
		]
	))
	
	# ─── TREASURE CHEST (TRAPPED?) ───────────────────────────────
	events.append(DungeonEvent.create(
		"Suspicious Chest",
		"An ornate chest sits in the center of the room.\nSomething about it feels... off.",
		[
			{
				"text": "Open it carefully",
				"outcomes": [
					{"weight": 5, "type": "gold", "value": 40, "message": "Jackpot! 40 gold inside!"},
					{"weight": 2, "type": "item", "value": "Mega Potion", "message": "A Mega Potion was hidden inside!"},
					{"weight": 3, "type": "damage_party", "value": 20, "message": "TRAP! Poison darts fly out! -20 HP each!"},
				]
			},
			{
				"text": "Kick it open (reckless)",
				"outcomes": [
					{"weight": 3, "type": "gold", "value": 60, "message": "The chest bursts open! 60 gold!"},
					{"weight": 4, "type": "damage_party", "value": 30, "message": "EXPLOSION! The chest was rigged! -30 HP each!"},
					{"weight": 3, "type": "ambush", "value": 0, "message": "A mimic! Enemies attack!"},
				]
			},
			{
				"text": "Leave it alone",
				"outcomes": [
					{"weight": 1, "type": "nothing", "value": 0, "message": "Wisdom is its own reward... right?"},
				]
			},
		]
	))
	
	# ─── SHRINE ──────────────────────────────────────────────────
	events.append(DungeonEvent.create(
		"Ancient Shrine",
		"A crumbling shrine glows with faint power.\nAn inscription reads: \"Offer to receive.\"",
		[
			{
				"text": "Offer gold (20G)",
				"outcomes": [
					{"weight": 5, "type": "buff_atk", "value": 25, "message": "Power surges through you! ATK +25% for the floor!"},
					{"weight": 3, "type": "heal_party", "value": 50, "message": "Warm light heals your party! +50 HP each!"},
					{"weight": 2, "type": "crystal", "value": 1, "message": "The shrine crumbles, revealing a Meta-Crystal!"},
				]
			},
			{
				"text": "Offer HP (sacrifice 30 HP from leader)",
				"outcomes": [
					{"weight": 4, "type": "crystal", "value": 2, "message": "Your sacrifice is honored. +2 Meta-Crystals!"},
					{"weight": 4, "type": "item", "value": "Elixir", "message": "The shrine rewards your devotion with an Elixir!"},
					{"weight": 2, "type": "buff_atk", "value": 40, "message": "GREAT power flows into you! ATK +40% for the floor!"},
				]
			},
			{
				"text": "Pray (free)",
				"outcomes": [
					{"weight": 5, "type": "restore_mp", "value": 15, "message": "You feel refreshed. +15 MP each."},
					{"weight": 5, "type": "nothing", "value": 0, "message": "Silence. The gods are busy today."},
				]
			},
		]
	))
	
	# ─── GAMBLING GOBLIN ─────────────────────────────────────────
	events.append(DungeonEvent.create(
		"Gambling Goblin",
		"A goblin sits behind a makeshift table.\n\"Hey hey! Wanna play? Double or nothin'!\"",
		[
			{
				"text": "Gamble 20G",
				"outcomes": [
					{"weight": 5, "type": "gold", "value": 40, "message": "\"Winner winner!\" You double your bet! +40G!"},
					{"weight": 5, "type": "lose_gold", "value": 20, "message": "\"Hehehe! Better luck next time!\" You lose 20G."},
				]
			},
			{
				"text": "Gamble 50G (big bet)",
				"outcomes": [
					{"weight": 4, "type": "gold", "value": 100, "message": "\"JACKPOT!\" The goblin cries. +100G!"},
					{"weight": 6, "type": "lose_gold", "value": 50, "message": "\"Thanks for the donation!\" You lose 50G."},
				]
			},
			{
				"text": "Decline",
				"outcomes": [
					{"weight": 1, "type": "nothing", "value": 0, "message": "\"Bah! No fun.\" The goblin vanishes."},
				]
			},
		]
	))
	
	# ─── CAMPFIRE ────────────────────────────────────────────────
	events.append(DungeonEvent.create(
		"Abandoned Campfire",
		"Warm embers still glow in a makeshift campfire.\nSomeone was here recently.",
		[
			{
				"text": "Rest here (heal party)",
				"outcomes": [
					{"weight": 8, "type": "heal_party", "value": 25, "message": "Your party rests by the fire. +25 HP each."},
					{"weight": 2, "type": "ambush", "value": 0, "message": "Enemies sneak up while you rest!"},
				]
			},
			{
				"text": "Search the campsite",
				"outcomes": [
					{"weight": 4, "type": "item", "value": "Health Potion", "message": "You find a Health Potion in a pack!"},
					{"weight": 3, "type": "gold", "value": 12, "message": "A few coins hidden under a rock. +12G."},
					{"weight": 3, "type": "nothing", "value": 0, "message": "Nothing useful here."},
				]
			},
			{
				"text": "Move on",
				"outcomes": [
					{"weight": 1, "type": "nothing", "value": 0, "message": "You continue deeper into the dungeon."},
				]
			},
		]
	))
