extends StaticBody2D

var door_id: String = "escape-door"

@onready var door_sprite = $"door-sprite"
@onready var close_door_blocker = $"close-door-blocker"
@onready var open_door_blocker = $"open-door-blocker"
@onready var open_door_blocker2 = $"open-door-blocker2"
@onready var play_door_anim: AnimatedSprite2D = $"door-sprite"
@onready var btn = $Button

var is_door_open: bool = false
var player_near_door: bool = false
var door_anim_playing: bool = false

var player: Node = null
var escapedoor_ui: Control = null

func _ready() -> void:
	player = get_tree().current_scene.find_child("Player", true, false)
	escapedoor_ui = get_tree().current_scene.find_child("Escape-Door-Modal", true, false)

	if SaveSystem.loaded:
		_check_if_door_should_be_open()
	else:
		SaveSystem.save_loaded.connect(_check_if_door_should_be_open)

	# Connect UI's signals
	if escapedoor_ui:
		escapedoor_ui.escape_confirmed.connect(_on_escape_confirmed)
		escapedoor_ui.modal_closed.connect(_hide_escape_door_modal) 

	# Connect animation finished signal
	if play_door_anim:
		play_door_anim.animation_finished.connect(_on_door_animation_finished)

func _check_if_door_can_open():
	# Only set animation if door is open and animation NOT playing
	if is_door_open and play_door_anim and not door_anim_playing:
		var last_frame = play_door_anim.sprite_frames.get_frame_count("open") - 1
		if play_door_anim.frame != last_frame:
			play_door_anim.animation = "open"
			play_door_anim.frame = last_frame
			play_door_anim.stop()
			close_door_blocker.set_deferred("disabled", true)
			print("✅ Door fully opened, blocker disabled.")
		else:
			# Already at last frame, ensure blocker is off
			close_door_blocker.set_deferred("disabled", true)

func _on_escape_confirmed():
	if not is_door_open:
		btn.hide()
		is_door_open = true
		SaveSystem.opened_doors[door_id] = true
		GameManager.opened_doors_count += 1
		if play_door_anim:
			play_door_anim.animation = "open"
			play_door_anim.play()
			door_anim_playing = true
		_disable_player_input(false)
		print("🚪 Escape door opening...")
	elif not player_near_door:
		print("⚠ Player not near door, cannot open.")

func _on_door_animation_finished():
	if play_door_anim.animation == "open":
		door_anim_playing = false
		close_door_blocker.set_deferred("disabled", true)
		print("✅ Door animation done — blocker disabled.")

func _on_button_pressed() -> void:
	if not player_near_door:
		return
	_show_escape_door_modal()

func _show_escape_door_modal():
	if escapedoor_ui:
		escapedoor_ui.show()
		_disable_player_input(true) # Stop player movement

func _hide_escape_door_modal():
	if escapedoor_ui:
		escapedoor_ui.hide()
		_disable_player_input(false) # Allow player movement again

func _disable_player_input(state: bool):
	if player:
		player.typing = state
		print("🔧 Player typing_cant_move set to:", state)

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_door = true
		# Don't interfere if animation is playing
		if not door_anim_playing:
			_check_if_door_can_open()

func _on_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_door = false

func apply_saved_state():
	_check_if_door_should_be_open()

func _check_if_door_should_be_open():
	if SaveSystem.is_door_open(door_id):
		is_door_open = true
		btn.hide()
		call_deferred("_set_door_to_last_frame")
		close_door_blocker.set_deferred("disabled", true)

func _set_door_to_last_frame():
	if play_door_anim and play_door_anim.sprite_frames:
		play_door_anim.animation = "open"
		play_door_anim.stop()
		var last_frame = play_door_anim.sprite_frames.get_frame_count("open") - 1
		play_door_anim.frame = last_frame
		play_door_anim.set_frame_and_progress(last_frame, 1.0) # Ensures visual update
