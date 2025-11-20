extends Panel

@onready var bg_slider = $bg_slider
@onready var sfx_slider = $sfx_slider
@onready var bg_percent = $bg_percent_label
@onready var sfx_percent = $sfx_percent_label

func _ready():
	self.hide()
	bg_slider.value = SoundSystem.background_volume * 100
	sfx_slider.value = SoundSystem.player_volume * 100
	update_labels()

	bg_slider.value_changed.connect(_on_bg_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_bg_slider_changed(value):
	SoundSystem.set_background_volume(value / 100.0)
	update_labels()

func _on_sfx_slider_changed(value):
	SoundSystem.set_player_volume(value / 100.0)
	SoundSystem.set_mob_volume(value / 100.0)
	update_labels()

func update_labels():
	bg_percent.text = str(round(bg_slider.value)) + "%"
	sfx_percent.text = str(round(sfx_slider.value)) + "%"


func _on_backbtn_pressed() -> void:
	self.hide()
