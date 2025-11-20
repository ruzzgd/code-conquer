extends Node

signal background_volume_changed(new_volume: float)
signal player_volume_changed(new_volume: float)
signal mob_volume_changed(new_volume: float)

var background_volume := 1.0
var player_volume := 1.0
var mob_volume := 1.0

var is_loading := false  # 🚫 Prevents music during loading

const SOUND_SETTINGS_PATH := "user://code_conquer_saves_gameplay/sound_settings.save"

# 🎧 Players
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

# 🔊 Preload SFX
const DOOR_OPEN_SOUND = preload("res://assets/sounds/door_open_sound.ogg")
const DOOR_CLOSE_SOUND = preload("res://assets/sounds/door_close_sound.ogg")
const CHEST_OPEN_SOUND = preload("res://assets/sounds/chest_open.ogg")

# 🎵 Paths for BGM
const MENU_BGM = "res://assets/music/menu_bg_music.ogg"
const MAP_BGMS = {
	"res://scenes/maps/first-floor-map.tscn": "res://assets/music/first_floor_theme.ogg",
	"res://scenes/maps/second-floor-underground-map.tscn": "res://assets/music/second_floor_theme.ogg",
	"res://scenes/maps/third-floor-underground-map.tscn": "res://assets/music/third_floor_theme.ogg"
}

func _ready():
	load_sound_settings()

	# Create players
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.bus = "Master"
	sfx_player.volume_db = linear_to_db(player_volume)

	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.bus = "Music"
	bgm_player.autoplay = false
	bgm_player.volume_db = linear_to_db(background_volume)

	# Volume sync
	player_volume_changed.connect(func(vol):
		sfx_player.volume_db = linear_to_db(vol)
	)
	background_volume_changed.connect(func(vol):
		bgm_player.volume_db = linear_to_db(vol)
	)

	# Listen to GameManager
	GameManager.is_game_start.connect(_on_game_start)
	GameManager.map_transitioning_changed.connect(_on_transition_changed)

	# Start menu music if game not started and not loading
	if not GameManager.is_game_started and not is_loading:
		_play_bgm(MENU_BGM)

# ----------------------------
# 🚪 Loading / Transition Handling
# ----------------------------
func _on_transition_changed(is_transitioning: bool):
	is_loading = is_transitioning  # ✅ Track loading state
	if is_transitioning:
		if bgm_player.playing:
			bgm_player.stop()
	else:
		# Transition ended — now safe to start music
		if GameManager.is_game_started:
			_play_bgm_for_map(GameManager.current_map_path)
		else:
			_play_bgm(MENU_BGM)

func _on_game_start(started: bool):
	if not started and not is_loading:
		_play_bgm(MENU_BGM)

# ----------------------------
# 🎵 Music Helpers
# ----------------------------
func _play_bgm_for_map(map_path: String):
	if MAP_BGMS.has(map_path):
		_play_bgm(MAP_BGMS[map_path])
	else:
		_play_bgm(MENU_BGM)

func _play_bgm(music_path: String):
	if is_loading:
		print("⏸ Not playing BGM — still loading")
		return
	if ResourceLoader.exists(music_path):
		var stream = load(music_path)
		if stream is AudioStream:
			stream.loop = true  # 🔁 Enable looping
		bgm_player.stop()
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(background_volume)
		bgm_player.play()
		print("🎵 Playing BGM:", music_path)
	else:
		push_warning("BGM file not found: " + music_path)

# ----------------------------
# 🎚 Volume Controls
# ----------------------------
func set_background_volume(value: float):
	background_volume = clamp(value, 0.0, 1.0)
	save_sound_settings()
	emit_signal("background_volume_changed", background_volume)

func set_player_volume(value: float):
	player_volume = clamp(value, 0.0, 1.0)
	save_sound_settings()
	emit_signal("player_volume_changed", player_volume)

func set_mob_volume(value: float):
	mob_volume = clamp(value, 0.0, 1.0)
	save_sound_settings()
	emit_signal("mob_volume_changed", mob_volume)


# ----------------------------
# 💾 Save / Load Helpers
# ----------------------------
func ensure_save_folder_exists() -> bool:
	var folder_path = "user://code_conquer_saves_gameplay"
	var dir = DirAccess.open(folder_path)
	if dir == null:
		var base_dir = DirAccess.open("user://")
		if base_dir == null:
			push_error("Cannot open user:// folder")
			return false
		var err = base_dir.make_dir_recursive("code_conquer_saves_gameplay")
		if err != OK:
			push_error("Failed to create save folder: " + folder_path)
			return false
		return true
	return true

func save_sound_settings():
	if not ensure_save_folder_exists():
		print("❌ Cannot save sound settings because folder doesn't exist and can't be created.")
		return

	var data := {
		"bg_volume": background_volume,
		"sfx_volume": player_volume
	}
	var file = FileAccess.open(SOUND_SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_sound_settings():
	if not ensure_save_folder_exists():
		print("⚠️ Save folder missing on load, skipping sound settings load.")
		return

	if FileAccess.file_exists(SOUND_SETTINGS_PATH):
		var file = FileAccess.open(SOUND_SETTINGS_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data.has("bg_volume"):
				background_volume = data["bg_volume"]
			if data.has("sfx_volume"):
				player_volume = data["sfx_volume"]
				mob_volume = data["sfx_volume"]


# ----------------------------
# 🔊 Play SFX
# ----------------------------
func play_door_open():
	_play_sfx(DOOR_OPEN_SOUND)

func play_door_close():
	_play_sfx(DOOR_CLOSE_SOUND)

func play_open_chest():
	_play_sfx(CHEST_OPEN_SOUND)

func _play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.volume_db = linear_to_db(player_volume)
	sfx_player.play()


# ----------------------------
# ⚔ Dynamic Music Control
# ----------------------------
func lower_bgm_for_fight():
	bgm_player.volume_db = linear_to_db(background_volume * 0.5)

func restore_bgm_after_fight():
	bgm_player.volume_db = linear_to_db(background_volume)
	
func set_loading(value: bool):
	is_loading = value
	if is_loading:
		if bgm_player.playing:
			bgm_player.stop()
	else:
		# Resume music based on current game state
		if GameManager.is_game_started:
			_play_bgm_for_map(GameManager.current_map_path)
		else:
			_play_bgm(MENU_BGM)
