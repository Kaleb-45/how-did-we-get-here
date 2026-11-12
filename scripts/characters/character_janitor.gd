@tool
# The Janitor: green overalls (bib and two straps) over a cream shirt, a green work
# cap, a large gray mustache centred under the eyes, and a mop in the LEFT hand.
# Shape: wide at the bottom. (The cream shirt is his top_material, the green is his
# bottom_material, set in his scene.)
extends "res://scripts/characters/character_base.gd"


func _build_extras() -> void:
	var green: Material = load("res://materials/cloth_work_green.tres")

	# Big mustache, centred under the eyes (the two halves meet in the middle).
	add_mustache(1.35, 0.2, 0.15, true)

	# --- overalls: a bib and two straps (front and back) on top of the cream shirt ---
	var bib := BoxMesh.new()
	bib.size = Vector3(top_r * 1.5, 0.2, 0.014)
	add_on_body(bib, green, waist_y() + 0.1, 0.0, 0.012)
	var strap_bottom := waist_y() + 0.15
	var strap_top := head_base_y - 0.04
	var slope := atan((body_radius_at(strap_bottom) - body_radius_at(strap_top)) / (strap_top - strap_bottom))
	for side in [-1, 1]:
		var strap := BoxMesh.new()
		strap.size = Vector3(0.07, (strap_top - strap_bottom) / cos(slope), 0.014)
		add_on_body(strap, green, (strap_top + strap_bottom) * 0.5, side * top_r * 0.62, 0.012)
		add_on_body(strap, green, (strap_top + strap_bottom) * 0.5, side * top_r * 0.62, 0.012, true)

	# --- green work cap: a flat dome high on the lid (above the eyebrows) and a short peak ---
	var rim := 0.66                                  # how high up the dome the cap starts (0..1)
	var rim_r := top_r * sqrt(1.0 - rim * rim) * 1.06
	var cap := SphereMesh.new()
	cap.radius = rim_r
	cap.height = rim_r
	cap.is_hemisphere = true
	cap.radial_segments = FACETS
	cap.rings = 5
	add_shape(lid, cap, green, Vector3(0, dome_h * rim, 0), Vector3(1, 0.45, 1))
	var peak := BoxMesh.new()
	peak.size = Vector3(top_r * 0.8, top_r * 0.05, top_r * 0.45)
	add_shape(lid, peak, green, Vector3(0, dome_h * rim + 0.005, -rim_r - top_r * 0.15), Vector3.ONE, Vector3(-0.15, 0, 0))

	# --- mop in the LEFT hand ---
	# The mop is a child of the arm (so it follows the arm), turned back by the arm's
	# tilt so it stands straight up. The handle goes through the hand; the head rests
	# on the floor beside him.
	var hand_y := shoulder_y - (arm_len + arm_r * 0.3) * cos(_arm_tilt)   # hand height above the floor
	var mop := Node3D.new()
	mop.name = "Mop"
	mop.set_meta("gen", true)
	arm_l.add_child(mop)
	mop.position = hand_position()
	mop.rotation.z = _arm_tilt
	var handle_low := 0.1                          # handle starts just above the floor
	var handle_top := shoulder_y + 0.12
	var handle := CylinderMesh.new()
	handle.top_radius = 0.028
	handle.bottom_radius = 0.028
	handle.height = handle_top - handle_low
	handle.radial_segments = 6
	handle.rings = 1
	add_shape(mop, handle, load("res://materials/prop_wood_brown.tres"), Vector3(0, (handle_top + handle_low) * 0.5 - hand_y, 0))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.17
	head_mesh.is_hemisphere = true
	head_mesh.radial_segments = SMALL_FACETS
	head_mesh.rings = 3
	add_shape(mop, head_mesh, load("res://materials/cloth_labcoat_white.tres"), Vector3(0, 0.02 - hand_y, 0), Vector3(1, 1.2, 1))
