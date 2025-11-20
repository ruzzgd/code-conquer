extends Node2D

@onready var decoration1 = $decoration1/AnimatedSprite2D
@onready var decoration2 = $decoration2/AnimatedSprite2D
@onready var decoration3 = $decoration3/AnimatedSprite2D

@onready var computer1 = $"computer-decor1/computer1"
@onready var computer2 = $"computer-decor1/computer2"
@onready var computer3 = $"computer-decor1/computer3"
@onready var computer4 = $"computer-decor1/computer4"
@onready var computer5 = $"computer-decor1/computer5"
@onready var computer6 = $"computer-decor1/computer6"

func _ready() -> void:
	decoration1.play()
	decoration2.play()
	decoration3.play()
	computer1.play()
	computer2.play()
	computer3.play()
	computer4.play()
	computer5.play()
	computer6.play()
	
