extends Control

@onready var system_message = $Panel/system_message
@onready var note_content = $Panel/content

func _ready() -> void:
	hide()

var notes = {
	"note1": {
		"title": "System Message: UNKNOWN",
		"content": "In the room where you awoke, look closer. The Lab never leaves its prey unarmed… for long."
	},
	"note2": {
		"title": "System Message: UNKNOWN",
		"content": "Surrounded by silent computers, only one still listens… and it remembers you."
	},
	"note3": {
		"title": "System Message: UNKNOWN",
		"content": "Every level has its guardian — a thing the Lab made, and could not unmake."
	},
	"note4": {
		"title": "System Message: UNKOWN",
		"content": "The escape lies where it all began — cold, locked, and waiting. But it only listens to the Cores."
	},
	"note5": {
		"title": "System Message: UNKNOWN",
		"content": "Specimen-D (Floor 1): Designed for reconnaissance. Small frame, high speed. Strikes quickly, but each hit barely wounds… until they swarm. Do not let them corner you."
	},
	"note6": {
		"title": "System Message: UNKNOWN",
		"content": "Specimen-R (Floor 2): Heavy construction unit repurposed for security. Moves slowly, but each strike can shatter bone. The Lab underestimated its hunger for destruction."
	},
	"note7": {
		"title": "System Message: UNKNOWN",
		"content": "Specimen-Ω (Floor 3): An abomination of speed and strength. Drone agility fused with robotic force. We could not contain it… we could only lock the doors and pray."
	}
}

func show_note(note_id: String):
	if note_id in notes:
		system_message.text = notes[note_id]["title"]
		note_content.text = notes[note_id]["content"]
		show()
