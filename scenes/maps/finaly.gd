extends Area2D

var triggered: bool = false  # Track if finished triggered

func _ready() -> void:
	triggered = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not triggered:
		triggered = true  # Mark as triggered
		GameManager.is_game_finish = true
		GameManager.reset_game(GameManager.ResetReason.MISSION_COMPLETE)
