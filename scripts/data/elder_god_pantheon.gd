## ElderGodPantheon — Defines all 12 elder gods and their domains.
##
## "They are not dead, nor truly alive. The Old Ones exist between states —
##  dreaming in frequencies our minds cannot process."
##
## Each god has:
##   - A domain (what they control/represent)
##   - Servants (enemy types tied to them)
##   - Rites (what rituals at their altars do)
##   - A boon (what calling on their power grants)
##   - A cost (what they demand in return)
##   - Lore (fragments the player can discover)
##
## The 12 gods are NOT allies. They have their own agendas.
## Some are hostile to the player. Some are indifferent.
## A few might help — for a price that is always too high.

extends Node

## ─── GOD DATA ───────────────────────────────────────────────────

class ElderGod:
	var id: String = ""
	var god_name: String = ""
	var title: String = ""           # "The Void Father", "The Frost That Thinks"
	var domain: String = ""          # What they represent
	var element: String = ""         # Gameplay element alignment
	var attitude: String = ""        # hostile, indifferent, curious, hungry
	var description: String = ""     # Lore snippet
	var servants: Array[String] = [] # Enemy IDs that serve this god
	var boon: String = ""            # What they offer
	var cost: String = ""            # What they demand
	var sigil_color: Color = Color.WHITE
	var floor_affinity: int = 0      # Which floors they're strongest on (0 = all)


## ─── STATE ──────────────────────────────────────────────────────

var gods: Dictionary = {}  # id → ElderGod
var player_favor: Dictionary = {}  # id → int (favor score, pos = liked, neg = angered)

signal favor_changed(god_id: String, new_favor: int)
@warning_ignore("unused_signal")
signal god_event(god_id: String, event_type: String, message: String)


func _ready() -> void:
	_build_pantheon()
	_init_favor()
	print("[Pantheon] %d elder gods defined" % gods.size())


func get_god(god_id: String) -> ElderGod:
	if god_id in gods:
		return gods[god_id]
	return null


func get_all_gods() -> Array:
	var result: Array = []
	for id in gods:
		result.append(gods[id])
	return result


## ─── FAVOR SYSTEM ───────────────────────────────────────────────

func change_favor(god_id: String, amount: int) -> void:
	## Change player's favor with a god. Positive = pleased, negative = angered.
	if god_id not in player_favor:
		player_favor[god_id] = 0
	player_favor[god_id] += amount
	favor_changed.emit(god_id, player_favor[god_id])
	
	var god: ElderGod = get_god(god_id)
	var god_display: String = god.god_name if god else god_id
	if amount > 0:
		print("[Pantheon] %s is pleased (+%d favor)" % [god_display, amount])
	else:
		print("[Pantheon] %s is displeased (%d favor)" % [god_display, amount])


func get_favor(god_id: String) -> int:
	return int(player_favor.get(god_id, 0))


func is_favored(god_id: String) -> bool:
	return get_favor(god_id) >= 10


func is_angered(god_id: String) -> bool:
	return get_favor(god_id) <= -10


func get_dominant_god() -> String:
	## Returns the god_id with the highest positive favor. Empty if none.
	var best_id: String = ""
	var best_favor: int = 0
	for id in player_favor:
		if int(player_favor[id]) > best_favor:
			best_favor = int(player_favor[id])
			best_id = id
	return best_id


## ─── INIT ───────────────────────────────────────────────────────

func _init_favor() -> void:
	for id in gods:
		player_favor[id] = 0


func _build_pantheon() -> void:
	# ═══ THE SIX KNOWN (referenced in ritual altars) ═══════════════

	# 1. NETH'ZARR — The Void Father
	var nethzarr := ElderGod.new()
	nethzarr.id = "nethzarr"
	nethzarr.god_name = "Neth'zarr"
	nethzarr.title = "The Void Father"
	nethzarr.domain = "Void, nothingness, forbidden knowledge"
	nethzarr.element = "dark"
	nethzarr.attitude = "hungry"
	nethzarr.description = "The first absence. Neth'zarr exists as a hole in reality — a consciousness made of nothing. His cultists hollow themselves to become vessels for his whispers. He offers knowledge freely, but each truth consumed leaves less of the recipient behind."
	nethzarr.servants = ["cultist", "void_stalker"]
	nethzarr.boon = "Perfect knowledge of any enemy (grants MASTERED tier)"
	nethzarr.cost = "Sanity — pieces of your mind become his"
	nethzarr.sigil_color = Color(0.3, 0.0, 0.5)
	nethzarr.floor_affinity = 5
	gods["nethzarr"] = nethzarr

	# 2. KAEL'THUN — The Frost That Thinks
	var kaelthun := ElderGod.new()
	kaelthun.id = "kaelthun"
	kaelthun.god_name = "Kael'thun"
	kaelthun.title = "The Frost That Thinks"
	kaelthun.domain = "Cold, stillness, preservation, patience"
	kaelthun.element = "ice"
	kaelthun.attitude = "indifferent"
	kaelthun.description = "A glacier with opinions. Kael'thun does not hate or love — he simply endures. His domain is the silence between heartbeats, the pause before death. Those who serve him lose warmth first, then voice, then will. What remains is efficient."
	kaelthun.servants = ["shadow_hound", "frost_wraith"]
	kaelthun.boon = "Defense and endurance beyond mortal limits"
	kaelthun.cost = "Emotion — you become cold and efficient"
	kaelthun.sigil_color = Color(0.5, 0.8, 0.9)
	kaelthun.floor_affinity = 3
	gods["kaelthun"] = kaelthun

	# 3. MOR'GHUL — The Flesh-Shaper
	var morghul := ElderGod.new()
	morghul.id = "morghul"
	morghul.god_name = "Mor'ghul"
	morghul.title = "The Flesh-Shaper"
	morghul.domain = "Biology, mutation, healing, body horror"
	morghul.element = "none"
	morghul.attitude = "curious"
	morghul.description = "Once a healer — or so the oldest texts claim. Now Mor'ghul reshapes living things like clay, fascinated by form and function. His creations work perfectly. They are also deeply, fundamentally wrong in ways the eye can see but the mind cannot articulate."
	morghul.servants = ["bone_sentinel", "flesh_golem"]
	morghul.boon = "Physical restoration and enhancement"
	morghul.cost = "Max HP — your body becomes less yours"
	morghul.sigil_color = Color(0.7, 0.3, 0.3)
	morghul.floor_affinity = 4
	gods["morghul"] = morghul

	# 4. VHOR'AX — The Blood Drinker
	var vhorax := ElderGod.new()
	vhorax.id = "vhorax"
	vhorax.god_name = "Vhor'ax"
	vhorax.title = "The Blood Drinker"
	vhorax.domain = "Blood, sacrifice, war, hunger"
	vhorax.element = "fire"
	vhorax.attitude = "hungry"
	vhorax.description = "Vhor'ax is appetite given form. Not evil — merely perpetually starving. Blood feeds him, violence pleases him, and those who offer freely find their strikes strengthened. But he is never full. He is never satisfied. And eventually, you run out of blood to give."
	vhorax.servants = ["blood_priest", "abyssal_maw"]
	vhorax.boon = "Raw offensive power — attack and damage"
	vhorax.cost = "Blood (HP) — always more than you planned"
	vhorax.sigil_color = Color(0.8, 0.0, 0.0)
	vhorax.floor_affinity = 0
	gods["vhorax"] = vhorax

	# 5. YITH'AEL — The Dream Keeper
	var yithael := ElderGod.new()
	yithael.id = "yithael"
	yithael.god_name = "Yith'ael"
	yithael.title = "The Dream Keeper"
	yithael.domain = "Dreams, perception, illusion, prophecy"
	yithael.element = "light"
	yithael.attitude = "curious"
	yithael.description = "Reality is Yith'ael's canvas. She paints over the world with dreams — some beautiful, some terrible, all convincing. Her followers cannot distinguish dream from waking. Some say that's a blessing. The dungeon itself may be one of her longer works."
	yithael.servants = ["mind_flayer", "dream_weaver"]
	yithael.boon = "Mental power and sanity restoration"
	yithael.cost = "The boundary between real and unreal blurs"
	yithael.sigil_color = Color(0.8, 0.6, 0.9)
	yithael.floor_affinity = 0
	gods["yithael"] = yithael

	# 6. XOTH'RA — The Plague Mother
	var xothra := ElderGod.new()
	xothra.id = "xothra"
	xothra.god_name = "Xoth'ra"
	xothra.title = "The Plague Mother"
	xothra.domain = "Disease, adaptation, evolution, decay"
	xothra.element = "none"
	xothra.attitude = "indifferent"
	xothra.description = "Xoth'ra does not create plagues out of malice. She is evolution incarnate — constantly testing, iterating, discarding failures. Her children are viruses and parasites. Those who survive her gifts become something more. Most do not survive."
	xothra.servants = ["plague_bearer"]
	xothra.boon = "Resistance and adaptation — immunity to status effects"
	xothra.cost = "Pain (HP from all party) — the inoculation process"
	xothra.sigil_color = Color(0.2, 0.5, 0.1)
	xothra.floor_affinity = 2
	gods["xothra"] = xothra

	# ═══ THE SIX HIDDEN (discovered deeper in the dungeon) ═════════

	# 7. SHAL'TEK — The Crystalline Mind
	var shaltek := ElderGod.new()
	shaltek.id = "shaltek"
	shaltek.god_name = "Shal'tek"
	shaltek.title = "The Crystalline Mind"
	shaltek.domain = "Order, geometry, mathematics, madness through perfection"
	shaltek.element = "light"
	shaltek.attitude = "indifferent"
	shaltek.description = "Shal'tek is pure logic without mercy. A consciousness of perfect crystal that sees the universe as an equation to be balanced. Those who glimpse his patterns find the world unbearably messy afterward. Some try to 'correct' it."
	shaltek.servants = ["crystal_horror"]
	shaltek.boon = "Perfect clarity — see all enemy stats and weaknesses"
	shaltek.cost = "Compassion — you begin to see people as numbers"
	shaltek.sigil_color = Color(0.9, 0.9, 1.0)
	shaltek.floor_affinity = 4
	gods["shaltek"] = shaltek

	# 8. UMBRITH — The Thing Beneath
	var umbrith := ElderGod.new()
	umbrith.id = "umbrith"
	umbrith.god_name = "Umbrith"
	umbrith.title = "The Thing Beneath"
	umbrith.domain = "Depth, gravity, weight, the underground"
	umbrith.element = "dark"
	umbrith.attitude = "hostile"
	umbrith.description = "Umbrith IS the dungeon. Or rather — the dungeon grew from Umbrith's dreaming body. Every floor deeper is a layer closer to waking it. It does not want visitors. It wants them to stay. Forever. As part of itself."
	umbrith.servants = []
	umbrith.boon = "The dungeon reshapes to help you (reveal secrets)"
	umbrith.cost = "You can never truly leave — part of you stays behind"
	umbrith.sigil_color = Color(0.1, 0.1, 0.1)
	umbrith.floor_affinity = 5
	gods["umbrith"] = umbrith

	# 9. WHISPER — The Unnamed
	var whisper := ElderGod.new()
	whisper.id = "whisper"
	whisper.god_name = "Whisper"
	whisper.title = "The Unnamed"
	whisper.domain = "Secrets, lies, identity, masks"
	whisper.element = "dark"
	whisper.attitude = "curious"
	whisper.description = "Nobody knows Whisper's true name — including Whisper. It exists as a concept of hidden things, wearing faces like clothes. It whispers truths that were meant to stay buried. Some truths can save you. Some truths destroy you. Whisper doesn't distinguish."
	whisper.servants = []
	whisper.boon = "Reveals hidden paths, secret rooms, NPC truths"
	whisper.cost = "Your identity frays — who are you, really?"
	whisper.sigil_color = Color(0.4, 0.4, 0.4)
	whisper.floor_affinity = 0
	gods["whisper"] = whisper

	# 10. THAL'GOROTH — The Hunger That Waits
	var thalgoroth := ElderGod.new()
	thalgoroth.id = "thalgoroth"
	thalgoroth.god_name = "Thal'goroth"
	thalgoroth.title = "The Hunger That Waits"
	thalgoroth.domain = "Time, entropy, inevitability, patience"
	thalgoroth.element = "none"
	thalgoroth.attitude = "hostile"
	thalgoroth.description = "Thal'goroth does not chase. It waits. It is the heat death of the universe given consciousness — patient, absolute, certain. Everything ends in Thal'goroth eventually. It does not need to hurry. It has all the time there ever was or will be."
	thalgoroth.servants = []
	thalgoroth.boon = "Slow enemies (reduce SPD), extend buff durations"
	thalgoroth.cost = "Time — your run timer accelerates, floor difficulty scales faster"
	thalgoroth.sigil_color = Color(0.3, 0.2, 0.1)
	thalgoroth.floor_affinity = 0
	gods["thalgoroth"] = thalgoroth

	# 11. AETHYS — The Watcher Above
	var aethys := ElderGod.new()
	aethys.id = "aethys"
	aethys.god_name = "Aethys"
	aethys.title = "The Watcher Above"
	aethys.domain = "Observation, judgment, cosmic indifference"
	aethys.element = "light"
	aethys.attitude = "indifferent"
	aethys.description = "Aethys watches everything. Records everything. Judges nothing. A vast eye that has seen civilizations rise and fall without blinking. Some find comfort in being witnessed. Others find the total absence of judgment worse than condemnation."
	aethys.servants = []
	aethys.boon = "Full map reveal + enemy positions for entire floor"
	aethys.cost = "Nothing is hidden — including your own weaknesses (enemies see your stats)"
	aethys.sigil_color = Color(1.0, 0.9, 0.5)
	aethys.floor_affinity = 0
	gods["aethys"] = aethys

	# 12. SYRA'KAL — The Broken Song
	var syrakal := ElderGod.new()
	syrakal.id = "syrakal"
	syrakal.god_name = "Syra'kal"
	syrakal.title = "The Broken Song"
	syrakal.domain = "Music, emotion, madness, beauty"
	syrakal.element = "none"
	syrakal.attitude = "curious"
	syrakal.description = "Once, Syra'kal sang the world into being — or so the myths claim. Now the song is broken, fragmented, scattered through the dungeon as half-heard melodies that drive listeners to ecstasy or despair. Her followers hear music in everything. The silence terrifies them."
	syrakal.servants = []
	syrakal.boon = "Sanity restoration and emotional resilience"
	syrakal.cost = "You hear the song forever. It never stops. Even in silence."
	syrakal.sigil_color = Color(0.9, 0.4, 0.6)
	syrakal.floor_affinity = 0
	gods["syrakal"] = syrakal

	# 13. VAEL'KUR — The Mirror That Remembers
	var vaelkur := ElderGod.new()
	vaelkur.id = "vaelkur"
	vaelkur.god_name = "Vael'kur"
	vaelkur.title = "The Mirror That Remembers"
	vaelkur.domain = "Memory, regret, alternate selves, permadeath"
	vaelkur.element = "none"
	vaelkur.attitude = "curious"
	vaelkur.description = "Vael'kur collects the echoes of every choice not taken, every person who died, every timeline that collapsed. He is a gallery of ghosts — not of the dead, but of the never-were. Those who look into his mirrors see the versions of themselves that made different choices. Some find comfort. Most find horror."
	vaelkur.servants = []
	vaelkur.boon = "Undo a permadeath — bring one fallen character back (once)"
	vaelkur.cost = "You see every failure, every death, every wrong turn. Massive sanity cost."
	vaelkur.sigil_color = Color(0.6, 0.6, 0.7)  # Mirror silver
	vaelkur.floor_affinity = 0
	gods["vaelkur"] = vaelkur


## ─── QUERIES ────────────────────────────────────────────────────

func get_god_for_enemy(enemy_id: String) -> ElderGod:
	## Find which god a specific enemy serves.
	for id in gods:
		var god: ElderGod = gods[id]
		if enemy_id in god.servants:
			return god
	return null


func get_gods_by_attitude(attitude: String) -> Array:
	## Get all gods with a specific attitude (hostile, indifferent, curious, hungry).
	var result: Array = []
	for id in gods:
		if gods[id].attitude == attitude:
			result.append(gods[id])
	return result


func get_gods_for_floor(floor_num: int) -> Array:
	## Get gods whose influence is strongest on this floor.
	var result: Array = []
	for id in gods:
		var god: ElderGod = gods[id]
		if god.floor_affinity == 0 or god.floor_affinity == floor_num:
			result.append(god)
	return result


func get_random_god() -> ElderGod:
	## Pick a random god from the pantheon.
	var ids: Array = gods.keys()
	if ids.is_empty():
		return null
	return gods[ids[randi() % ids.size()]]


## ─── SERIALIZATION ──────────────────────────────────────────────

func to_dict() -> Dictionary:
	var favor_data: Dictionary = {}
	for id in player_favor:
		favor_data[id] = player_favor[id]
	return {"favor": favor_data}


func from_dict(data: Dictionary) -> void:
	var favor_data: Dictionary = data.get("favor", {})
	for id in favor_data:
		player_favor[id] = int(favor_data[id])
