# AGENTS.md — Cross-Agent Knowledge Base

## Project Summary
Godot 4.7 2D roguelite RPG prototype in GDScript. Turn-based combat, procedural dungeons, hub town with meta-progression. 32 tasks completed.

## Important Workflow
- Keep bug reports and fixes documented in ERROR_LOG.md
- When a bug is reported, add an entry before changing code
- When a bug is fixed, update the same entry to reflect resolution
- Prefer small, verified changes over large speculative edits
- Check for bugs after every feature implementation
- Push to GitHub after confirming no bugs

## Architecture Overview

### Autoloads (load order matters)
1. GameManager — Game state, scene transitions, run management
2. UnlocksManager — Permanent progression (facility tiers, milestones)
3. SaveManager — JSON file I/O (meta_save.json, run_save.json, settings.json, stats.json)
4. ClassDatabase — Character class definitions (Warrior, Mage, Rogue, Paladin, Archer, Necromancer)
5. EnemyDatabase — Enemy definitions (12 enemies, 3 tiers)
6. BossDatabase — Boss definitions (Goblin King floor 3, Shadow Lord floor 5)
7. EventDatabase — Dungeon event encounters (6 events)
8. BiomeDatabase — Biome color palettes (Cave, Crypt, Inferno)
9. ItemDatabase — Item definitions (consumables + equipment)
10. PartyManager — Party roster (active + reserve)
11. SettingsMenu — Settings UI (volume, resolution, fullscreen)
12. StatsTracker — Run history and lifetime stats
13. TransitionManager — Fade in/out screen transitions
14. AudioManager — SFX pool + music crossfade (waiting for audio files)
15. StatsScreen — Stats display UI

### Key Patterns
- Player movement: grid-based, RayCast2D for wall detection, Tween for smooth slide
- Dungeon generation: room templates (ASCII) → FloorGenerator (random walk) → DungeonRenderer (_draw)
- Combat: TurnManager (SPD order) + Combatant (adapter) + DamageCalculator (pure functions)
- UI overlays: CanvasLayer scripts built programmatically (no .tscn for menus)
- NPC interaction: proximity-based detection + metadata on Area2D nodes
- Movement blocking: check is_active on all UI overlays before allowing input

### Common Bugs to Watch For
- **Integer division warning**: Use `/ 2.0` for Vector2 positions, `/ 2` only for intentional int
- **Shared reference types**: Never initialize Resource/RefCounted at class level (use null + init in _ready/initialize)
- **Scene file UIDs**: Godot 4.7 generates .uid files automatically. Don't write fake UIDs.
- **Autoload order**: GameManager loads first. Others may depend on it during _ready. Use `await get_tree().process_frame` if needed.
- **Input event filtering**: Always accept both InputEventKey AND InputEventJoypadButton in _unhandled_input
- **Tile snapping**: Player snaps to tile CENTERS (n*32+16), not edges (n*32)
- **Double-trigger prevention**: Use `transitioning` flag for scene changes, `is_active` for UI overlays

### File Locations
```
scenes/
  hub/ — hub_town.gd, npc_interaction.gd, dialogue_box.gd, shop_ui.gd, guild_ui.gd, town_hall_ui.gd
  dungeon/ — dungeon.gd, dungeon.tscn, event_ui.gd
  combat/ — combat.gd, combat.tscn
  player/ — player.gd, player.tscn
  ui/ — title_screen.gd/tscn, settings_menu.gd, stats_screen.gd
scripts/
  managers/ — game_manager, save_manager, unlocks_manager, stats_tracker, transition_manager, audio_manager
  data/ — character_data, class_data, class_database, enemy_data, enemy_database, boss_data, boss_database, item_data, item_database, inventory, loot_table, shop_data, skill_data, stat_block, level_system, biome_data, biome_database, dungeon_event, event_database
  combat/ — turn_manager, combatant, boss_combatant, damage_calculator, battle_renderer, combat_effects, status_effect, status_manager, element_system
  generation/ — floor_generator, room_template, room_templates_data, dungeon_renderer, minimap, minimap_draw
```

### Task History
Tasks 1-15: Core game (movement, scenes, data, hub, combat, skills, items, dungeon gen, loot, party, unlocks, save, bosses)
Task 16: Settings Menu
Task 17: Title Screen
Task 18: Run History / Stats
Task 19: Resolution Options
Task 20: Status Effects
Task 21: Event Rooms
Task 22: New Classes (Paladin, Archer, Necromancer)
Task 23: Biomes + Enemy Variety
Task 24: XP/Leveling System
Task 25: Screen Transitions
Task 26: Audio System (no files yet)
Task 27: Combat Visual Effects
Task 28: Minimap
Task 29: TileMap (skipped — needs art)
Task 30: Gamepad Support
Task 31: Pixel Art (skipped — needs art tools)
Task 32: Elemental Weakness System

## Notes for Future Agents
- The project uses autoloads for ALL core state
- Floor progression uses GameManager.current_floor
- Save/load handled by SaveManager (user:// path)
- Player is spawned from code (not in .tscn) via load() + instantiate()
- Combat menus still use keyboard number keys (1-5) — no gamepad menu nav yet
- Audio system is built but has no audio files (silent until .ogg dropped in)
- error_screenshots/ folder for cross-device debugging via git
