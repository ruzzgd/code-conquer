extends Node

signal save_loaded
var loaded := false

var player_state := {}
var opened_chests := {}
var opened_doors := {}
var killed_drones := {}
var killed_robots := {}

const SAVE_DIR := "user://code_conquer_saves_gameplay"

var save_data := {
	"chests_opened": {},
	"doors_opened": {},
	"killed_drones": {},
	"killed_robots": {},
	"player_state": {},
	"current_map_path": "",
	"player_spawn_marker_path": "",
	"player_username": "",
	"difficulty": "",
	"save_station_map": "",
	"gameplay_time": 0.0,
	"cores_collected": {},
	"saved_at": ""  # ✅ add field here
}

func reset_save():
	opened_chests = {}
	opened_doors = {}
	killed_drones = {}
	killed_robots = {}
	player_state = {}

	save_data = {
		"chests_opened": {},
		"doors_opened": {},
		"killed_drones": {},
		"killed_robots": {},
		"player_state": {},
		"current_map_path": "",
		"player_spawn_marker_path": "",
		"player_username": "",
		"difficulty": "",
		"save_station_map": "",
		"gameplay_time": 0.0,
		"cores_collected": {},
		"saved_at": ""  # ✅ reset too
	}

func save_game(file_name := "", save_station_map := ""):
	if file_name == "":
		file_name = GameManager.get_save_file()

	if file_name == "":
		print("❌ No valid filename provided or tracked. Save aborted.")
		return

	GameManager.set_save_file(file_name)
	GameManager.update_current_save_station_marker()

	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		var err = DirAccess.make_dir_absolute(SAVE_DIR)
		if err != OK:
			print("❌ Failed to create save directory!")
			return
		else:
			print("📁 Save directory created:", SAVE_DIR)

	var final_path = "%s/%s" % [SAVE_DIR, file_name]

	save_data["player_username"] = GameManager.player_username
	save_data["chests_opened"] = opened_chests
	save_data["doors_opened"] = opened_doors
	save_data["killed_drones"] = killed_drones
	save_data["killed_robots"] = killed_robots
	save_data["current_map_path"] = GameManager.current_map_path
	save_data["player_spawn_marker_path"] = GameManager.current_save_station_marker
	save_data["difficulty"] = GameManager.difficulty
	save_data["save_station_map"] = save_station_map
	save_data["gameplay_time"] = GameManager.get_elapsed_time()
	save_data["death_count"] = GameManager.death_count
	save_data["opened_doors_count"] = GameManager.opened_doors_count
	save_data["opened_chests_count"] = GameManager.opened_chests_count
	save_data["killed_drones_count"] = GameManager.killed_drones_count
	save_data["killed_robots_count"] = GameManager.killed_robots_count
	save_data["cores_collected"] = GameManager.cores_collected 
	save_data["saved_at"] = Time.get_datetime_string_from_system(true, true)  # ✅ store save timestamp

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_state = player_node.get_save_state()
		save_data["player_state"] = player_state

	var file = FileAccess.open(final_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))  # ✅ keep pretty format
		file.close()
		print("✅ Game saved to:", final_path)

func load_game(file_name := "save_data.json"):
	var final_path = "%s/%s" % [SAVE_DIR, file_name]

	if not FileAccess.file_exists(final_path):
		loaded = false
		print("🟨 Save file not found:", final_path)
		return

	var file = FileAccess.open(final_path, FileAccess.READ)
	if not file:
		print("❌ Failed to open save file.")
		return

	var content = file.get_as_text()
	file.close()

	save_data = JSON.parse_string(content) if content else {}
	if typeof(save_data) != TYPE_DICTIONARY:
		print("❌ Save data is invalid!")
		return

	if not save_data.has("current_map_path") or not save_data.has("player_spawn_marker_path"):
		print("❌ Save file is missing critical data. Aborting load.")
		return

	GameManager.player_username = save_data.get("player_username", "")
	opened_chests = save_data.get("chests_opened", {})
	opened_doors = save_data.get("doors_opened", {})
	killed_drones = save_data.get("killed_drones", {})
	killed_robots = save_data.get("killed_robots", {})
	player_state = save_data.get("player_state", {})
	GameManager.death_count = save_data.get("death_count", 0)
	GameManager.opened_doors_count = save_data.get("opened_doors_count", 0)
	GameManager.opened_chests_count = save_data.get("opened_chests_count", 0)
	GameManager.killed_drones_count = save_data.get("killed_drones_count", 0)
	GameManager.killed_robots_count = save_data.get("killed_robots_count", 0)

	# ✅ Load cores
	GameManager.cores_collected = save_data.get("cores_collected", {
		"green": false,
		"blue": false,
		"red": false
	})

	GameManager.current_map_path = save_data["current_map_path"]
	GameManager.spawn_marker_name = save_data["player_spawn_marker_path"]
	GameManager.difficulty = save_data.get("difficulty", "Medium")
	GameManager.set_save_file(file_name)

	var loaded_time = save_data.get("gameplay_time", 0.0)
	GameManager.game_timer = loaded_time
	GameManager.update_map(GameManager.current_map_path, GameManager.spawn_marker_name)

	# ✅ Update UI for already collected cores
	for core_type in GameManager.cores_collected.keys():
		if GameManager.cores_collected[core_type]:
			GameManager.emit_signal("core_collected", core_type)

	call_deferred("_apply_player_state")
	emit_signal("save_loaded")

func _apply_player_state():
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.load_save_state(player_state)
	else:
		print("⚠️ Player node not found when applying saved state.")

func is_chest_opened(chest_id: String) -> bool:
	return opened_chests.has(chest_id) and opened_chests[chest_id]

func is_door_open(door_id: String) -> bool:
	return opened_doors.has(door_id) and opened_doors[door_id]

func is_drone_killed(drone_id: String) -> bool:
	return killed_drones.has(drone_id) and killed_drones[drone_id]

func is_robot_killed(robot_id: String) -> bool:
	return killed_robots.has(robot_id) and killed_robots[robot_id]
	
func _ready():
	print("✅ SaveSystem ready")
	GameManager.map_updated.connect(_on_map_changed)

func _on_map_changed(new_map_path: String, spawn_marker: String) -> void:
	await get_tree().process_frame  
	reapply_map_state()
	
func reapply_map_state():
	print("✅ SaveSystem reapplying saved state")
	for node in get_tree().get_nodes_in_group("persistent_object"):
		if node.has_method("apply_saved_state"):
			node.apply_saved_state()
