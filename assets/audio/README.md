# Audio Assets

Drop audio files here. The AudioManager will automatically find and play them.

## Required SFX (place in sfx/ folder as .ogg or .wav):

### Combat
- attack_hit.ogg — Physical attack lands
- attack_miss.ogg — Attack misses/blocked
- skill_cast.ogg — Magic skill used
- heal.ogg — Healing sound
- enemy_hit.ogg — Enemy takes damage
- enemy_die.ogg — Enemy defeated
- player_hit.ogg — Player takes damage
- player_die.ogg — Party member dies
- defend.ogg — Defend stance activated
- level_up.ogg — Character levels up
- victory.ogg — Battle won fanfare
- defeat.ogg — Party wiped

### UI
- menu_select.ogg — Move cursor in menu
- menu_confirm.ogg — Confirm selection
- menu_cancel.ogg — Back/cancel
- menu_move.ogg — Navigate options

### Dungeon
- chest_open.ogg — Opening a chest
- footstep.ogg — Player movement step
- encounter.ogg — Random encounter triggers
- stairs.ogg — Going to next floor

### Hub
- shop_buy.ogg — Purchase item
- shop_sell.ogg — Sell item
- equip.ogg — Equip gear

## Required Music (place in music/ folder as .ogg):

- title.ogg — Title screen (calm, mysterious)
- hub.ogg — Hub town (warm, peaceful)
- dungeon_cave.ogg — Cave floors 1-2 (dark, ambient)
- dungeon_crypt.ogg — Crypt floors 3-4 (eerie, cold)
- dungeon_inferno.ogg — Inferno floor 5 (intense, hot)
- combat.ogg — Normal battle (energetic)
- boss.ogg — Boss battle (epic, dramatic)
- victory.ogg — Victory fanfare (triumphant, short)
- defeat.ogg — Defeat theme (somber, short)

## Tips
- Use .ogg format (smaller, loops well)
- Keep SFX short (0.2-2 seconds)
- Music should loop seamlessly (set loop flag in Godot import settings)
- Aim for 44100 Hz sample rate
