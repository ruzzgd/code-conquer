extends PanelContainer

@onready var all_core = {
	"green": $"HBoxContainer/green-core",
	"blue": $"HBoxContainer/blue-core",
	"red": $"HBoxContainer/red-core"
}

func _ready():
	visible = false  # Hide the entire container by default
	for core in all_core.values():
		core.visible = false
	
	GameManager.core_collected.connect(_on_core_collected)
	GameManager.game_reset.connect(_on_game_reset)
	
	_update_all_cores()

func _on_core_collected(core_type: String):
	_update_core(core_type)
	_check_container_visibility()

func _update_core(core_type: String):
	if core_type in all_core:
		all_core[core_type].visible = GameManager.has_core(core_type)

func _update_all_cores():
	for core_type in all_core.keys():
		all_core[core_type].visible = GameManager.has_core(core_type)
	_check_container_visibility()

func _on_game_reset():
	visible = false
	for core in all_core.values():
		core.visible = false

func _check_container_visibility():
	# Show container only if at least one core is collected
	visible = GameManager.has_core("green") \
		or GameManager.has_core("blue") \
		or GameManager.has_core("red")
