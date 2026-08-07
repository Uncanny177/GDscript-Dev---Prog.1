# Story Outline (Work in Progress)

## Tone & Theme
- Horror mystery / cosmic horror / eldritch
- Elder gods (12-god pantheon, Cthulhu-inspired)
- Psychological + existential dread, some body horror
- Spooky, unsettling atmosphere — player should feel VULNERABLE
- Power grows over runs but always at a cost
- Some humor to break tension (dark comedy, gallows humor from NPCs)
- Not relentless — pacing between dread and relief

---

## Core Concept
- A dungeon that shouldn't exist, built by unknown forces
- 12 party members arrive for different personal reasons (mostly strangers)
- They must cooperate to survive
- Knowledge IS the progression — learning enemy patterns, finding spells, reading forbidden texts
- The deeper you go, the more you understand... and the more it costs you

---

## Stats System
- **HP** — Health (traditional, you die at 0)
- **MP** — Magic/Mana (for spells and rituals)
- **Sanity** — Mental health (new stat)
  - Drops from: witnessing horror, elder god encounters, using forbidden knowledge, certain enemies
  - At low sanity: hallucinations? Wrong information? Characters act on their own?
  - At zero: character goes permanently insane (removed from party? Becomes hostile?)
  - Recovers at: safe zones, certain items, rest, companion interactions

---

## Characters (12 total)
- Fixed personalities and backstories
- Mostly strangers — maybe 2-3 pairs know each other
- Each at the dungeon for a different personal reason:
  - (TBD: revenge, curiosity, duty, greed, running from something, summoned, scholar seeking knowledge, hired mercenary, lost family member, religious zealot, thief who stole the wrong thing, etc.)
- **Permadeath** — characters CAN die permanently
- **Insanity** — characters can go permanently insane (lost to madness)
- Party composition matters more since losses are permanent
- Relationships develop through safe zone conversations

---

## The Dungeon
- Not naturally formed — BUILT by something, but it grows and changes
- Forces inside can control/alter their surroundings (seems alive but isn't traditionally)
- Impossible environments (non-euclidean, gravity shifts, rooms that shouldn't connect)
- Each "zone" could be the domain/influence of a specific elder god
- Format TBD: procedural generation vs hand-crafted sections that shuffle
  - Leaning toward: set map SECTIONS that rearrange (quality + variety)
  - Some areas fixed (key story locations), some randomized

### Safe Zones
- Areas within the dungeon for respite
- Talk to party members (develop relationships, reveal backstory)
- Talk to NPCs (other trapped explorers, mad scholars, mysterious figures)
- Rest to recover sanity/HP
- "Sudo-safe" zones — mostly safe but something feels off

---

## Elder God Pantheon (12 Gods)
- Each god has a domain/theme (TBD: decay, hunger, time, flesh, void, eyes, etc.)
- Gods are mostly NOT interested in the party directly
- They have their own designs — their agents/servants interact with the party
- Some bosses are the gods themselves (or avatars/stand-ins)
- Gods conflict with each other (can be exploited?)

### Calling on the Gods
- Players can learn rituals/rites associated with specific gods
- Performing rites at altars grants power at a COST
  - Cost could be: sanity, HP, party member corruption, permanent changes
- Risk/reward: elder god powers are strong but erode your party

---

## Enemies
- Every enemy is meaningful — mini-boss feel, NOT cannon fodder
- Each enemy has weaknesses and a "solution" to discover
- First encounter is hard (you're learning the pattern)
- Once you know the solution, they become manageable
- Each enemy connected to a specific elder god from the pantheon
- Enemy design should feel WRONG (not just "goblin with a sword")

### Knowledge-Based Progression
- Learn enemy weaknesses through:
  - Fighting them (trial and error)
  - Finding journals/books in the dungeon
  - NPC information
  - Performing research at safe zones
- Once learned, weaknesses are permanent knowledge (carries across runs/attempts)
- Bestiary/Journal fills in as you discover things

---

## Spells & Knowledge
- Find spell books/journals in the dungeon
- Learn rituals from altars, NPCs, or boss encounters
- Some knowledge has a sanity cost to learn
- Spells can be powerful but tied to specific gods (using them pleases/angers gods)
- Forbidden knowledge: learn the truth about the dungeon itself?

---

## Moral Choices
- Accept a god's gift (power but corruption/sanity loss)
- Save or sacrifice NPCs/party members
- Share dangerous knowledge or keep it hidden
- Perform dark rituals for advantage vs staying "pure"
- These choices affect which ending you get

---

## Endings (Multiple, TBD)
- Ideas to explore:
  - Escape the dungeon (but at what cost? Who's left?)
  - Embrace an elder god (become their champion/vessel)
  - Destroy the dungeon (seal it? Collapse it?)
  - Become something new (ascend? Transcend?)
  - Fail / trapped forever
- Ending depends on: choices made, gods appeased/angered, party survival, sanity state

---

## Game Structure Questions (Still Deciding)
- Roguelite (short runs, meta-progression) vs Traditional RPG (longer, limited saves)?
- Hybrid possible: longer runs, knowledge carries between attempts, limited saves add tension
- Current systems can support either — the switch is mostly about run length and save frequency
- "Information gathering" as the core meta-progression fits both models
- Permadeath + insanity add consequence regardless of format

---

## Atmosphere & Presentation
- Environmental storytelling (inscriptions, murals, remnants of previous explorers who failed)
- The dungeon reacts to your progress (things change, things remember you)
- NPCs inside range from helpful to clearly broken to suspiciously calm
- Audio: whispers, distant wrong sounds, silence where there shouldn't be silence
- Visual: pixel art but with unsettling elements (things in the background, eyes, movement at edges)
- Safe zones feel different — warm light, calm music — the contrast makes horror STRONGER

---

## Implementation Notes
- Sanity system: new stat on CharacterData (like HP/MP), tracked and saved
- Permadeath: character removed from all rosters on death (not just "fainted")
- Bestiary: new data structure tracking enemy knowledge (unlocks weakness info)
- Rituals: like skills but with sanity/HP cost instead of MP
- Altars: new dungeon interactive (like events but specifically for god interaction)
- Safe zones: new room type in generation (no enemies, special interactions)
- 12 party members: expand CharacterData definitions, each with unique backstory
- 12 gods: new data structure defining domains, servants, rites, effects
