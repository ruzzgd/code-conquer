extends Area2D

@onready var room_cover = $"../cover-15"

func _ready():

	if room_cover:
		room_cover.modulate = Color(0, 0, 0, 1)  # Start darkened
	else:
		print("❌ ERROR: Could not find ColorRect-Main-Room. Check node structure!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		if room_cover:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(room_cover, "modulate", Color(0, 0, 0, 0), 1.0)  # Fade out
			await tween.finished

func _on_body_exited(body):
	if body.is_in_group("player"):
		if room_cover:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(room_cover, "modulate", Color(0, 0, 0, 1), 1.0)  # Fade in
			await tween.finished
