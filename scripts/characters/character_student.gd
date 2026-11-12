@tool
# The Student: orange hoodie (with a hood bump at the back), brown bowl-cut hair,
# big eyes, white sneakers with an orange stripe, and a backpack with two straps.
# Shape: small and short.
extends "res://scripts/characters/character_base.gd"


# Bigger eyes than everybody else.
func _eye_size_factor() -> float:
	return 1.35


func _boot_material() -> Material:
	return load("res://materials/shoe_white.tres")


func _boot_has_stripe() -> bool:
	return true


func _build_extras() -> void:
	var hair: Material = load("res://materials/hair_brown.tres")
	var pack: Material = load("res://materials/cloth_cyan_gray.tres")
	var hoodie: Material = top_material

	# Bowl-cut hair: a rounded cap that sits a little low at the back and sides.
	add_hair_cap(hair, 0.55, 1.1)

	# Hood bump: a soft ball on the back of the neck.
	var hood := SphereMesh.new()
	hood.radius = top_r * 0.55
	hood.height = top_r * 1.1
	hood.radial_segments = SMALL_FACETS
	hood.rings = 4
	add_shape(rig, hood, hoodie, Vector3(0, head_base_y - top_r * 0.1, top_r * 0.78), Vector3(1.3, 0.8, 0.7))

	# Backpack on the back, with two straps you can see on the front.
	var body_h := head_base_y - tube_bottom
	var pack_y := tube_bottom + body_h * 0.42
	var bag := BoxMesh.new()
	bag.size = Vector3(top_r * 1.3, body_h * 0.6, top_r * 0.5)
	add_on_body(bag, pack, pack_y, 0.0, top_r * 0.22, true)
	var strap_top := head_base_y - 0.03
	var strap_bottom := pack_y - body_h * 0.18
	for side in [-1, 1]:
		var strap := BoxMesh.new()
		strap.size = Vector3(top_r * 0.2, strap_top - strap_bottom, 0.014)
		add_on_body(strap, pack, (strap_top + strap_bottom) * 0.5, side * top_r * 0.5, 0.012)
