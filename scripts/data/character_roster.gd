## CharacterRoster — Defines the 13 unique party members.
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


## All 13 characters
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

	# ─── 2. SERA BRIGHTHOLLOW — The Scholar (Occultist) ────────────────
	var sera := CharacterProfile.new()
	sera.id = "sera"
	sera.character_name = "Sera Brighthollow"
	sera.class_name_key = "Occultist"
	sera.age = 28
	sera.personality = "Curious, brilliant, grief-driven"
	sera.backstory = "A prominent scholar of the White Tower — seat of the College of Insight, which rules an archipelago of islands east of the dungeon and prizes knowledge above all else. Sera devoted her life to study and was entrusted with teaching the next generation of mages. Then the Order of Retribution came: they invaded the College, burned the school, and slaughtered her students. She fled to the Apex continent carrying one burning question — she had learned the Order came hunting information about the dungeon. She means to find out what they wanted, and why it was worth her students' lives."
	sera.motivation = "Uncover what the Order of Retribution sought in the dungeon — and reckon with what it cost her"
	sera.fear = "Dying ignorant — and the guilt that she survived when her students did not"
	sera.known_connection = ""
	sera.dialogue_healthy = [
		"\"Fascinating — the College spent centuries theorizing about places like this. They had no idea.\"",
		"\"My students should be seeing this, not me. They earned it more than I did.\"",
		"\"Whatever the Order burned my home to find, it's down here. I'll reach it first.\"",
	]
	sera.dialogue_stressed = [
		"\"The symbols keep shifting. My own notes contradict each other. I HAVE to understand this.\"",
		"\"I hear my students sometimes. Reciting their lessons. Then the screaming starts.\"",
	]
	sera.dialogue_breaking = [
		"\"I understand now. I understand EVERYTHING and I wish I didn't.\"",
		"*Sera writes furiously in her notebook, but the pages are blank.*",
		"\"I should have burned with them. Scholars don't run. I ran.\"",
	]
	profiles["sera"] = sera

	# ─── 3. DAGGER — The Thief (Rogue) ────────────────────────────
	var dagger := CharacterProfile.new()
	dagger.id = "dagger"
	dagger.character_name = "Dagger"
	dagger.class_name_key = "Rogue"
	dagger.age = 22
	dagger.personality = "Sarcastic, street-smart, hiding fear with humor"
	dagger.backstory = "Dagger isn't his real name — it's what the streets called him, after the scar down the right side of his face that looks like a blade's tear. Born the second son of a wealthy slaver family in Calcifur, a coastal city in the nation of Illsayad, southwest of the dungeon. They abandoned him to the city's overcrowded orphanages at birth; a deformed child wouldn't do for a family of their standing. He grew up in those orphanages and on the streets, surviving however he could. His one real friend was a girl named Mycella — until slavers took her too. Now she's owned by one of Calcifur's Merchant Lords, who won't free her for anything less than an ancient artifact rumored to lie deep within the dungeon. So Dagger came to steal it."
	dagger.motivation = "Buy Mycella's freedom by retrieving the artifact the Merchant Lord demands"
	dagger.fear = "Being trapped, no escape"
	dagger.known_connection = ""
	dagger.dialogue_healthy = [
		"\"So this is what rock bottom looks like. Literally.\"",
		"\"I'm not doing this for me. Someone's counting on that shiny prize down there.\"",
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

	# ─── 4. ELEANOR ASHVILLE — The Inquisitor (Inquisitor) ────────────
	var eleanor := CharacterProfile.new()
	eleanor.id = "eleanor"
	eleanor.character_name = "Eleanor Ashville"
	eleanor.class_name_key = "Inquisitor"
	eleanor.age = 26
	eleanor.personality = "Jaded, dutiful, quietly losing faith"
	eleanor.backstory = "An Inquisitor of the Order of Retribution — a hallowed branch of the Church of the Vestibule. The church operates a theocracy in the nation of Golgatha, west of the Apex continent. She was sent to apprehend a supposedly blasphemous revolutionary leader rumored to have traveled to the dungeon searching for something. It's a straightforward mission — find the heretic, bring them back. But Eleanor has seen how the church abuses its power. She's watched them silence dissent and call it holiness. She doesn't see herself as a pawn... but the thought creeps in. And with every prayer that goes unanswered, the thought gets louder: what if her god is false?"
	eleanor.motivation = "Complete her mission (while questioning everything it stands for)"
	eleanor.fear = "That her god is false and her entire life has been in service to a lie"
	eleanor.known_connection = ""
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

	# ─── 6. VALDRIS — The Grimwalker ───────────────────
	var valdris := CharacterProfile.new()
	valdris.id = "valdris"
	valdris.character_name = "Valdris"
	valdris.class_name_key = "Grimwalker"
	valdris.age = 55
	valdris.personality = "Serene on the surface, deeply unstable beneath"
	valdris.backstory = "Born on the Apex continent, south of the dungeon, into the Grimwalkers — a reclusive enclave of dark priests who dwell in the ruins of the old empire's fallen capital. Grimwalkers are whispered of across the world as the most powerful ether users alive, masters of the most forbidden magics; few survive the training to adulthood. Valdris endured an upbringing closer to torture than tutelage and emerged an expert in blood magic and necromancy — but he failed his final ascension. To become a true Grimwalker he was to sever his own humanity, and he could not. He faked his death and fled; the order believes him gone. His enclave has long been rumored to sacrifice children to something waiting in the dungeon. Valdris appears calm, detached, unshakable — but the trauma runs bone-deep. He will do anything for knowledge. He came to the dungeon searching for... something he will not name."
	valdris.motivation = "Anything for knowledge — and something in the dungeon he keeps to himself"
	valdris.fear = "That the humanity he failed to sever will resurface and unmake his composure"
	valdris.known_connection = "sera"  # Linked by forbidden knowledge: Sera wants what he knows; he stays elusive
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

	# ─── 7. KIRA OZAN — The Queen in Exile (Dancer) ───────────────────
	var kira := CharacterProfile.new()
	kira.id = "kira"
	kira.character_name = "Kira Ozan"
	kira.class_name_key = "Dancer"
	kira.age = 24
	kira.personality = "Reluctant and dutiful — grace worn like armor over a life she never chose"
	kira.backstory = "Born to nobility in Lenoire, capital of the Nation of Ameer on the Eastern continent, northeast of the dungeon. Her father served as the King's Monarch of Coin, and Kira grew up alongside the crown prince. Nothing about her life was ever hers to choose: the betrothal was arranged, the crown was simply assumed, and even the child she would bear was expected of her long before anyone thought to ask. Then the king, the queen, and her new husband were all murdered in a plot no one has unraveled. Loyalists spirited her away in the night — carrying, though she didn't yet know it, the prince's child. She bore the last of Ameer's royal blood and was crowned queen by a council of surviving Lords, even as unknown hardliners seized the capital. She never wanted the throne. She wants her child. Then she woke, inexplicably, here — and every hour away from her baby is agony."
	kira.motivation = "Get back to her child — the throne is a burden she never wanted"
	kira.fear = "That her child's fate, like everything else, will be decided without her — and she'll be powerless to stop it"
	kira.known_connection = ""  # Woke here alone; no prior tie to the party
	kira.dialogue_healthy = [
		"\"I have a child waiting for me. That is reason enough to survive this place.\"",
		"\"They crowned me. They never once asked if I wanted it. I only want my child back.\"",
		"\"Stay close. I have lost one family already — I will not lose another.\"",
	]
	kira.dialogue_stressed = [
		"\"My child is a world away, and I am trapped HERE. I feel every hour of it.\"",
		"\"They killed the king, the queen, my husband — and I still do not know who.\"",
		"\"I keep seeing my child's face in the dark down here. That... cannot be right.\"",
	]
	kira.dialogue_breaking = [
		"\"Is my child even still alive? Would I know? Would I FEEL it if they weren't?\"",
		"*Kira clutches a small locket, whispering a lullaby to no one.*",
		"\"I never chose ANY of this. Not the crown. Not the child. Not this pit. None of it.\"",
	]
	profiles["kira"] = kira

	# ─── 8. MOTH — The Occultist (Summoner) ──────────────────────────
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

	# ─── 12. FINCH — The Escaped Psion (Psion) ──────────────────────
	var finch := CharacterProfile.new()
	finch.id = "finch"
	finch.character_name = "Finch"
	finch.class_name_key = "Psion"
	finch.age = 19
	finch.personality = "Guarded, afraid of herself, desperately wants normalcy"
	finch.backstory = "A test subject from a government shadow program designed to create controllable super-soldiers. They awakened psionic powers in her through years of experimentation. When her abilities surged out of control, she killed everyone — the other subjects, the scientists, the guards. All of them. She didn't mean to. She was 16. Now she's running, hiding in a place so broken that even a government's reach can't follow. The dungeon's interference masks her psychic signature. She's safe here. Safer than anywhere else."
	finch.motivation = "Hide from the people hunting her (and learn to control her power)"
	finch.fear = "Losing control again — killing the people around her"
	finch.known_connection = ""
	finch.dialogue_healthy = [
		"\"It's quiet here. In my head. The dungeon... dampens things. I like it.\"",
		"\"Don't touch me. Please. It's not personal — I just can't always control what happens.\"",
		"\"I didn't ask for this. I didn't ask for any of this.\"",
	]
	finch.dialogue_stressed = [
		"\"I can feel it building. The pressure. Like static behind my eyes.\"",
		"\"If I start bleeding from my nose, you need to get away from me. Fast.\"",
	]
	finch.dialogue_breaking = [
		"*The air around Finch vibrates. Objects lift off the ground.* \"RUN. PLEASE.\"",
		"*Finch grabs her head, screaming.* \"I'M SORRY I'M SORRY I'M SORRY—\"",
	]
	profiles["finch"] = finch

	# ─── 13. GARRETT STONE — The Knight (Knight) ─────────────────
	var garrett := CharacterProfile.new()
	garrett.id = "garrett"
	garrett.character_name = "Garrett Stone"
	garrett.class_name_key = "Knight"
	garrett.age = 52
	garrett.personality = "Honorable but haunted — reformed ambition, quiet self-doubt"
	garrett.backstory = "A disgraced Kingsguard who fled Romera, capital of the Nation of Opportunity — a realm across a short sea to the north of the dungeon. He was framed for treason by a Council he refused to serve, but he isn't blameless: he'd grown too ambitious for his already elevated station, and though he never betrayed the crown, he despises the man that ambition made him. He wonders, constantly, whether his remorse is genuine or just the shape regret takes when you've lost everything. After fleeing, he threw in with a revolutionary force rising against the Nation of Opportunity and became one of the rebel Queen's closest confidants. He came to the dungeon chasing the kidnapped princess — the rebel Queen's own daughter — rumored to have been dragged down into it. No one knows who took her or why. Only that a young blond man with pale green eyes was the last person seen at her side. Garrett swore to his Queen he would bring her daughter home."
	garrett.motivation = "Rescue the kidnapped princess and honor his vow to the rebel Queen"
	garrett.fear = "That his repentance isn't real — that he only regrets his ambition because it cost him everything"
	garrett.known_connection = ""  # Stranger to the party
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
