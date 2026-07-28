# Project Steering — Roguelite RPG

## Overview

A roguelite RPG Maker-style game built in Godot 4.x with GDScript. Top-down 2D, tile-based, with a persistent hub town, procedurally generated dungeons, and classic turn-based combat.

## Tech Stack

- Language: GDScript (Godot 4.x / GDScript 2.0)
- Engine: Godot 4.x (latest stable)
- Assets: Placeholder (colored shapes/rectangles) until art pass
- Target platform: Desktop (Windows/Linux/Mac)

## Code Style

- Follow GDScript style guide: snake_case for functions/variables, PascalCase for classes/nodes
- Use static type hints everywhere (`var health: int = 100`, `func take_damage(amount: int) -> void:`)
- Prefer composition over inheritance — use child nodes and Resources for behavior
- Keep scripts focused: one responsibility per script
- Use signals for decoupled communication between systems
- Add comments explaining the *why*, not the *what*
- Use `@export` for designer-tunable values
- Prefer early returns and guard clauses over deep nesting

## File & Folder Conventions

- Group by feature domain:

```
project/
├── scenes/        (hub/, dungeon/, combat/, ui/)
├── scripts/       (managers/, data/, combat/, generation/)
├── resources/     (classes/, enemies/, items/, skills/, loot_tables/)
├── assets/        (sprites/, tilesets/, audio/)
└── addons/        (if needed later)
```

- Scene files: `snake_case.tscn`
- Script files: `snake_case.gd`
- Resource files: `snake_case.tres`
- Keep scenes and their scripts co-located or in matching folder structures

## Architecture Patterns

- **Autoloads** for global managers: GameManager, AudioManager, SaveManager
- **Resources** (`.tres`) for all data definitions: characters, enemies, items, skills, loot tables
- **State machines** for complex behavior (combat flow, enemy AI, game states)
- **Signals** for event-driven communication between decoupled systems
- **Scene composition** — small reusable scenes composed into larger ones

## Error Handling

- Use `assert()` during development for invariant checks
- Use `push_error()` / `push_warning()` for runtime issues
- Never silently swallow errors — at minimum log them
- Graceful fallback for save file loading (corrupted data shouldn't crash)

## Testing

- Test by playing — each task produces a demoable increment
- Use `print()` debugging and Godot's built-in debugger/profiler
- Consider GUT (Godot Unit Test) addon for core systems (damage formulas, generation)
- Verify procedural generation with fixed seeds for reproducibility

## Git & Commits

- Commits should be atomic: one logical change per commit
- Commit messages: imperative mood, present tense
- Branch naming: `feature/<short-description>`, `fix/<short-description>`
- Never commit `.godot/` cache files (add to .gitignore)
- Commit `.tres` and `.tscn` files (they are project content)

## Performance

- Profile before optimizing — use Godot's built-in profiler
- Keep `_process()` and `_physics_process()` lightweight
- Use object pooling for frequently spawned/despawned nodes (projectiles, effects)
- Preload resources (`@onready`, `preload()`) rather than loading at runtime in hot paths

## Learning Notes

- Developer is new to Godot but has Python/C++ background
- GDScript syntax is very similar to Python — leverage that familiarity
- Each task should teach a new Godot concept progressively
- Explain *why* we use specific patterns, not just *how*
