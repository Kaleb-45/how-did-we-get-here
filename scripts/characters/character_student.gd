@tool
# The Student: neat kid hair and a clean face. Shape: small and short.
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	var hair: Material = load("res://materials/hair_brown.tres")
	# A neat hair cap, tilted back so the forehead and eyes show.
	var cap := SphereMesh.new()
	cap.radius = top_r * 1.07
	cap.height = top_r * 1.07
	cap.is_hemisphere = true
	cap.radial_segments = 16
	cap.rings = 6
	add_shape(lid, cap, hair, Vector3(0, dome_h * 0.1, top_r * 0.08), Vector3(1, DOME_FRACTION * 1.05, 1), Vector3(0.75, 0, 0))
