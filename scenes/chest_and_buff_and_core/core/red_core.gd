extends Area2D

var float_amplitude = 3.0
var float_speed = 2.0
var base_y = 0.0
var time_passed = 0.0
@onready var float_node = $FloatImage
@export var core_type: String = "red"

func _ready():
	if GameManager.has_core(core_type):
		queue_free()
		return
	
	base_y = float_node.position.y  # store local Y position

func _process(delta):
	time_passed += delta * float_speed
	var offset = sin(time_passed) * float_amplitude
	float_node.position.y = base_y + offset  # only move the image, not the shadow

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.collect_core(core_type)
		queue_free()
		
		# Trigger red screen warning only if this is the red core
		if core_type == "red":
			_show_escape_warning()

func _show_escape_warning():
	# Get the UI CanvasLayer (adjust path if needed)
	var ui = get_tree().current_scene.find_child("Ending")  
	if ui:
		ui.start_escape_warning(20)  # 3 minutes countdown
