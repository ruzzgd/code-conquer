extends TextureButton
@onready var tween = get_tree().create_tween()

func _on_mouse_entered():
	if tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	self.get_parent().hide()
