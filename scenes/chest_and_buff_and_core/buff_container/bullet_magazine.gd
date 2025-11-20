extends Area2D

@export var magazine: int = 1  
var float_amplitude = 3.0
var float_speed = 2.0
var base_position = Vector2.ZERO

func _ready():
	connect("body_entered", _on_body_entered)
	base_position = position
	
func _process(delta):
	var offset = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_amplitude
	position.y = base_position.y + offset

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.get_bullet_magazine(magazine)
		queue_free()
