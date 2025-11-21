extends CharacterBody2D

# --- Nodes ---
@onready var full_body_anim: AnimatedSprite2D = $FullBodySprite
@onready var torso_sprite: AnimatedSprite2D = $TorsoSprite
@onready var leg_sprite: AnimatedSprite2D = $LegSprite
@onready var patrol_area = $"../PatrolArea"
@onready var detection_area: Area2D = $"../DetectionArea"
@onready var machine_gun_scene = preload("res://scenes/mobs/boss/machinegunbullet.tscn")
@onready var missile_scene = preload("res://scenes/mobs/boss/missilebullet.tscn")
@onready var core_scene = preload("res://scenes/chest_and_buff_and_core/core/red-core.tscn")

# --- Sounds ---
@onready var machine_gun_sound = $machine_gun
@onready var flame_thrower_sound = $flame_thrower
@onready var death_sound = $death_sound
@onready var walking_sound = $walk_sound

# --- Boss Settings ---
@export var boss_id: String = "boss_lab"  # unique ID per boss for save/load
@export var movement_speed: float = 50
@export var attack1_range: float = 80.0
@export var attack2_range: float = 150.0
@export var attack3_range: float = 200.0
@export var attack1_damage: int = 30
@export var attack2_damage: int = 3
@export var attack3_damage: int = 15
@export var attack_cooldown: float = 1.0
@export var missile_cooldown: float = 3.0
@export var min_safe_distance: float = 50.0  # Boss relocation distance

# --- Boss HP ---
@onready var boss_hp_bar = $"boss-hp"
@export var boss_max_hp: int = 1000
var boss_current_hp: int = boss_max_hp

# --- Internal Variables ---
var radius: float = 0.0
var target_position: Vector2
var wait_time: float = 0.0
var velocity_smooth: Vector2 = Vector2.ZERO
var attacking: bool = false
var attack_timer: float = 0.0
var player_in_range: CharacterBody2D = null
var is_dying: bool = false
var current_attack: int = 0  # 1=Flamethrower, 2=Machine Gun, 3=Missile

# --- Machine Gun Variables ---
var bullets_left := 0
var machine_gun_damage := 0
@onready var machine_gun_timer: Timer = Timer.new()
@onready var missile_timer: Timer = Timer.new()
@onready var muzzle_right: Marker2D = $TorsoSprite/MuzzleRight
@onready var muzzle_left: Marker2D = $TorsoSprite/MuzzleLeft
var facing_right := true

# --- Boss Mode ---
enum BossMode { IDLE, PATROL, CHASE, ATTACK, RELOCATE }
var current_mode: BossMode = BossMode.IDLE

# --- Relocation ---
var relocating := false
var relocation_target := Vector2.ZERO

func _ready() -> void:
	randomize()

	# --- Check if already killed ---
	if boss_id != "" and SaveSystem.is_boss_killed(boss_id):
		queue_free()
		return

	var shape = patrol_area.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		radius = shape.radius
	_pick_new_target()

	if boss_hp_bar:
		boss_hp_bar.max_value = boss_max_hp
		boss_hp_bar.value = boss_current_hp
		boss_hp_bar.visible = false

	# Setup timers
	machine_gun_timer.wait_time = 0.1
	machine_gun_timer.one_shot = false
	machine_gun_timer.timeout.connect(_shoot_machine_gun_bullet)
	add_child(machine_gun_timer)

	missile_timer.wait_time = missile_cooldown
	missile_timer.one_shot = true
	add_child(missile_timer)

	# Sync boss SFX
	machine_gun_sound.volume_db = linear_to_db(SoundSystem.player_volume)
	flame_thrower_sound.volume_db = linear_to_db(SoundSystem.player_volume)
	death_sound.volume_db = linear_to_db(SoundSystem.player_volume)
	walking_sound.volume_db = linear_to_db(SoundSystem.player_volume)
	SoundSystem.player_volume_changed.connect(_on_sfx_volume_changed)

	# --- Ensure boss disappears on map reload ---
	if SaveSystem.loaded:
		_apply_saved_state()
	else:
		SaveSystem.save_loaded.connect(_apply_saved_state)

func _apply_saved_state():
	if boss_id != "" and SaveSystem.is_boss_killed(boss_id):
		call_deferred("queue_free")

func _on_sfx_volume_changed(new_volume: float) -> void:
	machine_gun_sound.volume_db = linear_to_db(new_volume)
	flame_thrower_sound.volume_db = linear_to_db(new_volume)
	death_sound.volume_db = linear_to_db(new_volume)
	walking_sound.volume_db = linear_to_db(new_volume)

func _physics_process(delta: float) -> void:
	if not GameManager.is_game_started or is_dying:
		_stop_all_attacks()
		return

	# Detect Player
	player_in_range = null
	for body in detection_area.get_overlapping_bodies():
		if body.is_in_group("player") and not (body.has_method("is_dead_state") and body.is_dead_state()):
			player_in_range = body
			break

	# Reset attack and chase
	attacking = false
	var new_mode = BossMode.IDLE

	if player_in_range and not player_in_range.is_dead_state():
		var distance = global_position.distance_to(player_in_range.global_position)
		# --- Relocate if too close ---
		if distance < min_safe_distance:
			_start_relocation()
			new_mode = BossMode.RELOCATE
		elif distance <= attack1_range:
			new_mode = BossMode.ATTACK
			current_attack = 1
			attack_timer -= delta
			if attack_timer <= 0:
				_attack_player(attack1_damage)
				attack_timer = attack_cooldown
		elif distance <= attack2_range:
			new_mode = BossMode.ATTACK
			current_attack = 2
			_fire_machine_gun(attack2_damage)
		elif distance <= attack3_range:
			new_mode = BossMode.ATTACK
			current_attack = 3
			if missile_timer.is_stopped():
				_fire_missile_rain()
				missile_timer.start()
			_stop_attack_machine_gun()
		else:
			new_mode = BossMode.CHASE
			_chase_player(delta)
	elif current_mode == BossMode.RELOCATE:
		_move_to_relocation(delta)
	else:
		new_mode = BossMode.PATROL
		_patrol(delta)

	current_mode = new_mode
	_update_animation()
	_flip_sprites(velocity_smooth)

# --- Relocation ---
func _start_relocation():
	if relocating or not player_in_range:
		return
	var attempts = 10
	var dodge_distance = min_safe_distance + 20
	while attempts > 0:
		var angle = (player_in_range.global_position - global_position).angle() + randf_range(-PI/2, PI/2)
		var offset = Vector2(cos(angle), sin(angle)) * dodge_distance
		var new_pos = player_in_range.global_position + offset
		if new_pos.distance_to(player_in_range.global_position) > min_safe_distance:
			relocation_target = new_pos
			relocating = true
			break
		attempts -= 1

func _move_to_relocation(delta: float):
	if not relocating or not player_in_range:
		relocating = false
		return
	var direction = (relocation_target - global_position).normalized()
	velocity_smooth = velocity_smooth.lerp(direction * movement_speed, 0.2)
	velocity = velocity_smooth
	move_and_slide()
	if global_position.distance_to(relocation_target) < 5:
		relocating = false

# --- Animations / Sprite Flip ---
func _update_animation() -> void:
	if is_dying:
		_stop_all_attacks()
		return

	match current_mode:
		BossMode.IDLE, BossMode.PATROL:
			full_body_anim.visible = true
			torso_sprite.visible = false
			leg_sprite.visible = false
			if velocity_smooth.length() > 0.1:
				full_body_anim.play("walk")
				full_body_anim.speed_scale = velocity_smooth.length() / movement_speed
				if not walking_sound.playing:
					walking_sound.play()
			else:
				full_body_anim.play("idle")
				full_body_anim.speed_scale = 1.0
				if walking_sound.playing:
					walking_sound.stop()
		BossMode.CHASE, BossMode.RELOCATE:
			full_body_anim.visible = false
			torso_sprite.visible = true
			leg_sprite.visible = true
			torso_sprite.play("attack_2")
			if velocity_smooth.length() > 0.1:
				leg_sprite.play("walk")
				leg_sprite.speed_scale = velocity_smooth.length() / movement_speed
				if not walking_sound.playing:
					walking_sound.play()
			else:
				leg_sprite.play("idle")
				if walking_sound.playing:
					walking_sound.stop()
		BossMode.ATTACK:
			full_body_anim.visible = false
			torso_sprite.visible = true
			leg_sprite.visible = true
			match current_attack:
				1:
					torso_sprite.play("attack_1")
					if not flame_thrower_sound.playing:
						flame_thrower_sound.play()
				2:
					torso_sprite.play("attack_2")
				3:
					torso_sprite.play("attack_3")
			leg_sprite.play("idle")
			if walking_sound.playing:
				walking_sound.stop()

func _flip_sprites(dir: Vector2) -> void:
	var flip = false
	if player_in_range and (current_mode == BossMode.CHASE or current_mode == BossMode.ATTACK or current_mode == BossMode.RELOCATE):
		flip = player_in_range.global_position.x < global_position.x
	elif dir.x < 0:
		flip = true
	elif dir.x > 0:
		flip = false
	full_body_anim.flip_h = flip
	torso_sprite.flip_h = flip
	leg_sprite.flip_h = flip
	facing_right = not flip

# --- Attacks ---
func _stop_all_attacks():
	_stop_attack_machine_gun()
	if flame_thrower_sound.playing:
		flame_thrower_sound.stop()
	if walking_sound.playing:
		walking_sound.stop()
	attacking = false
	current_attack = 0

func _stop_attack_machine_gun():
	if not machine_gun_timer.is_stopped():
		machine_gun_timer.stop()
	if machine_gun_sound.playing:
		machine_gun_sound.stop()

func _chase_player(delta: float):
	if not player_in_range:
		return
	var direction = (player_in_range.global_position - global_position).normalized()
	velocity_smooth = velocity_smooth.lerp(direction * movement_speed, 0.2)
	velocity = velocity_smooth
	move_and_slide()

func _attack_player(damage: int) -> void:
	if player_in_range.has_method("take_damage"):
		player_in_range.take_damage(damage)
	attacking = true
	if not flame_thrower_sound.playing:
		flame_thrower_sound.play()

func _fire_machine_gun(damage: int) -> void:
	if machine_gun_timer.is_stopped():
		bullets_left = 3
		machine_gun_damage = damage
		machine_gun_timer.start()
		if not machine_gun_sound.playing:
			machine_gun_sound.play()
	attacking = true

func _shoot_machine_gun_bullet() -> void:
	if bullets_left <= 0 or not player_in_range or player_in_range.is_dead_state():
		_stop_attack_machine_gun()
		return
	var bullet = machine_gun_scene.instantiate()
	var muzzle = muzzle_right if facing_right else muzzle_left
	bullet.global_position = muzzle.global_position
	bullet.direction = (player_in_range.global_position - muzzle.global_position).normalized()
	bullet.attack_damage = machine_gun_damage
	bullet.attack_range = attack2_range
	get_tree().current_scene.add_child(bullet)
	bullets_left -= 1

func _fire_missile_rain() -> void:
	if not player_in_range:
		return
	attacking = true
	torso_sprite.play("attack_3")
	leg_sprite.play("idle")
	for i in range(6):
		if not player_in_range or not is_instance_valid(player_in_range):
			break
		var missile = missile_scene.instantiate()
		var offset_x = randf_range(-150, 150)
		missile.global_position = player_in_range.global_position + Vector2(offset_x, -200)
		missile.attack_damage = attack3_damage
		missile.target = player_in_range
		get_tree().current_scene.add_child(missile)
		await get_tree().create_timer(0.6).timeout
	attacking = false

# --- Patrol / Target ---
func _patrol(delta: float) -> void:
	var to_center = patrol_area.global_position - global_position
	var desired_direction: Vector2
	if to_center.length() > radius:
		desired_direction = to_center.normalized()
	else:
		desired_direction = (target_position - global_position).normalized()
	velocity_smooth = velocity_smooth.lerp(desired_direction * movement_speed, 0.1)
	velocity = velocity_smooth
	move_and_slide()
	if global_position.distance_to(target_position) < 5 and to_center.length() <= radius:
		velocity_smooth = Vector2.ZERO
		wait_time = randf_range(1.0, 2.5)
		_pick_new_target()

func _pick_new_target() -> void:
	while true:
		var angle = randf() * TAU
		var r = randf() * radius
		var point = patrol_area.global_position + Vector2(cos(angle), sin(angle)) * r
		if (point - patrol_area.global_position).length() <= radius:
			target_position = point
			break

# --- Boss Life ---
func take_damage(amount: int) -> void:
	if is_dying:
		return
	boss_current_hp = clamp(boss_current_hp - amount, 0, boss_max_hp)
	if boss_hp_bar:
		boss_hp_bar.value = boss_current_hp
		boss_hp_bar.visible = true
	if boss_current_hp <= 0:
		die()

func die() -> void:
	if is_dying:
		return
	is_dying = true
	_stop_all_attacks()
	velocity = Vector2.ZERO

	death_sound.play()
	torso_sprite.visible = false
	leg_sprite.visible = false
	full_body_anim.visible = true
	full_body_anim.play("death")
	full_body_anim.speed_scale = 1.0
	full_body_anim.flip_h = not facing_right

	# --- Save as killed ---
	if boss_id != "":
		SaveSystem.mark_boss_killed(boss_id)

	# Spawn core
	if core_scene:
		var core_instance = core_scene.instantiate()
		core_instance.global_position = global_position + Vector2(0, 16)
		get_tree().current_scene.add_child(core_instance)

	queue_free()
