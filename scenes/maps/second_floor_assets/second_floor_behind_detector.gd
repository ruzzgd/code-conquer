extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("drone"):
		print("✅", body.name, "is behind an object!")
		body.z_index = 4  # Move behind

func _on_body_exited(body):
	if body.is_in_group("player") or body.is_in_group("drone"):
		print("🔄", body.name, "moved out from behind the object!")
		body.z_index = 9  # Move in front
