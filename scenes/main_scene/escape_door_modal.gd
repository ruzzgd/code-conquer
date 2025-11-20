extends Control

signal escape_confirmed # Fired when player has all cores
signal modal_closed

@onready var green_core = $Panel/green_core
@onready var blue_core = $Panel/blue_core
@onready var red_core = $Panel/red_core
@onready var message_label = $Panel/MessageLabel

var player: Node = null


func _ready():
	player = get_tree().current_scene.find_child("Player", true, false)
	GameManager.core_collected.connect(_on_core_collected)
	_update_core_icons()

func _on_core_collected(_core_type: String):
	_update_core_icons()

func _update_core_icons():
	_set_icon_state(green_core, GameManager.has_core("green"))
	_set_icon_state(blue_core, GameManager.has_core("blue"))
	_set_icon_state(red_core, GameManager.has_core("red"))

func _set_icon_state(texture_rect: TextureRect, collected: bool):
	texture_rect.modulate = Color(1, 1, 1) if collected else Color(0.5, 0.5, 0.5)

func _on_button_pressed() -> void:
	if GameManager.has_core("green") and GameManager.has_core("blue") and GameManager.has_core("red"):
		emit_signal("escape_confirmed") # Tell the door “you can open now”
		emit_signal("modal_closed")
		hide()
	else:
		var missing = []
		if not GameManager.has_core("green"): missing.append("Green Core")
		if not GameManager.has_core("blue"): missing.append("Blue Core")
		if not GameManager.has_core("red"): missing.append("Red Core")
		message_label.text = "❌ Missing: " + ", ".join(missing)


func _disable_player_input(state: bool):
	if player:
		player.typing = state


func _on_back_button_pressed() -> void:
	hide()
	emit_signal("modal_closed")
