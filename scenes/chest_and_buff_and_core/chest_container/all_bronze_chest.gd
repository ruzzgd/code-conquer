extends Area2D

@export var chest_id: String = ""
var is_from_drone := false  
var is_from_robot := false  
var player_near = false
var debug_ui_first_floor_all_chest: Node = null
var chest_already_opened = false
var has_set_challenge = false
var challenge_difficulty = ""

var float_amplitude = 3     
var float_speed = 2.0       
var base_position = Vector2.ZERO

@onready var magazine_loot = $bullet_magazine
@onready var extra_live_loot = $extra_live
@onready var skip_skill_loot = $skip_skill
@onready var double_damage_loot = $DoubleDamageBuff
@onready var triple_damage_loot = $TripleDamageBuff
@onready var attack_speed_loot = $AttackSpeedBuff
@onready var attack_range_loot = $AttackRangeBuff

var all_loots = []
var selected_challenge = {}

func _ready():
	if SaveSystem.loaded:
		_check_if_chest_should_be_open()
	else:
		SaveSystem.save_loaded.connect(_check_if_chest_should_be_open)
	GameManager.game_reset.connect(_on_game_reset)
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

	all_loots = [
		magazine_loot,
		extra_live_loot,
		skip_skill_loot,
		double_damage_loot,
		triple_damage_loot,
		attack_speed_loot,
		attack_range_loot
	]

	debug_ui_first_floor_all_chest = get_tree().current_scene.find_child("DebugUI-first-floor-all-chest", true, false)
	call_deferred("_disable_all_loots")

	if chest_already_opened:
		$chest_sprite.frame = $chest_sprite.sprite_frames.get_frame_count("bronze_chest_anim") - 1

	# ✅ Despawn dropped chests after 60 seconds
	if is_from_drone:
		var timer = Timer.new()
		timer.name = "LifetimeTimer"
		timer.wait_time = 60.0
		timer.one_shot = true
		timer.autostart = true
		timer.timeout.connect(_on_LifetimeTimer_timeout)
		add_child(timer)
		var start_pos = global_position - Vector2(0, 20)
		global_position = start_pos

		var tween = create_tween()
		tween.tween_property(self, "global_position", start_pos + Vector2(0, 20), 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3) \
			.from(Vector2(1.4, 0.6)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)	
			
func _on_game_reset():
	if chest_id == "":
		queue_free()

func _disable_all_loots():
	for loot in all_loots:
		loot.visible = false
		if loot.has_node("CollisionShape2D"):
			loot.get_node("CollisionShape2D").disabled = true

func _check_if_chest_should_be_open():
	if chest_id != "" and SaveSystem.is_chest_opened(chest_id):
		chest_already_opened = true
		$chest_sprite.frame = $chest_sprite.sprite_frames.get_frame_count("bronze_chest_anim") - 1

func _on_body_entered(body):
	if body.name == "Player":
		player_near = true

func _on_body_exited(body):
	if body.name == "Player":
		player_near = false

func _on_button_pressed():
	if player_near and not chest_already_opened:
		start_debug_challenge()

func start_debug_challenge():
	if debug_ui_first_floor_all_chest:
		if not has_set_challenge:
			debug_ui_first_floor_all_chest.set_random_challenge(GameManager.difficulty)
			selected_challenge = debug_ui_first_floor_all_chest.selected_challenge
			has_set_challenge = true
			challenge_difficulty = GameManager.difficulty

		debug_ui_first_floor_all_chest.show_debug_ui(self, selected_challenge)

func _on_challenge_solved():
	if not chest_already_opened:
		open_chest()

func open_chest():
	print("✅ Chest opened!")
	chest_already_opened = true
	
	if chest_id != "":
		SaveSystem.opened_chests[chest_id] = true
		GameManager.opened_chests_count += 1
	SoundSystem.play_open_chest()
	$chest_sprite.play("bronze_chest_anim")

	await $chest_sprite.animation_finished
	$chest_sprite.stop()
	$chest_sprite.frame = $chest_sprite.sprite_frames.get_frame_count("bronze_chest_anim") - 1

	var rand = randi_range(1, 100)
	var selected_loot = null

	if rand <= 15:
		selected_loot = [extra_live_loot, skip_skill_loot,magazine_loot].pick_random()
	elif rand <= 35:
		selected_loot = [triple_damage_loot, attack_range_loot, magazine_loot].pick_random()
	else:
		selected_loot = [double_damage_loot, attack_speed_loot].pick_random()

	if selected_loot:
		selected_loot.visible = true
		if selected_loot.has_node("CollisionShape2D"):
			selected_loot.get_node("CollisionShape2D").disabled = false

func _on_LifetimeTimer_timeout():
	queue_free()

func apply_saved_state():
	if SaveSystem.is_chest_opened(chest_id):
		chest_already_opened = true
		$chest_sprite.frame = $chest_sprite.sprite_frames.get_frame_count("bronze_chest_anim") - 1
