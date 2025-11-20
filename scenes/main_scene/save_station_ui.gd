extends Control

@onready var saved_file_name = $save_container/saved_name
@onready var save_btn = $save_container/save_btn
@onready var floor_name_label = $"save_container/floor-name-label"
@onready var save_message = $"save_container/save-message"
@onready var reset_timer = $reset_timer

var saved_filename: String = ""
var has_saved_once := false
var player: Node = null

func _ready():
	hide()
	reset_timer.timeout.connect(_on_reset_timer_timeout)
	GameManager.game_reset.connect(_on_game_reset)

	# ✅ Listen to GameManager signal when save file is loaded
	GameManager.save_file_loaded.connect(_on_save_file_loaded)

	# ✅ Handle case where save file is already loaded before UI appears
	if GameManager.has_meta("current_save_file"):
		_on_save_file_loaded(GameManager.get_meta("current_save_file"))

func _disable_player_input(state: bool):
	if player == null:
		player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.typing = state
	else:
		print("❌ Player not found.")
		
func show_modal():
	show()
	_disable_player_input(true)

func hide_modal():
	hide()
	_disable_player_input(false)

func _on_save_file_loaded(file_name: String) -> void:
	saved_filename = file_name
	has_saved_once = true

	# ✅ Load save to get save date
	var full_path = "user://code_conquer_saves_gameplay/%s" % file_name
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			var saved_at = parsed.get("saved_at", "Unknown date")
			saved_file_name.text = "%s (📅 %s)" % [
				file_name.replace(".json", "").capitalize(),
				saved_at
			]
		else:
			saved_file_name.text = file_name.replace(".json", "").capitalize()
	else:
		saved_file_name.text = file_name.replace(".json", "").capitalize()

	saved_file_name.editable = false
	save_btn.disabled = false

func _on_save_btn_pressed() -> void:
	var floor_name = floor_name_label.text.strip_edges()

	if has_saved_once:
		# ✅ overwrite existing save (with new date inside JSON)
		SaveSystem.save_game(saved_filename, floor_name)
		save_message.text = "✅ Progress updated!"
		reset_timer.start()
		return

	var chapter_name = saved_file_name.text.strip_edges()

	if chapter_name == "" or floor_name == "":
		save_message.text = "❗ Cannot save. Missing username or floor name."
		return

	saved_filename = "%s.json" % chapter_name.to_lower().replace(" ", "-")
	var full_path = "user://code_conquer_saves_gameplay/%s" % saved_filename

	if FileAccess.file_exists(full_path):
		save_message.text = "⚠️ Save already exists. Choose another name."
		reset_timer.start()
		return

	SaveSystem.save_game(saved_filename, floor_name)  # ✅ new save with date
	has_saved_once = true
	saved_file_name.editable = false
	save_btn.disabled = true
	save_message.text = "✅ Save Successful!"
	reset_timer.start()

	GameManager.set_save_file(saved_filename)

func _on_reset_timer_timeout() -> void:
	save_btn.disabled = false
	save_message.text = ""

func _on_closebtn_pressed() -> void:
	hide_modal()

func _on_game_reset() -> void:
	has_saved_once = false
	saved_filename = ""
	saved_file_name.editable = true
	saved_file_name.text = ""
	save_btn.disabled = false
	save_message.text = ""
