# spacecraft.gd
# Builds the 3D spacecraft from the player's choices:
# the body (a box) plus ONLY the part versions they picked.
# Shapes, colors and sizes come from the "look" sections in game_data.json.
#
# Each part goes inside its own holder node named after the part
# (solar_panel, camera, antenna), so later steps can find it.
extends Node3D

# The holder node for each part, for example: { "camera": <Node3D>, ... }
var part_nodes: Dictionary = {}

# Invisible "reach zones" around the parts. When the player stands inside
# one, they can press E on that part. Each zone remembers its part_id.
var reach_zones: Array[Area3D] = []

# How tall the reach zones are, from the floor up (meters).
const ZONE_HEIGHT := 4.0

var body_size: Vector3


func build() -> void:
	var look: Dictionary = Data.game_data["spacecraft_base"]["look"]
	body_size = to_vector(look["size"])

	# Lift the whole spacecraft so the body's bottom is at height_above_floor.
	# (This node's center = the body's center.)
	position.y = look["height_above_floor"] + body_size.y / 2

	var body := make_box(body_size, Color.html(look["color"]))
	Textures.apply(body.material, look["texture"])   # gold foil
	add_child(body)

	for part_id in GameState.choices:
		build_part(part_id, GameState.choices[part_id])


# Builds one part version and puts it in the right place on the body.
func build_part(part_id: String, version_id: String) -> void:
	var part: Dictionary = Data.parts[part_id]
	var part_look: Dictionary = part["look"]
	var version_look: Dictionary = part["versions"][version_id]["look"]
	var size: Array = version_look["size"]
	var color: Color = Color.html(part_look["color"])

	var holder := Node3D.new()
	holder.name = part_id
	add_child(holder)
	part_nodes[part_id] = holder

	# WHERE on the body: sides, bottom or top.
	match part_look["mount"]:
		"sides":
			holder.position = Vector3.ZERO
		"bottom":
			holder.position = Vector3(body_size.x / 4, -body_size.y / 2, body_size.z / 4)
		"top":
			holder.position = Vector3(0, body_size.y / 2, 0)

	# If the data file names a real 3D model, and the file exists, use it.
	var model_path: String = version_look.get("model", "")
	if model_path != "" and ResourceLoader.exists(model_path):
		holder.add_child(load(model_path).instantiate())
		add_reach_zone(holder, Vector3.ZERO, Vector2(1, 1))
		return

	# Otherwise, build the simple shape.
	match part_look["shape"]:
		"wings":
			make_wings(holder, size, color)
		"cylinder":
			make_hanging_cylinder(holder, size, color)
		"dish":
			make_dish(holder, size, color)


# Two flat panels, one on each side, each on a short arm.
# size = [width, thickness, depth]
func make_wings(holder: Node3D, size: Array, color: Color) -> void:
	var panel_size := Vector3(size[0], size[1], size[2])
	var arm_length := 0.4
	for side in [-1, 1]:   # -1 = left, 1 = right
		var arm := make_box(Vector3(arm_length, 0.08, 0.08), Color(0.6, 0.6, 0.6))
		arm.position.x = side * (body_size.x / 2 + arm_length / 2)
		holder.add_child(arm)

		var panel := make_box(panel_size, color)
		# Solar cells. The texture name comes from the part's "look" in the data.
		Textures.apply(panel.material, Data.parts["solar_panel"]["look"]["texture"])
		panel.position.x = side * (body_size.x / 2 + arm_length + panel_size.x / 2)
		holder.add_child(panel)
		add_reach_zone(holder, panel.position, Vector2(panel_size.x / 2, panel_size.z / 2))


# A cylinder hanging down under the body, like a camera lens.
# size = [radius, length]
func make_hanging_cylinder(holder: Node3D, size: Array, color: Color) -> void:
	var lens := make_cylinder(size[0], size[1], color)
	lens.position.y = -size[1] / 2.0
	holder.add_child(lens)
	add_reach_zone(holder, lens.position, Vector2(size[0], size[0]))

	# A small green light on the side: it means "this part is ON".
	var light := CSGSphere3D.new()
	light.name = "StatusLight"
	light.radius = 0.08
	light.material = make_glowing_material(Color(0.2, 1, 0.3))
	light.position = Vector3(size[0] + 0.02, -0.15, 0)
	holder.add_child(light)


# Turns a part "off": its colors go darker and its green light goes out.
# Each piece remembers its "on" color, so turn_on_part() can bring it back.
func turn_off_part(part_id: String) -> void:
	if not part_nodes.has(part_id):
		return   # for example the heater: it has no 3D part
	var holder: Node3D = part_nodes[part_id]
	for piece in holder.get_children():
		if piece.name == "StatusLight":
			piece.material = make_material(Color(0.15, 0.15, 0.15))
		elif piece is CSGShape3D:
			if not piece.has_meta("on_color"):
				piece.set_meta("on_color", piece.material.albedo_color)
			piece.material.albedo_color = piece.get_meta("on_color").darkened(0.6)


# Turns a part back "on": its colors come back and its green light glows.
func turn_on_part(part_id: String) -> void:
	if not part_nodes.has(part_id):
		return
	var holder: Node3D = part_nodes[part_id]
	for piece in holder.get_children():
		if piece.name == "StatusLight":
			piece.material = make_glowing_material(Color(0.2, 1, 0.3))
		elif piece is CSGShape3D and piece.has_meta("on_color"):
			piece.material.albedo_color = piece.get_meta("on_color")


# A material that glows (it doesn't need light to be seen).
func make_glowing_material(color: Color) -> StandardMaterial3D:
	var material := make_material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	return material


# A mast with a bowl-shaped dish on top.
# size = [radius, depth]
func make_dish(holder: Node3D, size: Array, color: Color) -> void:
	var mast_height := 0.4
	var mast := make_cylinder(0.06, mast_height, Color(0.6, 0.6, 0.6))
	mast.position.y = mast_height / 2
	holder.add_child(mast)

	var dish := make_cylinder(size[0], size[1], color)
	dish.cone = true              # a cone: wide at the bottom, a point at the top
	dish.rotation.x = PI          # flip it, so it opens UP like a bowl
	dish.position.y = mast_height + size[1] / 2.0
	holder.add_child(dish)

	# A thin disc on the rim, so the dish catches the light from above.
	var rim := make_cylinder(size[0], 0.03, color)
	rim.position.y = mast_height + size[1]
	holder.add_child(rim)
	add_reach_zone(holder, Vector3.ZERO, Vector2(size[0], size[0]))


# Adds an invisible box around a part piece: the reach zone.
# It is as wide as the piece plus reach_distance on every side,
# and it goes from the floor up, so you can reach parts above your head.
func add_reach_zone(holder: Node3D, center: Vector3, half_size: Vector2) -> void:
	var reach: float = Data.game_data["walk"]["reach_distance"]

	var box := BoxShape3D.new()
	box.size = Vector3(half_size.x * 2 + reach * 2, ZONE_HEIGHT, half_size.y * 2 + reach * 2)
	var shape := CollisionShape3D.new()
	shape.shape = box

	# An Area3D is not solid. It only notices when bodies go in or out.
	var zone := Area3D.new()
	zone.add_child(shape)
	zone.set_meta("part_id", String(holder.name))

	# Put the zone's bottom on the floor: the holder sits high up on the
	# spacecraft, so we move the zone down by the holder's height.
	var holder_height: float = position.y + holder.position.y
	zone.position = Vector3(center.x, ZONE_HEIGHT / 2 - holder_height, center.z)

	holder.add_child(zone)
	reach_zones.append(zone)


# --- Small helpers -------------------------------------------------------

# A solid box. CSG shapes with use_collision = true are solid: you bump into them.
func make_box(size: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.size = size
	box.material = make_material(color)
	box.use_collision = true
	return box


func make_cylinder(radius: float, height: float, color: Color) -> CSGCylinder3D:
	var cylinder := CSGCylinder3D.new()
	cylinder.radius = radius
	cylinder.height = height
	cylinder.sides = 24
	cylinder.material = make_material(color)
	cylinder.use_collision = true
	return cylinder


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


# JSON lists like [2, 2, 2] become a Vector3.
func to_vector(list: Array) -> Vector3:
	return Vector3(list[0], list[1], list[2])
