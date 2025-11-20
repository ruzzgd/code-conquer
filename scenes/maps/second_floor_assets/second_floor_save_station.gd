extends Area2D

var save_station_floor = "Second-Floor"
var save_btn_clickable := false

@onready var save_station_anim := $AnimatedSprite2D
var save_ui: Node = null

func _ready():
	save_station_anim.play()
	save_ui = get_tree().current_scene.find_child("save-station-ui", true, false)
	connect("body_entered", Callable(self, "_on_player_entered"))  # Ensure signal is connected

func _on_button_pressed() -> void:
	if not save_btn_clickable:
		return
	save_ui.floor_name_label.text = save_station_floor
	save_ui.show_modal()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		save_btn_clickable = true
		print("Player entered save station")
