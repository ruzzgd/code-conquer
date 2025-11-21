extends CharacterBody2D

const SPEED = 90
const DASH_SPEED = 100
const DASH_TIME = 0.8

@onready var anim_sprite = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var bullet_scene = preload("res://scenes/player/PlayerBullet.tscn")
@onready var floating_message_scene = preload("res://scenes/main_scene/FloatingMessage.tscn")


@onready var shoot_timer = $ShootTimer
@onready var foot_step_sound = $FootstepSound
@onready var shooting_sound = $ShootingSound

@onready var muzzle_up = $AnimatedSprite2D/MuzzleUp
@onready var muzzle_down = $AnimatedSprite2D/MuzzleDown
@onready var muzzle_left = $AnimatedSprite2D/MuzzleLeft
@onready var muzzle_right = $AnimatedSprite2D/MuzzleRight
@onready var muzzle_up_right = $AnimatedSprite2D/MuzzleUpRight
@onready var muzzle_up_left = $AnimatedSprite2D/MuzzleUpLeft
@onready var muzzle_down_right = $AnimatedSprite2D/MuzzleDownRight
@onready var muzzle_down_left = $AnimatedSprite2D/MuzzleDownLeft

signal player_health_changed(current)
signal player_lives_changed(current)
signal player_hints_changed(current)
signal player_bullet_changed(current)
signal player_magazine_changed(current)
signal player_buff(buff_type, buff_time)

var last_idle = "idle_down"
var last_aim_direction := "down"
var is_dashing = false
var dash_velocity = Vector2.ZERO
var is_shooting = false
var is_dead = false

@export var base_attack_range := 100
@export var base_attack_damage := 8
@export var base_attack_speed := 6

var max_health := 200
var current_health := 200
var max_lives := 3
var current_lives := 3
var max_hints := 3
var current_hints := 1

var max_bullet := 70
var current_bullet := 70

var max_magazine := 5
var current_magazine := 3

var typing := false
var has_gun := false 

var is_player_have_double_damage_buff := false
var is_player_have_triple_damage_buff := false
var is_player_have_attack_speed_buff := false
var is_player_have_attack_range_buff := false

@onready var double_damage_buff_cd := $double_damage_buff_cd
@onready var triple_damage_buff_cd := $triple_damage_buff_cd
@onready var attack_speed_buff_cd := $attack_speed_buff_cd
@onready var attack_range_buff_cd := $attack_range_buff_cd

@onready var reload_sound = $ReloadSound
var is_reloading := false
var is_map_transitioning := false

@onready var respawn_timer = $RespawnTimer
@onready var respawn_label = $RespawnLabel

func _ready():
	SoundSystem.player_volume_changed.connect(_on_volume_changed)
	_on_volume_changed(SoundSystem.player_volume)

	dash_timer.wait_time = DASH_TIME
	dash_timer.one_shot = true

	shoot_timer.wait_time = 1.0 / get_attack_speed()
	shoot_timer.timeout.connect(_on_ShootTimer_timeout)
	GameManager.connect("map_transitioning_changed", Callable(self, "_on_map_transitioning_changed"))
	GameManager.game_reset.connect(_on_game_reset)

	emit_signal("player_health_changed", current_health)
	emit_signal("player_lives_changed", current_lives)
	emit_signal("player_hints_changed", current_hints)
	emit_signal("player_bullet_changed", current_bullet)
	emit_signal("player_magazine_changed", current_magazine)

	if not GameManager.is_game_started:
		reset_state()

func _physics_process(_delta):
	if not GameManager.is_game_started or is_dead or typing or is_map_transitioning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# ✅ Only allow reload if player has gun
	if has_gun and Input.is_action_just_pressed("to_reload") and current_magazine > 0 and current_bullet < max_bullet:
		reload()

	# ✅ Shooting logic
	if has_gun and Input.is_action_pressed("to_shoot") and not get_viewport().gui_get_hovered_control():
		if current_bullet > 0:
			if shoot_timer.is_stopped():
				shoot_timer.wait_time = 1.0 / get_attack_speed()
				shoot_timer.start()
			is_shooting = true
		else:
			# 🔁 No bullets: stop shooting and switch to idle animation with gun
			is_shooting = false
			if not shoot_timer.is_stopped():
				shoot_timer.stop()
			if shooting_sound.playing:
				shooting_sound.stop()

			# Set idle animation with gun based on aim
			last_aim_direction = _get_direction_from_mouse()
			var suffix = "_with_gun"
			var idle_anim = "idle_" + last_aim_direction + suffix
			if anim_sprite.sprite_frames.has_animation(idle_anim):
				anim_sprite.play(idle_anim)
			last_idle = idle_anim
	else:
		if not shoot_timer.is_stopped():
			shoot_timer.stop()
		is_shooting = false
		if shooting_sound.playing:
			shooting_sound.stop()

	# ✅ Interrupt sounds if dashing/reloading/shooting
	if is_dashing or is_shooting or is_reloading:
		if foot_step_sound.playing:
			foot_step_sound.stop()

		if is_dashing:
			velocity = dash_velocity
			move_and_slide()
			if dash_timer.time_left <= 0:
				_stop_dash()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
		return

	# ✅ Regular movement
	var direction = _get_movement_direction()
	if Input.is_action_just_pressed("dash_move") and direction != Vector2.ZERO and _is_valid_dash_direction(direction):
		_dash(direction)
	else:
		if not is_reloading:
			_handle_movement(direction)
		else:
			velocity = Vector2.ZERO
			move_and_slide()

func show_floating_message(text: String):
	var msg = floating_message_scene.instantiate()  # ALWAYS instantiate a new node
	msg.text = text
	msg.global_position = global_position + Vector2(0, -30)  # above player's head
	get_tree().current_scene.add_child(msg)
	
func _on_volume_changed(new_volume: float):
	var db = linear_to_db(new_volume)
	reload_sound.volume_db = db
	foot_step_sound.volume_db = db
	shooting_sound.volume_db = db

func _on_map_transitioning_changed(value: bool) -> void:
	is_map_transitioning = value

	if is_map_transitioning:
		# Force face-down idle pose
		var suffix = "_with_gun" if has_gun else ""
		last_idle = "idle_down" + suffix
		anim_sprite.play(last_idle)

		velocity = Vector2.ZERO
		move_and_slide()

func get_muzzle_position() -> Vector2:
	match last_aim_direction:
		"up": return muzzle_up.global_position
		"down": return muzzle_down.global_position
		"left": return muzzle_left.global_position
		"right": return muzzle_right.global_position
		"up_right": return muzzle_up_right.global_position
		"up_left": return muzzle_up_left.global_position
		"down_right": return muzzle_down_right.global_position
		"down_left": return muzzle_down_left.global_position
		_: return global_position  # fallback if missing

func reload():
	var bullets_needed = max_bullet - current_bullet
	if bullets_needed > 0 and current_magazine > 0:
		current_bullet = max_bullet
		current_magazine -= 1
		emit_signal("player_bullet_changed", current_bullet)
		emit_signal("player_magazine_changed", current_magazine)

		var base_idle = last_idle.replace("_with_gun", "")
		var reload_anim = base_idle.replace("idle", "reload")

		if anim_sprite.sprite_frames.has_animation(reload_anim):
			is_reloading = true
			# ✅ Play reload sound
			if reload_sound.stream:
				reload_sound.play()

			anim_sprite.play(reload_anim)
			await anim_sprite.animation_finished
			is_reloading = false
		else:
			print("❌ Missing reload animation:", reload_anim)

func shoot():
	if is_reloading or not has_gun:
		return

	if current_bullet <= 0:
		if not shoot_timer.is_stopped():
			shoot_timer.stop()
		is_shooting = false
		return

	current_bullet = clamp(current_bullet - 1, 0, max_bullet)
	emit_signal("player_bullet_changed", current_bullet)

	var bullet = bullet_scene.instantiate()
	bullet.global_position = get_muzzle_position()
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	bullet.attack_range = get_attack_range()
	bullet.attack_damage = get_attack_damage()
	get_tree().current_scene.add_child(bullet)

	last_aim_direction = _get_direction_from_mouse()
	anim_sprite.play("shooting_" + last_aim_direction)
	
	var suffix = "_with_gun" if has_gun else ""
	last_idle = "idle_" + last_aim_direction + suffix
	
	if not shooting_sound.playing:
		shooting_sound.play()

func _on_ShootTimer_timeout():
	if current_bullet > 0:
		shoot()
	else:
		shoot_timer.stop()
		is_shooting = false


func _get_movement_direction() -> Vector2:
	var direction = Vector2.ZERO
	var suffix = "_with_gun" if has_gun else ""

	if Input.is_action_pressed("move_up") and Input.is_action_pressed("move_right"):
		direction = Vector2(1, -1)
		last_idle = "idle_up_right" + suffix
	elif Input.is_action_pressed("move_up") and Input.is_action_pressed("move_left"):
		direction = Vector2(-1, -1)
		last_idle = "idle_up_left" + suffix
	elif Input.is_action_pressed("move_down") and Input.is_action_pressed("move_right"):
		direction = Vector2(1, 1)
		last_idle = "idle_down_right" + suffix
	elif Input.is_action_pressed("move_down") and Input.is_action_pressed("move_left"):
		direction = Vector2(-1, 1)
		last_idle = "idle_down_left" + suffix
	elif Input.is_action_pressed("move_up"):
		direction.y -= 1
		last_idle = "idle_up" + suffix
	elif Input.is_action_pressed("move_down"):
		direction.y += 1
		last_idle = "idle_down" + suffix
	elif Input.is_action_pressed("move_left"):
		direction.x -= 1
		last_idle = "idle_left" + suffix
	elif Input.is_action_pressed("move_right"):
		direction.x += 1
		last_idle = "idle_right" + suffix

	return direction.normalized()

func _handle_movement(direction: Vector2):
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		anim_sprite.play(last_idle.replace("idle", "walk"))
		if not foot_step_sound.playing:
			foot_step_sound.play()
	else:
		velocity = Vector2.ZERO
		anim_sprite.play(last_idle)
		if foot_step_sound.playing:
			foot_step_sound.stop()
	move_and_slide()

func _dash(dash_direction):
	if is_shooting or is_reloading:
		return
	is_dashing = true
	dash_velocity = dash_direction.normalized() * DASH_SPEED
	anim_sprite.play(_get_dash_animation(dash_direction))
	dash_timer.start()

func _stop_dash():
	is_dashing = false
	dash_velocity = Vector2.ZERO

func _is_valid_dash_direction(direction: Vector2) -> bool:
	return direction in [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized(),
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized()
	]

func _get_dash_animation(direction: Vector2) -> String:
	direction = direction.normalized()
	var suffix = "_with_gun" if has_gun else ""

	if direction == Vector2.LEFT:
		return "dash_left" + suffix
	elif direction == Vector2.RIGHT:
		return "dash_right" + suffix
	elif direction == Vector2.UP:
		return "dash_up" + suffix
	elif direction == Vector2.DOWN:
		return "dash_down" + suffix
	elif direction.dot(Vector2(1, -1).normalized()) > 0.99:
		return "dash_up_right" + suffix
	elif direction.dot(Vector2(-1, -1).normalized()) > 0.99:
		return "dash_up_left" + suffix
	elif direction.dot(Vector2(1, 1).normalized()) > 0.99:
		return "dash_down_right" + suffix
	elif direction.dot(Vector2(-1, 1).normalized()) > 0.99:
		return "dash_down_left" + suffix
	else:
		return last_idle.replace("idle", "dash")

func is_dead_state() -> bool:
	return is_dead

func _play_death_animation():
	is_dead = true
	is_reloading = false  
	velocity = Vector2.ZERO

	if not shoot_timer.is_stopped():
		shoot_timer.stop()
	is_shooting = false

	if shooting_sound.playing:
		shooting_sound.stop()
	if reload_sound.playing:
		reload_sound.stop() 

	# Play death animation
	var death_anim = "death_normal_down"
	match last_idle:
		"idle_down": death_anim = "death_normal_down"
		"idle_up": death_anim = "death_normal_up"
		"idle_left": death_anim = "death_normal_left"
		"idle_right": death_anim = "death_normal_right"
		"idle_left_down": death_anim = "death_normal_left"
		"idle_right_down": death_anim = "death_normal_right"
		"idle_left_up": death_anim = "death_normal_left_up"
		"idle_right_up": death_anim = "death_normal_right_up"

	anim_sprite.play(death_anim)
	if current_lives > 0:
		respawn_label.show()
		_start_respawn_countdown(5) 
	else:
		GameManager.reset_game(GameManager.ResetReason.DEATH)

	
func _start_respawn_countdown(seconds: int) -> void:
	respawn_timer.wait_time = seconds
	respawn_timer.start()

	var remaining = seconds
	respawn_label.text = "Respawning in %d.." % remaining

	while remaining > 0:
		respawn_label.text = "Respawning in %d.." % remaining
		await get_tree().create_timer(1.0).timeout
		remaining -= 1

	respawn_label.hide()
	# Restore player after countdown
	lose_life()
	# Play idle animation after respawn
	var suffix = "_with_gun" if has_gun else ""
	last_idle = "idle_down" + suffix
	anim_sprite.play(last_idle)

func _get_direction_from_mouse() -> String:
	var aim = (get_global_mouse_position() - global_position).normalized()

	if aim.x > 0.5:
		if aim.y < -0.5:
			return "up_right"
		elif aim.y > 0.5:
			return "down_right"
		else:
			return "right"
	elif aim.x < -0.5:
		if aim.y < -0.5:
			return "up_left"
		elif aim.y > 0.5:
			return "down_left"
		else:
			return "left"
	else:
		if aim.y < 0:
			return "up"
		else:
			return "down"


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	emit_signal("player_health_changed", current_health)
	if current_health == 0:
		_play_death_animation()

func get_attack_damage() -> int:
	if is_player_have_triple_damage_buff:
		return base_attack_damage * 3
	elif is_player_have_double_damage_buff:
		return base_attack_damage * 2
	return base_attack_damage

func get_attack_speed() -> float:
	if is_player_have_attack_speed_buff:
		return base_attack_speed * 1.5
	return base_attack_speed

func get_attack_range() -> int:
	if is_player_have_attack_range_buff:
		return int(base_attack_range * 1.5)
	return base_attack_range

func get_extra_live(heart):
	if current_lives >= max_lives:
		# Already at max, cannot pick up more
		return
	current_lives = min(current_lives + heart, max_lives)
	emit_signal("player_lives_changed", current_lives)
	show_floating_message("+%d Heart" % heart)

func get_extra_skip_skill(hints):
	if current_hints >= max_hints:
		# Already at max, cannot pick up more
		return
	current_hints = min(current_hints + hints, max_hints)
	emit_signal("player_hints_changed", current_hints)
	show_floating_message("+%d Skip Skill" % hints)

func get_bullet_magazine(magazine):
	if current_magazine >= max_magazine:
		# Already at max, cannot pick up more
		return
	current_magazine = min(current_magazine + magazine, max_magazine)
	emit_signal("player_magazine_changed", current_magazine)
	show_floating_message("+%d Magazine" % magazine)
	
func lose_life():
	if current_lives > 0:
		current_lives -= 1
		GameManager.death_count += 1
		current_health = max_health
		is_dead = false
		emit_signal("player_lives_changed", current_lives)
		emit_signal("player_health_changed", current_health)

		# Reset velocity to make sure player can move again
		velocity = Vector2.ZERO
	else:
		is_dead = true
		GameManager.reset_game(GameManager.ResetReason.DEATH)

func use_hint():
	if current_hints > 0:
		current_hints -= 1
		emit_signal("player_hints_changed", current_hints)

func start_buff(buff_type: String, duration: float = 180.0) -> void:
	var timer: Timer

	match buff_type:
		"double_damage":
			if is_player_have_triple_damage_buff:
				triple_damage_buff_cd.stop()
				is_player_have_triple_damage_buff = false
				emit_signal("player_buff", "triple_damage", 0.0)
			is_player_have_double_damage_buff = true
			show_floating_message("+Double Damage Buff")
			timer = double_damage_buff_cd
		"triple_damage":
			if is_player_have_double_damage_buff:
				double_damage_buff_cd.stop()
				is_player_have_double_damage_buff = false
				emit_signal("player_buff", "double_damage", 0.0)
			is_player_have_triple_damage_buff = true
			show_floating_message("+Triple Damage Buff")
			timer = triple_damage_buff_cd
		"attack_speed":
			is_player_have_attack_speed_buff = true
			show_floating_message("+Attack Speed Buff")
			timer = attack_speed_buff_cd
		"attack_range":
			is_player_have_attack_range_buff = true
			show_floating_message("+Attack Range Buff")
			timer = attack_range_buff_cd
		_:
			print("❌ Unknown buff type:", buff_type)
			return

	for conn in timer.timeout.get_connections():
		timer.timeout.disconnect(conn.callable)

	timer.timeout.connect(Callable(self, "_on_buff_timeout").bind(buff_type), CONNECT_DEFERRED)
	timer.stop()
	timer.wait_time = duration
	timer.one_shot = true
	timer.start()
	emit_signal("player_buff", buff_type, duration)

func _on_buff_timeout(buff_type: String) -> void:
	_remove_buff(buff_type)

func _remove_buff(buff_type: String) -> void:
	match buff_type:
		"double_damage": is_player_have_double_damage_buff = false
		"triple_damage": is_player_have_triple_damage_buff = false
		"attack_speed": is_player_have_attack_speed_buff = false
		"attack_range": is_player_have_attack_range_buff = false
	emit_signal("player_buff", buff_type, 0.0)

func get_save_state() -> Dictionary:
	return {
		"current_health": current_health,
		"current_lives": current_lives,
		"current_hints": current_hints,
		"current_bullet": current_bullet,
		"current_magazine": current_magazine,
		"has_gun": has_gun,
		"buffs": {
			"double_damage": is_player_have_double_damage_buff,
			"triple_damage": is_player_have_triple_damage_buff,
			"attack_speed": is_player_have_attack_speed_buff,
			"attack_range": is_player_have_attack_range_buff,
			"double_cd": double_damage_buff_cd.time_left,
			"triple_cd": triple_damage_buff_cd.time_left,
			"speed_cd": attack_speed_buff_cd.time_left,
			"range_cd": attack_range_buff_cd.time_left,
		}
	}

func load_save_state(state: Dictionary) -> void:
	current_health = state.get("current_health", max_health)
	current_lives = state.get("current_lives", max_lives)
	current_hints = state.get("current_hints", max_hints)
	current_bullet = state.get("current_bullet", max_bullet)
	current_magazine = state.get("current_magazine", max_magazine)
	has_gun = state.get("has_gun", false)

	var buffs = state.get("buffs", {})
	is_player_have_double_damage_buff = buffs.get("double_damage", false)
	is_player_have_triple_damage_buff = buffs.get("triple_damage", false)
	is_player_have_attack_speed_buff = buffs.get("attack_speed", false)
	is_player_have_attack_range_buff = buffs.get("attack_range", false)

	if buffs.get("double_cd", 0.0) > 0.0:
		start_buff("double_damage", buffs.get("double_cd"))
	if buffs.get("triple_cd", 0.0) > 0.0:
		start_buff("triple_damage", buffs.get("triple_cd"))
	if buffs.get("speed_cd", 0.0) > 0.0:
		start_buff("attack_speed", buffs.get("speed_cd"))
	if buffs.get("range_cd", 0.0) > 0.0:
		start_buff("attack_range", buffs.get("range_cd"))

	emit_signal("player_health_changed", current_health)
	emit_signal("player_lives_changed", current_lives)
	emit_signal("player_hints_changed", current_hints)
	emit_signal("player_bullet_changed", current_bullet)
	emit_signal("player_magazine_changed", current_magazine)

	# ✅ Set last_idle and play animation based on gun status
	var base_direction = "down"  # default idle direction on load
	var suffix = "_with_gun" if has_gun else ""
	last_idle = "idle_" + base_direction + suffix

	if anim_sprite.sprite_frames.has_animation(last_idle):
		anim_sprite.play(last_idle)

func _on_game_reset():
	current_health = max_health
	current_lives = max_lives
	current_hints = max_hints
	current_magazine = 3
	current_bullet = max_bullet
	has_gun = false  # ✅ Reset gun on game reset
	is_dead = false
	typing = false
	emit_signal("player_health_changed", current_health)
	emit_signal("player_lives_changed", current_lives)
	emit_signal("player_hints_changed", current_hints)
	emit_signal("player_magazine_changed", current_magazine)
	emit_signal("player_bullet_changed", current_bullet)
	reset_state()

func reset_state():
	var player_pos_in_first_floor = load("res://scenes/maps/first-floor-map.tscn").instantiate()
	var marker = player_pos_in_first_floor.get_node_or_null("first_floor_spawn_marker")

	global_position = marker.global_position
	velocity = Vector2.ZERO
	dash_velocity = Vector2.ZERO
	is_dashing = false
	is_shooting = false
	is_dead = false
	has_gun = false 
	typing = false
	
	is_player_have_double_damage_buff = false
	is_player_have_triple_damage_buff = false
	is_player_have_attack_speed_buff = false
	is_player_have_attack_range_buff = false

	double_damage_buff_cd.stop()
	triple_damage_buff_cd.stop()
	attack_speed_buff_cd.stop()
	attack_range_buff_cd.stop()

	emit_signal("player_buff", "double_damage", 0.0)
	emit_signal("player_buff", "triple_damage", 0.0)
	emit_signal("player_buff", "attack_speed", 0.0)
	emit_signal("player_buff", "attack_range", 0.0)

	if shooting_sound.playing:
		shooting_sound.stop()
	if not GameManager.is_game_started:
		last_idle = "idle_down"
	anim_sprite.play(last_idle)
	if not dash_timer.is_stopped():
		dash_timer.stop()
