@tool
# The General: navy uniform, peaked cap, gray mustache, heavy brows, gold shoulder
# boards, three medals, a belt, and ONE pointing finger. Shape (set in his scene): V shape.
extends "res://scripts/characters/character_base.gd"


# Heavy brows: longer, thicker.
func _brow_scale() -> Vector3:
	return Vector3(1.2, 1.5, 1.2)


func _build_extras() -> void:
	var navy: Material = load("res://materials/cloth_navy.tres")
	var gold: Material = load("res://materials/gold_trim.tres")
	var orange: Material = load("res://materials/accent_orange.tres")
	var cyan: Material = load("res://materials/accent_cyan.tres")
	var belt_gray: Material = load("res://materials/cloth_dark_gray.tres")

	# Gray mustache (it is on the lid, so it lifts with the top lip).
	add_mustache(1.0)

	# Belt with a gold buckle, at the waist (where jacket meets trousers).
	add_belt(belt_gray, waist_y(), 0.07)
	var buckle := BoxMesh.new()
	buckle.size = Vector3(0.1, 0.085, 0.03)
	add_on_body(buckle, gold, waist_y(), 0.0, 0.02)

	# Gold shoulder boards: a flat gold box on top of each shoulder ball.
	for s in [-1, 1]:
		var board := BoxMesh.new()
		board.size = Vector3(arm_r * 2.7, arm_r * 0.5, arm_r * 2.6)
		add_shape(rig, board, gold, Vector3(s * shoulder_x, shoulder_y + arm_r * 1.0, 0),
			Vector3.ONE, Vector3(0, 0, s * _arm_tilt * 0.7))

	# A row of 3 medal blocks on the left of the chest: gold, orange, cyan.
	var medal_mats: Array[Material] = [gold, orange, cyan]
	for i in 3:
		var medal := BoxMesh.new()
		medal.size = Vector3(0.085, 0.1, 0.03)
		add_on_body(medal, medal_mats[i], shoulder_y - 0.17, -top_r * (0.18 + 0.24 * i), 0.018)

	# The pointing finger on the right hand (point_at_camera() sticks it out).
	add_pointer_finger()

	# The cap sits high on the head so the eyes stay visible.
	var band_y := dome_h * 0.86
	var band_r := top_r * sqrt(1.0 - 0.86 * 0.86)
	var band := CylinderMesh.new()
	band.top_radius = band_r * 1.04
	band.bottom_radius = band_r * 1.12
	band.height = top_r * 0.2
	band.radial_segments = FACETS
	band.rings = 1
	add_shape(lid, band, gold, Vector3(0, band_y, 0))
	var crown := CylinderMesh.new()
	crown.top_radius = top_r * 0.95
	crown.bottom_radius = band_r * 1.1
	crown.height = top_r * 0.3
	crown.radial_segments = FACETS
	crown.rings = 1
	add_shape(lid, crown, navy, Vector3(0, band_y + top_r * 0.22, 0))
	var visor := BoxMesh.new()
	visor.size = Vector3(top_r * 0.8, top_r * 0.05, top_r * 0.4)
	add_shape(lid, visor, navy, Vector3(0, band_y - top_r * 0.04, -band_r * 1.1), Vector3.ONE, Vector3(-0.15, 0, 0))
	var badge := SphereMesh.new()
	badge.radius = top_r * 0.08
	badge.height = top_r * 0.16
	badge.radial_segments = 6
	badge.rings = 3
	add_shape(lid, badge, gold, Vector3(0, band_y + top_r * 0.2, -band_r * 1.15))
