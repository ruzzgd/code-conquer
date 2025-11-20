extends VBoxContainer

var index: int = 0
var cards: Array = []
var _tween: Tween = null

@onready var card_container: Control = $CardContainer
@onready var photo: TextureRect = $CardContainer/Photo
@onready var name_label: Label = $CardContainer/NameLabel
@onready var role_label: Label = $CardContainer/RoleLabel
@onready var left_button: Button = $Buttons/LeftButton
@onready var right_button: Button = $Buttons/RightButton
@onready var timer: Timer = $AutoSlideTimer

func _ready():
	cards = [
		{"photo": load("res://assets/img/ruzhell.png"), "name": "Ruzhell Gimena", "role": "Developer"},
		{"photo": load("res://assets/img/raniel.png"), "name": "John Raniel Gerolao", "role": "Developer"},
		{"photo": load("res://assets/img/peter.png"), "name": "Peter Estocado", "role": "Project Manager"},
		{"photo": load("res://assets/img/arar.png"), "name": "Ar-ar Marmol", "role": "Systems Analysis"},
		{"photo": load("res://assets/img/pauline.png"), "name": "Pauline Godilo", "role": "Technical writer"},
	]
	_apply_card(index)

	# Connect buttons
	# Connect timer
	timer.connect("timeout", Callable(self, "_on_auto_slide_timeout"))
	timer.start()

func _on_auto_slide_timeout() -> void:
	var new_index = index + 1
	if new_index >= cards.size():
		new_index = 0
	_animate_to_index(new_index, 1)

func _apply_card(i: int) -> void:
	var card = cards[i]
	photo.texture = card["photo"]
	name_label.text = card["name"]
	role_label.text = card["role"]

func _animate_to_index(target_index: int, dir: int = 1) -> void:
	if target_index == index:
		return

	if _tween and _tween.is_running():
		_tween.kill()

	var w = card_container.size.x
	if w == 0:
		w = size.x

	var center_pos := card_container.position
	var off_left := center_pos + Vector2(-w * dir, 0)
	var off_right := center_pos + Vector2(w * dir, 0)

	_tween = get_tree().create_tween()
	_tween.parallel().tween_property(card_container, "position", off_left, 0.22)
	_tween.parallel().tween_property(card_container, "modulate:a", 0.0, 0.22)

	# ✅ Godot 4 way: pass a lambda directly
	_tween.tween_callback(func():
		_apply_and_slide_in(target_index, off_right, center_pos)
	)

func _apply_and_slide_in(target_index: int, start_pos: Vector2, center_pos: Vector2) -> void:
	index = target_index
	_apply_card(index)
	card_container.position = start_pos
	card_container.modulate.a = 0.0

	_tween = get_tree().create_tween()
	_tween.parallel().tween_property(card_container, "position", center_pos, 0.22)
	_tween.parallel().tween_property(card_container, "modulate:a", 1.0, 0.22)

# Buttons
func _on_left_button_pressed() -> void:
	timer.stop()
	var new_index = index - 1
	if new_index < 0:
		new_index = cards.size() - 1
	_animate_to_index(new_index, -1)
	timer.start()

func _on_right_button_pressed() -> void:
	timer.stop()
	var new_index = index + 1
	if new_index >= cards.size():
		new_index = 0
	_animate_to_index(new_index, 1)
	timer.start()
