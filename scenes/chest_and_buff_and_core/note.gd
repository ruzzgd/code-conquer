extends Area2D

@export var note_id : String = ""
var note_ui : Node = null

var float_amplitude = 3.0
var float_speed = 2.0
var base_y = 0.0
var time_passed = 0.0
@onready var float_node = $FloatImage

func _ready():
	base_y = float_node.position.y
	note_ui = get_tree().current_scene.find_child("Note-ui", true, false)

func _process(delta):
	time_passed += delta * float_speed
	var offset = sin(time_passed) * float_amplitude
	float_node.position.y = base_y + offset 

func _on_body_entered(body):
	if body.is_in_group("player") and note_ui:
		hide()
		note_ui.show_note(note_id)  

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and note_ui:
		show()
		note_ui.hide()
