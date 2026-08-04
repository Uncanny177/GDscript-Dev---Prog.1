## BiomeData — Defines a dungeon biome (tileset colors + enemy pool).
##
## Each biome has:
## - A unique color palette for dungeon rendering
## - Its own enemy pool (different creatures per biome)
## - Flavor text / atmosphere
##
## The dungeon picks a biome based on floor depth:
##   Floors 1-2: Cave (starting area)
##   Floors 3-4: Crypt (undead themed)
##   Floor 5: Inferno (fire/demon themed, boss floor)

class_name BiomeData
extends RefCounted

var biome_name: String = ""
var description: String = ""

## Tile colors for dungeon rendering
var floor_color: Color = Color(0.14, 0.12, 0.2)
var floor_alt_color: Color = Color(0.16, 0.13, 0.22)
var wall_color: Color = Color(0.3, 0.22, 0.14)
var wall_top_color: Color = Color(0.36, 0.27, 0.17)
var wall_dark_color: Color = Color(0.2, 0.14, 0.08)
var door_color: Color = Color(0.45, 0.35, 0.2)

## Enemy names available in this biome (references EnemyDatabase)
var enemy_names: Array[String] = []


static func create(p_name: String, p_desc: String, colors: Dictionary, enemies: Array[String]) -> BiomeData:
	var biome := BiomeData.new()
	biome.biome_name = p_name
	biome.description = p_desc
	biome.floor_color = colors.get("floor", Color(0.14, 0.12, 0.2))
	biome.floor_alt_color = colors.get("floor_alt", Color(0.16, 0.13, 0.22))
	biome.wall_color = colors.get("wall", Color(0.3, 0.22, 0.14))
	biome.wall_top_color = colors.get("wall_top", Color(0.36, 0.27, 0.17))
	biome.wall_dark_color = colors.get("wall_dark", Color(0.2, 0.14, 0.08))
	biome.door_color = colors.get("door", Color(0.45, 0.35, 0.2))
	biome.enemy_names = enemies
	return biome
