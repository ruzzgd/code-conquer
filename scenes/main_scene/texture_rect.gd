extends TextureRect

@onready var mat := material

var glitch_active := false
var timer := 0.0       # counts current phase time
var phase := "wait"    # "wait" = normal, "glitch" = glitching

func _ready():
	# start in normal phase
	mat.set("shader_param/glitch_strength", 0.0)
	timer = 10.0  # first wait 10 seconds

func _process(delta):
	timer -= delta
	if timer <= 0.0:
		if phase == "wait":
			# Start glitch phase
			phase = "glitch"
			glitch_active = true
			mat.set("shader_param/glitch_strength", 1.0)
			timer = randf_range(5.0, 10.0)  # glitch duration
		elif phase == "glitch":
			# End glitch phase, go back to normal
			phase = "wait"
			glitch_active = false
			mat.set("shader_param/glitch_strength", 0.0)
			timer = 10.0  # normal duration before next glitch
