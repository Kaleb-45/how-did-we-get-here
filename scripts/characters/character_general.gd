@tool
# The General: gray mustache and an officer cap. Shape (set in his scene): V shape.
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	add_mustache(1.0)
	var navy: Material = load("res://materials/cloth_navy.tres")
	var gold: Material = load("res://materials/gold_trim.tres")
	# The cap sits high on the head so the eyes stay visible.
	var band_y := dome_h * 0.8
	var band_r := top_r * sqrt(1.0 - 0.8 * 0.8)
	var band := CylinderMesh.new()
	band.top_radius = band_r * 1.04
	band.bottom_radius = band_r * 1.12
	band.height = top_r * 0.2
	band.radial_segments = 16
	band.rings = 1
	add_shape(lid, band, gold, Vector3(0, band_y, 0))
	var crown := CylinderMesh.new()
	crown.top_radius = top_r * 0.95
	crown.bottom_radius = band_r * 1.1
	crown.height = top_r * 0.3
	crown.radial_segments = 16
	crown.rings = 1
	add_shape(lid, crown, navy, Vector3(0, band_y + top_r * 0.22, 0))
	var visor := BoxMesh.new()
	visor.size = Vector3(top_r * 0.8, top_r * 0.05, top_r * 0.4)
	add_shape(lid, visor, navy, Vector3(0, band_y - top_r * 0.04, -band_r * 1.1), Vector3.ONE, Vector3(-0.15, 0, 0))
	var badge := SphereMesh.new()
	badge.radius = top_r * 0.08
	badge.height = top_r * 0.16
	add_shape(lid, badge, gold, Vector3(0, band_y + top_r * 0.2, -band_r * 1.15))
