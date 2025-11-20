extends ColorRect

@onready var conrtol_info = $"info-page/MarginContainer/control-info"

func _ready() -> void:
	conrtol_info.visible = true
	


func _on_controlinfobtn_pressed() -> void:
	conrtol_info.visible = true



func _on_back_pressed() -> void:
	hide()
