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

var medium_challenges: Array = [
	{
		"buggy_code": 'nums = [1,2,3]\nfor n nums:\nprint(n)',
		"expected_output": '1 2 3',
		"required_vars": ["nums"]
	},
	{
		"buggy_code": 'letters = ["a","b","c"]\ni = 0\nwhile i < len(letters)\nprint(letters[i])\ni += 1',
		"expected_output": 'a b c',
		"required_vars": ["letters","i"]
	},
	{
		"buggy_code": 'matrix = [[1,2],[3,4]]\nfor row in matrix:\nfor x in row\nprint(x)',
		"expected_output": '1 2 3 4',
		"required_vars": ["matrix"]
	},
	{
		"buggy_code": 'for i in range(3)\n    for j in range(2)\n        print(i+j, end=" ")',
		"expected_output": '0 1 0 1 1 2',
		"required_vars": ["i","j"]
	},
	{
		"buggy_code": 'nums = [2,4,6]\ni=0\nwhile i<len(nums):\nprint("Num:" + str(nums[i]))\ni+=1',
		"expected_output": 'Num:2 Num:4 Num:6',
		"required_vars": ["nums","i"]
	},
	{
		"buggy_code": 'for i in range(1,4)\n    total += i\nprint("Total:" + str(total))',
		"expected_output": 'Total:6',
		"required_vars": ["total","i"]
	},
	{
		"buggy_code": 'data = ["x","y","z"]\nfor i in range(len(data))\nprint(data[i], end=" ")',
		"expected_output": 'x y z',
		"required_vars": ["data","i"]
	},
	{
		"buggy_code": 'fruits = ["apple","banana"]\nfor f in fruits print(f)',
		"expected_output": 'apple banana',
		"required_vars": ["fruits"]
	},
	{
		"buggy_code": 'for i in range(3):\n    if i%2==0\n        print(i, end=" ")',
		"expected_output": '0 2',
		"required_vars": ["i"]
	},
	{
		"buggy_code": 'vals = [1,2,3]\nfor v vals:\nprint("Value:" + str(v))',
		"expected_output": 'Value:1 Value:2 Value:3',
		"required_vars": ["vals"]
	}
]


var hard_challenges: Array = [
	{
		"buggy_code": 'sum=0\nfor x in range(1,5)\nsum+=x\nprit("Sum:" + str(sum))',
		"expected_output": 'Sum:10',
		"required_vars": ["sum","x"]
	},
	{
		"buggy_code": 'words = ["cat","dog"]\nfor w words:\nprint("Word:" + w)',
		"expected_output": 'Word:cat Word:dog',
		"required_vars": ["words"]
	},
	{
		"buggy_code": 'i=0\nwhile i<3\n    print("Count:" + str(i))\n    i+=1',
		"expected_output": 'Count:0 Count:1 Count:2',
		"required_vars": ["i"]
	},
	{
		"buggy_code": 'matrix = [[1,2],[3,4]]\nfor row in matrix:\n    for v in row\n        print("Val:" + str(v))',
		"expected_output": 'Val:1 Val:2 Val:3 Val:4',
		"required_vars": ["matrix"]
	},
	{
		"buggy_code": 'nums=[2,4,6]\nfor n in nums\n    total += n\nprint("Total:" + str(total))',
		"expected_output": 'Total:12',
		"required_vars": ["nums","total"]
	},
	{
		"buggy_code": 'letters=["x","y","z"]\nfor l letters:\nprint("Letter:" + l)',
		"expected_output": 'Letter:x Letter:y Letter:z',
		"required_vars": ["letters"]
	},
	{
		"buggy_code": 'vals=[5,10]\ni=0\nwhile i<len(vals)\nprint("Val:" + str(vals[i]))\ni+=1',
		"expected_output": 'Val:5 Val:10',
		"required_vars": ["vals","i"]
	},
	{
		"buggy_code": 'for i in range(3)\n    for j in range(i+1)\n        print(i+j, end=" ")',
		"expected_output": '0 1 1 2 2 3',
		"required_vars": ["i","j"]
	},
	{
		"buggy_code": 'data=[1,2,3]\nfor d data:\nprint("Data:" + str(d))',
		"expected_output": 'Data:1 Data:2 Data:3',
		"required_vars": ["data"]
	},
	{
		"buggy_code": 'for n in range(1,4):\n    result=n*2\nprit("Result:" + str(result))',
		"expected_output": 'Result:2 Result:4 Result:6',
		"required_vars": ["n","result"]
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
	return text.strip_edges().replace("\n", " ").replace("\r", " ").replace("  ", " ").to_lower()

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
