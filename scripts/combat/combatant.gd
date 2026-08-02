## Combatant — Wraps a CharacterData or EnemyData for use in combat.
##
## WHY THIS EXISTS:
## Characters and enemies have different data structures (CharacterData vs EnemyData).
## But the combat system needs to treat them the same way — both have HP, ATK, SPD,
## both take turns, both can attack and be attacked.
##
## This is the ADAPTER pattern: wraps different types behind a common interface.
## The TurnManager doesn't care if it's a player or enemy — it just calls
## combatant.get_atk(), combatant.take_damage(), etc.
##
## KEY CONCEPT: COMPOSITION OVER INHERITANCE
## Instead of making CharacterData and EnemyData share a base class,
## we wrap them in a Combatant that delegates to whichever data it holds.
## This is more flexible — we don't have to modify the data classes at all.

class_name Combatant
extends RefCounted

## Is this a party member or an enemy?
var is_player: bool = false

## The underlying data (only one of these will be set)
var character_data: CharacterData = null
var enemy_data: EnemyData = null

## Current HP/MP for enemies (characters track their own in CharacterData)
var current_hp: int = 0
var current_mp: int = 0

## Is this combatant still alive?
var is_alive: bool = true

## Is this combatant defending this turn? (halves incoming damage)
var is_defending: bool = false

## Display name for UI
var display_name: String = "???"

## Visual color for placeholder rendering
var sprite_color: Color = Color.WHITE


## ─── STATIC CONSTRUCTORS ────────────────────────────────────────
## These create Combatant instances from our existing data types.

static func from_character(data: CharacterData) -> Combatant:
	## Create a player combatant from CharacterData.
	var c := Combatant.new()
	c.is_player = true
	c.character_data = data
	c.current_hp = data.current_hp
	c.current_mp = data.current_mp
	c.is_alive = data.is_alive
	c.display_name = data.character_name
	if data.character_class:
		c.sprite_color = data.character_class.sprite_color
	return c


static func from_enemy(data: EnemyData) -> Combatant:
	## Create an enemy combatant from EnemyData.
	var c := Combatant.new()
	c.is_player = false
	c.enemy_data = data
	c.current_hp = data.stats.max_hp
	c.current_mp = data.stats.max_mp if data.stats else 0
	c.is_alive = true
	c.display_name = data.enemy_name
	c.sprite_color = data.sprite_color
	return c


## ─── STAT ACCESSORS ─────────────────────────────────────────────
## Unified access to stats regardless of underlying data type.

func get_max_hp() -> int:
	if is_player and character_data:
		return character_data.get_stats().max_hp
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.max_hp
	return 1


func get_max_mp() -> int:
	if is_player and character_data:
		return character_data.get_stats().max_mp
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.max_mp
	return 0


func get_atk() -> int:
	if is_player and character_data:
		return character_data.get_stats().atk
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.atk
	return 1


func get_def() -> int:
	if is_player and character_data:
		return character_data.get_stats().def_stat
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.def_stat
	return 0


func get_mag() -> int:
	if is_player and character_data:
		return character_data.get_stats().mag
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.mag
	return 1


func get_res() -> int:
	if is_player and character_data:
		return character_data.get_stats().res_stat
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.res_stat
	return 0


func get_spd() -> int:
	if is_player and character_data:
		return character_data.get_stats().spd
	elif enemy_data and enemy_data.stats:
		return enemy_data.stats.spd
	return 1


## ─── COMBAT ACTIONS ─────────────────────────────────────────────

func take_damage(amount: int) -> int:
	## Apply damage. If defending, halve it. Minimum 1 damage.
	## Returns actual damage dealt.
	var actual: int = amount
	
	if is_defending:
		actual = maxi(actual / 2, 1)  # Integer division intentional (halve damage)
	
	actual = mini(actual, current_hp)  # Can't deal more than remaining HP
	current_hp -= actual
	
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
	
	# Sync back to CharacterData if it's a player (persistent state)
	if is_player and character_data:
		character_data.current_hp = current_hp
		character_data.is_alive = is_alive
	
	return actual


func defend() -> void:
	## Set defending stance. Halves damage until next turn.
	is_defending = true


func clear_defend() -> void:
	## Remove defending stance (called at start of combatant's next turn).
	is_defending = false


func _to_string() -> String:
	return "%s HP:%d/%d %s" % [display_name, current_hp, get_max_hp(), "(DEF)" if is_defending else ""]
