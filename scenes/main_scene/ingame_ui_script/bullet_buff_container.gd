extends PanelContainer

@onready var bullet_bar = $HBoxContainer/VBoxContainer/Control/ProgressBar
@onready var bullet_label = $HBoxContainer/VBoxContainer/Control/Label
var fill_style := StyleBoxFlat.new()

var max_bullets := 0
var current_bullets := 0
var current_magazine := 0
var buff_timers := {}
var buff_tweens := {}

var player: Node = null

@onready var buff_icon = {
	"double_damage": $HBoxContainer/VBoxContainer/buff_container/double_damage_icon,
	"triple_damage": $HBoxContainer/VBoxContainer/buff_container/triple_damage_icon,
	"attack_range": $HBoxContainer/VBoxContainer/buff_container/increase_atk_range_icon,
	"attack_speed": $HBoxContainer/VBoxContainer/buff_container/increase_atk_speed_icon
}

func _ready():
	# Style bullet bar
	fill_style.bg_color = Color(0.8, 0.75, 0.0)
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_left = 10
	fill_style.corner_radius_bottom_right = 10
	bullet_bar.add_theme_stylebox_override("fill", fill_style)

	# 🔒 Hide all buffs by default
	for icon in buff_icon.values():
		icon.visible = false
		var bar = icon.get_node_or_null("ProgressBar")
		if bar:
			bar.visible = false
			bar.value = 0

	# ⏳ Wait a frame so the player exists
	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		print("❌ No player found in group 'player'")
		return

	player = players[0]
	player.player_buff.connect(_on_player_buff)
	player.player_bullet_changed.connect(_on_player_bullet_changed)
	player.player_magazine_changed.connect(_on_player_magazine_changed)

	# ✅ Sync initial bullet and magazine
	max_bullets = player.max_bullet
	current_bullets = player.current_bullet
	current_magazine = player.current_magazine
	update_bullet_bar()

	# ✅ Sync active buffs already running
	if player.is_player_have_double_damage_buff:
		_on_player_buff("double_damage", player.double_damage_buff_cd.time_left)
	if player.is_player_have_triple_damage_buff:
		_on_player_buff("triple_damage", player.triple_damage_buff_cd.time_left)
	if player.is_player_have_attack_speed_buff:
		_on_player_buff("attack_speed", player.attack_speed_buff_cd.time_left)
	if player.is_player_have_attack_range_buff:
		_on_player_buff("attack_range", player.attack_range_buff_cd.time_left)

	# ✅ Start tracking gun ownership
	set_process(true)

func _process(_delta):
	if player:
		visible = player.has_gun  # ✅ Auto-hide UI when player has no gun

func _on_player_bullet_changed(current: int):
	current_bullets = current
	update_bullet_bar()

func _on_player_magazine_changed(current: int):
	current_magazine = current
	update_bullet_bar()

func update_bullet_bar():
	bullet_bar.max_value = max_bullets
	bullet_bar.value = current_bullets
	bullet_label.text = str(current_bullets, " / ", current_magazine)

	var percent = float(current_bullets) / float(max_bullets)
	if percent <= 0.25:
		fill_style.bg_color = Color.RED
	elif percent <= 0.5:
		fill_style.bg_color = Color.ORANGE
	else:
		fill_style.bg_color = Color(0.8, 0.75, 0.0)

func _on_player_buff(buff_type: String, buff_time: float) -> void:
	if not buff_icon.has(buff_type):
		print("⚠️ Unknown buff type:", buff_type)
		return

	var icon_node = buff_icon[buff_type]
	icon_node.visible = buff_time > 0

	var bar = icon_node.get_node_or_null("ProgressBar")
	if not bar:
		return

	bar.visible = buff_time > 0
	bar.value = 0

	# ❌ Stop previous tween if it exists
	if buff_tweens.has(buff_type) and is_instance_valid(buff_tweens[buff_type]):
		buff_tweens[buff_type].kill()
		buff_tweens.erase(buff_type)

	# ❌ Remove previous timer if it exists
	if buff_timers.has(buff_type) and is_instance_valid(buff_timers[buff_type]):
		buff_timers[buff_type].queue_free()
		buff_timers.erase(buff_type)

	if buff_time > 0:
		# ✅ Start new tween
		var tween = create_tween()
		tween.tween_property(bar, "value", 1.0, buff_time)
		buff_tweens[buff_type] = tween

		# ✅ Start new timer to hide icon after buff ends
		var timer = Timer.new()
		timer.wait_time = buff_time
		timer.one_shot = true
		timer.timeout.connect(func():
			icon_node.visible = false
			bar.visible = false
			buff_timers.erase(buff_type)
		)
		add_child(timer)
		timer.start()
		buff_timers[buff_type] = timer
