extends Panel

@onready var saved_game_list = $ScrollContainer/saved_game_list  # container for rows
@onready var template_panel = $ScrollContainer/saved_game_list/Panel  # template row
@onready var menu = get_parent() 

@onready var username = $ScrollContainer/saved_game_list/Panel/username
@onready var filename = $ScrollContainer/saved_game_list/Panel/filename
@onready var floorname = $ScrollContainer/saved_game_list/Panel/floorname
@onready var date = $ScrollContainer/saved_game_list/Panel/date
func _ready():
	template_panel.visible = false
	
	hide()
	_populate_saved_game_list()
	GameManager.connect("game_reset", Callable(self, "_on_game_reset"))

# Called when the game resets → refresh save list
func _on_game_reset() -> void:
	print("🔄 Game reset detected, refreshing save list...")
	_populate_saved_game_list()

# Main method to populate save list
func _populate_saved_game_list() -> void:
	# Clear all except template
	for child in saved_game_list.get_children():
		if child != template_panel:
			child.queue_free()

	var dir = DirAccess.open("user://code_conquer_saves_gameplay")
	if not dir:
		print("❌ Failed to open save directory.")
		return

	var saves: Array = []

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = "user://code_conquer_saves_gameplay/%s" % file_name
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var parsed = JSON.parse_string(file.get_as_text())
					file.close()
					if typeof(parsed) == TYPE_DICTIONARY:
						var username = parsed.get("player_username", "Unknown")
						var save_station_map = parsed.get("save_station_map", "Unknown")
						var saved_at = parsed.get("saved_at", "Unknown")

						# Store info so we can sort later
						saves.append({
							"file_name": file_name,
							"username": username,
							"map": save_station_map,
							"saved_at": saved_at
						})
		file_name = dir.get_next()
	dir.list_dir_end()

	# ✅ Sort saves by newest date first
	saves.sort_custom(func(a, b): return a["saved_at"] > b["saved_at"])

	# ✅ Add rows after sorting
	for save in saves:
		_add_save_row(save["file_name"], save["username"], save["map"], save["saved_at"])

func _add_save_row(file_name: String, username: String, save_station_map: String, saved_at: String) -> void:
	var new_row = template_panel.duplicate()
	new_row.visible = true  # only duplicates are visible

	# Fill the labels inside saved_data
	var username_label = new_row.get_node("username")
	if username_label:
		username_label.text = "👤 " +"Player Name - "+ username

	var filename_label = new_row.get_node("filename")
	if filename_label:
		filename_label.text = "📂 " +"File Name - "+ file_name

	var floor_label = new_row.get_node("floorname")
	if floor_label:
		floor_label.text = "🏷️ " +"Save Station - "+ save_station_map

	var date_label = new_row.get_node("date")
	if date_label:
		date_label.text = "📅 " +"Date - "+ saved_at

	# Delete button
	var delete_btn = new_row.get_node("delete-btn")
	if delete_btn:
		delete_btn.pressed.connect(func():
			var full_path = "user://code_conquer_saves_gameplay/%s" % file_name
			if FileAccess.file_exists(full_path):
				DirAccess.remove_absolute(full_path)
				print("🗑️ Deleted:", file_name)
				_populate_saved_game_list()
		)

	# Load button
	var load_btn = new_row.get_node("load-game-btn")
	if load_btn:
		load_btn.pressed.connect(func():
			print("📂 Loading save:", file_name)
			SaveSystem.load_game(file_name)
			menu.hide()
		)

	saved_game_list.add_child(new_row)
