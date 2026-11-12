@tool
# A Staff member (Staff 1, 2, 3 share this script): short hair and a headset.
# The shirt colour, skin and hair colour are set in each staff scene file.
extends "res://scripts/characters/character_base.gd"

# The hair colour (pick a hair_ material from res://materials).
@export var hair_material: Material:
	set(v):
		hair_material = v
		_queue_rebuild()


func _build_extras() -> void:
	var hair: Material = hair_material if hair_material else load("res://materials/hair_brown.tres")
	add_hair_cap(hair, 0.8, 1.05)
	add_headset()
