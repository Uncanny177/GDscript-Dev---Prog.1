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
			"floor": Color(0.42, 0.40, 0.48),
			"floor_alt": Color(0.47, 0.44, 0.53),
			"wall": Color(0.56, 0.48, 0.40),
			"wall_top": Color(0.66, 0.57, 0.47),
			"wall_dark": Color(0.42, 0.34, 0.26),
			"door": Color(0.70, 0.56, 0.36),
		},
		["Slime", "Goblin", "Cave Bat", "Mushroom"]
	)
	
	# ─── CRYPT (Floors 3-4) — Undead, cold, medium ──────────────
	biomes["Crypt"] = BiomeData.create(
		"Crypt",
		"Ancient tombs line the walls. The air is cold and carries whispers of the dead.",
		{
			"floor": Color(0.38, 0.38, 0.47),
			"floor_alt": Color(0.43, 0.42, 0.52),
			"wall": Color(0.50, 0.50, 0.58),
			"wall_top": Color(0.60, 0.60, 0.68),
			"wall_dark": Color(0.36, 0.36, 0.44),
			"door": Color(0.56, 0.54, 0.62),
		},
		["Skeleton", "Ghost", "Zombie", "Bone Mage"]
	)
	
	# ─── INFERNO (Floor 5) — Fire, demons, hard ─────────────────
	biomes["Inferno"] = BiomeData.create(
		"Inferno",
		"Lava flows beneath cracked stone. Demonic energy pulses through the walls.",
		{
			"floor": Color(0.44, 0.26, 0.20),
			"floor_alt": Color(0.50, 0.30, 0.22),
			"wall": Color(0.68, 0.34, 0.20),
			"wall_top": Color(0.78, 0.42, 0.24),
			"wall_dark": Color(0.48, 0.24, 0.14),
			"door": Color(0.82, 0.48, 0.24),
		},
		["Dark Knight", "Fire Imp", "Lava Hound", "Demon"]
	)
