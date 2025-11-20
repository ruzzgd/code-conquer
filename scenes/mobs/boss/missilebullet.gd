extends CharacterBody2D

@export var speed: float = 300
@export var attack_damage: int = 10

var target: CharacterBody2D
var exploded: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_detector: Area2D = $HitDetector
@onready var explosion_sound: AudioStreamPlayer2D = $explosion

func _ready():
	hit_detector.area_entered.connect(_on_area_entered)
	
	# Make missile face down
	rotation_degrees = 90
	
	if anim_sprite:
		anim_sprite.play("missile_anim")

	# 🔊 Set initial volume from SoundSystem autoload
	explosion_sound.volume_db = linear_to_db(SoundSystem.player_volume)

	# 🔊 Connect to volume changes
	SoundSystem.player_volume_changed.connect(_update_sfx_volume)

func _update_sfx_volume(new_volume: float) -> void:
	# Stop and restart if already playing to apply new volume
	var was_playing = explosion_sound.playing
	explosion_sound.volume_db = linear_to_db(new_volume)
	if was_playing:
		explosion_sound.stop()
		explosion_sound.play()

func _physics_process(delta: float) -> void:
	if exploded or target == null:
		return

	# Move straight down
	velocity = Vector2(0, speed)
	move_and_slide()

	# Explode when reach horizontal line of player
	if global_position.y >= target.global_position.y:
		_explode()

func _explode():
	if exploded:
		return
	exploded = true
	velocity = Vector2.ZERO

	# Re-center explosion
	anim_sprite.position = Vector2.ZERO
	rotation_degrees = 0

	if anim_sprite:
		anim_sprite.play("missile_explode_anim")

	# 🔊 Play explosion sound
	explosion_sound.stop()
	explosion_sound.play()

	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(attack_damage)
	_explode()
