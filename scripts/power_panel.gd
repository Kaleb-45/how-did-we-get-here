# power_panel.gd
# The power panel in the Power room: a cabinet with a glowing screen,
# an orange stripe and a "POWER" sign. Walk up to it and press E.
# (The Reroute Power mini-game opens from here.)
#
# Like the spacecraft, it is built in code from game_data.json ("power_panel"),
# so moving it or changing its colors is a data change, not a code change.
extends Node3D

# The invisible "reach zone" in front of the panel. walk.gd listens to it,
# the same way it listens to the spacecraft's zones.
var reach_zone: Area3D

const ZONE_HEIGHT := 4.0


func build() -> void:
	var look: Dictionary = Data.game_data["power_panel"]
	var size := Vector3(look["size"][0], look["size"][1], look["size"][2])
	var lift: float = look["height_above_floor"]

	# Stand on the floor at `position`, turned to face into the room.
	position = Vector3(look["position"][0], look["position"][1], look["position"][2])
	rotation_degrees.y = look["facing_degrees"]

	# The cabinet: a solid box. Its front is the +Z side.
	var cabinet := make_box(size, make_material(Color.html(look["color"])))
	cabinet.position.y = lift + size.y / 2
	add_child(cabinet)

	# The screen: a thin glowing box on the front, in the upper part.
	var screen_size := Vector3(size.x * 0.75, size.y * 0.35, 0.02)
	var screen := make_box(screen_size, make_glowing_material(Color.html(look["screen_color"])))
	screen.position = Vector3(0, lift + size.y * 0.68, size.z / 2 + 0.01)
	add_child(screen)

	# An orange stripe under the screen, so it's easy to spot from the doorway.
	var stripe := make_box(Vector3(size.x, 0.08, 0.02), make_material(Color.html(look["stripe_color"])))
	stripe.position = Vector3(0, lift + size.y * 0.4, size.z / 2 + 0.01)
	add_child(stripe)

	# The sign above the cabinet. Label3D draws text in the 3D world.
	var sign := Label3D.new()
	sign.text = Data.voice["walk"]["panel_sign"]
	sign.font_size = 96
	sign.pixel_size = 0.004   # 96 px x 0.004 = letters about 0.4 m tall
	sign.modulate = Color.html(look["stripe_color"])
	sign.position = Vector3(0, lift + size.y + 0.3, size.z / 2)
	add_child(sign)

	add_reach_zone(size)


# The zone is the panel's size plus reach_distance on every side,
# from the floor up, like the spacecraft's zones.
func add_reach_zone(size: Vector3) -> void:
	var reach: float = Data.game_data["walk"]["reach_distance"]
	var box := BoxShape3D.new()
	box.size = Vector3(size.x + reach * 2, ZONE_HEIGHT, size.z + reach * 2)
	var shape := CollisionShape3D.new()
	shape.shape = box

	reach_zone = Area3D.new()
	reach_zone.add_child(shape)
	reach_zone.set_meta("part_id", "power_panel")   # walk.gd checks this name
	reach_zone.position.y = ZONE_HEIGHT / 2
	add_child(reach_zone)


# --- Small helpers -------------------------------------------------------

func make_box(size: Vector3, material: StandardMaterial3D) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.size = size
	box.material = material
	box.use_collision = true   # solid: you bump into it
	return box


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


# Glows by itself, so the screen is bright even in shadow.
func make_glowing_material(color: Color) -> StandardMaterial3D:
	var material := make_material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	return material
