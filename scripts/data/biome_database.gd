## BiomeDatabase — All biome definitions and floor-to-biome mapping.

extends Node

var biomes: Dictionary = {}  # name → BiomeData


func _ready() -> void:
	_create_biomes()
	print("[BiomeDatabase] Loaded %d biomes" % biomes.size())


func get_biome_for_floor(floor_number: int) -> BiomeData:
	## Returns the appropriate biome for the given floor.
	if floor_number <= 2:
		return biomes.get("Cave", null)
	elif floor_number <= 4:
		return biomes.get("Crypt", null)
	else:
		return biomes.get("Inferno", null)


func _create_biomes() -> void:
	
	# ─── CAVE (Floors 1-2) — Damp, natural, easy ────────────────
	biomes["Cave"] = BiomeData.create(
		"Cave",
		"Damp stone corridors drip with moisture. Faint growls echo in the dark.",
		{
			"floor": Color(0.12, 0.11, 0.16),
			"floor_alt": Color(0.14, 0.12, 0.18),
			"wall": Color(0.28, 0.24, 0.2),
			"wall_top": Color(0.34, 0.29, 0.24),
			"wall_dark": Color(0.18, 0.14, 0.1),
			"door": Color(0.4, 0.32, 0.2),
		},
		["Slime", "Goblin", "Cave Bat", "Mushroom"]
	)
	
	# ─── CRYPT (Floors 3-4) — Undead, cold, medium ──────────────
	biomes["Crypt"] = BiomeData.create(
		"Crypt",
		"Ancient tombs line the walls. The air is cold and carries whispers of the dead.",
		{
			"floor": Color(0.1, 0.1, 0.14),
			"floor_alt": Color(0.12, 0.11, 0.16),
			"wall": Color(0.22, 0.22, 0.28),
			"wall_top": Color(0.28, 0.28, 0.34),
			"wall_dark": Color(0.12, 0.12, 0.18),
			"door": Color(0.3, 0.28, 0.35),
		},
		["Skeleton", "Ghost", "Zombie", "Bone Mage"]
	)
	
	# ─── INFERNO (Floor 5) — Fire, demons, hard ─────────────────
	biomes["Inferno"] = BiomeData.create(
		"Inferno",
		"Lava flows beneath cracked stone. Demonic energy pulses through the walls.",
		{
			"floor": Color(0.15, 0.08, 0.06),
			"floor_alt": Color(0.18, 0.1, 0.07),
			"wall": Color(0.35, 0.15, 0.08),
			"wall_top": Color(0.45, 0.2, 0.1),
			"wall_dark": Color(0.2, 0.08, 0.04),
			"door": Color(0.5, 0.25, 0.1),
		},
		["Dark Knight", "Fire Imp", "Lava Hound", "Demon"]
	)
