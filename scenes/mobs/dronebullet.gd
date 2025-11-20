extends CharacterBody2D

var bullet_speed := 100
var attack_range := 0.0
var attack_damage := 0

var direction := Vector2.ZERO
var distance_traveled := 0.0
var start_position := Vector2.ZERO

func _ready():
	start_position = global_position
	$HitDetector.connect("area_entered", Callable(self, "_on_area_entered"))

	# 🔄 Rotate the bullet to face the direction it's moving
	rotation = direction.angle()

func _physics_process(delta):
	var move = direction * bullet_speed * delta
	var collision = move_and_collide(move)
	distance_traveled += move.length()

	# Stop on wall hit
	if collision:
		queue_free()
		return

	# Auto-remove after max range
	if distance_traveled >= attack_range:
		queue_free()

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(attack_damage)
	queue_free()
