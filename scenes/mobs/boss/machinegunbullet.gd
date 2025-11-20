extends CharacterBody2D

# --- Bullet Properties ---
@export var bullet_speed: float = 250
@export var attack_range: float = 0
@export var attack_damage: int = 0

var direction: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0
var start_position: Vector2 = Vector2.ZERO

# --- Nodes ---
@onready var hit_detector: Area2D = $HitDetector
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	start_position = global_position
	if direction != Vector2.ZERO:
		rotation = direction.angle()  
	hit_detector.area_entered.connect(_on_area_entered)
	if anim_sprite:
		anim_sprite.play("missile_anim")

func _physics_process(delta: float) -> void:
	var move = direction * bullet_speed * delta
	var collision = move_and_collide(move)
	distance_traveled += move.length()
	
	if collision:
		queue_free()
		return

	# Auto-remove after max range
	if distance_traveled >= attack_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(attack_damage)
	queue_free()
