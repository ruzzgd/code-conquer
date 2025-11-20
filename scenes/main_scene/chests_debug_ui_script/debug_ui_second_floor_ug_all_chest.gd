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
{"buggy_code": 'x = 7\nif x => 5:\n print("High")\nelse:\n print("Low")', "expected_output": "High", "required_vars": ["x"]},
{"buggy_code": 'num = 12\nif num % 4 = 0:\n print("Divisible")\nelse:\n print("Not divisible")', "expected_output": "Divisible", "required_vars": ["num"]},
{"buggy_code": 'temp = 18\nif temp > 20\n print("Hot")\nelse:\n print("Cool")', "expected_output": "Cool", "required_vars": ["temp"]},
{"buggy_code": 'score = 40\nif score >=50:\n print("Pass")\nelse\n print("Fail")', "expected_output": "Fail", "required_vars": ["score"]},
{"buggy_code": 'age = 13\nif age >= 15:\n print("Teen")\nelse\n print("Kid")', "expected_output": "Kid", "required_vars": ["age"]},
{"buggy_code": 'x = 6\nif x < 8\n print("Small")\nelse:\n print("Big")', "expected_output": "Small", "required_vars": ["x"]},
{"buggy_code": 'a = 2\nb = 3\nif a > b:\n print("Yes")\nelse\n print("No")', "expected_output": "No", "required_vars": ["a", "b"]},
{"buggy_code": 'value = 10\nif value => 10:\n print("Enough")\nelse:\n print("Less")', "expected_output": "Enough", "required_vars": ["value"]},
{"buggy_code": 'coins = 5\nif coins = 5:\n print("Five")\nelse:\n print("Other")', "expected_output": "Five", "required_vars": ["coins"]},
{"buggy_code": 'hp = 30\nif hp < 20\n print("Low")\nelse:\n print("Safe")', "expected_output": "Safe", "required_vars": ["hp"]},
{"buggy_code": 'speed = 8\nif speed => 10:\n print("Fast")\nelse:\n print("Normal")', "expected_output": "Normal", "required_vars": ["speed"]},
{"buggy_code": 'x = 4\nif x == 4\n print("Yes")\nelse\n print("No")', "expected_output": "Yes", "required_vars": ["x"]},
{"buggy_code": 'light = "off"\nif light = "off":\n print("Lights off")\nelse\n print("Lights on")', "expected_output": "Lights off", "required_vars": ["light"]},
{"buggy_code": 'temp = 32\nif temp < 30:\n print("Cool")\nelse:\n print("Hot")', "expected_output": "Hot", "required_vars": ["temp"]},
{"buggy_code": 'lvl = 3\nif lvl >=5\n print("High")\nelse:\n print("Low")', "expected_output": "Low", "required_vars": ["lvl"]},
{"buggy_code": 'x = 0\nif x != 0\n print("Non-zero")\nelse:\n print("Zero")', "expected_output": "Zero", "required_vars": ["x"]},
{"buggy_code": 'coins = 0\nif coins > 0\n print("Has coins")\nelse:\n print("No coins")', "expected_output": "No coins", "required_vars": ["coins"]},
{"buggy_code": 'num = 7\nif num % 2 = 0:\n print("Even")\nelse\n print("Odd")', "expected_output": "Odd", "required_vars": ["num"]},
{"buggy_code": 'score = 65\nif score > 70\n print("Pass")\nelse:\n print("Fail")', "expected_output": "Fail", "required_vars": ["score"]},
{"buggy_code": 'x = 5\nif x >= 6\n print("Big")\nelse\n print("Small")', "expected_output": "Small", "required_vars": ["x"]},
{"buggy_code": 'temp = 15\nif temp < 10\n print("Cold")\nelse\n print("Warm")', "expected_output": "Warm", "required_vars": ["temp"]},
{"buggy_code": 'a = 2\nb = 8\nif a + b > 12\n print("Big")\nelse\n print("Small")', "expected_output": "Small", "required_vars": ["a", "b"]},
{"buggy_code": 'x = 9\nif x < 5\n print("Low")\nelse\n print("High")', "expected_output": "High", "required_vars": ["x"]},
{"buggy_code": 'val = 6\nif val != 6\n print("Wrong")\nelse\n print("Correct")', "expected_output": "Correct", "required_vars": ["val"]},
{"buggy_code": 'mark = 55\nif mark >=60\n print("Passed")\nelse\n print("Failed")', "expected_output": "Failed", "required_vars": ["mark"]},
{"buggy_code": 'num = 3\nif num * 3 = 9\n print("Triple")\nelse\n print("Other")', "expected_output": "Triple", "required_vars": ["num"]},
{"buggy_code": 'x = 7\nif x > 7\n print("High")\nelse\n print("Low")', "expected_output": "Low", "required_vars": ["x"]},
{"buggy_code": 'age = 19\nif age >= 20\n print("Adult")\nelse\n print("Teen")', "expected_output": "Teen", "required_vars": ["age"]},
{"buggy_code": 'temp = 28\nif temp >= 30\n print("Hot")\nelse\n print("Warm")', "expected_output": "Warm", "required_vars": ["temp"]}
]

var hard_challenges: Array = [
{"buggy_code": 'a = 3\nb = 5\nc = a + b\nif c => 8\n print("Big")\nelse\n print("Small")', "expected_output": "Big", "required_vars": ["a","b","c"]},
{"buggy_code": 'x = 10\ny = 2\nif x / y = 5\n print("Correct")\nelse\n print("Wrong")', "expected_output": "Correct", "required_vars": ["x","y"]},
{"buggy_code": 'num = 12\nres = 0\nif num % 2 == 0\n res +=2\nif num >10\n res +=1\nif res = 3\n print("Yes")', "expected_output": "Yes", "required_vars": ["num","res"]},
{"buggy_code": 'score = 40\nif score >=50\n print("A")\nelif score >=40\n print("B")\nelse\n print("C")', "expected_output": "B", "required_vars": ["score"]},
{"buggy_code": 'x = 3\ny = 8\nif x * y = 24\n print("Right")\nelse\n print("Wrong")', "expected_output": "Right", "required_vars": ["x","y"]},
{"buggy_code": 'temp = 22\nif temp < 20\n print("Cold")\nelif temp < 25\n print("Warm")\nelse\n print("Hot")', "expected_output": "Warm", "required_vars": ["temp"]},
{"buggy_code": 'a = 7\nb = 2\nif a - b > 4\n print("Yes")\nelse\n print("No")\nprint("End")', "expected_output": "Yes End", "required_vars": ["a","b"]},
{"buggy_code": 'nums = [1,2,3]\ntotal = 0\nfor n in nums\n total += n\nif total = 6\n print("Done")', "expected_output": "Done", "required_vars": ["nums","total","n"]},
{"buggy_code": 'val = 5\nres = 1\nif val > 3\n res += 2\nif res = 3\n print("Yes")\nelse\n print("No")', "expected_output": "Yes", "required_vars": ["val","res"]},
{"buggy_code": 'num = 8\nif num % 2 == 0\n print("Even")\nelif num % 4 == 0\n print("Four")\nelse\n print("Other")', "expected_output": "Even", "required_vars": ["num"]},
{"buggy_code": 'x = 6\ny = 2\nif x / y = 3\n print("Correct")\nelse\n print("Wrong")\nprint("Done")', "expected_output": "Correct Done", "required_vars": ["x","y"]},
{"buggy_code": 'score = 55\nif score >=60\n print("Pass")\nelif score >=50\n print("Borderline")\nelse\n print("Fail")', "expected_output": "Borderline", "required_vars": ["score"]},
{"buggy_code": 'a = 2\nb = 3\nc = 5\nif a + b = c\n print("Yes")\nelse\n print("No")', "expected_output": "Yes", "required_vars": ["a","b","c"]},
{"buggy_code": 'num = 14\nif num % 7 == 0 and num >10\n print("Lucky")\nelse\n print("Unlucky")', "expected_output": "Lucky", "required_vars": ["num"]},
{"buggy_code": 'temp = 30\nif temp >35\n print("Hot")\nelif temp >25\n print("Warm")\nelse\n print("Cool")', "expected_output": "Warm", "required_vars": ["temp"]},
{"buggy_code": 'x = 8\ny = 3\nif x * y = 24\n print("Yes")\nelse\n print("No")', "expected_output": "Yes", "required_vars": ["x","y"]},
{"buggy_code": 'nums = [2,4,6]\ntotal = 0\nfor n in nums\n if n >3\n  total += n\nif total = 10\n print("OK")', "expected_output": "OK", "required_vars": ["nums","total","n"]},
{"buggy_code": 'val = 5\nif val >0 and val <10\n print("Valid")\nelse\n print("Invalid")', "expected_output": "Valid", "required_vars": ["val"]},
{"buggy_code": 'a = 10\nb = 5\nif a / b = 2\n print("Correct")\nelse\n print("Wrong")\nprint("End")', "expected_output": "Correct End", "required_vars": ["a","b"]},
{"buggy_code": 'score = 70\nif score >80\n print("A")\nelif score >60\n print("B")\nelse\n print("C")', "expected_output": "B", "required_vars": ["score"]},
{"buggy_code": 'x = 4\ny = 6\nif x + y = 10\n print("OK")\nelse\n print("No")', "expected_output": "OK", "required_vars": ["x","y"]},
{"buggy_code": 'num = 9\nif num % 3 =0\n print("Three")\nelse\n print("Other")\nprint("Done")', "expected_output": "Three Done", "required_vars": ["num"]},
{"buggy_code": 'age = 25\nif age >20 and age <30\n print("Adult")\nelse\n print("Other")', "expected_output": "Adult", "required_vars": ["age"]},
{"buggy_code": 'val = 7\nif val >=5\n print("Pass")\nelse\n print("Fail")', "expected_output": "Pass", "required_vars": ["val"]},
{"buggy_code": 'temp = 12\nif temp <=10\n print("Cold")\nelif temp <=15\n print("Cool")\nelse\n print("Warm")', "expected_output": "Cool", "required_vars": ["temp"]},
{"buggy_code": 'x = 5\ny = 10\nif x * y = 50\n print("Good")\nelse\n print("Bad")\nprint("End")', "expected_output": "Good End", "required_vars": ["x","y"]},
{"buggy_code": 'points = 110\nif points >=100\n print("Win")\nelse\n print("Lose")\nprint("Over")', "expected_output": "Win Over", "required_vars": ["points"]},
{"buggy_code": 'num = 15\nif num % 5 =0 and num >10\n print("Good")\nelse\n print("Bad")', "expected_output": "Good", "required_vars": ["num"]},
{"buggy_code": 'a = 2\nb = 4\nc = 6\nif a + b + c = 12\n print("Sum OK")\nelse\n print("Sum Wrong")', "expected_output": "Sum OK", "required_vars": ["a","b","c"]}
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
