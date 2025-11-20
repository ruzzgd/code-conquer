extends Control

@onready var ingame_setting_modal = $"ingame-setting-modal"
@onready var resume_btn = $"ingame-setting-modal/resume-btn"
@onready var info_route = $"../info-route"
@onready var soundpanel = $"../SoundSystemPanel"
@onready var setting_btn = $"ingame_setting"

var tween: Tween

func _ready() -> void:
	ingame_setting_modal.visible = false
	info_route.visible = false
	tween = get_tree().create_tween()

	# Connect hover signals for setting_btn
	setting_btn.connect("mouse_entered", Callable(self, "_on_setting_mouse_entered"))
	setting_btn.connect("mouse_exited", Callable(self, "_on_setting_mouse_exited"))

func _on_ingame_setting_pressed() -> void:
	ingame_setting_modal.visible = true

func _on_resumebtn_pressed() -> void:
	ingame_setting_modal.visible = false

func _on_quitbtn_pressed():
	GameManager.reset_game(GameManager.ResetReason.QUIT)
	ingame_setting_modal.visible = false

func _on_infobtn_pressed() -> void:
	info_route.visible = true

func _on_soundsystem_pressed() -> void:
	soundpanel.show()

# --- Hover animations for setting button ---
func _on_setting_mouse_entered() -> void:
	if tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(setting_btn, "scale", Vector2(1.1, 1.1), 0.30).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_setting_mouse_exited() -> void:
	if tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(setting_btn, "scale", Vector2(1, 1), 0.30).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
