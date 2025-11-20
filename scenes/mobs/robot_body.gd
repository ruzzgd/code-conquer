extends CharacterBody2D

@export var speed := 80
@export var chase_speed := 80
var robot_max_hp := 150
var robot_current_hp := 150  
@export var robot_range := 100  
@export var robot_damage := 20
@export var attack_speed := 1
@export var min_safe_distance := 30

@onready var attack_timer = $attack_timer
@onready var bullet_scene = preload("res://scenes/mobs/RobotBullet.tscn")
@onready var chase_area = $"../ChaseArea"
@onready var patrol_area = $"../PatrolArea"
@onready var area_to_detect = $AreaToDetect
@onready var robot_hp = $"robot-hp"
@onready var ray = $LineOfSightRay
@onready var anim = $AnimatedSprite2D
@onready var muzzle = $Muzzle

@onready var shooting = $ShootingSound
@onready var death_sound = $DeathSound
@onready var walking_sound = $WalkingSound

@onready var bronze_chest_scene = preload("res://scenes/chest_and_buff_and_core/chest_container/all_bronze_chest.tscn")
@onready var silver_chest_scene = preload("res://scenes/chest_and_buff_and_core/chest_container/all_silver_chest.tscn")
@onready var gold_chest_scene = preload("res://scenes/chest_and_buff_and_core/chest_container/all_gold_chest.tscn")

var start_position: Vector2  
var target_position: Vector2  
var player: Node2D = null  
var chasing := false  
var patrol_timer := 0.0
var relocating := false
var relocation_target := Vector2.ZERO
var stuck_timer := 0.0
var last_position := Vector2.ZERO
var stuck_check_interval := 1.0
var returning := false
var is_dying := false
var robot_id: String = ""

func _ready():
	SoundSystem.mob_volume_changed.connect(_on_mob_volume_changed)
	_on_mob_volume_changed(SoundSystem.mob_volume) 
	robot_id = get_parent().robot_id
	if robot_id == "":
		push_error("❌ Missing robot_id for robot at " + str(global_position))

	if SaveSystem.loaded:
		_check_if_robot_is_dead()
	else:
		SaveSystem.save_loaded.connect(_check_if_robot_is_dead)

	robot_hp.visible = false
	start_position = global_position  
	pick_new_target()  
	robot_hp.max_value = robot_max_hp
	robot_hp.value = robot_current_hp

	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(robot_shooting)

	area_to_detect.body_entered.connect(_on_area_to_detect_entered)
	area_to_detect.body_exited.connect(_on_area_to_detect_exited)
	chase_area.body_exited.connect(_on_chase_area_exited)
	anim.animation_finished.connect(_on_animation_finished)

func _process(delta):
	if is_dying:
		return

	# 🚫 Block AI actions while game is not started or loading screen is active
	if not GameManager.is_game_started or (SoundSystem and SoundSystem.is_loading):
		velocity = Vector2.ZERO
		move_and_slide()
		attack_timer.stop()
		shooting.stop()
		return

	check_if_stuck(delta)

	if not player:
		for body in area_to_detect.get_overlapping_bodies():
			if body.is_in_group("player") and not body.is_dead_state() and chase_area.overlaps_body(body):
				player = body
				if can_see_player():
					chasing = true
				else:
					player = null
				break

	if is_dying:
		return

	if chasing and player:
		if player.is_dead_state():
			chasing = false
			player = null
			attack_timer.stop()
			shooting.stop()
			stop_movement()
			return

		if not can_see_player():
			chasing = false
			player = null
			stop_movement()
			attack_timer.stop()
			shooting.stop()
			return

		if relocating:
			move_to_relocation(delta)
		else:
			handle_combat_positioning()
	elif player and not player.is_dead_state() and chase_area.overlaps_body(player):
		if can_see_player():
			chasing = true
	else:
		if is_patrolling_enabled():
			returning = false
			patrol(delta)
		elif returning:
			return_to_start(delta)
		else:
			stop_movement()

func _on_mob_volume_changed(new_volume: float):
	var db = linear_to_db(new_volume)
	shooting.volume_db = db
	walking_sound.volume_db = db
	death_sound.volume_db = db

func _check_if_robot_is_dead():
	if SaveSystem.is_robot_killed(robot_id):
		queue_free()

func is_patrolling_enabled() -> bool:
	return get_parent().is_patroling

func patrol(delta):
	if is_dying:
		return

	if patrol_timer > 0:
		patrol_timer -= delta
		stop_movement()  # Plays idle animation
		return

	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	update_animation(direction, "walk")
	move_and_slide()

	attack_timer.stop()
	shooting.stop()

	if global_position.distance_to(target_position) < 5:
		patrol_timer = randf_range(0.5, 1.5)
		pick_new_target()

func handle_combat_positioning():
	if is_dying:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > robot_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * chase_speed
		update_animation(direction, "walk")
		move_and_slide()
		attack_timer.stop()
		shooting.stop()

	elif distance_to_player < min_safe_distance:
		start_relocation()
		attack_timer.stop()
		shooting.stop()

	else:
		velocity = Vector2.ZERO
		move_and_slide()

		var shoot_dir = Vector2(player.global_position.x - global_position.x, 0)
		update_animation(shoot_dir, "shoot")

		if attack_timer.is_stopped():
			attack_timer.start()
		if not shooting.playing:
			shooting.play()

func start_relocation():
	if is_dying or not player:
		return

	var attempts = 10
	var dodge_distance = 60
	var angle_offset = PI / 2

	while attempts > 0:
		var angle = (player.global_position - global_position).angle() + randf_range(-angle_offset, angle_offset)
		var offset = Vector2(cos(angle), sin(angle)) * dodge_distance
		var new_pos = player.global_position + offset

		if new_pos.distance_to(player.global_position) > min_safe_distance and new_pos.distance_to(global_position) > 10:
			relocation_target = new_pos
			relocating = true
			break
		attempts -= 1

func move_to_relocation(delta):
	if is_dying:
		return

	var direction = (relocation_target - global_position).normalized()
	velocity = direction * speed
	update_animation(direction, "walk")
	move_and_slide()

	attack_timer.stop()
	shooting.stop()

	if global_position.distance_to(relocation_target) < 5:
		stop_movement()
		relocating = false
		if player and chasing:
			handle_combat_positioning()

func stop_movement():
	if is_dying:
		return
	velocity = Vector2.ZERO
	move_and_slide()
	update_animation(Vector2.ZERO, "idle")

func pick_new_target():
	if is_dying:
		return

	var angle = randf() * TAU
	var patrol_radius = 100

	if patrol_area and patrol_area.get_node_or_null("CollisionShape2D"):
		var shape = patrol_area.get_node("CollisionShape2D").shape
		if shape is CircleShape2D:
			patrol_radius = shape.radius

	target_position = start_position + Vector2(cos(angle), sin(angle)) * patrol_radius

func check_if_stuck(delta):
	if is_dying:
		return

	stuck_timer += delta
	if stuck_timer >= stuck_check_interval:
		var moved_distance = global_position.distance_to(last_position)
		if moved_distance < 2:
			if chasing:
				start_relocation()
			else:
				pick_new_target()
			patrol_timer = 0.0
		last_position = global_position
		stuck_timer = 0.0

func _on_area_to_detect_entered(body):
	if is_dying or not GameManager.is_game_started:
		return

	if body.is_in_group("player") and not body.is_dead_state():
		if chase_area.overlaps_body(body) and can_see_player():
			chasing = true
			player = body

func _on_area_to_detect_exited(body):
	if is_dying:
		return

	if body == player:
		chasing = false
		player = null
		relocating = false
		attack_timer.stop()
		shooting.stop()
		patrol_timer = 1.5
		pick_new_target()

func _on_chase_area_exited(body):
	if is_dying:
		return

	if body == player:
		chasing = false
		player = null
		relocating = false
		attack_timer.stop()
		shooting.stop()
		stop_movement()
		patrol_timer = 1.5
		if not is_patrolling_enabled():
			returning = true
		else:
			pick_new_target()

func robot_shooting():
	if is_dying:
		return

	if player and not player.is_dead_state() and global_position.distance_to(player.global_position) <= robot_range:
		if not can_see_player():
			return
		var bullet = bullet_scene.instantiate()
		bullet.global_position = get_muzzle_position()
		bullet.direction = (player.global_position - global_position).normalized()
		bullet.attack_range = robot_range
		bullet.attack_damage = robot_damage
		get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
	if is_dying:
		return

	robot_current_hp = clamp(robot_current_hp - amount, 0, robot_max_hp)
	robot_hp.value = robot_current_hp
	robot_hp.visible = true

	if robot_current_hp <= 0:
		die()

func die():
	if is_dying:
		return
	is_dying = true

	velocity = Vector2.ZERO
	move_and_slide()

	shooting.stop()
	attack_timer.stop()
	walking_sound.stop()

	death_sound.play()
	anim.play("death_left" if anim.flip_h else "death_right")

	SaveSystem.killed_robots[robot_id] = true
	GameManager.killed_robots_count += 1
	maybe_drop_chest()

func maybe_drop_chest():
	var roll = randf() * 100
	var chest

	if roll < 10.0:
		chest = gold_chest_scene.instantiate()
	elif roll < 15.0:
		chest = silver_chest_scene.instantiate()
	elif roll < 25.0:
		chest = bronze_chest_scene.instantiate()

	if chest:
		var spawn_position = global_position
		chest.global_position = spawn_position - Vector2(0, 20)
		chest.is_from_robot = true
		get_tree().current_scene.add_child(chest)

func _on_animation_finished():
	if anim.animation == "death_left" or anim.animation == "death_right":
		queue_free()

func can_see_player() -> bool:
	if not player:
		return false

	var to_player = player.global_position - global_position
	ray.target_position = to_player

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider != player:
			return false
	return true

func return_to_start(delta):
	if is_dying:
		return

	var direction = (start_position - global_position).normalized()
	velocity = direction * speed
	update_animation(direction, "walk")
	move_and_slide()

	if global_position.distance_to(start_position) < 5:
		stop_movement()
		returning = false

func update_animation(direction: Vector2, action: String = "walk") -> void:
	if is_dying:
		return

	if direction.x < 0:
		anim.flip_h = true
	elif direction.x > 0:
		anim.flip_h = false

	var anim_name = action + "_right"
	if anim.animation != anim_name:
		anim.play(anim_name)

	if anim_name == "walk_right" and is_player_in_hearing_range():
		if not walking_sound.playing:
			walking_sound.play()
	else:
		if walking_sound.playing:
			walking_sound.stop()

func is_player_in_hearing_range() -> bool:
	if not player:
		return false
	return chase_area.overlaps_body(player)

func apply_saved_state():
	if SaveSystem.is_robot_killed(robot_id):
		queue_free()
	else:
		print("🤖 Robot alive:", robot_id)

func get_muzzle_position() -> Vector2:
	var offset = muzzle.position
	if anim.flip_h:
		offset.x = -offset.x
	return global_position + offset
