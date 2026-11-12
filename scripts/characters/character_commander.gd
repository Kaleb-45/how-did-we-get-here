@tool
# The Commander: light blue shirt, short brown hair, a headset and a white ID badge.
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	# Short brown hair (a cap on the lid, tipped back so the forehead shows).
	add_hair_cap(load("res://materials/hair_brown.tres"), 0.8, 1.05)
	# Headset on the head.
	add_headset()
	# White ID badge on the chest (the person's left side).
	var badge := BoxMesh.new()
	badge.size = Vector3(0.07, 0.095, 0.02)
	add_on_body(badge, load("res://materials/cloth_labcoat_white.tres"), shoulder_y - 0.17, -top_r * 0.42, 0.012)
