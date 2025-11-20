extends CanvasLayer

@onready var transition_label = $TransitionLabel
@onready var vid_loading = $VidLoading

func _ready() -> void:
	visible = false
	vid_loading.visible = false
	vid_loading.autoplay = false
	transition_label.visible = false

	# Connect GameManager signals
	GameManager.map_updated.connect(_on_map_changed)
	GameManager.game_loaded.connect(_on_game_loaded)
	GameManager.game_reset.connect(_on_game_reset)

	# ✅ Sync video audio with background volume
	if SoundSystem:
		SoundSystem.background_volume_changed.connect(_on_background_volume_changed)
		vid_loading.volume_db = linear_to_db(SoundSystem.background_volume)

# --- MAIN TRANSITION ---
func play_video_transition(func_to_call: Callable, wait_time: float = 5.0) -> void:
	if SoundSystem:
		SoundSystem.set_loading(true) # Pause background music

	show()
	vid_loading.visible = true

	# 🎧 Make sure the video sound matches BGM volume
	vid_loading.volume_db = linear_to_db(SoundSystem.background_volume)
	vid_loading.play()

	transition_label.visible = true

	var tween = get_tree().create_tween()
	tween.tween_interval(wait_time)
	tween.tween_callback(func_to_call)
	tween.tween_callback(_on_transition_complete)

# --- VOLUME SYNC HANDLER ---
func _on_background_volume_changed(new_volume: float) -> void:
	if vid_loading:
		vid_loading.volume_db = linear_to_db(new_volume)

# --- TRANSITION COMPLETE ---
func _on_transition_complete() -> void:
	if SoundSystem:
		SoundSystem.set_loading(false) # Resume background music

	vid_loading.stop()
	vid_loading.visible = false
	hide()

# --- GAME MANAGER HOOKS ---
func _on_map_changed(new_map_path: String, new_spawn_marker: String) -> void:
	set_transition_message("Entering: %s" % _get_readable_map_name(new_map_path))
	play_video_transition(_on_transition_complete)

func _on_game_loaded() -> void:
	set_transition_message("Entering: %s" % _get_readable_map_name(GameManager.current_map_path))
	play_video_transition(_on_transition_complete)

func _on_game_reset():
	match GameManager.last_reset_reason:
		GameManager.ResetReason.DEATH:
			set_transition_message("You Died!!")
		GameManager.ResetReason.QUIT:
			set_transition_message("Goodbye!")
		GameManager.ResetReason.MISSION_COMPLETE:
			set_transition_message("Mission Complete!")
		_:
			set_transition_message("")
	play_video_transition(_on_transition_complete)

# --- LABEL HANDLING ---
func set_transition_message(message: String) -> void:
	transition_label.text = message
	transition_label.visible = message != ""

# --- MAP NAME HELPER ---
func _get_readable_map_name(map_path: String) -> String:
	match map_path:
		GameManager.first_floor_map:
			return "First-Floor"
		GameManager.second_floor_underground_map:
			return "Second-Floor-Underground"
		GameManager.third_floor_underground_map:
			return "Third-Floor-Underground"
		_:
			return "Unknown Area"
