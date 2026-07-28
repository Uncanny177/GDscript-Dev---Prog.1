# Game Design Document — Roguelite RPG

## Concept

A roguelite RPG with classic RPG Maker aesthetics. The player manages a party of 2-4 characters, explores a persistent hub town that grows across runs, and enters procedurally generated dungeons with turn-based combat. Death resets dungeon progress but preserves meta-currency and permanent unlocks.

## Core Pillars

1. **Satisfying turn-based combat** — Classic menu-driven battles with meaningful tactical choices
2. **Rewarding progression** — Every run contributes to permanent growth (town, classes, abilities)
3. **Procedural variety** — Dungeons feel different each run through room template recombination
4. **Accessible depth** — Easy to pick up, with enough systems to stay interesting

## Game Loop

```
Hub Town → Enter Dungeon → Explore Floors → Combat Encounters → Boss Fight
    ↑                                                                ↓
    ←←←←←←←←←←←← Death OR Victory (meta-progression applied) ←←←←←
```

### Run Structure

- Leave hub town, enter dungeon
- Dungeon has 3-5 procedurally generated floors
- Each floor: explore rooms, fight encounters, find loot/chests
- Final floor: boss encounter
- On death: lose all run-gold and dungeon items, keep meta-currency
- On victory: keep everything + bonus meta-currency
- Return to hub town, spend meta-currency on permanent upgrades

## Combat System

### Style

Classic turn-based, menu-driven (like RPG Maker / early Final Fantasy):

- Party (left side) vs Enemy group (right side)
- Turn order based on SPD stat (initiative)
- Actions: Attack, Skill, Item, Defend

### Stats

- **HP** — Health Points
- **MP** — Magic/Mana Points (for skills)
- **ATK** — Physical attack power
- **DEF** — Physical defense
- **MAG** — Magic attack power
- **RES** — Magic resistance
- **SPD** — Determines turn order

### Damage Formula

- Physical: `ATK * multiplier - DEF` (minimum 1)
- Magical: `MAG * multiplier - RES` (minimum 1)
- Defend: reduce incoming damage by 50% for one turn

### Enemy AI

- Basic enemies: random target selection, weighted skill usage
- Bosses: phase-based behavior (e.g., enrage at low HP, summon minions)

## Party System

### Composition

- Party size: 2-4 active members
- Additional characters stored in reserve (swappable in town)
- Characters recruited at Guild in hub town

### Classes (Initial)

- **Warrior** — High HP/ATK/DEF, low SPD/MAG. Skills: Power Strike, Shield Bash
- **Mage** — High MAG/MP, low HP/DEF. Skills: Fireball (AOE), Heal, Ice Shard
- **Rogue** — High SPD/ATK, low HP/DEF. Skills: Backstab (bonus from speed), Poison Strike

### Equipment

- Slots: Weapon, Armor, Accessory (per character)
- Equipment modifies base stats
- Found in dungeons or purchased in shop

## Hub Town

### Facilities (Unlocked progressively via meta-currency)

- **Shop** — Buy consumables and basic equipment (available from start)
- **Guild** — Recruit new party members / unlock classes
- **Blacksmith** — Upgrade equipment, craft gear from dungeon materials
- **Training Ground** — Unlock new skills for classes

### Town Growth

- Facilities visually appear/upgrade as player invests meta-currency
- Each facility tier provides better services
- Town state persists permanently (saved to disk)

### Open Design Questions

- Exact costs and progression curves for facility upgrades (balance later)
- Whether facilities have multiple tiers or just unlock once
- Additional facilities beyond the four listed

## Dungeon Generation

### Approach: Hybrid

- Hand-crafted room templates (small tilemap scenes)
- Procedural placement algorithm connects rooms into a floor
- Graph-based: rooms = nodes, corridors = edges

### Room Template Types

- Start room (player spawn)
- Dead ends (treasure, ambush)
- Corridors (connectors)
- T-junctions / crossroads
- Large rooms (arena fights, events)
- Boss room (final floor only)
- Exit room (stairs to next floor)

### Generation Algorithm

1. Pick room count for floor (based on floor number / difficulty)
2. Select rooms from template pool (weighted by floor)
3. Build a graph connecting rooms (ensure all reachable)
4. Place rooms in 2D space with corridors
5. Populate with enemies, chests, events based on difficulty

### Extensibility

- New biomes = new tileset + new room templates + new enemy pool
- Architecture supports multiple biomes through Resource swapping
- Initial implementation: one biome (cave/ruins), 3-5 floors

## Economy

### Currencies

- **Gold** (run currency) — Earned from enemies/chests during a run. Lost on death.
- **Meta-crystals** (meta currency) — Earned per run (floor reached + boss bonus). Kept permanently.

### Loot

- Enemies drop from a weighted loot table (items, gold, nothing)
- Chests contain guaranteed loot (equipment, consumables, meta-crystals)
- Boss drops bonus meta-crystals + rare equipment

## Meta-Progression

### Permanent Unlocks

- New character classes (meet conditions + spend meta-crystals at Guild)
- Town facility upgrades (spend meta-crystals)
- New skills for existing classes (Training Ground)
- Better shop inventory tiers
- Blacksmith crafting recipes

### Unlock Conditions (examples)

- Reach floor 3 → unlock Rogue class
- Defeat first boss → unlock Blacksmith
- Recruit 5 characters → unlock Training Ground

## Save System

### What's Saved

- **Meta save** (always): Unlocks, meta-currency, town state, settings
- **Run save** (optional): Current floor, party state, inventory — allows resume

### Implementation

- JSON file via Godot's FileAccess
- Auto-save on return to hub town
- Graceful handling of corrupted saves

## Target First Playable

A complete loop: Hub (with shop + guild) → Dungeon (3 floors, one biome) → Boss → Return with rewards → Spend on unlocks → Next run feels different.

Estimated run length: 10-15 minutes.

---

## Implementation Plan

### Task 1: Project Setup & Player Movement

**Objective:** Set up Godot 4.x project structure and implement grid-based player movement on a tilemap.

**Guidance:**

- Create project with folder structure (scenes/, scripts/, resources/, assets/)
- Create a TileMap with placeholder tiles (colored rectangles)
- Implement CharacterBody2D player with grid-based movement (one tile per input)
- Learn: Scene tree, nodes, TileMap basics, `_input()`, `_physics_process()`, signals

**Tests:** Player moves one tile per input, can't walk through walls, camera follows.

**Demo:** A character moving on a grid map with walls it can't pass through.

---

### Task 2: Scene Management & Game State

**Objective:** Build a GameManager autoload for scene transitions and persistent state.

**Guidance:**

- Create GameManager autoload tracking game state (current scene, run data, meta data)
- Implement scene transitions (hub → dungeon → combat → back)
- Create placeholder scenes for Hub, Dungeon, Combat
- Learn: Autoloads/singletons, scene tree management, Resources, dictionaries

**Tests:** Scene transitions preserve GameManager state. State accessible from any scene.

**Demo:** Walk to dungeon entrance in hub, press interact, transition to dungeon, return.

---

### Task 3: Data Models — Characters, Classes, and Enemies

**Objective:** Define core data structures using Godot's Resource system.

**Guidance:**

- Custom Resources: CharacterData, ClassData, EnemyData, SkillData, ItemData
- Stats: HP, MP, ATK, DEF, MAG, RES, SPD
- Create 2-3 placeholder classes (Warrior, Mage, Rogue) with stat distributions
- Learn: Custom Resources (extends Resource), @export, .tres files, inheritance

**Tests:** Resources load correctly, classes modify base stats properly.

**Demo:** Print party roster to console showing characters with class stats applied.

---

### Task 4: Hub Town — Basic Layout and NPC Interaction

**Objective:** Build hub town with tilemap, walkable areas, and interactable NPCs with dialogue.

**Guidance:**

- Small hub town tilemap with placeholder tiles
- NPC scene (Area2D + Sprite + CollisionShape) with interaction detection
- Dialogue box UI (CanvasLayer + PanelContainer + RichTextLabel)
- Interact key triggers dialogue when near NPC
- Learn: Area2D signals, UI with Control nodes, CanvasLayer, input actions

**Tests:** Player talks to NPCs, dialogue appears/disappears, multiple NPCs with different text.

**Demo:** Walk around town, talk to 2-3 NPCs with different dialogue.

---

### Task 5: Turn-Based Combat — Core Battle System

**Objective:** Implement core combat loop: initiative, Attack action, enemy AI, win/lose.

**Guidance:**

- Combat scene: party left, enemies right (placeholder sprites)
- TurnManager sorts combatants by SPD, cycles turns
- Attack action: select target → ATK - DEF damage
- Enemy AI: attack random party member
- Win: all enemies dead. Lose: all party dead.
- Learn: State machines, await/signals for async flow, UI during gameplay

**Tests:** Turns alternate by speed, damage formula works, battle ends on win/loss.

**Demo:** 2 party members vs 2 enemies, fight to victory or defeat using Attack.

---

### Task 6: Combat UI & Menu System

**Objective:** Build battle menu (Attack/Skill/Item/Defend) with target selection and feedback.

**Guidance:**

- Battle menu with VBoxContainer + Buttons
- Target selection (highlight enemy/ally)
- HP/MP bars for party
- Damage number tweens, Defend action
- Learn: UI navigation, Tween, containers, themes

**Tests:** Menu navigable with keyboard, targets highlight, HP bars update live.

**Demo:** Full battle UI with animated damage numbers and HP changes.

---

### Task 7: Skills and Magic System

**Objective:** Add skills consuming MP with various effects.

**Guidance:**

- SkillData: cost, target type, damage formula, element
- Skill submenu in battle
- 2-3 skills per class (Power Strike, Fireball, Heal, etc.)
- Multi-target and healing implementations
- Learn: Strategy pattern for effects, polymorphism with Resources

**Tests:** Skills consume MP, can't use without MP, AOE hits all targets, healing caps at max HP.

**Demo:** Mage casts Fireball AOE, Warrior uses Power Strike, Mage heals ally.

---

### Task 8: Items and Inventory System

**Objective:** Inventory with consumables usable in combat and overworld.

**Guidance:**

- Inventory class (ItemData → quantity dictionary)
- Item submenu in combat
- Item effects: heal HP, restore MP, cure status
- Inventory UI in pause menu
- Learn: Dictionary management, dynamic UI lists, menu layering

**Tests:** Items consumed on use, effects work, can't use empty items, inventory persists in run.

**Demo:** Use health potion in combat. Open inventory in overworld.

---

### Task 9: Dungeon Generation — Room Template System

**Objective:** Hybrid dungeon generation with hand-crafted rooms placed procedurally.

**Guidance:**

- Room template format (small tilemap scenes with entry/exit points)
- 5-8 templates: start, dead end, corridor, T-junction, large room
- Floor generator: graph-based room placement
- Seeded RNG for reproducibility
- Compose into single TileMap at runtime
- Learn: Procedural generation, scene instancing at runtime, RNG seeding

**Tests:** Floors always connected, different each run, same seed = same floor.

**Demo:** Enter dungeon, see procedurally generated floor from room pieces. Re-enter for different layout.

---

### Task 10: Dungeon Exploration — Movement, Encounters, Floor Progression

**Objective:** Wire up dungeon movement, encounters, floor transitions.

**Guidance:**

- Reuse grid movement in dungeon
- Random encounters (step-based probability)
- Visible encounter triggers (enemy sprites on map)
- Stairs in exit room → next floor
- Floor counter + difficulty scaling
- Learn: Signals for encounters, scene instancing, difficulty scaling

**Tests:** Encounters at reasonable rate, stairs work, difficulty increases per floor.

**Demo:** Explore 3-floor dungeon with encounters, stairs, increasing difficulty.

---

### Task 11: Loot, Rewards, and Economy

**Objective:** Item drops, gold, chests, shop system, dual-currency economy.

**Guidance:**

- LootTable resource (weighted drops per enemy/chest)
- Gold + items on combat victory
- Treasure chests in dungeon rooms
- Shop NPC: buy/sell with gold
- Run-gold (lost on death) vs meta-crystals (permanent)
- Learn: Weighted random, shop UI, dual-currency systems

**Tests:** Drops follow weights, gold tracked correctly, shop works, meta-currency persists after death.

**Demo:** Kill enemies → loot → find chest → buy at shop. Die → lose run-gold, keep meta-crystals.

---

### Task 12: Party Management & Recruitment

**Objective:** Guild recruitment and party management UI.

**Guidance:**

- Guild NPC shows recruitable characters
- Party management screen (view all, select active 2-4)
- Equipment system (weapon, armor, accessory per character)
- Unlocked classes appear as recruitable
- Learn: Complex UI with tabs, data binding, observer pattern

**Tests:** Recruit characters, swap party, equipment modifies stats, party limit enforced.

**Demo:** Visit guild, recruit Mage, equip staff, swap party, see stats update.

---

### Task 13: Meta-Progression — Unlocks and Town Growth

**Objective:** Meta-currency spending for class unlocks and town facility upgrades.

**Guidance:**

- Unlocks manager (tracking state)
- Meta-crystal spending at Town Hall NPC
- Town upgrades unlock shop tiers, blacksmith, training ground
- Class unlocks (conditions + currency)
- Visual town changes (tile/sprite swaps)
- Learn: Persistent state, conditional content, progression design

**Tests:** Meta-currency accumulates, spending unlocks correctly, content appears next run, visuals update.

**Demo:** Earn meta-crystals, unlock Blacksmith, see it appear in town next run.

---

### Task 14: Save/Load System

**Objective:** Persistent saves for meta-progression and optional mid-run resume.

**Guidance:**

- FileAccess + JSON serialization
- Meta save: unlocks, currency, town state, settings
- Run save: current floor, party, inventory (for resume)
- Auto-save on town return
- Learn: File I/O, JSON serialization, error handling for corrupted data

**Tests:** Quit/reload preserves everything, mid-run save works, corrupted save doesn't crash.

**Demo:** Play, unlock, close game, reopen — preserved. Save mid-dungeon, reload, continue.

---

### Task 15: Boss Fights & Run Completion

**Objective:** Boss encounter on final floor, victory path, and balance pass.

**Guidance:**

- BossData resource (special abilities, phases)
- Boss room on final floor (special template)
- 2-phase boss (enrage at low HP or summon minions)
- Victory screen with bonus rewards
- Balance: tune for satisfying 10-15 minute runs
- Learn: Complex AI state machines, balancing, game feel

**Tests:** Boss spawns correctly, uses special abilities, victory triggers rewards, full loop completable.

**Demo:** Complete full game loop — town → 3 floors → boss → victory → upgrades → harder next run.
