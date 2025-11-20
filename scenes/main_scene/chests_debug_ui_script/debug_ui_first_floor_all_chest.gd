extends Control

@onready var panel: Panel = $Panel
@onready var debug_input: TextEdit = $Panel/TextEdit
@onready var submit_button: Button = $Panel/SubmitButton
@onready var closed_button: Button = $Panel/ClosedButton
@onready var skip_skill: Button = $Panel/SkipButton
@onready var error_label: Label = $Panel/ErrorLabel
@onready var error_timer: Timer = $Panel/ErrorTimer
@onready var to_view_expected_output: Button = $Panel/ViewExpectedOutput
@onready var http: HTTPRequest = $"../HTTPRequest"

var player: Node = null
var showing_expected_output: bool = false
var selected_challenge: Dictionary = {}
var current_chest: Node = null
var used_medium: Array = []
var used_hard: Array = []

# Loading animation
var loading_dots: int = 0
@onready var loading_timer: Timer = Timer.new()

var medium_challenges: Array = [
	# --- existing 20 ---
{"buggy_code": 'hp = 20\nif hp => 10:\nprint("Safe")', "expected_output": "Safe", "required_vars": ["hp"]},
{"buggy_code": 'speed = 5\nif speed > 3\n    print("Fast")', "expected_output": "Fast", "required_vars": ["speed"]},
{"buggy_code": 'coins = 0\nif coins = 0:\nprint("No coins")', "expected_output": "No coins", "required_vars": ["coins"]},
{"buggy_code": 'mode = "easy"\nif mode == easy:\n print("Easy mode")', "expected_output": "Easy mode", "required_vars": ["mode"]},
{"buggy_code": 'lvl = 1\nif lvl < 2 print("Level low")', "expected_output": "Level low", "required_vars": ["lvl"]},
{"buggy_code": 'energy = 50\nif energy > 40:\nprint("Energy OK")', "expected_output": "Energy OK", "required_vars": ["energy"]},
{"buggy_code": 'temp = 30\nif temp < 40\nprint("Warm")', "expected_output": "Warm", "required_vars": ["temp"]},
{"buggy_code": 'battery = 80\nif battery =>80:\nprint("Charged")', "expected_output": "Charged", "required_vars": ["battery"]},
{"buggy_code": 'score = 10\nif scroe > 5:\nprint("Good")', "expected_output": "Good", "required_vars": ["score"]},
{"buggy_code": 'hp = 0\nif hp == 0\nprint("Down")', "expected_output": "Down", "required_vars": ["hp"]},
{"buggy_code": 'power = 9\nif power > 5:\nprint("OK")', "expected_output": "OK", "required_vars": ["power"]},
{"buggy_code": 'ammo = 3\nif ammo < 5\nprint("Low ammo")', "expected_output": "Low ammo", "required_vars": ["ammo"]},
{"buggy_code": 'signal = "weak"\nif signal = "weak":\nprint("Weak signal")', "expected_output": "Weak signal", "required_vars": ["signal"]},
{"buggy_code": 'fuel = 100\nif fuel >50\nprint("Full")', "expected_output": "Full", "required_vars": ["fuel"]},
{"buggy_code": 'coins = 2\nif coins > 1:\n    print("Can buy")', "expected_output": "Can buy", "required_vars": ["coins"]},
{"buggy_code": 'speed = 1\nif speeed < 3:\nprint("Slow")', "expected_output": "Slow", "required_vars": ["speed"]},
{"buggy_code": 'x=5\nif x >2\nprint("Yes")', "expected_output": "Yes", "required_vars": ["x"]},
{"buggy_code": 'hp = 99\nif hp == 99:\n    print("Perfect")', "expected_output": "Perfect", "required_vars": ["hp"]},
{"buggy_code": 'light = "on"\nif light == "on"\nprint("Lights on")', "expected_output": "Lights on", "required_vars": ["light"]},
{"buggy_code": 'rain = False\nif rain == True:\nprint("Rainy")\nelse\nprint("Clear")', "expected_output": "Clear", "required_vars": ["rain"]},
{"buggy_code": 'temp=10\nif temp < 20:\nprint("Cold")', "expected_output": "Cold", "required_vars": ["temp"]},
{"buggy_code": 'ammo = 1\nif ammo >0:\n    print("Ammo left")', "expected_output": "Ammo left", "required_vars": ["ammo"]},
{"buggy_code": 'battery=5\nif battery <=5\nprint("Low battery")', "expected_output": "Low battery", "required_vars": ["battery"]},
{"buggy_code": 'health=10\nif helth == 10:\nprint("Healthy")', "expected_output": "Healthy", "required_vars": ["health"]},
{"buggy_code": 'points=50\nif points >= 50\nprint("Nice")', "expected_output": "Nice", "required_vars": ["points"]},
{"buggy_code": 'enemy=False\nif enemy == False:\nprint("Safe")', "expected_output": "Safe", "required_vars": ["enemy"]},
{"buggy_code": 'mode="night"\nif mode = "night":\nprint("Night")', "expected_output": "Night", "required_vars": ["mode"]},
{"buggy_code": 'xp = 1\nif xp < 2:\nprint("Level up")', "expected_output": "Level up", "required_vars": ["xp"]},
{"buggy_code": 'oxygen=99\nif oxygen >90\nprint("Good air")', "expected_output": "Good air", "required_vars": ["oxygen"]},
{"buggy_code": 'wave=3\nif wave >=3:\nprint("Wave incoming")', "expected_output": "Wave incoming", "required_vars": ["wave"]},

]


var hard_challenges: Array = [
	# --- existing 20 ---
{"buggy_code": 'a=5\nb=5\nif a + b =10:\nprint("Ten")', "expected_output":"Ten", "required_vars":["a","b"]},
{"buggy_code": 'hp=10\nshield=5\nif hp+shield > 12 print("Strong")', "expected_output":"Strong", "required_vars":["hp","shield"]},
{"buggy_code": 'temp=50\nif temp > 30 and temp < 60:\nprint("Warm")', "expected_output":"Warm", "required_vars":["temp"]},
{"buggy_code": 'coins=20\nbonus=5\nif coins + bonu ==25:\nprint("Perfect")', "expected_output":"Perfect", "required_vars":["coins","bonus"]},
{"buggy_code": 'x=2\ny=3\nif x*y == 6:\nprint("OK")', "expected_output":"OK", "required_vars":["x","y"]},
{"buggy_code": 'speed=10\nif speed >= 5 and speed <=10\nprint("In range")', "expected_output":"In range", "required_vars":["speed"]},
{"buggy_code": 'hp=90\nif hp > 50\nprint("High")\nelse:\nprint("Low")', "expected_output":"High", "required_vars":["hp"]},
{"buggy_code": 'light="on"\nif light == "off":\nprint("Off")\nelse print("On")', "expected_output":"On", "required_vars":["light"]},
{"buggy_code": 'fuel=3\nreq=2\nif fuel >= req print("Enough fuel")', "expected_output":"Enough fuel", "required_vars":["fuel","req"]},
{"buggy_code": 'score=15\nif score > 10 and scroe < 20:\nprint("Good")', "expected_output":"Good", "required_vars":["score"]},
{"buggy_code": 'x=5\ny=10\nif x + y = 15:\nprint("Sum correct")', "expected_output":"Sum correct", "required_vars":["x","y"]},
{"buggy_code": 'enemy=True\nhp=5\nif enemy and hp <10 print("Danger")', "expected_output":"Danger", "required_vars":["enemy","hp"]},
{"buggy_code": 'coins=10\nif coins =>10:\nprint("Enough coins")', "expected_output":"Enough coins", "required_vars":["coins"]},
{"buggy_code": 'battery=30\nif battery < 20 or battrey >50:\nprint("Check battery")', "expected_output":"Check battery", "required_vars":["battery"]},
{"buggy_code": 'temp=0\nif temp <0\nprint("Freezing")\nelse:\nprint("Normal")', "expected_output":"Normal", "required_vars":["temp"]},
{"buggy_code": 'power=100\nif power = 100:\nprint("Full power")', "expected_output":"Full power", "required_vars":["power"]},
{"buggy_code": 'mode="day"\nif mode == "Day":\nprint("Day mode")', "expected_output":"Day mode", "required_vars":["mode"]},
{"buggy_code": 'speed=7\nif speed >=5 and speed <=7\nprint("Optimal")', "expected_output":"Optimal", "required_vars":["speed"]},
{"buggy_code": 'armor=0\nif armor <1:\nprint("No armor")\nelse print("Protected")', "expected_output":"No armor", "required_vars":["armor"]},
{"buggy_code": 'hp=50\nif hp >0 and hp <100 print("Alive")', "expected_output":"Alive", "required_vars":["hp"]},
{"buggy_code": 'fuel=5\nif fuel >=0 and fuel <10:\nprint("Low fuel")', "expected_output":"Low fuel", "required_vars":["fuel"]},
{"buggy_code": 'oxygen=100\nif oxygen <= 100\nprint("Oxygen OK")', "expected_output":"Oxygen OK", "required_vars":["oxygen"]},
{"buggy_code": 'xp=40\nif xp >=30 and xp <=50 print("Leveling")', "expected_output":"Leveling", "required_vars":["xp"]},
{"buggy_code": 'enemy=False\nhp=10\nif enemy == True or hp <5 print("Alert")', "expected_output":"Alert", "required_vars":["enemy","hp"]},
{"buggy_code": 'score=0\nif score <0 or score >0 print("Check")', "expected_output":"Check", "required_vars":["score"]},
{"buggy_code": 'coins=1\nif coins ==0 or coins =>1 print("Coins OK")', "expected_output":"Coins OK", "required_vars":["coins"]},
{"buggy_code": 'power=20\nif power <10 and power >30 print("Check power")', "expected_output":"Check power", "required_vars":["power"]},
{"buggy_code": 'temp=15\nif temp <10 or temp >20 print("Temp alert")', "expected_output":"Temp alert", "required_vars":["temp"]},
{"buggy_code": 'light="off"\nif light == "on" or light == "Off":\nprint("Check light")', "expected_output":"Check light", "required_vars":["light"]},
{"buggy_code": 'armor=10\nif armor <=5 or armor >=10\nprint("Armor status")', "expected_output":"Armor status", "required_vars":["armor"]},

]


# Active challenge data
var buggy_code: String = ""
var expected_output: String = ""
var required_vars: Array = []

# ---------------------------------------------------------------------

func _ready() -> void:
	GameManager.difficulty_changed.connect(Callable(self, "_on_difficulty_changed"))
	set_random_challenge(GameManager.difficulty)

	submit_button.pressed.connect(Callable(self, "_on_submit_pressed"))
	closed_button.pressed.connect(Callable(self, "_on_close_pressed"))
	skip_skill.pressed.connect(Callable(self, "_on_skip_pressed"))
	to_view_expected_output.pressed.connect(Callable(self, "_on_view_output_toggle"))
	error_timer.timeout.connect(Callable(self, "_hide_error_message"))
	http.request_completed.connect(Callable(self, "_on_http_request_completed"))

	# Setup loading timer
	add_child(loading_timer)
	loading_timer.wait_time = 0.5
	loading_timer.one_shot = false
	loading_timer.timeout.connect(Callable(self, "_update_loading_text"))

	hide()
	error_label.hide()
	player = get_tree().current_scene.find_child("Player", true, false)

# ---------------------------------------------------------------------

func _on_difficulty_changed(new_difficulty: String) -> void:
	set_random_challenge(new_difficulty)

func set_random_challenge(difficulty: String) -> void:
	var pool: Array = medium_challenges if difficulty == "Medium" else hard_challenges
	var used: Array = used_medium if difficulty == "Medium" else used_hard

	var available: Array = pool.filter(func(ch): return not used.has(ch))
	if available.is_empty():
		used.clear()
		available = pool.duplicate()

	selected_challenge = available[randi() % available.size()]
	used.append(selected_challenge)

	buggy_code = selected_challenge["buggy_code"]
	expected_output = selected_challenge["expected_output"]
	required_vars = selected_challenge.get("required_vars", [])

# ---------------------------------------------------------------------

func show_debug_ui(chest: Node, challenge: Dictionary) -> void:
	current_chest = chest
	selected_challenge = challenge
	buggy_code = challenge["buggy_code"]
	expected_output = challenge["expected_output"]
	required_vars = challenge.get("required_vars", [])

	showing_expected_output = false
	to_view_expected_output.text = "🔍 View Expected Output"
	debug_input.editable = true
	debug_input.text = buggy_code

	show()
	panel.visible = true
	error_label.text = "🛠️ Fix the buggy code!"
	error_label.show()

	if player:
		skip_skill.disabled = player.current_hints <= 0

	_disable_player_input(true)

# ---------------------------------------------------------------------

func _on_submit_pressed() -> void:
	var user_code: String = debug_input.text.strip_edges()
	var buggy_lower: String = buggy_code.strip_edges().to_lower()

	for var_name in required_vars:
		if not user_code.to_lower().contains(var_name.to_lower()):
			_show_error_message("❌ Missing variable: %s" % var_name)
			return

	_run_python_code(user_code)

# ---------------------------------------------------------------------

func _run_python_code(code: String) -> void:
	var payload := {
		"language": "python",
		"version": "3.10.0",
		"files": [{ "content": code }]
	}
	var json_data := JSON.stringify(payload)

	# Start loading animation
	error_label.text = "⏳ Loading"
	error_label.show()
	loading_dots = 0
	loading_timer.start()

	var error := http.request(
		"https://emkc.org/api/v2/piston/execute",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_data
	)

	if error != OK:
		loading_timer.stop()
		_show_error_message("⚠️ No Internet Connection. Please check your network.")
		return

# ---------------------------------------------------------------------

func _update_loading_text() -> void:
	loading_dots = (loading_dots + 1) % 4
	var dots_str = ".".repeat(loading_dots)
	error_label.text = "⏳ Loading" + dots_str

# ---------------------------------------------------------------------
func _normalize_output(text: String) -> String:
	return text.strip_edges().replace("\n", " ").replace("\r", " ").replace("  ", " ").to_lower()

# ---------------------------------------------------------------------

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	loading_timer.stop()  # Stop loading animation

	# Any non-200 HTTP response triggers generic error
	if response_code != 200:
		_show_error_message("❌ Python Error. Code Still Buggy")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		_show_error_message("❌ Python Error. Code Still Buggy")
		return

	var run_data = data.get("run", {})
	var stderr: String = run_data.get("stderr", "")

	# If Python returned errors
	if stderr != "":
		_show_error_message("❌ Python Error. Code Still Buggy")
		return

	var stdout: String = run_data.get("stdout", "").strip_edges()
	var normalized_stdout = _normalize_output(stdout)
	var normalized_expected = _normalize_output(expected_output)

	# If output doesn't match expected
	if normalized_stdout != normalized_expected:
		_show_error_message("❌ Python Error. Code Still Buggy")
		return

	# Success path
	print("✅ Debugging success! Chest unlocked.")
	if current_chest:
		current_chest._on_challenge_solved()
	hide()
	_disable_player_input(false)

# ---------------------------------------------------------------------

func _on_skip_pressed() -> void:
	if player and player.current_hints > 0:
		player.use_hint()
		print("🪄 Skip skill used! Auto-solve challenge.")
		if current_chest:
			current_chest._on_challenge_solved()
		hide()
		_disable_player_input(false)
	else:
		_show_error_message("❌ No more Skip Skills!")

# ---------------------------------------------------------------------

func _show_error_message(msg: String = "❌ Debugging failed! Try again.") -> void:
	loading_timer.stop()
	error_label.text = msg
	error_label.show()
	error_timer.start(5)

func _hide_error_message() -> void:
	error_label.hide()

func _on_close_pressed() -> void:
	hide()
	_disable_player_input(false)

func _disable_player_input(state: bool) -> void:
	if player == null:
		player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.typing = state
	else:
		print("❌ Player not found when trying to set typing state.")

func _on_view_output_toggle() -> void:
	showing_expected_output = !showing_expected_output
	if showing_expected_output:
		debug_input.editable = false
		debug_input.text = expected_output
		to_view_expected_output.text = "🔁 Back to Debug Code"
	else:
		debug_input.editable = true
		debug_input.text = buggy_code
		to_view_expected_output.text = "🔍 View Expected Output"
