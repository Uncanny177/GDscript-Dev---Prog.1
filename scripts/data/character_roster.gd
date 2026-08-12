## CharacterRoster — Defines the 12 unique party members.
##
## Each character has:
##   - A fixed personality and backstory
##   - A reason for entering the dungeon
##   - A class assignment (2 per class)
##   - Unique dialogue lines for safe zones
##   - Relationships (who they know before entering)
##
## Characters can permanently die (permadeath) or go insane (sanity 0).
## They are mostly strangers — a few pairs have prior connections.
##
## Design intent: player should feel attached, then devastated when they're lost.

extends Node

## ─── CHARACTER DEFINITIONS ──────────────────────────────────────

class CharacterProfile:
	var id: String = ""
	var character_name: String = ""
	var class_name_key: String = ""  # Maps to ClassDatabase
	var age: int = 0
	var personality: String = ""     # Brief personality tag
	var backstory: String = ""       # Why they're here
	var motivation: String = ""      # What drives them
	var fear: String = ""            # What breaks them (sanity vulnerability)
	var known_connection: String = ""  # ID of someone they know (empty = stranger)
	var dialogue_healthy: Array[String] = []
	var dialogue_stressed: Array[String] = []
	var dialogue_breaking: Array[String] = []


## All 12 characters
var profiles: Dictionary = {}

## Recruitment order (which ones you start with vs find later)
var starting_party: Array[String] = []
var recruitable: Array[String] = []


func _ready() -> void:
	_build_roster()
	print("[CharacterRoster] %d characters defined | %d starting | %d recruitable" % [
		profiles.size(), starting_party.size(), recruitable.size()
	])


func get_profile(character_id: String) -> CharacterProfile:
	if character_id in profiles:
		return profiles[character_id]
	return null


func get_starting_profiles() -> Array[CharacterProfile]:
	var result: Array[CharacterProfile] = []
	for id in starting_party:
		if id in profiles:
			result.append(profiles[id])
	return result


func get_recruitable_profiles() -> Array[CharacterProfile]:
	var result: Array[CharacterProfile] = []
	for id in recruitable:
		if id in profiles:
			result.append(profiles[id])
	return result


func _build_roster() -> void:
	# ─── 1. MARCUS VALE — The Soldier (Warrior) ───────────────────
	var marcus := CharacterProfile.new()
	marcus.id = "marcus"
	marcus.character_name = "Marcus Vale"
	marcus.class_name_key = "Warrior"
	marcus.age = 34
	marcus.personality = "Stoic, guilt-ridden"
	marcus.backstory = "Former border guard. Something happened at his post — people died because of his orders. He came here seeking redemption or death, whichever finds him first."
	marcus.motivation = "Redemption through sacrifice"
	marcus.fear = "Making decisions that kill others"
	marcus.known_connection = ""
	marcus.dialogue_healthy = [
		"\"Keep formation. Watch your flanks.\"",
		"\"I've seen worse. ...I think.\"",
		"\"Don't thank me. I'm not doing this for you.\"",
	]
	marcus.dialogue_stressed = [
		"\"The walls are closing in. No — that's just... focus.\"",
		"\"I keep hearing their voices. The ones I left behind.\"",
	]
	marcus.dialogue_breaking = [
		"\"I deserve this. All of this.\"",
		"*Marcus stares at his hands, trembling.* \"There's blood that won't wash off.\"",
	]
	profiles["marcus"] = marcus

	# ─── 2. SERA BRIGHTHOLLOW — The Scholar (Mage) ────────────────
	var sera := CharacterProfile.new()
	sera.id = "sera"
	sera.character_name = "Sera Brighthollow"
	sera.class_name_key = "Occultist"
	sera.age = 28
	sera.personality = "Curious, reckless, brilliant"
	sera.backstory = "University researcher who found references to this place in forbidden texts. She funded an expedition with stolen grant money. Knowledge is worth any price — she believes that absolutely."
	sera.motivation = "Forbidden knowledge at any cost"
	sera.fear = "Ignorance, losing her mind before understanding"
	sera.known_connection = ""
	sera.dialogue_healthy = [
		"\"Fascinating! The architecture here shouldn't be possible.\"",
		"\"I need to document everything. Hand me that journal.\"",
		"\"This is exactly what I came for. Isn't it wonderful?\"",
	]
	sera.dialogue_stressed = [
		"\"The symbols are changing. They weren't like that yesterday.\"",
		"\"I can almost understand them. Almost. It's maddening.\"",
	]
	sera.dialogue_breaking = [
		"\"I understand now. I understand EVERYTHING and I wish I didn't.\"",
		"*Sera writes furiously in her notebook, but the pages are blank.*",
	]
	profiles["sera"] = sera

	# ─── 3. DAGGER — The Thief (Rogue) ────────────────────────────
	var dagger := CharacterProfile.new()
	dagger.id = "dagger"
	dagger.character_name = "Dagger"
	dagger.class_name_key = "Rogue"
	dagger.age = 22
	dagger.personality = "Sarcastic, street-smart, hiding fear with humor"
	dagger.backstory = "Real name unknown. Grew up on the streets, took a job to steal something from the dungeon's first floor. The door locked behind them. Humor is the only thing keeping the fear at bay."
	dagger.motivation = "Survival (and maybe the score of a lifetime)"
	dagger.fear = "Being trapped, no escape"
	dagger.known_connection = ""
	dagger.dialogue_healthy = [
		"\"So this is what rock bottom looks like. Literally.\"",
		"\"If I die here, nobody's gonna miss me. ...That's fine.\"",
		"\"Dibs on anything shiny.\"",
	]
	dagger.dialogue_stressed = [
		"\"Okay less funny now. Where's the exit? There IS an exit, right?\"",
		"\"I've been trapped before. This is different. This is so much worse.\"",
	]
	dagger.dialogue_breaking = [
		"\"LET ME OUT LET ME OUT LET ME—\" *Dagger claws at the walls.*",
		"*Dagger laughs. It doesn't stop.* \"We're never leaving. That's the joke.\"",
	]
	profiles["dagger"] = dagger

	# ─── 4. ELEANOR ASHVANE — The Inquisitor (Inquisitor) ────────────
	var eleanor := CharacterProfile.new()
	eleanor.id = "eleanor"
	eleanor.character_name = "Eleanor Ashvane"
	eleanor.class_name_key = "Inquisitor"
	eleanor.age = 41
	eleanor.personality = "Jaded, dutiful, quietly losing faith"
	eleanor.backstory = "Sent by the church to apprehend a supposedly blasphemous revolutionary leader rumored to have traveled to the dungeon searching for something. It's a straightforward mission — find the heretic, bring them back. But Eleanor has seen how the church abuses its power. She's watched them silence dissent and call it holiness. She doesn't see herself as a pawn... but the thought creeps in. And with every prayer that goes unanswered, the thought gets louder: what if her god is false?"
	eleanor.motivation = "Complete her mission (while questioning everything it stands for)"
	eleanor.fear = "That her god is false and her entire life has been in service to a lie"
	eleanor.known_connection = "garrett"
	eleanor.dialogue_healthy = [
		"\"I have a job to do. Faith or no faith, I finish what I start.\"",
		"\"The church sent me. Whether they deserve my loyalty is... another question.\"",
		"\"Stay close. I won't let anything take you. That much I can promise.\"",
	]
	eleanor.dialogue_stressed = [
		"\"I prayed again last night. Silence. Always silence.\"",
		"\"Am I the church's sword or their dog? Sometimes I can't tell.\"",
	]
	eleanor.dialogue_breaking = [
		"\"There IS no god. There's just... them. The Old Ones. And they don't care about us at all.\"",
		"*Eleanor stares at her holy symbol.* \"I've killed people for this. And it means NOTHING.\"",
	]
	profiles["eleanor"] = eleanor

	# ─── 5. WREN — The Demon Hunter (Demon Hunter) ──────────────────
	var wren := CharacterProfile.new()
	wren.id = "wren"
	wren.character_name = "Wren"
	wren.class_name_key = "Demon Hunter"
	wren.age = 29
	wren.personality = "Chaotic good, grief-driven, relentless"
	wren.backstory = "A demon killed his wife. She was a scholar researching a cure for the plague sweeping the region — found references to a forbidden rite supposedly used to cure disease in ancient times. She performed the rite. Something went wrong. A demon answered instead of a cure, tormented her, and ultimately killed her. Wren tracked the thing here. The nightmares started after — visions of it wearing her face, mocking him from the dark. He doesn't sleep anymore. He hunts."
	wren.motivation = "Retribution — kill the specific demon that took everything from him"
	wren.fear = "That the hallucinations are real, that his wife's killer is toying with him"
	wren.known_connection = ""
	wren.dialogue_healthy = [
		"\"It's here. I can feel it. Deeper.\"",
		"\"Don't get between me and my target. I won't stop.\"",
		"\"She deserved better. I'm going to make sure it knows that.\"",
	]
	wren.dialogue_stressed = [
		"\"I saw her again last night. Smiling. Then it wasn't her face anymore.\"",
		"\"It's taunting me. Leaving traces. It WANTS me to follow.\"",
	]
	wren.dialogue_breaking = [
		"\"SHE'S RIGHT THERE. CAN'T YOU SEE HER?!\" *There's nothing there.*",
		"*Wren talks to empty air, then turns to you, confused.* \"...She was just here.\"",
	]
	profiles["wren"] = wren

	# ─── 6. VALDRIS — The Heretic (Necromancer) ───────────────────
	var valdris := CharacterProfile.new()
	valdris.id = "valdris"
	valdris.character_name = "Valdris"
	valdris.class_name_key = "Necromancer"
	valdris.age = 55
	valdris.personality = "Calm, amoral, academically detached"
	valdris.backstory = "Excommunicated scholar of death magic. He came here because the boundary between life and death is thin in this place. He wants to cross it — and come back."
	valdris.motivation = "Conquer death itself"
	valdris.fear = "Dying as a mortal, all research wasted"
	valdris.known_connection = "sera"  # Knows Sera from academic circles
	valdris.dialogue_healthy = [
		"\"Death is not an ending here. It's barely an inconvenience.\"",
		"\"The creatures here are fascinating specimens. May I keep one?\"",
		"\"I've been dead before. Briefly. It was... informative.\"",
	]
	valdris.dialogue_stressed = [
		"\"My preparations are failing. The magic here is... different.\"",
		"\"I can feel my wards eroding. Interesting. Terrifying, but interesting.\"",
	]
	valdris.dialogue_breaking = [
		"\"I can see the other side now. It's not empty. Something is THERE.\"",
		"*Valdris draws circles on the floor, muttering equations that make your head hurt.*",
	]
	profiles["valdris"] = valdris

	# ─── 7. KIRA OZAN — The Mercenary (Warrior) ───────────────────
	var kira := CharacterProfile.new()
	kira.id = "kira"
	kira.character_name = "Kira Ozan"
	kira.class_name_key = "Blood Mage"
	kira.age = 29
	kira.personality = "Professional, pragmatic, unexpectedly kind"
	kira.backstory = "Hired to escort the scholar (Sera) into the dungeon. The money was too good to question. Now the client is deeper in and Kira's contract says 'alive extraction.' Professional pride won't let her quit."
	kira.motivation = "Complete the job (and survive to spend the gold)"
	kira.fear = "Failing a contract — her reputation is everything"
	kira.known_connection = "sera"  # Hired by Sera
	kira.dialogue_healthy = [
		"\"I'm getting paid for this. That's what I keep telling myself.\"",
		"\"Stay behind me. I didn't survive three wars to die in a hole.\"",
		"\"The scholar better have my gold ready when we get out.\"",
	]
	kira.dialogue_stressed = [
		"\"No amount of money is worth this. ...But I said I'd finish the job.\"",
		"\"I've never retreated. I'm not starting now.\"",
	]
	kira.dialogue_breaking = [
		"\"There's no client to protect anymore. There's nothing to protect.\"",
		"*Kira grips her sword so tight her knuckles whiten.* \"Just point me at something.\"",
	]
	profiles["kira"] = kira

	# ─── 8. MOTH — The Occultist (Mage) ──────────────────────────
	var moth := CharacterProfile.new()
	moth.id = "moth"
	moth.character_name = "Moth"
	moth.class_name_key = "Summoner"
	moth.age = 33
	moth.personality = "Eerie, gentle, lost, hears voices"
	moth.backstory = "Moth doesn't know why she's here. Not really. She hears voices — has since childhood — and they led her to this place. She followed because what else do you do when something speaks directly into your mind? Someone or something wants to use her as a vessel, a conduit to summon something back into this reality. She doesn't understand this yet. She just knows the voices are louder here, and they seem pleased she came."
	moth.motivation = "Answer the voices (she doesn't know what they want yet)"
	moth.fear = "That she's a puppet — that nothing she's done has been her own choice"
	moth.known_connection = ""
	moth.dialogue_healthy = [
		"\"The voices are quiet today. That's... unusual.\"",
		"\"They say we're going the right way. I think that's good.\"",
		"\"I don't know why I'm here. But it feels like I'm supposed to be.\"",
	]
	moth.dialogue_stressed = [
		"\"They're all talking at once. I can't make out the words anymore.\"",
		"\"Something wants me to go deeper. I don't think it's asking.\"",
	]
	moth.dialogue_breaking = [
		"\"I can feel it reaching through me. Using my hands. My mouth. I can't stop it.\"",
		"*Moth speaks in a language no one recognizes. Her eyes are open but she isn't there.*",
	]
	profiles["moth"] = moth

	# ─── 9. PATCH — The Medic (Paladin) ───────────────────────────
	var patch := CharacterProfile.new()
	patch.id = "patch"
	patch.character_name = "Patch"
	patch.class_name_key = "Monk"
	patch.age = 38
	patch.personality = "Warm, tired, darkly funny"
	patch.backstory = "Former battlefield medic. Lost their license after a 'creative' treatment saved a patient but broke twelve laws. Came to the dungeon because someone said there were people trapped inside who needed help."
	patch.motivation = "Save people (even here, especially here)"
	patch.fear = "Being unable to help when it matters"
	patch.known_connection = "marcus"  # Served in same conflict as Marcus
	patch.dialogue_healthy = [
		"\"Anyone hurt? Let me see. ...Everyone's always hurt down here.\"",
		"\"I've patched up worse. Probably.\"",
		"\"The good news: you're alive. The bad news: so is everything else.\"",
	]
	patch.dialogue_stressed = [
		"\"I'm running out of supplies. And optimism.\"",
		"\"I can't fix this. Whatever is wrong with this place, I can't fix it.\"",
	]
	patch.dialogue_breaking = [
		"\"Do no harm. Do no harm. Do no— I CAN'T HELP THEM.\"",
		"*Patch bandages their own hands, over and over. They aren't injured.*",
	]
	profiles["patch"] = patch

	# ─── 10. SILAS CRANE — The Plague Doctor (Alchemist) ─────────────
	var silas := CharacterProfile.new()
	silas.id = "silas"
	silas.character_name = "Dr. Silas Crane"
	silas.class_name_key = "Alchemist"
	silas.age = 45
	silas.personality = "Determined, haunted, clinically detached until he isn't"
	silas.backstory = "Started as a battlefield medic whose tinctures actually worked — too well. His superiors noticed. They pulled him off the field and put him in a lab. What started as healing became something else: stimulants that burned soldiers out from the inside, gases that choked entire battalions. He made those things. He told himself it was duty. After the war, he couldn't look at his own hands without seeing what they'd done. The plague gave him purpose again — a chance to use his knowledge to SAVE instead of destroy. He heard that ancient alchemical knowledge in the dungeon might hold the key to a cure."
	silas.motivation = "Cure the plague — right the wrongs of his past"
	silas.fear = "That he's only good at making things that hurt people"
	silas.known_connection = ""
	silas.dialogue_healthy = [
		"\"There has to be something here. Some compound, some formula. I'll find it.\"",
		"\"I've seen what the plague does. Every hour I spend down here, people are dying up there.\"",
		"\"Don't get hurt. I can patch you up but my supplies aren't infinite.\"",
	]
	silas.dialogue_stressed = [
		"\"I keep seeing their faces. The ones from the war. The ones I couldn't save.\"",
		"\"What if there IS no cure? What if I came here for nothing?\"",
	]
	silas.dialogue_breaking = [
		"\"I hear them dying. Above us. Right now. And I'm DOWN HERE doing NOTHING.\"",
		"*Silas stares at his hands.* \"These hands were supposed to heal. All they do is fail.\"",
	]
	profiles["silas"] = silas

	# ─── 11. ECHO — The Deserter (Archer) ─────────────────────────
	var echo := CharacterProfile.new()
	echo.id = "echo"
	echo.character_name = "Echo"
	echo.class_name_key = "Engineer"
	echo.age = 26
	echo.personality = "Skittish, loyal once trusted, survivor"
	echo.backstory = "Was part of a previous expedition that went wrong. Everyone else died. Echo survived by hiding. They've been living in the upper floors for weeks, too afraid to go deeper, too lost to find the exit."
	echo.motivation = "Find a way out (and maybe stop hiding)"
	echo.fear = "Being a coward when others need them"
	echo.known_connection = ""
	echo.dialogue_healthy = [
		"\"I know the upper floors. The paths, the safe spots. Let me guide you.\"",
		"\"Last time... I ran. I won't do that again. Probably.\"",
		"\"Stay quiet. Sound carries wrong down here.\"",
	]
	echo.dialogue_stressed = [
		"\"Every instinct says run. I'm so tired of running.\"",
		"\"The others — my old party — I hear them sometimes. In the walls.\"",
	]
	echo.dialogue_breaking = [
		"\"They're here. My old party. They found me. They're ANGRY.\"",
		"*Echo won't stop looking over their shoulder.* \"It followed us. It always follows.\"",
	]
	profiles["echo"] = echo

	# ─── 12. DR. FINCH — The Former Cultist (Necromancer) ─────────
	var finch := CharacterProfile.new()
	finch.id = "finch"
	finch.character_name = "Dr. Finch"
	finch.class_name_key = "Psion"
	finch.age = 48
	finch.personality = "Nervous, apologetic, trying to atone"
	finch.backstory = "Was a cultist of Neth'zarr. Participated in the rituals that opened this dungeon. When they saw what came through, they fled. Now they're back to undo what they helped create — if that's even possible."
	finch.motivation = "Undo the damage they caused"
	finch.fear = "That their old master (Neth'zarr) will reclaim them"
	finch.known_connection = ""
	finch.dialogue_healthy = [
		"\"I know these symbols. I helped WRITE some of them. I'm so sorry.\"",
		"\"The wards here — I can modify them. I know how they work.\"",
		"\"Please don't judge me for what I was. Judge me for what I do now.\"",
	]
	finch.dialogue_stressed = [
		"\"He's calling. Neth'zarr. I can feel him reaching for me.\"",
		"\"The old words keep coming back. I catch myself almost saying them.\"",
	]
	finch.dialogue_breaking = [
		"\"Father... I hear you. I'm coming home.\" *Finch's eyes go black.*",
		"*Finch kneels before a wall, drawing void sigils.* \"It's easier this way.\"",
	]
	profiles["finch"] = finch

	# ─── 13. GARRETT STONE — The Knight (Knight) ─────────────────
	var garrett := CharacterProfile.new()
	garrett.id = "garrett"
	garrett.character_name = "Garrett Stone"
	garrett.class_name_key = "Knight"
	garrett.age = 52
	garrett.personality = "Honorable, tired, stubbornly protective"
	garrett.backstory = "A retired royal guard who heard rumors of people disappearing into the dungeon. Came out of retirement because nobody else would. He's too old for this. He knows it. He came anyway."
	garrett.motivation = "Protect the others (because someone has to)"
	garrett.fear = "Being too slow to save someone"
	garrett.known_connection = "eleanor"  # Served in the same temple order years ago
	garrett.dialogue_healthy = [
		"\"Stay behind me. That's all I ask.\"",
		"\"I've stood watch at gates for thirty years. This is just... a darker gate.\"",
		"\"My knees aren't what they were. But my shield arm is still strong.\"",
	]
	garrett.dialogue_stressed = [
		"\"I can't protect all of you. There are too many angles.\"",
		"\"In the old days, I'd have a squad. Now it's just me and this shield.\"",
	]
	garrett.dialogue_breaking = [
		"\"I failed them. I failed ALL of them. Just like before.\"",
		"*Garrett plants his shield in the ground and doesn't move.* \"...I'll hold here.\"",
	]
	profiles["garrett"] = garrett

	# ─── PARTY COMPOSITION ────────────────────────────────────────
	# Start with 4, recruit rest during dungeon runs
	starting_party = ["marcus", "sera", "dagger", "eleanor"]
	recruitable = ["wren", "valdris", "kira", "moth", "patch", "silas", "echo", "finch", "garrett"]


## ─── CREATE GAME CHARACTERS ─────────────────────────────────────

func create_character_data(character_id: String) -> CharacterData:
	## Create a CharacterData instance from a roster profile.
	## Used by PartyManager to populate the party.
	var profile: CharacterProfile = get_profile(character_id)
	if not profile:
		push_error("[CharacterRoster] Unknown character: %s" % character_id)
		return null
	
	var class_data: ClassData = ClassDatabase.get_class_data(profile.class_name_key)
	if not class_data:
		push_error("[CharacterRoster] Unknown class: %s" % profile.class_name_key)
		return null
	
	var character := CharacterData.new()
	character.character_name = profile.character_name
	character.character_class = class_data
	character.initialize()
	
	return character


func create_starting_party() -> Array[CharacterData]:
	## Create all starting party members as CharacterData.
	var party: Array[CharacterData] = []
	for id in starting_party:
		var c: CharacterData = create_character_data(id)
		if c:
			party.append(c)
	return party


## ─── DIALOGUE ACCESS ────────────────────────────────────────────

func get_dialogue(character_id: String, sanity: int) -> String:
	## Get contextual dialogue based on character's sanity state.
	var profile: CharacterProfile = get_profile(character_id)
	if not profile:
		return "\"...\""
	
	if sanity <= 10:
		if profile.dialogue_breaking.is_empty():
			return "\"...\""
		return profile.dialogue_breaking[randi() % profile.dialogue_breaking.size()]
	elif sanity <= 30:
		if profile.dialogue_stressed.is_empty():
			return "\"...\""
		return profile.dialogue_stressed[randi() % profile.dialogue_stressed.size()]
	else:
		if profile.dialogue_healthy.is_empty():
			return "\"...\""
		return profile.dialogue_healthy[randi() % profile.dialogue_healthy.size()]


## ─── RELATIONSHIP MAP ───────────────────────────────────────────

func get_connections() -> Array[Dictionary]:
	## Returns pairs of characters who know each other.
	var connections: Array[Dictionary] = []
	for id in profiles:
		var profile: CharacterProfile = profiles[id]
		if profile.known_connection != "":
			connections.append({
				"from": id,
				"to": profile.known_connection,
				"from_name": profile.character_name,
				"to_name": profiles[profile.known_connection].character_name if profile.known_connection in profiles else "???",
			})
	return connections
