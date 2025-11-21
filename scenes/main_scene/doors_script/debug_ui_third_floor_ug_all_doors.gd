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
		"buggy_code": 'nums = [1,2,3,4]\ntotal = 0\nfor n nums\n    if n % 2 == 1\n        total =+ n\nprint("Sum:" + total)',
		"expected_output": 'Sum:4',
		"required_vars": ["nums","total","n"]
	},
	{
		"buggy_code": 'letters = ["a","b","c"]\ni = 0\nwhile i < len(letters)\n    if letters[i] != "b"\n        print(letters[i], end=" ")\n i +=1',
		"expected_output": 'a c',
		"required_vars": ["letters","i"]
	},
	{
		"buggy_code": 'x = 1\ny = 5\nwhile x < y\n    if x % 2 == 0\n        print("Even:" + x)\n    else\n        print("Odd:" + x)\n    x = x + 1',
		"expected_output": 'Odd:1 Even:2 Odd:3 Even:4',
		"required_vars": ["x","y"]
	},
	{
		"buggy_code": 'nums = [2,4,6,8]\ntotal = 0\nfor n nums\n    if n % 2 == 0\n        total =+ n\n    else\n        total += 0\nprint("Sum:" + total)',
		"expected_output": 'Sum:20',
		"required_vars": ["nums","total","n"]
	},
	{
		"buggy_code": 'vals = [7,14,21]\nfor v vals\n    if v > 10\n        print("High:" + v)\n    else\n        print("Low:" + v)',
		"expected_output": 'Low:7 High:14 High:21',
		"required_vars": ["vals","v"]
	},
	{
		"buggy_code": 'matrix = [[1,2],[3,4]]\nfor row matrix\n    for n in row\n        if n % 2 == 1\n            print("Odd:" + n)\n        else\n            print("Even:" + n)',
		"expected_output": 'Odd:1 Even:2 Odd:3 Even:4',
		"required_vars": ["matrix","row","n"]
	},
	{
		"buggy_code": 'names = ["Ann","Bob","Eve"]\ngreeting = ""\nfor n names\n    if n == "Bob"\n        greeting += "Hi "+n+" "\n    else\n        greeting += "Hello "+n+" "\nprint(greting)',
		"expected_output": 'Hello Ann Hi Bob Hello Eve ',
		"required_vars": ["names","greeting","n"]
	},
	{
		"buggy_code": 'i = 0\nwhile i<4\n    if i==2\n        print("Two")\n    else\n        print("Num:" + i)\n i+=1',
		"expected_output": 'Num:0 Num:1 Two Num:3',
		"required_vars": ["i"]
	},
	{
		"buggy_code": 'letters = ["x","y","z"]\nfor l letters\n    if l != "y"\n        print(l)\n    else\n        print("Skipped "+l)',
		"expected_output": 'x Skipped y z',
		"required_vars": ["letters","l"]
	},
	{
		"buggy_code": 'nums = [3,6,9]\ntotal = 0\nfor n nums\n    if n > 5\n        total =+ n\n    else\n        total += 0\nprint("Total:" + total)',
		"expected_output": 'Total:15',
		"required_vars": ["nums","total","n"]
	}
]

var hard_challenges: Array = [
	{
		"buggy_code": 'nums = [1,2,3,4,5]\nsum_vals = 0\nfor n nums\n    if n % 2 == 0\n        sum_vals =+ n\nprint("Sum:" + sum_vals)',
		"expected_output": 'Sum:6',
		"required_vars": ["nums","sum_vals","n"]
	},
	{
		"buggy_code": 'matrix = [[1,2,3],[4,5,6]]\nfor r matrix\n    for n in r\n        if n%2==0\n            print("Even:" + n)\n        else\n            print("Odd:" + n)',
		"expected_output": 'Odd:1 Even:2 Odd:3 Even:4 Odd:5 Even:6',
		"required_vars": ["matrix","r","n"]
	},
	{
		"buggy_code": 'vals = [5,10,15,20]\ntotal = 0\nfor v vals\n    if v>10\n        total =+ v\n    else\n        total += 0\nprint("Total:" + total)',
		"expected_output": 'Total:35',
		"required_vars": ["vals","total","v"]
	},
	{
		"buggy_code": 'i = 0\nwhile i<5\n    if i==3\n        print("Three")\n    else\n        print("Num:" + i)\n i+=1',
		"expected_output": 'Num:0 Num:1 Num:2 Three Num:4',
		"required_vars": ["i"]
	},
	{
		"buggy_code": 'x = 1\ny = 4\nwhile x<=y\n    if x%2==0\n        print("Even:" + x)\n    else\n        print("Odd:" + x)\n x +=1',
		"expected_output": 'Odd:1 Even:2 Odd:3 Even:4',
		"required_vars": ["x","y"]
	},
	{
		"buggy_code": 'names = ["Ann","Bob","Eve"]\ngreet = ""\nfor n names\n    if n=="Eve"\n        greet += "Hi "+n+" "\n    else\n        greet += "Hello "+n+" "\nprint(gret)',
		"expected_output": 'Hello Ann Hello Bob Hi Eve ',
		"required_vars": ["names","greet","n"]
	},
	{
		"buggy_code": 'matrix = [[1,2],[3,4]]\nfor r matrix\n    for n in r\n        if n%2==0\n            print("Even:" + n)\n        else\n            print("Odd:" + n)',
		"expected_output": 'Odd:1 Even:2 Odd:3 Even:4',
		"required_vars": ["matrix","r","n"]
	},
	{
		"buggy_code": 'nums = [1,2,3,4]\nsum_vals = 0\nfor n nums\n    if n!=2\n        sum_vals += n\n    else\n        sum_vals += 0\nprint("Sum:" + sum_vals)',
		"expected_output": 'Sum:8',
		"required_vars": ["nums","sum_vals","n"]
	},
	{
		"buggy_code": 'i = 0\nwhile i<4\n    if i==1\n        print("One")\n    else\n        print("Num:" + i)\n i+=1',
		"expected_output": 'Num:0 One Num:2 Num:3',
		"required_vars": ["i"]
	},
	{
		"buggy_code": 'vals = [2,4,6,8]\ntotal = 0\nfor v vals\n    if v>=6\n        total =+ v\n    else\n        total += 0\nprint("Total:" + total)',
		"expected_output": 'Total:14',
		"required_vars": ["vals","total","v"]
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
