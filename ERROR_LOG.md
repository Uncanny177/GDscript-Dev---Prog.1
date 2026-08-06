# Error / Issue Log

Record bugs, regressions, and fixes here. Check error_screenshots/ for visual evidence.

## Workflow
When you fix an issue, add a short entry with: Date, Area, Problem, Fix, Status, Notes.

---

## Open Issues
- Untested: Tasks 9-32 not fully tested in Godot 4.7 (built from code, needs runtime verification)
- Screenshots pending from home machine testing session

---

## Fixed Issues

### 2025-07-28 — Player snapping to tile edges (movement broken)
- **Area**: Player movement / dungeon corridors
- **Problem**: Player couldn't move through corridors. Snapped to tile edges (multiples of 32) instead of centers (n*32+16).
- **Fix**: Changed `position.snapped(Vector2(32,32))` to offset-snap formula: `(position - half_tile).snapped(...) + half_tile`
- **Status**: Fixed
- **Notes**: Affected both _ready() and _on_move_finished(). RayCast2D was hitting walls because player was on grid lines.

### 2025-07-28 — Integer division warnings in Godot 4.7
- **Area**: Multiple files (all position calculations)
- **Problem**: `int / 2` triggers "decimal part discarded" warning in 4.7
- **Fix**: Changed position divisions to `/ 2.0`. Left intentional int divisions with comments.
- **Status**: Fixed
- **Notes**: Affected hub_town, test_room_generator, dungeon_renderer, combatant, battle_renderer, floor_generator, item_data.

### 2025-07-28 — stat_bonuses shared reference across all characters
- **Area**: CharacterData / Level System
- **Problem**: `var stat_bonuses: StatBlock = StatBlock.new()` at class level shared one instance across ALL CharacterData. Leveling one character modified all others.
- **Fix**: Changed to `var stat_bonuses: StatBlock = null`, create fresh in `initialize()`.
- **Status**: Fixed
- **Notes**: Critical for XP/leveling system. Always declare Resource/RefCounted as null at class level.

### 2025-07-28 — NPC interaction blocked gamepad input
- **Area**: Hub town NPC interaction
- **Problem**: `if not event is InputEventKey` filtered out joypad events, preventing A button from working.
- **Fix**: Accept both InputEventKey and InputEventJoypadButton, use `Input.is_action_just_pressed("interact")`.
- **Status**: Fixed

### 2025-07-28 — Enemy AI never used skills (only basic attacks)
- **Area**: Combat / TurnManager
- **Problem**: `execute_enemy_turn()` always picked a random target and did basic attack. Enemy skills (with status effects) never fired.
- **Fix**: Added weighted skill selection from `enemy_data.skills`. Enemies now use Fire Spit, Spore Cloud, Hellfire, etc.
- **Status**: Fixed
- **Notes**: Also added `last_enemy_skill` tracking for status effect application.

### 2025-07-28 — Event UI ambush never triggered combat
- **Area**: Dungeon events
- **Problem**: `_close()` always emitted `{"type": ""}` — the result type was never stored.
- **Fix**: Store `_last_result_type` on choice, pass it in signal emission. Dungeon checks for "ambush" and triggers combat.
- **Status**: Fixed

### 2025-07-28 — Dialogue box crash on startup
- **Area**: Hub dialogue system
- **Problem**: `@onready var panel = $PanelContainer` — node doesn't exist (built programmatically).
- **Fix**: Changed to `var panel = null`, build in `_build_ui()`, call before `panel.hide()`.
- **Status**: Fixed
- **Notes**: Pattern: never use @onready for programmatically-built UI.

### 2025-07-28 — ESC re-opens settings immediately after closing
- **Area**: Hub town / Settings menu
- **Problem**: ESC closes settings (sets is_active=false) then propagates to hub_town which sees is_active=false and reopens.
- **Fix**: Added `if SettingsMenu.is_active: return` guard at top of hub's _unhandled_input.
- **Status**: Fixed

### 2025-08-05 — Player respawned at floor entrance after combat
- **Area**: Dungeon progression
- **Problem**: Player position lost on combat scene change → dungeon reload.
- **Fix**: Preserved current floor tile in GameManager, restored on dungeon rebuild.
- **Status**: Fixed (by VS Code agent at home)

---

## Notes / Follow-Up
- Always check for bugs after implementing a feature
- Integer division and shared references are the two most common GDScript 4.7 gotchas
- error_screenshots/ folder available for visual bug reports via git
