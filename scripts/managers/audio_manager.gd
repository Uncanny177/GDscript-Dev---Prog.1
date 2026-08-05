## AudioManager — Centralized audio playback for music and SFX.
##
## HOW TO USE:
##   AudioManager.play_sfx("attack_hit")
##   AudioManager.play_music("dungeon")
##   AudioManager.stop_music()
##
## HOW TO ADD SOUNDS:
## 1. Drop .ogg or .wav files into res://assets/audio/sfx/ or res://assets/audio/music/
## 2. Add the filename (without extension) to the SFX_PATHS or MUSIC_PATHS dictionaries below
## 3. That's it — the system handles loading, playing, and volume.
##
## AUDIO BUS LAYOUT (set up in project settings or default_bus_layout.tres):
##   Master → Music (for background tracks)
##   Master → SFX (for sound effects)
##
## For now we use the default "Master" bus for everything until separate
## buses are configured in the Godot editor.

extends Node

## ─── SFX DEFINITIONS ────────────────────────────────────────────
## Map of sound_name → file path. Add entries here as you add audio files.
## The system will try to load these on first use and cache them.

const SFX_PATHS: Dictionary = {
	# Combat
	"attack_hit": "res://assets/audio/sfx/attack_hit.ogg",
	"attack_miss": "res://assets/audio/sfx/attack_miss.ogg",
	"skill_cast": "res://assets/audio/sfx/skill_cast.ogg",
	"heal": "res://assets/audio/sfx/heal.ogg",
	"enemy_hit": "res://assets/audio/sfx/enemy_hit.ogg",
	"enemy_die": "res://assets/audio/sfx/enemy_die.ogg",
	"player_hit": "res://assets/audio/sfx/player_hit.ogg",
	"player_die": "res://assets/audio/sfx/player_die.ogg",
	"defend": "res://assets/audio/sfx/defend.ogg",
	"level_up": "res://assets/audio/sfx/level_up.ogg",
	"victory": "res://assets/audio/sfx/victory.ogg",
	"defeat": "res://assets/audio/sfx/defeat.ogg",
	# UI
	"menu_select": "res://assets/audio/sfx/menu_select.ogg",
	"menu_confirm": "res://assets/audio/sfx/menu_confirm.ogg",
	"menu_cancel": "res://assets/audio/sfx/menu_cancel.ogg",
	"menu_move": "res://assets/audio/sfx/menu_move.ogg",
	# Dungeon
	"chest_open": "res://assets/audio/sfx/chest_open.ogg",
	"footstep": "res://assets/audio/sfx/footstep.ogg",
	"encounter": "res://assets/audio/sfx/encounter.ogg",
	"stairs": "res://assets/audio/sfx/stairs.ogg",
	# Hub
	"shop_buy": "res://assets/audio/sfx/shop_buy.ogg",
	"shop_sell": "res://assets/audio/sfx/shop_sell.ogg",
	"equip": "res://assets/audio/sfx/equip.ogg",
}

## ─── MUSIC DEFINITIONS ──────────────────────────────────────────
const MUSIC_PATHS: Dictionary = {
	"title": "res://assets/audio/music/title.ogg",
	"hub": "res://assets/audio/music/hub.ogg",
	"dungeon_cave": "res://assets/audio/music/dungeon_cave.ogg",
	"dungeon_crypt": "res://assets/audio/music/dungeon_crypt.ogg",
	"dungeon_inferno": "res://assets/audio/music/dungeon_inferno.ogg",
	"combat": "res://assets/audio/music/combat.ogg",
	"boss": "res://assets/audio/music/boss.ogg",
	"victory": "res://assets/audio/music/victory.ogg",
	"defeat": "res://assets/audio/music/defeat.ogg",
}

## ─── INTERNAL STATE ─────────────────────────────────────────────

## SFX player pool (reuse AudioStreamPlayer nodes for performance)
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8

## Music player (one at a time, with crossfade support)
var music_player: AudioStreamPlayer = null
var music_fade_player: AudioStreamPlayer = null  # For crossfading
var current_music: String = ""

## Cache for loaded audio streams
var sfx_cache: Dictionary = {}  # name → AudioStream


func _ready() -> void:
	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%d" % i
		player.bus = "Master"  # Change to "SFX" when bus exists
		add_child(player)
		sfx_players.append(player)
	
	# Create music players
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"  # Change to "Music" when bus exists
	add_child(music_player)
	
	music_fade_player = AudioStreamPlayer.new()
	music_fade_player.name = "MusicFadePlayer"
	music_fade_player.bus = "Master"
	add_child(music_fade_player)
	
	print("[AudioManager] Initialized — %d SFX slots, music ready" % SFX_POOL_SIZE)


## ─── SFX PLAYBACK ──────────────────────────────────────────────

func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	## Play a sound effect by name. Fails silently if file doesn't exist.
	if not SFX_PATHS.has(sound_name):
		return  # Unknown sound — skip silently
	
	var stream: AudioStream = _get_or_load_sfx(sound_name)
	if not stream:
		return  # File doesn't exist yet — skip silently
	
	# Find an available player from the pool
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.play()


func _get_or_load_sfx(sound_name: String) -> AudioStream:
	## Load and cache an SFX stream. Returns null if file doesn't exist.
	if sfx_cache.has(sound_name):
		return sfx_cache[sound_name]
	
	var path: String = SFX_PATHS[sound_name]
	if not ResourceLoader.exists(path):
		return null  # File not added yet — that's okay
	
	var stream: AudioStream = load(path)
	if stream:
		sfx_cache[sound_name] = stream
	return stream


func _get_free_sfx_player() -> AudioStreamPlayer:
	## Find a player that isn't currently playing. Returns null if all busy.
	for player in sfx_players:
		if not player.playing:
			return player
	# All busy — reuse the first one (oldest sound gets cut)
	return sfx_players[0]


## ─── MUSIC PLAYBACK ─────────────────────────────────────────────

func play_music(track_name: String, crossfade_duration: float = 1.0) -> void:
	## Play a music track. Crossfades from current track if one is playing.
	## Does nothing if the requested track is already playing.
	if track_name == current_music:
		return  # Already playing this
	
	if not MUSIC_PATHS.has(track_name):
		return  # Unknown track
	
	var path: String = MUSIC_PATHS[track_name]
	if not ResourceLoader.exists(path):
		print("[AudioManager] Music file not found: %s (add later)" % path)
		return
	
	var stream: AudioStream = load(path)
	if not stream:
		return
	
	current_music = track_name
	
	if music_player.playing:
		# Crossfade: fade out current, fade in new
		_crossfade(stream, crossfade_duration)
	else:
		# Nothing playing — just start
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()


func stop_music(fade_duration: float = 0.5) -> void:
	## Fade out and stop current music.
	if not music_player.playing:
		return
	
	current_music = ""
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, fade_duration)
	tween.tween_callback(music_player.stop)


func _crossfade(new_stream: AudioStream, duration: float) -> void:
	## Crossfade: fade out music_player, play new on music_fade_player, then swap.
	
	# Start new track on fade player at low volume
	music_fade_player.stream = new_stream
	music_fade_player.volume_db = -40.0
	music_fade_player.play()
	
	# Fade out old, fade in new
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(music_player, "volume_db", -40.0, duration)
	tween.tween_property(music_fade_player, "volume_db", 0.0, duration)
	tween.chain().tween_callback(_swap_music_players)


func _swap_music_players() -> void:
	## After crossfade, stop old player and swap references.
	music_player.stop()
	# Swap the players
	var temp: AudioStreamPlayer = music_player
	music_player = music_fade_player
	music_fade_player = temp


## ─── SCENE-BASED MUSIC ──────────────────────────────────────────

func play_music_for_scene(scene_name: String) -> void:
	## Convenience: play the appropriate music for a given scene/context.
	match scene_name:
		"title_screen": play_music("title")
		"hub": play_music("hub")
		"dungeon":
			# Pick dungeon track based on floor biome
			match GameManager.current_floor:
				1, 2: play_music("dungeon_cave")
				3, 4: play_music("dungeon_crypt")
				_: play_music("dungeon_inferno")
		"combat": play_music("combat")
		"boss": play_music("boss")
		"victory": play_music("victory", 0.3)
		"defeat": play_music("defeat", 0.3)
