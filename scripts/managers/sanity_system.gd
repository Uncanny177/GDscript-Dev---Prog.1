## SanitySystem — Tracks and manages mental health for party members.
##
## Each character has a Sanity stat (0-100). It drops from:
## - Witnessing horror (entering certain rooms, boss encounters)
## - Using forbidden knowledge (rituals, dark spells)
## - Seeing party members die
## - Certain enemy attacks
##
## At low sanity, characters become unreliable:
## - 50-30: "Stressed" — occasional wrong actions, dialogue changes
## - 30-10: "Unstable" — may refuse orders, attack wrong target, flee
## - 10-0: "Breaking" — high chance of acting randomly
## - 0: "Insane" — character permanently lost to madness
##
## Sanity recovers from:
## - Safe zone rest
## - Certain items (calming herbs, etc.)
## - Party member conversations (companion bonus)
## - Returning to hub (partial recovery)

extends Node

## Sanity thresholds
const MAX_SANITY: int = 100
const STRESSED_THRESHOLD: int = 50
const UNSTABLE_THRESHOLD: int = 30
const BREAKING_THRESHOLD: int = 10

## Sanity loss amounts for various events
const LOSS_WITNESS_DEATH: int = 15
const LOSS_BOSS_ENCOUNTER: int = 10
const LOSS_HORROR_ROOM: int = 8
const LOSS_DARK_RITUAL: int = 20
const LOSS_DARK_SPELL: int = 5
const LOSS_ENEMY_ATTACK: int = 3  # Specific horror enemies only

## Sanity recovery amounts
const RECOVER_SAFE_ZONE: int = 20
const RECOVER_HUB_RETURN: int = 30
const RECOVER_COMPANION_CHAT: int = 10
const RECOVER_ITEM: int = 25


func _ready() -> void:
	print("[SanitySystem] Initialized")


## ─── SANITY MODIFICATION ────────────────────────────────────────

func lose_sanity(character: CharacterData, amount: int, reason: String = "") -> Dictionary:
	## Reduce a character's sanity. Returns result info.
	## {"character": name, "old": int, "new": int, "state_changed": bool, "went_insane": bool}
	var old_sanity: int = character.sanity
	character.sanity = maxi(character.sanity - amount, 0)
	
	var state_changed: bool = _get_state(old_sanity) != _get_state(character.sanity)
	var went_insane: bool = character.sanity <= 0 and old_sanity > 0
	
	if reason != "":
		print("[Sanity] %s lost %d sanity (%s) → %d" % [character.character_name, amount, reason, character.sanity])
	
	return {
		"character": character.character_name,
		"old": old_sanity,
		"new": character.sanity,
		"state_changed": state_changed,
		"went_insane": went_insane,
	}


func recover_sanity(character: CharacterData, amount: int) -> int:
	## Restore sanity. Returns actual amount recovered.
	var old: int = character.sanity
	character.sanity = mini(character.sanity + amount, MAX_SANITY)
	return character.sanity - old


func lose_party_sanity(amount: int, reason: String = "") -> Array[Dictionary]:
	## Apply sanity loss to entire active party. Returns results for each.
	var results: Array[Dictionary] = []
	for member in PartyManager.active_party:
		if member.is_alive:
			results.append(lose_sanity(member, amount, reason))
	return results


func recover_party_sanity(amount: int) -> void:
	## Recover sanity for entire party.
	for member in PartyManager.active_party:
		if member.is_alive:
			recover_sanity(member, amount)


## ─── STATE QUERIES ──────────────────────────────────────────────

func get_state(character: CharacterData) -> String:
	## Returns the mental state label for a character.
	return _get_state(character.sanity)


func _get_state(sanity: int) -> String:
	if sanity <= 0:
		return "Insane"
	elif sanity <= BREAKING_THRESHOLD:
		return "Breaking"
	elif sanity <= UNSTABLE_THRESHOLD:
		return "Unstable"
	elif sanity <= STRESSED_THRESHOLD:
		return "Stressed"
	return "Sane"


func get_state_color(character: CharacterData) -> Color:
	match get_state(character):
		"Sane": return Color(0.4, 0.9, 0.4)
		"Stressed": return Color(0.9, 0.8, 0.2)
		"Unstable": return Color(0.9, 0.5, 0.1)
		"Breaking": return Color(0.9, 0.2, 0.2)
		"Insane": return Color(0.5, 0.0, 0.5)
		_: return Color.WHITE


func is_insane(character: CharacterData) -> bool:
	return character.sanity <= 0


## ─── COMBAT BEHAVIOR MODIFIERS ──────────────────────────────────

func should_act_randomly(character: CharacterData) -> bool:
	## Roll to see if a low-sanity character acts on their own.
	## Used in combat to override player commands.
	var state: String = get_state(character)
	var roll: int = randi() % 100
	
	match state:
		"Stressed":
			return roll < 10  # 10% chance of wrong action
		"Unstable":
			return roll < 30  # 30% chance
		"Breaking":
			return roll < 60  # 60% chance
		_:
			return false


func get_random_action() -> String:
	## What does a panicking character do?
	var roll: int = randi() % 100
	if roll < 30:
		return "attack_random"  # Attack random target (could be ally!)
	elif roll < 50:
		return "flee_attempt"   # Try to flee
	elif roll < 70:
		return "freeze"         # Do nothing (frozen in fear)
	else:
		return "attack_self"    # Hurt themselves


## ─── EVENT HOOKS ────────────────────────────────────────────────

func on_party_member_died(dead_name: String) -> void:
	## Called when a party member dies. Others lose sanity.
	lose_party_sanity(LOSS_WITNESS_DEATH, "witnessed %s die" % dead_name)


func on_boss_encounter(boss_name: String) -> void:
	## Called when entering a boss fight.
	lose_party_sanity(LOSS_BOSS_ENCOUNTER, "facing %s" % boss_name)


func on_horror_event() -> void:
	## Called when something horrifying happens in a room/event.
	lose_party_sanity(LOSS_HORROR_ROOM, "horror event")


func on_dark_ritual(caster: CharacterData) -> void:
	## Called when a character performs a dark ritual.
	lose_sanity(caster, LOSS_DARK_RITUAL, "dark ritual")


func on_dark_spell_used(caster: CharacterData) -> void:
	## Called when a dark element spell is used.
	lose_sanity(caster, LOSS_DARK_SPELL, "dark magic")


func on_safe_zone_rest() -> void:
	## Called when party rests at a safe zone.
	recover_party_sanity(RECOVER_SAFE_ZONE)
	print("[Sanity] Party rested at safe zone (+%d sanity)" % RECOVER_SAFE_ZONE)


func on_hub_return() -> void:
	## Called when returning to hub town.
	recover_party_sanity(RECOVER_HUB_RETURN)
