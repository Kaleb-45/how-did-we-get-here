@tool
# The Assistant Scientist: wild messy hair and round glasses. Shape: tall thin cylinder.
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	var hair: Material = load("res://materials/char_hair_wild.tres")
	var glass: Material = load("res://materials/char_glasses.tres")
	# Messy hair: thin capsules sticking out of the top of the head in all directions.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var around := TAU * float(i) / 14.0 + rng.randf_range(-0.2, 0.2)
		var up := rng.randf_range(0.45, 0.95)
		var xf := cos(around) * sqrt(1.0 - up * up)
		var zf := sin(around) * sqrt(1.0 - up * up)
		var base := Vector3(xf * top_r, up * dome_h, zf * top_r)
		var dir := (Vector3(xf, up * 0.9, zf) + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.0, 0.6), rng.randf_range(-0.5, 0.5))).normalized()
		var strand_len := top_r * rng.randf_range(0.8, 1.3)
		var strand := CapsuleMesh.new()
		strand.radius = top_r * 0.13
		strand.height = strand_len
		var node := add_shape(lid, strand, hair, base + dir * strand_len * 0.35)
		node.basis = Basis(Quaternion(Vector3.UP, dir))
	# Round glasses: two rings around the eyes and a small bridge.
	for side in [-1, 1]:
		var ring := TorusMesh.new()
		ring.inner_radius = top_r * 0.2
		ring.outer_radius = top_r * 0.28
		ring.rings = 24
		ring.ring_segments = 8
		var node := add_shape(lid, ring, glass, dome_point(side * 0.36, 0.42, top_r * 0.03))
		node.basis = dome_basis(side * 0.36, 0.42) * Basis(Vector3.RIGHT, PI * 0.5)
	var bridge := BoxMesh.new()
	bridge.size = Vector3(top_r * 0.3, top_r * 0.04, top_r * 0.04)
	add_shape(lid, bridge, glass, dome_point(0.0, 0.42, top_r * 0.03))
