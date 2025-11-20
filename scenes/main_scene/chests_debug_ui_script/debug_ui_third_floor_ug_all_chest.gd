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
{
	"buggy_code": 'nums = [1,2,3,4]\nfor n in nums:\n if n % 2 = 0\n  print("Even")\n else\n  print("Odd")',
	"expected_output": 'Odd Even Odd Even',
	"required_vars": ["nums","n"]
},
{
	"buggy_code": 'temps = [10,20,30,40]\nfor t in temps\n if t >= 25\n  print("Hot")\n else\n  print("Cold")',
	"expected_output": 'Cold Cold Hot Hot',
	"required_vars": ["temps","t"]
},
{
	"buggy_code": 'letters = ["a","b","e","f"]\nfor l in letters:\n if l == "a" or l == "e"\n  print("Vowel")\n else\n  print("Consonant")',
	"expected_output": 'Vowel Consonant Vowel Consonant',
	"required_vars": ["letters","l"]
},
{
	"buggy_code": 'grades = [55,65,75,85]\nfor g in grades\n if g > 70\n  print("Pass")\n else\n  print("Fail")',
	"expected_output": 'Fail Fail Pass Pass',
	"required_vars": ["grades","g"]
},
{
	"buggy_code": 'values = [2,4,6,8]\nfor v in values:\n if v = 6\n  print("Middle")\n else\n  print(v)',
	"expected_output": '2 4 Middle 8',
	"required_vars": ["values","v"]
},
{
	"buggy_code": 'points = [12,18,24]\nfor p in points\n if p < 15\n  print("Low")\n elif p <= 20\n  print("Mid")\n else\n  print("High")',
	"expected_output": 'Low Mid High',
	"required_vars": ["points","p"]
},
{
	"buggy_code": 'nums = [1,3,5,6]\ncount = 0\nfor n in nums\n if n % 2 == 0\n  count += 1\nprint(count)',
	"expected_output": '1',
	"required_vars": ["nums","count","n"]
},
{
	"buggy_code": 'scores = [40,70,60]\nfor s in scores\n if s >= 70\n  print("High")\n else\n  print("Low")',
	"expected_output": 'Low High Low',
	"required_vars": ["scores","s"]
},
{
	"buggy_code": 'nums = [2,3,6,9]\nfor n in nums\n if n % 3 == 0 and n % 2 = 0\n  print("DivBy6")\n elif n % 3 == 0\n  print("DivBy3")',
	"expected_output": 'DivBy3 DivBy3 DivBy6 DivBy3',
	"required_vars": ["nums","n"]
},
{
	"buggy_code": 'ages = [12,16,21]\nfor a in ages\n if a < 13\n  print("Child")\n elif a < 18\n  print("Teen")\n else\n  print("Adult")',
	"expected_output": 'Child Teen Adult',
	"required_vars": ["ages","a"]
},
{
	"buggy_code": 'nums = [2,5,8,10]\ntotal = 0\nfor n in nums\n if n > 5\n  total += n\nprint(total)',
	"expected_output": '18',
	"required_vars": ["nums","total","n"]
},
{
	"buggy_code": 'values = [3,4,5]\nfor v in values\n if v == 3\n  print("Start")\n elif v == 5\n  print("End")\n else\n  print("Middle")',
	"expected_output": 'Start Middle End',
	"required_vars": ["values","v"]
},
{
	"buggy_code": 'chars = ["a","b","c","d"]\nfor c in chars\n if c in ["a","d"]\n  print("Edge")\n else\n  print("Center")',
	"expected_output": 'Edge Center Center Edge',
	"required_vars": ["chars","c"]
},
{
	"buggy_code": 'nums = [1,3,6,9]\nfor n in nums\n if n % 3 = 0\n  print("Div3")\n else\n  print("No")',
	"expected_output": 'No Div3 Div3 Div3',
	"required_vars": ["nums","n"]
},
{
	"buggy_code": 'values = [2,4,6,8]\nsum = 0\nfor v in values\n if v > 4\n  sum += v*2\n else\n  sum += v\nprint(sum)',
	"expected_output": '40',
	"required_vars": ["values","sum","v"]
},
{
	"buggy_code": 'nums = [2,4,6,8,10]\ncount = 0\nfor n in nums\n if n % 4 = 0\n  count += 1\nprint(count)',
	"expected_output": '2',
	"required_vars": ["nums","count","n"]
},
{
	"buggy_code": 'temps = [18,22,26,30]\nfor t in temps\n if t < 20\n  print("Cold")\n elif t < 28\n  print("Warm")\n else\n  print("Hot")',
	"expected_output": 'Cold Warm Warm Hot',
	"required_vars": ["temps","t"]
},
{
	"buggy_code": 'nums = [5,10,15,20]\nfor n in nums\n if n == 10 or n == 20\n  print("EvenTen")\n else\n  print("OddFive")',
	"expected_output": 'OddFive EvenTen OddFive EvenTen',
	"required_vars": ["nums","n"]
},
{
	"buggy_code": 'points = [3,6,9,12]\nfor p in points\n if p < 5\n  print("Low")\n elif p < 10\n  print("Mid")\n else\n  print("High")',
	"expected_output": 'Low Mid Mid High',
	"required_vars": ["points","p"]
},
{
	"buggy_code": 'nums = [1,2,3,4]\nproduct = 1\nfor n in nums\n if n % 2 = 0\n  product *= n\nprint(product)',
	"expected_output": '8',
	"required_vars": ["nums","product","n"]
},
{
	"buggy_code": "age = 12\nif age >= 18\n    print('Adult')\nelse\n    print('Minor')",
	"expected_output": "Minor",
	"required_vars": ["age"]
},
{
	"buggy_code": "temp = 25\nif temprature > 30\n    print('Hot')\nelse\n    print('Cool')",
	"expected_output": "Cool",
	"required_vars": ["temp"]
},
{
	"buggy_code": "coins = 9\nif coins => 10\n    print('Enough coins')\nelse\n    print('Not enough')",
	"expected_output": "Not enough",
	"required_vars": ["coins"]
},
{
	"buggy_code": "speed = 50\nif speed < 60\nprint('Safe speed')\nelse\n    print('Too fast')",
	"expected_output": "Safe speed",
	"required_vars": ["speed"]
},
{
	"buggy_code": "power = 70\nif powr > 50\n    print('Stable')\nelse\n    print('Low power')",
	"expected_output": "Stable",
	"required_vars": ["power"]
},
{
	"buggy_code": "hp = 0\nif hp = 0\n    print('Game Over')\nelse\n    print('Alive')",
	"expected_output": "Game Over",
	"required_vars": ["hp"]
},
{
	"buggy_code": "fuel = 20\nif fuel <=10\n    print('Low fuel')\nelse\nprint('Fuel OK')",
	"expected_output": "Fuel OK",
	"required_vars": ["fuel"]
},
{
	"buggy_code": "mode = 'easy'\nif mode == easy\n    print('Casual mode')\nelse\n    print('Hard mode')",
	"expected_output": "Casual mode",
	"required_vars": ["mode"]
}
]
var hard_challenges: Array = [
{
	"buggy_code": 'nums = [1,2,3,4,5]\nsum = 0\nfor n in nums\n if n % 2 = 0\n  sum += n*3\n else\n  sum += n\nif sum > 25\n print("Pass")\nelse\n print("Fail")',
	"expected_output": 'Pass',
	"required_vars": ["nums","sum","n"]
},
{
	"buggy_code": 'vals = [3,6,9,12]\ncount = 0\nfor v in vals\n if v % 3 = 0\n  count += v\nif count > 25\n print("Good")\nelse\n print("Bad")',
	"expected_output": 'Good',
	"required_vars": ["vals","count","v"]
},
{
	"buggy_code": 'nums = [2,4,6,8]\ntotal = 0\nfor n in nums\n if n % 4 == 0\n  total += n*2\n else\n  total += n\nif total > 30\n print("Yes")\nelse\n print("No")',
	"expected_output": 'Yes',
	"required_vars": ["nums","total","n"]
},
{
	"buggy_code": 'data = [5,10,15,20]\nsum = 0\nfor d in data\n if d > 10\n  sum += d*2\n else\n  sum += d\nif sum >= 70\n print("Large")\nelse\n print("Small")',
	"expected_output": 'Large',
	"required_vars": ["data","sum","d"]
},
{
	"buggy_code": 'nums = [1,2,3,4,5]\neven = 0\nodd = 0\nfor n in nums\n if n % 2 = 0\n  even += n\n else\n  odd += n\nif even > odd\n print("Even")\nelse\n print("Odd")',
	"expected_output": 'Odd',
	"required_vars": ["nums","even","odd","n"]
},
{
	"buggy_code": 'values = [2,5,8,11]\ntotal = 0\nfor v in values\n if v % 2 = 0\n  total += v\n else\n  total -= v\nif total > 0\n print("Positive")\nelse\n print("Negative")',
	"expected_output": 'Negative',
	"required_vars": ["values","total","v"]
},
{
	"buggy_code": 'nums = [1,4,9,16]\ncount = 0\nfor n in nums\n if n**0.5 > 3\n  count += 2\n else\n  count += 1\nif count == 5\n print("Yes")\nelse\n print("No")',
	"expected_output": 'Yes',
	"required_vars": ["nums","count","n"]
},
{
	"buggy_code": 'temps = [10,20,30]\nsum = 0\nfor t in temps\n if t < 15\n  sum += 1\n elif t < 25\n  sum += 2\n else\n  sum += 3\nif sum == 6\n print("Okay")\nelse\n print("Error")',
	"expected_output": 'Okay',
	"required_vars": ["temps","sum","t"]
},
{
	"buggy_code": 'nums = [3,5,7]\nresult = 0\nfor n in nums\n if n > 5\n  result += n*2\n else\n  result += n\nif result == 27\n print("Exact")\nelse\n print("Off")',
	"expected_output": 'Exact',
	"required_vars": ["nums","result","n"]
},
{
	"buggy_code": 'data = [4,8,12]\nvalue = 0\nfor d in data\n if d % 4 = 0\n  value += d/2\n else\n  value += d\nif value == 12\n print("Correct")\nelse\n print("Wrong")',
	"expected_output": 'Correct',
	"required_vars": ["data","value","d"]
},
{
	"buggy_code": 'nums = [1,3,5,7]\nprod = 1\nfor n in nums\n if n < 5\n  prod *= n\n else\n  prod += n\nif prod == 28\n print("Right")\nelse\n print("Wrong")',
	"expected_output": 'Right',
	"required_vars": ["nums","prod","n"]
},
{
	"buggy_code": 'vals = [2,3,4,5]\nsum = 0\nfor v in vals\n if v % 2 = 0\n  sum += v*2\n else\n  sum += v\nif sum == 23\n print("Pass")\nelse\n print("Fail")',
	"expected_output": 'Pass',
	"required_vars": ["vals","sum","v"]
},
{
	"buggy_code": 'grades = [40,70,90]\nresult = ""\nfor g in grades\n if g < 50\n  result += "F"\n elif g < 80\n  result += "B"\n else\n  result += "A"\nprint(result)',
	"expected_output": 'FBA',
	"required_vars": ["grades","result","g"]
},
{
	"buggy_code": 'nums = [2,5,8,11]\nscore = 0\nfor n in nums\n if n % 2 = 0\n  score += n\n else\n  score -= n\nif score == -6\n print("Yes")\nelse\n print("No")',
	"expected_output": 'Yes',
	"required_vars": ["nums","score","n"]
},
{
	"buggy_code": 'data = [5,10,15]\ntotal = 0\nfor d in data\n if d < 10\n  total += d*2\n else\n  total += d\nif total == 40\n print("Match")\nelse\n print("No")',
	"expected_output": 'Match',
	"required_vars": ["data","total","d"]
},
{
	"buggy_code": 'nums = [1,2,3,4]\nresult = 0\nfor n in nums\n if n % 2 = 0\n  result += n\n else\n  result += n*3\nif result == 18\n print("Pass")\nelse\n print("Fail")',
	"expected_output": 'Pass',
	"required_vars": ["nums","result","n"]
},
{
	"buggy_code": 'vals = [4,6,8]\nresult = 0\nfor v in vals\n if v > 5\n  result += v*2\n else\n  result += v\nif result == 38\n print("Done")\nelse\n print("Retry")',
	"expected_output": 'Done',
	"required_vars": ["vals","result","v"]
},
{
	"buggy_code": 'nums = [3,6,9,12]\nsum = 0\nfor n in nums\n if n % 2 = 0\n  sum += n*2\n else\n  sum += n\nif sum == 60\n print("Win")\nelse\n print("Lose")',
	"expected_output": 'Win',
	"required_vars": ["nums","sum","n"]
},
{
	"buggy_code": 'nums = [1,2,3,4,5]\ncount = 0\nfor n in nums\n if n % 2 == 1 and n > 2\n  count += 1\nprint(count)',
	"expected_output": '2',
	"required_vars": ["nums","count","n"]
},
{
	"buggy_code": 'vals = [5,10,15,20]\nsum = 0\nfor v in vals\n if v % 10 = 0\n  sum += v/2\n else\n  sum += v\nif sum == 45\n print("Okay")\nelse\n print("No")',
	"expected_output": 'Okay',
	"required_vars": ["vals","sum","v"]
},
{
	"buggy_code": "hp = 50\narmor = 30\nif hp + armor >= 80\n    print('Well protected')\nelse\n    if hp < 20\n        print('Critical!')\n    else\n        print('Average defense')",
	"expected_output": "Well protected",
	"required_vars": ["hp", "armor"]
},
{
	"buggy_code": "x = 5\ny = 10\nif x > y\n    print('x greater')\nelse\n    if x = y\n        print('Equal')\n    else\n        print('y greater')",
	"expected_output": "y greater",
	"required_vars": ["x", "y"]
},
{
	"buggy_code": "temp = 35\nif temp > 40\n    print('Very hot')\nelif temp >= 30\n    print('Warm')\nelse\n    print('Cold')\nprint('Check done')",
	"expected_output": "Warm\nCheck done",
	"required_vars": ["temp"]
},
{
	"buggy_code": "coins = 15\nif coins >= 20\n    print('Plenty')\nelif coins => 10\n    print('Enough')\nelse\n    print('Low')",
	"expected_output": "Enough",
	"required_vars": ["coins"]
},
{
	"buggy_code": "power = 60\nmode = 'auto'\nif power > 50 and mode = 'auto'\n    print('Active')\nelse\n    print('Inactive')",
	"expected_output": "Active",
	"required_vars": ["power", "mode"]
},
{
	"buggy_code": "nums = [2,3,5,7]\nresult = 1\nfor n in nums\n if n % 2 = 0\n  result *= n\n else\n  result += n\nprint(result)",
	"expected_output": '17',
	"required_vars": ["nums","result","n"]
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
