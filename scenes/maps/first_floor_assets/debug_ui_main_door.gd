extends Control

signal challenge_solved  # Signal to notify the door

@onready var panel = $Panel
@onready var answer_input = $Panel/TextEdit
@onready var submit_button = $Panel/SubmitButton
@onready var challenge_label = $Panel/Label
@onready var closed_button = $Panel/ClosedButton
@onready var error_label = $Panel/ErrorLabel
@onready var error_timer = $Panel/ErrorTimer

var correct_answer = "5"
var player: Node = null  

func _ready():
	submit_button.pressed.connect(_on_submit_pressed)
	closed_button.pressed.connect(_on_close_pressed)
	error_timer.timeout.connect(_hide_error_message)

	hide()
	error_label.hide()

	player = get_tree().current_scene.find_child("Player", true, false)

func show_debug_ui():
	print("📌 Showing Debug UI modal!")
	show()
	panel.visible = true
	answer_input.grab_focus()
	_disable_player_input(true)

func _on_submit_pressed():
	var user_input = answer_input.text.strip_edges()

	if user_input == correct_answer:
		print("✅ Debugging success!")
		challenge_solved.emit()
		hide()
		_disable_player_input(false)
	else:
		print("❌ Wrong answer! Debugging failed!")
		_show_error_message()
		answer_input.text = ""

func _show_error_message():
	error_label.text = "❌ Debugging failed! Try again."
	error_label.show()
	error_timer.start(5)

func _hide_error_message():
	error_label.hide()

func _on_close_pressed():
	print("❌ Challenge skipped.")
	hide()
	_disable_player_input(false)

func _disable_player_input(state: bool):
	if player == null:
		player = get_tree().current_scene.find_child("Player", true, false)

	if player:
		player.typing_cant_move = state
		print("🔧 typing_cant_move set to:", state)
	else:
		print("❌ Player not found when trying to set typing_cant_move.")
