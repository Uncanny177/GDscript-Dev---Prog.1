# AGENTS.md

## Project Summary
This repository is a Godot 4.7 2D roguelite RPG prototype written in GDScript.

## Important Workflow
- Keep bug reports and fixes documented in ERROR_LOG.md.
- When a bug is reported, add an entry before changing code if possible.
- When a bug is fixed, update the same entry to reflect the resolution.
- Prefer small, verified changes over large speculative edits.
- Verify changes with workspace diagnostics before claiming success.

## Current Project Goals
- Keep dungeon progression working correctly.
- Preserve player state across floor reloads and combat transitions.
- Keep the project stable for future agent handoffs.

## Key Files
- scenes/dungeon/dungeon.gd
- scripts/managers/game_manager.gd
- scripts/managers/save_manager.gd
- scenes/ui/settings_menu.gd
- scripts/generation/floor_generator.gd

## Notes for Future Agents
- The project uses autoloads for core state.
- Floor progression uses GameManager.current_floor and dungeon_player_positions.
- Save/load state is handled by SaveManager.
- Use ERROR_LOG.md for persistent bug tracking.
- Use README.md for short project notes.
