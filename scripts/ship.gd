# ship.gd
# Builds the ship interior (a "graybox": plain boxes, no art) from the numbers
# in game_data.json ("ship"): one hallway and five rooms, a name sign over
# each doorway, and glowing markers where future stations will go
# (the words are in story.json "ship"). Every floor, wall
# and ceiling is solid, and each room has a doorway into the hallway.
#
# Like the spacecraft and the power panel, it is built in code, so changing
# the layout is a data change: move a room, make it bigger, add a room.
#
# Seen from above:  x = left/right,  z = front/back (the Bridge is at the front).
extends Node3D

var ship: Dictionary
var height: float
var thickness: float

# Each room's box, so other scripts can find the rooms later:
# { "bridge": Rect2(...), ... }  (Rect2 position = (x0, z0), size = (width, depth))
var room_rects: Dictionary = {}

# The reach zones at the Life Support stations: { "food": Area3D, "water": ..., "air": ... }
# walk.gd listens to them (part_id "station_food" and so on).
var station_zones: Dictionary = {}


func build() -> void:
	ship = Data.game_data["ship"]
	height = ship["wall_height"]
	thickness = ship["wall_thickness"]

	for room_id in ship["rooms"]:
		var room: Dictionary = ship["rooms"][room_id]
		var rect := to_rect(room)
		room_rects[room_id] = rect
		build_room(room_id, rect, room["door"])
		add_light(Vector3(rect.get_center().x, height - 0.3, rect.get_center().y))
		add_room_signs(room_id, rect, room["door"])

	build_hallway()

	var markers: Dictionary = ship["station_markers"]
	for room_id in Data.story["ship"]["future_stations"]:
		var spot: Array = markers[room_id]
		add_station_marker(Vector3(spot[0], 0, spot[1]), Data.story["ship"]["future_stations"][room_id])

	# The three Life Support stations also get a reach zone, so "Press E" works there.
	for marker_id in markers:
		if marker_id.begins_with("life_support_"):
			var spot: Array = markers[marker_id]
			add_station_zone(marker_id.trim_prefix("life_support_"), Vector3(spot[0], 0, spot[1]))


# One room: floor, ceiling, and four walls. The wall on the `door` side
# gets a doorway in the middle (centered on the room).
func build_room(room_id: String, rect: Rect2, door: String) -> void:
	var holder := Node3D.new()
	holder.name = room_id   # for example "bridge", so the scene tree is easy to read
	add_child(holder)
	add_floor_and_ceiling(holder, rect)

	var x0 := rect.position.x
	var x1 := rect.end.x
	var z0 := rect.position.y
	var z1 := rect.end.y
	var half_door: float = ship["door_width"] / 2.0

	# For each side: the line it sits on, where it starts and ends,
	# and a doorway gap if this is the door side.
	add_wall(holder, "x", z0, x0, x1, door_gap(door == "north", rect.get_center().x, half_door))
	add_wall(holder, "x", z1, x0, x1, door_gap(door == "south", rect.get_center().x, half_door))
	add_wall(holder, "z", x0, z0, z1, door_gap(door == "west", rect.get_center().y, half_door))
	add_wall(holder, "z", x1, z0, z1, door_gap(door == "east", rect.get_center().y, half_door))


func door_gap(has_door: bool, center: float, half_door: float) -> Array:
	if has_door:
		return [[center - half_door, center + half_door]]
	return []


# The hallway: floor, ceiling, and its two long side walls. Where a room's
# door wall sits on the hallway's side, the hallway leaves that stretch out
# (the room's own wall, with its doorway, is already there). The two ends are
# closed by the Bridge and the Comms room.
func build_hallway() -> void:
	var holder := Node3D.new()
	holder.name = "hallway"
	add_child(holder)
	var rect := to_rect(ship["hallway"])
	add_floor_and_ceiling(holder, rect)

	var east_gaps: Array = []   # rooms whose door is on their WEST side sit east of the hallway
	var west_gaps: Array = []
	for room_id in ship["rooms"]:
		var room: Dictionary = ship["rooms"][room_id]
		if room["door"] == "west":
			east_gaps.append(room["z"])
		elif room["door"] == "east":
			west_gaps.append(room["z"])
	add_wall(holder, "z", rect.position.x, rect.position.y, rect.end.y, west_gaps)
	add_wall(holder, "z", rect.end.x, rect.position.y, rect.end.y, east_gaps)

	# Lights spread evenly along the hallway.
	var count: int = ship["hallway_lights"]
	for i in count:
		var z: float = lerpf(rect.position.y, rect.end.y, (i + 0.5) / count)
		add_light(Vector3(rect.get_center().x, height - 0.3, z))


# A wall along one line, from `from` to `to`, with gaps cut out.
#   along = "x": the wall runs left/right, sitting at z = `at`
#   along = "z": the wall runs front/back, sitting at x = `at`
# Each gap is [start, end]. A gap that is a doorway also gets a "lintel":
# the piece of wall above the door.
func add_wall(holder: Node3D, along: String, at: float, from: float, to: float, gaps: Array) -> void:
	var pieces: Array = []      # the solid stretches between the gaps
	var start := from
	var sorted_gaps := gaps.duplicate()
	sorted_gaps.sort_custom(func(a, b): return a[0] < b[0])
	for gap in sorted_gaps:
		if gap[0] > start:
			pieces.append([start, float(gap[0]), 0.0, height])
		start = maxf(start, gap[1])
		# Above a doorway (a gap narrower than a room): a lintel.
		if float(gap[1]) - float(gap[0]) <= ship["door_width"] + 0.01:
			pieces.append([float(gap[0]), float(gap[1]), ship["door_height"], height])
	if start < to:
		pieces.append([start, to, 0.0, height])

	for piece in pieces:
		var length: float = piece[1] - piece[0]
		var middle: float = (piece[0] + piece[1]) / 2.0
		var bottom: float = piece[2]
		var top: float = piece[3]
		var size := Vector3(length, top - bottom, thickness)
		var spot := Vector3(middle, (bottom + top) / 2.0, at)
		if along == "z":
			size = Vector3(thickness, top - bottom, length)
			spot = Vector3(at, (bottom + top) / 2.0, middle)
		var wall := make_box(size, "wall")
		wall.position = spot
		holder.add_child(wall)


# The floor's top is at height 0. The ceiling sits on top of the walls.
func add_floor_and_ceiling(holder: Node3D, rect: Rect2) -> void:
	var floor_box := make_box(Vector3(rect.size.x, 0.2, rect.size.y), "floor")
	floor_box.position = Vector3(rect.get_center().x, -0.1, rect.get_center().y)
	holder.add_child(floor_box)

	var ceiling := make_box(Vector3(rect.size.x, 0.2, rect.size.y), "")
	ceiling.material.albedo_color = Color.html(ship["ceiling_color"])
	ceiling.position = Vector3(rect.get_center().x, height + 0.1, rect.get_center().y)
	ceiling.add_to_group("ceiling")   # so a test camera can hide them and look from above
	holder.add_child(ceiling)


# --- Signs and markers ---------------------------------------------------------

# The room's name above its doorway, on BOTH sides of the wall: one you read
# from the hallway, one you read from inside the room.
func add_room_signs(room_id: String, rect: Rect2, door: String) -> void:
	# Where the doorway is, and which way is "out" (toward the hallway).
	var spots := {
		"north": [Vector3(rect.get_center().x, 0, rect.position.y), Vector3(0, 0, -1)],
		"south": [Vector3(rect.get_center().x, 0, rect.end.y), Vector3(0, 0, 1)],
		"west": [Vector3(rect.position.x, 0, rect.get_center().y), Vector3(-1, 0, 0)],
		"east": [Vector3(rect.end.x, 0, rect.get_center().y), Vector3(1, 0, 0)],
	}
	var door_middle: Vector3 = spots[door][0]
	var out: Vector3 = spots[door][1]
	door_middle.y = (ship["door_height"] + height) / 2.0   # on the lintel, above the door
	var name_text: String = Data.story["ship"]["room_names"][room_id]

	for side in [out, -out]:   # hallway side, then room side
		var sign := make_text(name_text, ship["sign_letter_size"], Color.html(ship["sign_color"]))
		sign.position = door_middle + side * (thickness / 2.0 + 0.01)   # just off the wall
		sign.rotation.y = atan2(side.x, side.z)   # a Label3D reads from its +Z side
		add_child(sign)


# A glowing square on the floor, a small light above it, and a floating label.
# It marks the spot where a future station will go.
func add_station_marker(spot: Vector3, text: String) -> void:
	var color := Color.html(ship["marker_color"])
	var marker_size: float = ship["marker_size"]

	var square := CSGBox3D.new()   # no collision: you can stand on it
	square.size = Vector3(marker_size, 0.02, marker_size)
	square.position = spot + Vector3(0, 0.01, 0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color
	glow.emission_enabled = true
	glow.emission = color
	glow.emission_energy_multiplier = ship["marker_glow"]
	square.material = glow
	add_child(square)

	var light := OmniLight3D.new()   # spills the marker's color onto the floor around it
	light.position = spot + Vector3(0, 0.5, 0)
	light.light_color = color
	light.light_energy = ship["marker_light_energy"]
	light.omni_range = ship["marker_light_range"]
	light.shadow_enabled = false
	add_child(light)

	var label := make_text(text, ship["marker_letter_size"], color)
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y   # always turns to face you
	label.position = spot + Vector3(0, ship["marker_label_height"], 0)
	add_child(label)


# An invisible box around a station marker: the marker's size plus reach_distance.
# Standing inside it means "you are at the station".
func add_station_zone(station_id: String, spot: Vector3) -> void:
	var reach: float = Data.game_data["walk"]["reach_distance"]
	var height_of_zone := 4.0
	var box := BoxShape3D.new()
	box.size = Vector3(ship["marker_size"] + reach, height_of_zone, ship["marker_size"] + reach)
	var shape := CollisionShape3D.new()
	shape.shape = box

	var zone := Area3D.new()
	zone.add_child(shape)
	zone.set_meta("part_id", "station_" + station_id)   # walk.gd checks this name
	zone.position = spot + Vector3(0, height_of_zone / 2.0, 0)
	add_child(zone)
	station_zones[station_id] = zone


# Text in the 3D world. letter_size = how tall the letters are, in meters.
func make_text(text: String, letter_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = letter_size / 96.0   # 96 pixels tall = letter_size meters
	label.modulate = color
	label.outline_size = 16
	label.double_sided = false   # from behind you'd see it backwards, so hide it
	return label


# A ceiling light. No shadows: they cost a lot in the browser.
func add_light(spot: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = spot
	light.light_color = Color.html(ship["light_color"])
	light.light_energy = ship["light_energy"]
	light.omni_range = ship["light_range"]
	light.shadow_enabled = false
	add_child(light)


# A solid box. texture = "floor" or "wall" (a recipe in game_data.json
# "textures"), or "" for a plain color.
func make_box(size: Vector3, texture: String) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.size = size
	box.use_collision = true
	box.material = StandardMaterial3D.new()
	if texture != "":
		box.material.albedo_color = Color.html(ship[texture + "_color"])   # "wall_color" or "floor_color"
		Textures.apply(box.material, texture, true)   # world = true: same tile size everywhere
	return box


# A room from the data file, as a Rect2: position = (x0, z0), size = (width, depth).
func to_rect(box: Dictionary) -> Rect2:
	var x0: float = box["x"][0]
	var z0: float = box["z"][0]
	return Rect2(x0, z0, float(box["x"][1]) - x0, float(box["z"][1]) - z0)
