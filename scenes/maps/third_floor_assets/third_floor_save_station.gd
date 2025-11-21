extends Area2D

var save_station_floor = "Third-Floor"
var save_btn_clickable := false

@onready var save_station_anim := $AnimatedSprite2D
var save_ui: Node = null

func _ready():
	save_station_anim.play()
	save_ui = get_tree().current_scene.find_child("save-station-ui", true, false)
	connect("body_entered", Callable(self, "_on_player_entered"))

	# ✅ Listen to global can_save change
	if not GameManager.can_save_changed.is_connected(_on_can_save_changed):
		GameManager.can_save_changed.connect(_on_can_save_changed)

	# Apply current state immediately
	_on_can_save_changed(GameManager.can_save)


func _on_button_pressed() -> void:
	if not save_btn_clickable or not GameManager.can_save:
		print("❌ Cannot save right now!")
		return
	save_ui.floor_name_label.text = save_station_floor
	save_ui.show_modal()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		save_btn_clickable = true
		print("Player entered save station")


# 🔔 Update save button state when global can_save changes
func _on_can_save_changed(can_save: bool) -> void:
	if not save_btn_clickable:
		return
	if not can_save:
		# Optional: visually indicate button disabled
		save_station_anim.modulate = Color(1, 1, 1, 0.5)
	else:
		save_station_anim.modulate = Color(1, 1, 1, 1)
