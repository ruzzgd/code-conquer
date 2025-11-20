extends Control

@onready var gametime = $Panel/gametime
@onready var deathcount = $Panel/deathcount
@onready var openeddoor = $Panel/openeddoor
@onready var openedchest = $Panel/openedchest
@onready var killeddrone = $Panel/killeddrone
@onready var killedrobot = $Panel/killedrobot
@onready var difficulty_label = $Panel/difficulty

var waiting_for_reset = false
var current_username := "unknown"

func _ready():
	hide()

	# Connect to signals
	if GameManager.has_signal("game_finish_changed"):
		GameManager.game_finish_changed.connect(_on_game_finish_changed)
	if GameManager.has_signal("username_changed"):
		GameManager.connect("username_changed", Callable(self, "_on_username_changed"))

	_on_username_changed(GameManager.player_username)

func _on_username_changed(new_username: String) -> void:
	current_username = new_username.strip_edges()
	if current_username == "":
		current_username = "unknown"
	print("DEBUG: Username updated to:", current_username)

func _on_game_finish_changed(is_finished: bool):
	print("Modal _on_game_finish_changed received:", is_finished)
	if is_finished:
		_load_stats()
		_save_stats_to_file()
		show()
	else:
		hide()

func _load_stats():
	var total_seconds = int(GameManager.game_timer)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	gametime.text = "Time: " + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

	deathcount.text = "Deaths: " + str(GameManager.death_count)
	openeddoor.text = "Doors: " + str(GameManager.opened_doors_count)
	openedchest.text = "Chests: " + str(GameManager.opened_chests_count)
	killeddrone.text = "Drones: " + str(GameManager.killed_drones_count)
	killedrobot.text = "Robots: " + str(GameManager.killed_robots_count)
	difficulty_label.text = "Difficulty: " + GameManager.difficulty 

func _save_stats_to_file():
	var folder_path = "user://code_conquer_saves_gameplay"
	
	var username = current_username.to_lower().strip_edges()
	if username == "":
		username = "unknown"

	# Get current date/time + milliseconds for unique filename
	var dt = Time.get_date_dict_from_system()
	var tm = Time.get_time_dict_from_system()
	var ms = int(Time.get_unix_time_from_system() * 1000) % 1000
	
	var timestamp = "%04d%02d%02d_%02d%02d%02d_%03d" % [
		dt.year, dt.month, dt.day,
		tm.hour, tm.minute, tm.second,
		ms
	]

	var file_path = "%s/%s_%s_game_history.txt" % [folder_path, username, timestamp]

	var dir = DirAccess.open("user://")
	if dir == null:
		push_error("Cannot access user:// directory")
		return

	if not dir.dir_exists("code_conquer_saves_gameplay"):
		var err = dir.make_dir("code_conquer_saves_gameplay")
		if err != OK:
			push_error("Failed to create directory: %s" % folder_path)
			return

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file: %s" % file_path)
		return

	var total_seconds = int(GameManager.game_timer)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	var time_str = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

	var entry = "[%04d-%02d-%02d %02d:%02d:%02d] Player: %s | Difficulty: %s | Time: %s | Deaths: %d | Doors: %d | Chests: %d | Drones: %d | Robots: %d\n" % [
		dt.year, dt.month, dt.day,
		tm.hour, tm.minute, tm.second,
		username,
		GameManager.difficulty,  
		time_str,
		GameManager.death_count,
		GameManager.opened_doors_count,
		GameManager.opened_chests_count,
		GameManager.killed_drones_count,
		GameManager.killed_robots_count
	]

	file.store_string(entry)
	file.close()
	print("Saved history to:", file_path)

func _on_back_to_menu_pressed() -> void:
	GameManager.player_username = ""
	GameManager.game_timer = 0.0
	GameManager.death_count = 0
	GameManager.opened_doors_count = 0
	GameManager.opened_chests_count = 0
	GameManager.killed_drones_count = 0
	GameManager.killed_robots_count = 0
	GameManager.is_game_finish = false
