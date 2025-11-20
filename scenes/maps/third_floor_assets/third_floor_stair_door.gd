extends Area2D

@onready var blocker = $StaticBody2D/CollisionShape2D
@onready var open_door_texture = $open_door  
@onready var close_door_texture = $close_door
@onready var shadow = $ColorRect2

var is_open = false
var player: Node = null

func _ready() -> void:
	close_door_texture.visible = true
	open_door_texture.visible = false
	shadow.visible = false
	player = get_tree().current_scene.find_child("Player", true, false)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body

		# Optional: Face down before fading
		var suffix = "_with_gun" if player.has_gun else ""
		player.last_idle = "idle_down" + suffix
		player.anim_sprite.play(player.last_idle)
		_delayed_change_floor()
		
func _delayed_change_floor():
	# Change map
	GameManager.update_map(
		GameManager.second_floor_underground_map,
		GameManager.second_floor_underground_stair_spawner2
	)

	await get_tree().process_frame
	player = get_tree().current_scene.find_child("Player", true, false)
	if not player:
		print("⚠️ Could not find player after scene change")

func _on_button_pressed() -> void:
	if not is_open:
		open_door()

func open_door() -> void:
	is_open = true
	blocker.hide()
	blocker.disabled = true

	shadow.visible = true
	close_door_texture.visible = false
	open_door_texture.visible = true

	auto_close_door_after_delay()

func auto_close_door_after_delay() -> void:
	await get_tree().create_timer(10.0).timeout
	close_door()

func close_door() -> void:
	is_open = false
	blocker.show()
	blocker.disabled = false

	shadow.visible = false
	close_door_texture.visible = true
	open_door_texture.visible = false
