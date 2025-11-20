extends Label

@export var float_speed: float = 40
@export var lifetime: float = 1.5 

func _ready():
	# Automatically queue free after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	# Move the label up
	global_position.y -= float_speed * delta
