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
			"floor": Color(0.26, 0.24, 0.32),
			"floor_alt": Color(0.30, 0.27, 0.36),
			"wall": Color(0.42, 0.36, 0.30),
			"wall_top": Color(0.50, 0.43, 0.36),
			"wall_dark": Color(0.30, 0.24, 0.18),
			"door": Color(0.55, 0.44, 0.28),
		},
		["Slime", "Goblin", "Cave Bat", "Mushroom"]
	)
	
	# ─── CRYPT (Floors 3-4) — Undead, cold, medium ──────────────
	biomes["Crypt"] = BiomeData.create(
		"Crypt",
		"Ancient tombs line the walls. The air is cold and carries whispers of the dead.",
		{
			"floor": Color(0.22, 0.22, 0.30),
			"floor_alt": Color(0.26, 0.25, 0.34),
			"wall": Color(0.36, 0.36, 0.44),
			"wall_top": Color(0.44, 0.44, 0.52),
			"wall_dark": Color(0.24, 0.24, 0.32),
			"door": Color(0.44, 0.42, 0.50),
		},
		["Skeleton", "Ghost", "Zombie", "Bone Mage"]
	)
	
	# ─── INFERNO (Floor 5) — Fire, demons, hard ─────────────────
	biomes["Inferno"] = BiomeData.create(
		"Inferno",
		"Lava flows beneath cracked stone. Demonic energy pulses through the walls.",
		{
			"floor": Color(0.28, 0.16, 0.12),
			"floor_alt": Color(0.33, 0.19, 0.13),
			"wall": Color(0.52, 0.24, 0.13),
			"wall_top": Color(0.62, 0.30, 0.16),
			"wall_dark": Color(0.34, 0.15, 0.08),
			"door": Color(0.68, 0.36, 0.16),
		},
		["Dark Knight", "Fire Imp", "Lava Hound", "Demon"]
	)
