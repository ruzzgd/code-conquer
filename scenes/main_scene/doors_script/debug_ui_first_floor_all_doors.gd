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
var current_door: Node = null
var used_medium: Array = []
var used_hard: Array = []

# Loading animation
var loading_dots: int = 0
@onready var loading_timer: Timer = Timer.new()

# 🧩 Challenge pools
var medium_challenges: Array = [
	{
		"buggy_code": 'username = "ECHO-7"\nprint("Welcome " + usernme)',
		"expected_output": 'Welcome ECHO-7',
		"required_vars": ["username"]
	},
	{
		"buggy_code": 'code = "ACCESS-GRANTED"\nprint("Code: " + c0de)',
		"expected_output": 'Code: ACCESS-GRANTED',
		"required_vars": ["code"]
	},
	{
		"buggy_code": 'status = "Ready"\nif sttaus == "Ready":\n    print("System ready")',
		"expected_output": 'System ready',
		"required_vars": ["status"]
	},
	{
		"buggy_code": 'temp = 35\nif temp > 30\n    print("Hot day")',
		"expected_output": 'Hot day',
		"required_vars": ["temp"]
	},
	{
		"buggy_code": 'level = 5\nif level = 5:\n    print("Max level")',
		"expected_output": 'Max level',
		"required_vars": ["level"]
	},
	{
		"buggy_code": 'mode = "auto"\nif mode == "Auto":\n    print("Mode is automatic")',
		"expected_output": 'Mode is automatic',
		"required_vars": ["mode"]
	},
	{
		"buggy_code": 'x = 10\ny = 5\nif x > y\nprint("x is greater")',
		"expected_output": 'x is greater',
		"required_vars": ["x", "y"]
	},
	{
		"buggy_code": 'door = "open"\nif door == "open"\n    print("Door unlocked")',
		"expected_output": 'Door unlocked',
		"required_vars": ["door"]
	},
	{
		"buggy_code": 'score = 100\nif scroe >= 100:\n    print("Winner!")',
		"expected_output": 'Winner!',
		"required_vars": ["score"]
	},
	{
		"buggy_code": 'flag = True\nif flg:\n    print("Flag is set")',
		"expected_output": 'Flag is set',
		"required_vars": ["flag"]
	}
]

var hard_challenges: Array = [
	{
		"buggy_code": 'a = 10\nb == "5"\nsum = a - b\nprint("Sum is " + sm)',
		"expected_output": 'Sum is 15',
		"required_vars": ["a", "b", "sum"]
	},
	{
		"buggy_code": 'x == 4\ny = "2\nz = x * y\nprint("Result: " + z)',
		"expected_output": 'Result: 8',
		"required_vars": ["x", "y", "z"]
	},
	{
		"buggy_code": 'num = 7\nif num => 5:\n    print("High number")',
		"expected_output": 'High number',
		"required_vars": ["num"]
	},
	{
		"buggy_code": 'text = "Godot"\nif text = "godot":\n    print("Correct engine")',
		"expected_output": 'Correct engine',
		"required_vars": ["text"]
	},
	{
		"buggy_code": 'val = 3\nif val < 5\nprint("Below five")',
		"expected_output": 'Below five',
		"required_vars": ["val"]
	},
	{
		"buggy_code": 'a = 8\nb = 2\nif a / b == 4\nprint("Division correct")',
		"expected_output": 'Division correct',
		"required_vars": ["a", "b"]
	},
	{
		"buggy_code": 'x = 10\ny = 20\nif x + y = 30:\n    print("Sum matches")',
		"expected_output": 'Sum matches',
		"required_vars": ["x", "y"]
	},
	{
		"buggy_code": 'state = "ON"\nif state == "on":\n    print("Power active")',
		"expected_output": 'Power active',
		"required_vars": ["state"]
	},
	{
		"buggy_code": 'temp = 50\nif temp > 40\nprint("Too hot")',
		"expected_output": 'Too hot',
		"required_vars": ["temp"]
	},
	{
		"buggy_code": 'flag = False\nif flage == False:\n    print("Flag is false")',
		"expected_output": 'Flag is false',
		"required_vars": ["flag"]
	}
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

	# Setup loading animation timer
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

func show_debug_ui(door: Node, challenge: Dictionary) -> void:
	current_door = door
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
# 🧠 Executes Python code via Piston API
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

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	loading_timer.stop()  # Stop loading animation

	# If HTTP error or non-200 response
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

	# Success
	print("✅ Debugging success! Door unlocked.")
	if current_door:
		current_door.solve_challenge()
	hide()
	_disable_player_input(false)

# ---------------------------------------------------------------------

func _normalize_output(text: String) -> String:
	var t = text.to_lower()
	t = t.replace("\r", " ").replace("\n", " ").strip_edges()
	var parts: Array = t.split(" ", true) 
	t = "".join(parts) 
	return t
# ---------------------------------------------------------------------

func _on_skip_pressed() -> void:
	if player and player.current_hints > 0:
		player.use_hint()
		print("🪄 Skip skill used! Auto-solve challenge.")
		if current_door:
			current_door.solve_challenge()
		hide()
		_disable_player_input(false)
	else:
		_show_error_message("❌ No more Skip Skills!")

# ---------------------------------------------------------------------

func _show_error_message(msg: String = "❌ Debugging failed! Try again.") -> void:
	loading_timer.stop()  # Stop loading if any
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
		print("❌ Player not found.")

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
