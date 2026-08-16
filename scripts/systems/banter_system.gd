## BanterSystem — Party conversations & companion banter.
##
## Two kinds of content share ONE data model:
##   1. SOLO   — "talk to X" (approach a companion in town, a safe room, or a
##               future Talk menu). participants = [one_id].
##   2. BANTER — two or more companions trade lines automatically (safe zones,
##               depth beats). participants = [id_a, id_b, ...].
##
## Every conversation is a Dictionary. The system filters all definitions by the
## current CONTEXT ("town" / "safe_zone" / "menu") plus CONDITIONS (who's in the
## party, story flags, depth, run count, relationship stage), then hands the
## chosen entry's lines to the DialogueBox for display.
##
## ── GRADUAL / ESCALATING ARCS ───────────────────────────────────
## Relationships that build over time (e.g. Sera vs. Eleanor) use a per-pair
## "stage" integer. Each arc entry is gated to a specific stage (`stage_eq`) and
## advances it on play (`advances_stage`). Combined with `min_depth`, the beats
## unlock in order and spread out across the run — the enmity surfaces slowly
## instead of dumping all at once.
##
## ── DECOUPLING ──────────────────────────────────────────────────
## This autoload never touches the scene tree. When a conversation should play it
## emits `conversation_started(convo)`. Whatever scene currently owns a DialogueBox
## (hub, safe room) connects to that signal and calls:
##     dialogue_box.start_conversation(BanterSystem.format_lines(convo))
##
## Persisted to user://relationships.json (played one-shots, flags, pair stages).

extends Node

const SAVE_PATH: String = "user://relationships.json"

## Emitted when an eligible conversation is chosen and its effects applied.
## A scene with a DialogueBox listens and actually renders the lines.
signal conversation_started(convo: Dictionary)

## ─── PERSISTENT STATE ───────────────────────────────────────────
var played_one_shots: Array[String] = []   # conversation ids already seen
var flags: Dictionary = {}                  # story flags: name -> bool
var pair_stage: Dictionary = {}             # "a|b" -> int (relationship arc stage)
var affinity: Dictionary = {}               # "a|b" -> int (optional like/dislike score)

## In-memory only: conversations already shown during THIS safe-zone/town visit,
## so idle banter doesn't repeat back-to-back. Cleared by begin_visit().
var _seen_this_visit: Array[String] = []

## All conversation definitions (filled in _define_conversations).
var conversations: Array[Dictionary] = []


func _ready() -> void:
	_define_conversations()
	_load()
	print("[BanterSystem] %d conversations defined" % conversations.size())


## ─── RELATIONSHIP / FLAG HELPERS ────────────────────────────────

func pair_key(a: String, b: String) -> String:
	## Canonical (order-independent) key for a character pair.
	if a <= b:
		return a + "|" + b
	return b + "|" + a


func get_stage(a: String, b: String) -> int:
	return int(pair_stage.get(pair_key(a, b), 0))


func set_stage(a: String, b: String, value: int) -> void:
	pair_stage[pair_key(a, b)] = value
	_save()


func advance_stage(a: String, b: String) -> void:
	set_stage(a, b, get_stage(a, b) + 1)


func adjust_affinity(a: String, b: String, delta: int) -> void:
	var key := pair_key(a, b)
	affinity[key] = int(affinity.get(key, 0)) + delta
	_save()


func get_flag(f: String) -> bool:
	return bool(flags.get(f, false))


func set_flag(f: String, value: bool = true) -> void:
	flags[f] = value
	_save()


## ─── VISIT LIFECYCLE ────────────────────────────────────────────

func begin_visit() -> void:
	## Call when the party enters a safe zone or the town. Resets the
	## "already chatted here" guard so idle banter can play again.
	_seen_this_visit.clear()


## ─── SELECTION ──────────────────────────────────────────────────

func get_eligible(context: String, ctx: Dictionary = {}) -> Array[Dictionary]:
	## All conversations that can play right now in `context`.
	## `ctx` carries transient state, e.g. {"depth": 4}.
	var out: Array[Dictionary] = []
	for convo in conversations:
		if _is_eligible(convo, context, ctx):
			out.append(convo)
	return out


func get_solo_topics(character_id: String, context: String, ctx: Dictionary = {}) -> Array[Dictionary]:
	## Topics available when the player approaches / opens Talk on one character.
	var out: Array[Dictionary] = []
	for convo in get_eligible(context, ctx):
		var parts: Array = convo.get("participants", [])
		if parts.size() == 1 and parts[0] == character_id:
			out.append(convo)
	return out


func pick_banter(context: String, ctx: Dictionary = {}) -> Dictionary:
	## Choose one multi-character banter to auto-play (returns {} if none).
	## Highest-priority tier wins; ties broken by weighted random.
	var pool: Array[Dictionary] = []
	for convo in get_eligible(context, ctx):
		if convo.get("participants", []).size() >= 2:
			pool.append(convo)
	if pool.is_empty():
		return {}

	var best_priority: int = -1
	for convo in pool:
		best_priority = maxi(best_priority, int(convo.get("priority", 0)))

	var tier: Array[Dictionary] = []
	for convo in pool:
		if int(convo.get("priority", 0)) == best_priority:
			tier.append(convo)

	return _weighted_pick(tier)


func _is_eligible(convo: Dictionary, context: String, ctx: Dictionary) -> bool:
	# Context (where it can trigger)
	if context not in convo.get("contexts", []):
		return false

	# One-shot already consumed (persistent) or already seen this visit
	var id: String = convo.get("id", "")
	if convo.get("one_shot", false) and id in played_one_shots:
		return false
	if id in _seen_this_visit:
		return false

	# Required party members present (defaults to the participants)
	var present := _active_ids()
	for req in convo.get("requires_present", convo.get("participants", [])):
		if req not in present:
			return false

	# Story flags
	for f in convo.get("required_flags", []):
		if not get_flag(f):
			return false
	for f in convo.get("forbidden_flags", []):
		if get_flag(f):
			return false

	# Depth / run gates
	if int(ctx.get("depth", 0)) < int(convo.get("min_depth", 0)):
		return false
	if GameManager.total_runs < int(convo.get("min_run", 0)):
		return false

	# Relationship-stage gate (keeps arc beats in order)
	if convo.has("stage_of"):
		var pair: Array = convo["stage_of"]
		if get_stage(pair[0], pair[1]) != int(convo.get("stage_eq", 0)):
			return false

	return true


func _weighted_pick(pool: Array[Dictionary]) -> Dictionary:
	var total: int = 0
	for convo in pool:
		total += int(convo.get("weight", 1))
	var roll: int = randi() % maxi(total, 1)
	for convo in pool:
		roll -= int(convo.get("weight", 1))
		if roll < 0:
			return convo
	return pool[0]


## ─── PLAYBACK ───────────────────────────────────────────────────

func play(convo: Dictionary) -> void:
	## Apply a conversation's effects, then emit it for a scene to render.
	var id: String = convo.get("id", "")

	if convo.get("one_shot", false) and id not in played_one_shots:
		played_one_shots.append(id)
	if id != "":
		_seen_this_visit.append(id)

	for f in convo.get("set_flags", []):
		flags[f] = true

	if convo.has("advances_stage"):
		var pair: Array = convo["advances_stage"]
		advance_stage(pair[0], pair[1])

	if convo.has("affinity_delta"):
		var pair: Array = convo["affinity_delta"]  # [a, b, delta]
		adjust_affinity(pair[0], pair[1], int(pair[2]))

	# Companion chats can restore a little sanity (SanitySystem anticipates this).
	var reward: int = int(convo.get("sanity_reward", 0))
	if reward > 0:
		SanitySystem.recover_party_sanity(reward)

	_save()
	conversation_started.emit(convo)


func format_lines(convo: Dictionary) -> Array:
	## Resolve speaker ids to display names for the DialogueBox.
	## Returns [{"speaker": "Sera Brighthollow", "text": "..."}, ...].
	var out: Array = []
	for line in convo.get("lines", []):
		out.append({
			"speaker": _display_name(line.get("speaker", "")),
			"text": line.get("text", ""),
		})
	return out


## ─── PARTY / NAME LOOKUP ────────────────────────────────────────

func _active_ids() -> Array[String]:
	## Roster ids of the current active party.
	## TODO: add a `roster_id` field to CharacterData and set it in
	## CharacterRoster.create_character_data() for a robust link. Until then we
	## match on display name (works, but names could collide or be renamed).
	var ids: Array[String] = []
	for member in PartyManager.active_party:
		for id in CharacterRoster.profiles:
			if CharacterRoster.profiles[id].character_name == member.character_name:
				ids.append(id)
				break
	return ids


func _display_name(character_id: String) -> String:
	var p = CharacterRoster.get_profile(character_id)
	return p.character_name if p else "???"


## ─── CONVERSATION DEFINITIONS ───────────────────────────────────
## Fields:
##   id             unique string
##   participants   roster ids ([one] = solo, [a,b,..] = banter)
##   lines          [{"speaker": id, "text": String}, ...]
##   contexts       where it can fire: "town" / "safe_zone" / "menu"
##   requires_present  ids that must be in the active party (default: participants)
##   required_flags / forbidden_flags   story-flag gates
##   min_depth / min_run    numeric gates (min_run reads GameManager.total_runs)
##   stage_of + stage_eq    only eligible when pair stage == stage_eq
##   advances_stage [a,b]   bump the pair stage on play
##   affinity_delta [a,b,n] nudge numeric affinity on play
##   set_flags      flags set true on play
##   sanity_reward  party sanity restored on play
##   one_shot       play once ever (persisted)
##   priority       higher wins in banter selection (story beats > idle)
##   weight         relative odds within the winning priority tier

func _define_conversations() -> void:
	conversations = [

		# ─── SERA ✕ ELEANOR — escalating enmity (surfaces gradually) ──
		# Both start in the party. Beats unlock in order via stage + depth.
		{
			"id": "sera_eleanor_00_unease",
			"participants": ["sera", "eleanor"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 0,
			"stage_of": ["sera", "eleanor"], "stage_eq": 0,
			"advances_stage": ["sera", "eleanor"],
			"lines": [
				{"speaker": "sera", "text": "You pray a great deal for someone this far from any altar."},
				{"speaker": "eleanor", "text": "Habit. It hasn't been answered much, lately."},
			],
		},
		{
			"id": "sera_eleanor_01_recognition",
			"participants": ["sera", "eleanor"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 2,
			"stage_of": ["sera", "eleanor"], "stage_eq": 1,
			"advances_stage": ["sera", "eleanor"],
			"lines": [
				{"speaker": "eleanor", "text": "That script on your satchel — Tower work. You're College of Insight."},
				{"speaker": "sera", "text": "And that's a Retribution seal on your gauntlet. I know precisely what your order is."},
			],
		},
		{
			"id": "sera_eleanor_02_hostility",
			"participants": ["sera", "eleanor"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 4,
			"stage_of": ["sera", "eleanor"], "stage_eq": 2,
			"advances_stage": ["sera", "eleanor"],
			"lines": [
				{"speaker": "sera", "text": "Your people burned my school. My students. Do you even remember the White Tower?"},
				{"speaker": "eleanor", "text": "I remember heretics hoarding forbidden things. ...I remember it less proudly than I used to."},
			],
		},
		{
			"id": "sera_eleanor_03_reckoning",
			"participants": ["sera", "eleanor"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 6,
			"stage_of": ["sera", "eleanor"], "stage_eq": 3,
			"advances_stage": ["sera", "eleanor"],
			"set_flags": ["sera_eleanor_confronted"],
			"lines": [
				{"speaker": "sera", "text": "When we climb out of here, one of us settles this."},
				{"speaker": "eleanor", "text": "Maybe. Or maybe your Tower and my Order were both lied to about what's really down here."},
			],
		},

		# ─── KIRA ✕ GARRETT — the bleeding child (reality-bleed arc) ──
		# Two royals from different nations: Garrett hunts a kidnapped princess;
		# Kira is a queen torn from her infant. The scar bleeds them together —
		# Kira grows convinced the princess IS her child. Stays ambiguous.
		{
			"id": "kira_garrett_00_thequest",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 1,
			"stage_of": ["kira", "garrett"], "stage_eq": 0,
			"advances_stage": ["kira", "garrett"],
			"lines": [
				{"speaker": "garrett", "text": "I'm hunting a girl — a princess, stolen and dragged down into this place. I swore my queen I'd bring her home."},
				{"speaker": "kira", "text": "A child. Alone, in here."},
				{"speaker": "kira", "text": "...Then we had best hurry, ser."},
			],
		},
		{
			"id": "kira_garrett_01_resemblance",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 3,
			"stage_of": ["kira", "garrett"], "stage_eq": 1,
			"advances_stage": ["kira", "garrett"],
			"lines": [
				{"speaker": "kira", "text": "The princess. Describe her to me. Her face — describe her face."},
				{"speaker": "garrett", "text": "Fair. Pale eyes. Why does that— my lady, you've gone white as chalk."},
				{"speaker": "kira", "text": "It's nothing. It's nothing. It can't be."},
			],
		},
		{
			"id": "kira_garrett_02_insistence",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 5,
			"stage_of": ["kira", "garrett"], "stage_eq": 2,
			"advances_stage": ["kira", "garrett"],
			"lines": [
				{"speaker": "kira", "text": "It's her. The girl you seek. She's mine, Garrett. She's my child."},
				{"speaker": "garrett", "text": "Your child is an infant, my lady. The princess is a grown girl. It isn't possible."},
				{"speaker": "kira", "text": "This place isn't possible. And still — here we both are."},
			],
		},
		{
			"id": "kira_garrett_03_twoworlds",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 10,
			"min_depth": 7,
			"stage_of": ["kira", "garrett"], "stage_eq": 3,
			"advances_stage": ["kira", "garrett"],
			"set_flags": ["kira_garrett_bleed"],
			"lines": [
				{"speaker": "kira", "text": "When you find her — if she knows my face, you'll know I was right all along."},
				{"speaker": "garrett", "text": "And if she doesn't know you?"},
				{"speaker": "kira", "text": "Then I've lost her twice, in two worlds. Don't ask me which is crueler."},
			],
		},

		# ─── STUB: KIRA ✕ GARRETT payoff (DORMANT — do not fire yet) ──
		# These two entries are the planned resolution to the reality-bleed arc.
		# They are intentionally INERT for now: they require flags that nothing
		# sets yet, so `_is_eligible` will always reject them until the pieces
		# below exist. Safe to ship — they simply never trigger.
		#
		# PREREQUISITES before these become live:
		#   1. The arc must be complete — flag "kira_garrett_bleed" (set by
		#      kira_garrett_03_twoworlds above).
		#   2. The PRINCESS must exist as an in-game entity, and something must
		#      set flag "princess_found" when she is actually recovered.
		#   3. A branch decision: does she recognize Kira? Whatever handles the
		#      princess encounter should set "princess_knows_kira" (true/false).
		#      - recognizes  -> requires "princess_knows_kira"
		#      - stranger     -> forbids  "princess_knows_kira"
		#
		# DESIGN NOTE: keep the outcome ambiguous even here. "Recognition" should
		# not hard-confirm the bleed is literally real — a lost, terrified child
		# might cling to any kind face. Let the player decide what it meant.
		# TODO: pick a context for these (a scripted post-rescue scene may fit
		# better than a random safe-zone roll). Also consider a sanity effect.
		{
			"id": "kira_garrett_04_payoff_recognizes",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 20,
			"required_flags": ["kira_garrett_bleed", "princess_found", "princess_knows_kira"],
			"lines": [
				{"speaker": "garrett", "text": "My lady... she asked for you. By name. She called you Mother."},
				{"speaker": "kira", "text": "*barely a whisper* Then I was right. Gods help me, I was right."},
			],
		},
		{
			"id": "kira_garrett_04_payoff_stranger",
			"participants": ["kira", "garrett"],
			"contexts": ["safe_zone"],
			"one_shot": true,
			"priority": 20,
			"required_flags": ["kira_garrett_bleed", "princess_found"],
			"forbidden_flags": ["princess_knows_kira"],
			"lines": [
				{"speaker": "garrett", "text": "She looked at you and saw a stranger, my lady. I'm sorry."},
				{"speaker": "kira", "text": "No. No — she's frightened, that's all. That's all it is."},
				{"speaker": "kira", "text": "...Isn't it?"},
			],
		},

		# ─── FRIENDLY BANTER — Marcus & Patch (served together) ───────
		{
			"id": "marcus_patch_leg",
			"participants": ["marcus", "patch"],
			"contexts": ["safe_zone", "town"],
			"one_shot": false,
			"priority": 1,
			"weight": 1,
			"affinity_delta": ["marcus", "patch", 1],
			"lines": [
				{"speaker": "patch", "text": "You still favor that left leg, Vale. Old wound?"},
				{"speaker": "marcus", "text": "You're the one who stitched it. You tell me."},
				{"speaker": "patch", "text": "Then it'll never heal right. You're welcome."},
			],
		},

		# ─── SOLO TOPICS — "talk to X" (repeatable, small sanity balm) ─
		{
			"id": "sera_solo_students",
			"participants": ["sera"],
			"contexts": ["town", "safe_zone", "menu"],
			"one_shot": false,
			"priority": 0,
			"weight": 1,
			"sanity_reward": 5,
			"lines": [
				{"speaker": "sera", "text": "My students would have filled three notebooks by now. So I fill them. For all of us."},
			],
		},
		{
			"id": "dagger_solo_mycella",
			"participants": ["dagger"],
			"contexts": ["town", "safe_zone", "menu"],
			"one_shot": false,
			"priority": 0,
			"weight": 1,
			"sanity_reward": 5,
			"lines": [
				{"speaker": "dagger", "text": "Mycella always said I'd talk my way into a noose one day. Instead I climbed into a hole. Progress."},
			],
		},
	]


## ─── PERSISTENCE ────────────────────────────────────────────────

func _save() -> void:
	var data: Dictionary = {
		"played_one_shots": played_one_shots,
		"flags": flags,
		"pair_stage": pair_stage,
		"affinity": affinity,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.get_data()
		if data is Dictionary:
			played_one_shots.clear()
			for id in data.get("played_one_shots", []):
				if id is String:
					played_one_shots.append(id)
			flags = data.get("flags", {})
			pair_stage = data.get("pair_stage", {})
			affinity = data.get("affinity", {})
	file.close()
