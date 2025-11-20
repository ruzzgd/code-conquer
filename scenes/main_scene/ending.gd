extends CanvasLayer

@onready var red_overlay: ColorRect = $RedOverlay
@onready var warning_label: Label = $WarningLabel
@onready var stuck_label: Label = $StuckLabel
@onready var warning_sound: AudioStreamPlayer2D = $WarningSound

var flicker_timer: Timer
var total_duration: float = 180.0
var elapsed_time: float = 0.0
var flicker_interval: float = 0.05
var min_opacity: float = 0.2
var max_opacity: float = 0.6
var increasing: bool = true

# Transition (fade + glitch)
var transition_timer: Timer
var transition_duration: float = 8.0
var transition_elapsed: float = 0.0
var is_transition_active: bool = false

# Text shake
var shake_timer: Timer
var shake_duration: float = 5.0
var shake_elapsed: float = 0.0
var is_shaking: bool = false
var original_scale: Vector2

# Fade & glitch
var fade_start_opacity: float = 0.1
var fade_end_opacity: float = 0.9
var is_glitching: bool = false


func _ready():
	await get_tree().process_frame # ✅ Ensure SoundSystem is ready before connecting

	red_overlay.visible = false
	warning_label.visible = false
	stuck_label.visible = false
	red_overlay.modulate.a = min_opacity

	# ✅ Center alignment
	warning_label.set_anchors_preset(Control.PRESET_CENTER)
	stuck_label.set_anchors_preset(Control.PRESET_CENTER)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stuck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stuck_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Let clicks pass
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stuck_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ✅ Safe connection (avoids duplicate connections)
	if not SoundSystem.background_volume_changed.is_connected(_on_bgm_volume_changed):
		SoundSystem.background_volume_changed.connect(_on_bgm_volume_changed)

	# Apply current volume instantly
	_on_bgm_volume_changed(SoundSystem.background_volume)

	GameManager.game_reset.connect(_on_game_reset)


# 🔊 Start escape warning (with looping warning sound)
func start_escape_warning(duration: float = 180.0):
	if not GameManager.is_game_started:
		return

	total_duration = duration
	elapsed_time = 0.0
	increasing = true

	red_overlay.visible = true
	warning_label.visible = true
	red_overlay.modulate.a = min_opacity
	_update_warning_label()

	# Start flicker timer
	if not flicker_timer:
		flicker_timer = Timer.new()
		flicker_timer.one_shot = false
		flicker_timer.timeout.connect(_on_flicker)
		add_child(flicker_timer)
	flicker_timer.wait_time = flicker_interval
	flicker_timer.start()

	# 🔊 Start looping warning sound synced with SoundSystem
	if warning_sound.stream:
		warning_sound.stop()
		if warning_sound.stream is AudioStream:
			warning_sound.stream.loop = true
		# ✅ Sync with BGM volume
		warning_sound.volume_db = linear_to_db(SoundSystem.background_volume * 0.8)
		warning_sound.play()


func _on_flicker():
	if is_transition_active:
		return

	if increasing:
		red_overlay.modulate.a += 0.02
		if red_overlay.modulate.a >= max_opacity:
			red_overlay.modulate.a = max_opacity
			increasing = false
	else:
		red_overlay.modulate.a -= 0.02
		if red_overlay.modulate.a <= min_opacity:
			red_overlay.modulate.a = min_opacity
			increasing = true

	elapsed_time += flicker_interval
	_update_warning_label()

	if elapsed_time >= total_duration:
		_start_final_transition()


func _update_warning_label():
	var remaining = max(total_duration - elapsed_time, 0)
	var minutes = int(remaining / 60)
	var seconds = int(remaining) % 60
	warning_label.text = "⚠️ Escape Lab in: %02d:%02d" % [minutes, seconds]


# 🔥 Fade + glitch start
func _start_final_transition():
	flicker_timer.stop()
	warning_label.visible = false
	is_transition_active = true
	is_glitching = true
	transition_elapsed = 0.0

	# Stop warning sound when transition starts
	if warning_sound.playing:
		warning_sound.stop()

	stuck_label.visible = true
	stuck_label.text = "💀 You are stuck in the lab forever"
	original_scale = stuck_label.scale

	red_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stuck_label.mouse_filter = Control.MOUSE_FILTER_STOP

	if not transition_timer:
		transition_timer = Timer.new()
		transition_timer.one_shot = false
		transition_timer.wait_time = 0.1
		transition_timer.timeout.connect(_on_transition_tick)
		add_child(transition_timer)
	transition_timer.start()


func _on_transition_tick():
	transition_elapsed += transition_timer.wait_time
	var t = clamp(transition_elapsed / transition_duration, 0, 1)
	red_overlay.modulate.a = lerp(fade_start_opacity, fade_end_opacity, t)

	# Glitch text
	if randi() % 2 == 0:
		stuck_label.visible = not stuck_label.visible
	else:
		var base_text = "💀 You are stuck in the lab forever"
		var glitched = ""
		for c in base_text:
			if randi() % 6 == 0:
				glitched += char(randi_range(33, 126))
			else:
				glitched += c
		stuck_label.text = glitched

	if transition_elapsed >= transition_duration:
		transition_timer.stop()
		is_transition_active = false
		is_glitching = false
		stuck_label.visible = true
		stuck_label.text = "💀 You are stuck in the lab forever"
		red_overlay.modulate.a = fade_end_opacity
		_start_text_shake()


func _start_text_shake():
	is_shaking = true
	shake_elapsed = 0.0
	if not shake_timer:
		shake_timer = Timer.new()
		shake_timer.one_shot = false
		shake_timer.wait_time = 0.05
		shake_timer.timeout.connect(_on_shake_tick)
		add_child(shake_timer)
	shake_timer.start()


func _on_shake_tick():
	shake_elapsed += shake_timer.wait_time
	var shake_strength = 0.05
	stuck_label.scale = original_scale * (1.0 + randf_range(-shake_strength, shake_strength))

	if shake_elapsed >= shake_duration:
		shake_timer.stop()
		is_shaking = false
		stuck_label.scale = original_scale
		GameManager.reset_game(GameManager.ResetReason.DEATH)


func _stop_warning():
	red_overlay.visible = false
	warning_label.visible = false
	stuck_label.visible = false
	warning_label.text = ""
	if flicker_timer:
		flicker_timer.stop()
	if transition_timer:
		transition_timer.stop()
	if shake_timer:
		shake_timer.stop()

	# 🔇 Stop warning sound
	if warning_sound.playing:
		warning_sound.stop()

	red_overlay.modulate.a = min_opacity
	is_transition_active = false
	is_glitching = false
	is_shaking = false
	stuck_label.scale = Vector2.ONE

	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stuck_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_game_reset():
	_stop_warning()


# 🎚 Sync with SoundSystem background volume (LIVE)
func _on_bgm_volume_changed(new_volume: float):
	if warning_sound and warning_sound.playing:
		warning_sound.volume_db = linear_to_db(new_volume * 0.8)
