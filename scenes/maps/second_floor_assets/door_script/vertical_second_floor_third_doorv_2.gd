extends StaticBody2D

var door_id: String = "second_floor_third_door"

@export var door_button_open_texture = Texture
@export var door_button_close_texture = Texture

@onready var open_door_texture = $"open-door-texture"
@onready var close_door_texture = $"close-door-texture"
@onready var door_button_texture = $"door-button/button-texture"
@onready var door_detector = $"detector"
@onready var close_door_collision = $"close-door-collision"

var is_door_open: bool = false
var player_near: bool = false 
var player: Node = null
var debug_ui: Node = null

var challenge_solve: bool = false
var has_set_challenge = false
var challenge_difficulty = ""
var selected_challenge = {}

func _ready() -> void:
	player = get_tree().current_scene.find_child("Player", true, false)
	debug_ui = get_tree().current_scene.find_child("DebugUI-second-floor-ug-all-doors", true, false)
	update_door_texture()
	
	if SaveSystem.loaded:
		_check_if_door_should_be_open()
	else:
		SaveSystem.save_loaded.connect(_check_if_door_should_be_open)

	if debug_ui:
		debug_ui.hide()
	else:
		print("❌ Debug UI not found in scene!")


func _on_doorbutton_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not player_near:
		print("❌ Player too far from door.")
		return

	if challenge_solve:
		print("✅ Challenge already solved. Button is now locked.")
		return

	if event is InputEventMouseButton and event.pressed:
		if debug_ui:
			if debug_ui.visible:
				print("⚠️ Debug UI already open.")
				return

			# 🟢 Assign random challenge only once
			if not has_set_challenge:
				debug_ui.set_random_challenge(GameManager.difficulty)
				selected_challenge = debug_ui.selected_challenge
				has_set_challenge = true
				challenge_difficulty = GameManager.difficulty

			# ✅ Pass self and selected_challenge to shared debug UI
			debug_ui.show_debug_ui(self, selected_challenge)
			_disable_player_input(true)
		else:
			print("❌ Could not show debug UI")
			
func solve_challenge():
	print("✅ Debugging complete! Door can now open.")
	challenge_solve = true
	SaveSystem.opened_doors[door_id] = true 
	GameManager.opened_doors_count += 1
	update_door_texture()
	
	if debug_ui:
		debug_ui.hide()

	_disable_player_input(false)
	check_player_in_area()

func check_player_in_area():
	for body in door_detector.get_overlapping_bodies():
		if body.is_in_group("player"):
			if not is_door_open:
				print("🚪 Player already inside. Opening door.")
				open_door()
			return
	print("❌ No player inside door detector.")

func update_door_texture():
	door_button_texture.texture = door_button_open_texture if challenge_solve else door_button_close_texture
	open_door_texture.visible = is_door_open
	close_door_texture.visible = not is_door_open
	close_door_collision.set_deferred("disabled", is_door_open)

func open_door():
	is_door_open = true
	SoundSystem.play_door_open()
	update_door_texture()
	
func close_door():
	is_door_open = false
	SoundSystem.play_door_close()
	update_door_texture()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		print("👣 Player entered door area.")

		# ✅ Auto-open the door if challenge is already solved
		if challenge_solve and not is_door_open:
			print("✅ Challenge already solved. Auto-opening door.")
			open_door()

func _on_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		if is_door_open:
			close_door()

func _disable_player_input(state: bool):
	if player:
		player.typing = state
		print("🔧 Player typing_cant_move set to:", state)

func apply_saved_state():
	_check_if_door_should_be_open()

func _check_if_door_should_be_open():
	if SaveSystem.is_door_open(door_id):
		challenge_solve = true 
		update_door_texture()
