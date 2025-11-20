extends PanelContainer

@onready var health_bar = $"HBoxContainer/VBoxContainer/health-bar"
var fill_style := StyleBoxFlat.new()

@onready var lives_icons = [
	$"HBoxContainer/VBoxContainer/VBoxContainer/extra-lives-container/heart-1",
	$"HBoxContainer/VBoxContainer/VBoxContainer/extra-lives-container/heart-2",
	$"HBoxContainer/VBoxContainer/VBoxContainer/extra-lives-container/heart-3"
]

@onready var hints_icons = [
	$"HBoxContainer/VBoxContainer/VBoxContainer/hints-container/hint-1",
	$"HBoxContainer/VBoxContainer/VBoxContainer/hints-container/hint-2",
	$"HBoxContainer/VBoxContainer/VBoxContainer/hints-container/hint-3"
]

var player

func _ready():
	await get_tree().process_frame  # ⏳ Wait a frame so the player is added to the scene

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		print("❌ No player found in 'player' group!")
		return

	player = players[0]

	# ✅ Now connect signals safely
	player.player_health_changed.connect(update_health_bar)
	player.player_lives_changed.connect(update_lives)
	player.player_hints_changed.connect(update_hints)

	# 🎨 Style setup
	fill_style.bg_color = Color.GREEN
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_left = 10
	fill_style.corner_radius_bottom_right = 10
	health_bar.add_theme_stylebox_override("fill", fill_style)

	# 💾 Health bar setup
	health_bar.min_value = 0
	health_bar.max_value = player.max_health
	update_health_bar(player.current_health)
	update_lives(player.current_lives)
	update_hints(player.current_hints)

func update_health_bar(value: int) -> void:
	health_bar.value = value
	var percent := float(value) / float(health_bar.max_value)

	if percent <= 0.2:
		fill_style.bg_color = Color.RED
	elif percent <= 0.5:
		fill_style.bg_color = Color.ORANGE
	else:
		fill_style.bg_color = Color.GREEN

func update_lives(count: int) -> void:
	for i in range(lives_icons.size()):
		lives_icons[i].visible = i < count

func update_hints(count: int) -> void:
	for i in range(hints_icons.size()):
		hints_icons[i].visible = i < count
