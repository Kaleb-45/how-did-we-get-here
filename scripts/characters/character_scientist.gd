@tool
# The Assistant Scientist: open white lab coat over a teal shirt, two pens in the
# pocket, round glasses, a bald top with 4 chunky gray tufts, and a clipboard in the
# LEFT hand. Shape: tall thin cylinder.
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	var hair: Material = load("res://materials/hair_pale.tres")
	var glass: Material = load("res://materials/glasses.tres")
	var shirt: Material = load("res://materials/cloth_teal.tres")
	var pocket_mat: Material = load("res://materials/cloth_cream.tres")

	# --- the coat is open at the front: a teal shirt shows down the middle ---
	var shirt_top := head_base_y - 0.03
	var shirt_bottom := waist_y() - 0.05
	var panel := BoxMesh.new()
	panel.size = Vector3(top_r * 0.62, shirt_top - shirt_bottom, 0.012)
	add_on_body(panel, shirt, (shirt_top + shirt_bottom) * 0.5, 0.0, 0.026)

	# --- coat pocket on the chest (the person's left) with two pens ---
	var pocket_y := shoulder_y - 0.2
	var pocket := BoxMesh.new()
	pocket.size = Vector3(0.085, 0.07, 0.012)
	add_on_body(pocket, pocket_mat, pocket_y, -top_r * 0.62, 0.008)
	var pens: Array[Material] = [load("res://materials/accent_orange.tres"), load("res://materials/accent_cyan.tres")]
	for i in 2:
		var pen := CylinderMesh.new()
		pen.top_radius = 0.008
		pen.bottom_radius = 0.008
		pen.height = 0.075
		pen.radial_segments = 6
		pen.rings = 1
		add_on_body(pen, pens[i], pocket_y + 0.05, -top_r * (0.5 + 0.2 * i), 0.012)

	# --- bald on top, with 4 chunky gray tufts that sweep out to the sides ---
	# Two on each side: an upper one that sweeps up, a lower one that sweeps out.
	for side in [-1, 1]:
		for tuft in [[0.78, 0.5, 0.5], [0.95, 0.2, 0.15]]:
			var blob := SphereMesh.new()
			blob.radius = 1.0
			blob.height = 2.0
			blob.radial_segments = SMALL_FACETS
			blob.rings = 4
			var node := add_shape(lid, blob, hair, dome_point(side * tuft[0], tuft[1], top_r * 0.1))
			node.basis = Basis(Vector3.BACK, side * tuft[2]) * Basis.from_scale(Vector3(0.5, 0.24, 0.24) * top_r)

	# --- round glasses: two rings around the eyes and a small bridge ---
	for side in [-1, 1]:
		var ring := TorusMesh.new()
		ring.inner_radius = top_r * 0.2
		ring.outer_radius = top_r * 0.28
		ring.rings = 10
		ring.ring_segments = 6
		var node := add_shape(lid, ring, glass, dome_point(side * 0.36, 0.42, top_r * 0.03))
		node.basis = dome_basis(side * 0.36, 0.42) * Basis(Vector3.RIGHT, PI * 0.5)
	var bridge := BoxMesh.new()
	bridge.size = Vector3(top_r * 0.3, top_r * 0.04, top_r * 0.04)
	add_shape(lid, bridge, glass, dome_point(0.0, 0.42, top_r * 0.03))

	# --- clipboard in the LEFT hand (a child of the arm, so it moves with it) ---
	var board := BoxMesh.new()
	board.size = Vector3(arm_r * 2.7, arm_r * 3.5, arm_r * 0.3)
	var hold := Vector3(0, arm_r * 1.5, -arm_r * 1.6)   # the hand holds the bottom of the board
	add_shape(arm_l, board, load("res://materials/prop_wood_brown.tres"), hand_position() + hold)
	var paper := BoxMesh.new()
	paper.size = Vector3(arm_r * 2.2, arm_r * 2.9, arm_r * 0.12)
	add_shape(arm_l, paper, load("res://materials/cloth_labcoat_white.tres"), hand_position() + hold + Vector3(0, -arm_r * 0.05, -arm_r * 0.2))
