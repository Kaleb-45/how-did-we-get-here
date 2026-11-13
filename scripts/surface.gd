# surface.gd
# Stage 4 for a SURFACE destination (Jezero, Gale, Arcadia): the surface work.
# A small walkable area (a "graybox": plain boxes and spheres, Mars colors).
# It uses the same controls as the ship: WASD walk, mouse look, Space jump,
# E to use. The lander sits in the middle.
#
# Three tasks, each with a timed press on E (GAME_PLAN 7):
#   1. Collect the sample at the glowing rock.
#      Perfect or Good: collected. Miss: the drill slipped. It costs power and one day. Try again.
#   2. Run the instrument at its station. Any result runs it (a Miss stores less data).
#   3. Send the data home at the lander. Any result sends (a Miss sends less). Needs the instrument run first.
# The stay ends when all three are done, or when the days run out.
# The surface clock: every day costs power and crew supplies, and the parts
# from Stage 1 decide how many days there are (GameState.start_surface()).
# When the days run out without the sample, the mission fails (a finding).
# The numbers are in data/events.json ("surface_work") and the layout and
# colors in data/game_data.json ("surface_area"). The words are in
# story.json ("surface_screen") and inner_voice.json ("surface").
extends Node3D

const PRESS_SCENE = preload("res://scenes/timed_press.tscn")
const ROW_SCENE = preload("res://scenes/dashboard_row.tscn")

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var controls_hint: Label = %ControlsHint
@onready var banner: Label = %Banner
@onready var prompt_label: Label = %PromptLabel
@onready var day_label: Label = %DayLabel
@onready var meters: VBoxContainer = %Meters
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var layout: Dictionary           # game_data.json "surface_area"
var dims: Dictionary             # its "dims" (sizes)
var colors: Dictionary           # its colors
var numbers: Dictionary          # events.json "surface_work"
var words: Dictionary            # story.json "surface_screen"
var lines: Dictionary            # inner_voice.json "surface"
var material_name: String = ""   # for example "river delta rock"

var press: Control               # the timed press
var press_running: bool = false
var mission_over: bool = false
var sample_position: Vector3     # where the sample lies (meters)
var instrument_position: Vector3 # where the instrument station stands (meters)
var press_kind: String = ""      # which task the ring is for: sample, instrument or send
var in_instrument_zone: bool = false
var in_sample_zone: bool = false
var in_lander_zone: bool = false
var power_row: HBoxContainer
var supply_rows: Dictionary = {}
var sample_marker: Node3D
var last_days_left: int = -1
var hold_left: float = 0.0       # warnings wait after a spoken line


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	if GameState.destination_id == "" or GameState.get_arrival_type() != "surface":
		GameState.destination_id = GameState.get_first_destination_of("surface")
	GameState.fill_default_choices()

	layout = Data.game_data["surface_area"]
	colors = layout["colors"].duplicate()
	colors.merge(GameState.get_site_value("surface_colors", {}), true)   # the site's own ground and sky colors
	dims = layout["dims"]
	numbers = Data.events["surface_work"]
	words = Data.story["surface_screen"]
	lines = Data.voice["surface"]
	# The site's own material: ice at Arcadia, delta rock at Jezero, layered rock at Gale.
	var material_id: String = GameState.get_destination()["materials"]["value"][0]
	material_name = Data.story["destination_materials"][material_id]

	GameState.start_surface()   # the parts decide how many days
	sample_position = get_sample_position()
	instrument_position = get_instrument_position()
	build_world()
	build_hud()
	put_player_at_start()

	update_banner()
	say(lines["start"].format({"days": GameState.surface["days_total"], "material": material_name}))


# --- The world (built in code from data) ------------------------------------

# Where the sample lies: from the lander, in the data's direction, sample_distance_m away.
# A bad landing ("distance" damage, in percent) puts it farther.
func get_sample_position() -> Vector3:
	var direction := Vector2(layout["sample_direction"][0], layout["sample_direction"][1]).normalized()
	var distance: float = float(numbers["sample_distance_m"]["value"]) * float(GameState.get_site_value("sample_distance_factor", 1.0)) * (1.0 + GameState.damage.get("distance", 0.0) / 100.0)
	var limit: float = float(layout["half_size"]) - float(dims["sample_edge"])   # never outside the area
	var lander: Array = layout["lander_position"]
	var spot := Vector2(lander[0], lander[2]) + direction * minf(distance, limit)
	return Vector3(spot.x, 0, spot.y)


# Where the instrument station stands: from the lander, in the data's direction, instrument_distance_m away.
func get_instrument_position() -> Vector3:
	var direction := Vector2(layout["instrument_direction"][0], layout["instrument_direction"][1]).normalized()
	var limit: float = float(layout["half_size"]) - float(dims["sample_edge"])
	var lander: Array = layout["lander_position"]
	var spot := Vector2(lander[0], lander[2]) + direction * minf(float(numbers["instrument_distance_m"]["value"]), limit)
	return Vector3(spot.x, 0, spot.y)


func build_world() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color.html(colors["sky_top"])
	sky_material.sky_horizon_color = Color.html(colors["sky_horizon"])
	sky_material.ground_horizon_color = Color.html(colors["sky_horizon"])
	sky_material.ground_bottom_color = Color.html(colors["ground"])
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = layout["ambient_energy"]
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color.html(colors["sun"])
	sun.light_energy = layout["sun_energy"]
	sun.rotation_degrees = v3(dims["sun_rotation_degrees"])
	sun.shadow_enabled = true
	add_child(sun)

	build_ground()
	build_rim()
	build_rocks()
	build_lander()
	build_sample()
	build_instrument()


# A box with a matte color. A body makes it solid (the player cannot walk through it).
func make_box(size: Vector3, position: Vector3, color: Color, solid: bool) -> Node3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = make_material(color)
	mesh.position = position
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		mesh.add_child(body)
	return mesh


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0   # matte
	return material


func build_ground() -> void:
	var half: float = layout["half_size"]
	var ground_size: float = half * 2.0 + float(dims["ground_extra"])
	var thickness: float = dims["ground_thickness"]
	make_box(Vector3(ground_size, thickness, ground_size), Vector3(0, -thickness / 2.0, 0), Color.html(colors["ground"]), true)
	# A few lighter patches, so the floor is not one flat color.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(layout["rock_seed"])
	var patches: Dictionary = dims["patches"]
	var edge: float = patches["edge"]
	for i in int(patches["count"]):
		var size := Vector3(rng.randf_range(patches["size_min"], patches["size_max"]), patches["thickness"], rng.randf_range(patches["size_min"], patches["size_max"]))
		make_box(size, Vector3(rng.randf_range(-half + edge, half - edge), patches["thickness"] / 2.0, rng.randf_range(-half + edge, half - edge)), Color.html(colors["ground_patch"]), false)


# A low ridge all around, like a crater rim. It keeps the player inside.
func build_rim() -> void:
	var half: float = layout["half_size"]
	var height: float = layout["rim_height"]
	var rim_color := Color.html(colors["rim"])
	var thick: float = dims["rim_thickness"]
	make_box(Vector3(half * 2.0 + thick * 2.0, height, thick), Vector3(0, height / 2.0, -half - thick / 2.0), rim_color, true)
	make_box(Vector3(half * 2.0 + thick * 2.0, height, thick), Vector3(0, height / 2.0, half + thick / 2.0), rim_color, true)
	make_box(Vector3(thick, height, half * 2.0), Vector3(-half - thick / 2.0, height / 2.0, 0), rim_color, true)
	make_box(Vector3(thick, height, half * 2.0), Vector3(half + thick / 2.0, height / 2.0, 0), rim_color, true)


# Scenery rocks: boxes of different sizes in the Mars colors. They stay away from the lander and the sample.
func build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(layout["rock_seed"]) + 1
	var half: float = layout["half_size"]
	var rock_colors: Array = colors["rock"]
	var placed := 0
	var tries := 0
	while placed < int(layout["rocks"]) and tries < int(dims["rock_tries"]):
		tries += 1
		var edge: float = dims["rock_edge"]
		var spot := Vector3(rng.randf_range(-half + edge, half - edge), 0, rng.randf_range(-half + edge, half - edge))
		var keepout: Dictionary = dims["rock_keepout"]
		if spot.length() < keepout["lander"] or spot.distance_to(sample_position) < keepout["sample"] or spot.distance_to(instrument_position) < keepout["instrument"] or spot.distance_to(player_start_position()) < keepout["player"]:
			continue
		var small: Vector3 = v3(dims["rock_size_min"])
		var big: Vector3 = v3(dims["rock_size_max"])
		var size := Vector3(rng.randf_range(small.x, big.x), rng.randf_range(small.y, big.y), rng.randf_range(small.z, big.z))
		var rock := make_box(size, Vector3(spot.x, size.y / 2.0 - float(dims["rock_sink"]), spot.z), Color.html(rock_colors[placed % rock_colors.size()]), true)
		rock.rotation.y = rng.randf_range(0, TAU)
		placed += 1


# The lander: a body, three legs and two solar panels. It sits where the data says.
func build_lander() -> void:
	var at := Vector3(layout["lander_position"][0], layout["lander_position"][1], layout["lander_position"][2])
	var body_color := Color.html(colors["lander_body"])
	var leg_color := Color.html(colors["lander_leg"])
	var l: Dictionary = dims["lander"]
	make_box(v3(l["body_size"]), at + Vector3(0, l["body_height"], 0), body_color, true)
	make_box(v3(l["top_size"]), at + Vector3(0, l["top_height"], 0), body_color, false)
	var leg_size: Vector3 = v3(l["leg_size"])
	for spot in l["leg_spots"]:
		make_box(leg_size, at + Vector3(spot[0], 0, spot[1]) * float(l["leg_spread"]) + Vector3(0, leg_size.y / 2.0, 0), leg_color, true)
	for side in [-1.0, 1.0]:
		make_box(v3(l["panel_size"]), at + Vector3(side * float(l["panel_x"]), l["panel_height"], 0), Color.html(colors["lander_panel"]), false)
	# The lander's reach zone and its name.
	var zone := add_zone(at, float(layout["lander_zone_radius"]))
	zone.body_entered.connect(_on_zone_entered.bind("lander"))
	zone.body_exited.connect(_on_zone_exited.bind("lander"))
	add_label(at + Vector3(0, l["label_height"], 0), words["lander_marker"])


# The sample: a pale rock with an orange glow on top, so the player can find it from far away.
func build_sample() -> void:
	var m: Dictionary = dims["sample"]
	var rock := make_box(v3(m["rock_size"]), sample_position + Vector3(0, m["rock_height"], 0), Color.html(colors["sample_rock"]), false)
	sample_marker = rock
	var glow := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = m["glow_radius"]
	sphere.height = float(m["glow_radius"]) * 2.0
	glow.mesh = sphere
	var glow_material := make_material(Color.html(colors["sample_glow"]))
	glow_material.emission_enabled = true
	glow_material.emission = Color.html(colors["sample_glow"])
	glow_material.emission_energy_multiplier = m["glow_energy"]
	glow.material_override = glow_material
	glow.position = Vector3(0, m["glow_height"], 0)
	rock.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color.html(colors["sample_glow"])
	light.omni_range = m["light_range"]
	light.light_energy = m["light_energy"]
	light.position = Vector3(0, m["light_height"], 0)
	rock.add_child(light)
	var zone := add_zone(sample_position, float(layout["sample_zone_radius"]))
	zone.body_entered.connect(_on_zone_entered.bind("sample"))
	zone.body_exited.connect(_on_zone_exited.bind("sample"))
	add_label(sample_position + Vector3(0, m["label_height"], 0), words["sample_marker"].format({"material": material_name}))


# The instrument station: a blue box with a mast and a cyan glow, away from the lander.
func build_instrument() -> void:
	var m: Dictionary = dims["instrument"]
	make_box(v3(m["body_size"]), instrument_position + Vector3(0, m["body_height"], 0), Color.html(colors["instrument_body"]), true)
	make_box(v3(m["mast_size"]), instrument_position + Vector3(0, m["mast_height"], 0), Color.html(colors["instrument_body"]), false)
	var glow := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = m["glow_radius"]
	sphere.height = float(m["glow_radius"]) * 2.0
	glow.mesh = sphere
	var glow_material := make_material(Color.html(colors["instrument_glow"]))
	glow_material.emission_enabled = true
	glow_material.emission = Color.html(colors["instrument_glow"])
	glow_material.emission_energy_multiplier = m["glow_energy"]
	glow.material_override = glow_material
	glow.position = instrument_position + Vector3(0, m["glow_height"], 0)
	add_child(glow)
	var zone := add_zone(instrument_position, float(layout["instrument_zone_radius"]))
	zone.body_entered.connect(_on_zone_entered.bind("instrument"))
	zone.body_exited.connect(_on_zone_exited.bind("instrument"))
	add_label(instrument_position + Vector3(0, m["label_height"], 0), words["instrument_marker"])


# A round area that tells us when the player walks in (same idea as the ship's reach zones).
func add_zone(at: Vector3, radius: float) -> Area3D:
	var zone := Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	zone.add_child(shape)
	zone.position = at + Vector3(0, dims["zone_height"], 0)
	add_child(zone)
	return zone


# Floating text that always faces the player.
func add_label(at: Vector3, text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = dims["label"]["pixel_size"]
	label.font_size = int(dims["label"]["font_size"])
	label.outline_size = int(dims["label"]["outline_size"])
	label.no_depth_test = true
	label.position = at
	add_child(label)
	return label


# [x, y, z] from the data file as a Vector3.
func v3(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])


func player_start_position() -> Vector3:
	var start: Array = layout["player_start"]
	return Vector3(start[0], start[1], start[2])


func put_player_at_start() -> void:
	player.global_position = player_start_position()
	player.rotation_degrees.y = layout["player_facing_degrees"]


# --- The HUD ------------------------------------------------------------------

func build_hud() -> void:
	controls_hint.text = words["controls_hint"]
	prompt_label.text = ""
	# The meters: spare power, then food, water and air (only if there is a crew).
	power_row = ROW_SCENE.instantiate()
	meters.add_child(power_row)
	power_row.setup("power")
	make_row_narrow(power_row)
	if GameState.has_crew():
		for id in GameState.SUPPLY_IDS:
			var row: HBoxContainer = ROW_SCENE.instantiate()
			meters.add_child(row)
			row.setup_supply(id)
			make_row_narrow(row)
			supply_rows[id] = row

	# The timed press sits in the middle of the screen, a little high, and starts hidden
	# (the same place as the science pass ring).
	press = PRESS_SCENE.instantiate()
	hud.add_child(press)
	hud.move_child(press, inner_voice.get_index())
	press.set_anchors_preset(Control.PRESET_CENTER)
	press.offset_left = -press.custom_minimum_size.x / 2.0
	press.offset_right = press.custom_minimum_size.x / 2.0
	var lift: float = dims["press_lift_pixels"]
	press.offset_top = -press.custom_minimum_size.y / 2.0 - lift
	press.offset_bottom = press.custom_minimum_size.y / 2.0 - lift
	press.visible = false
	press.finished.connect(_on_press_finished)
	update_meters()


# The dashboard row is wide (made for the wrist panel). Here it is narrower, so the lander stays in view.
func make_row_narrow(row: HBoxContainer) -> void:
	var sizes: Dictionary = dims["row_pixels"]
	row.name_label.custom_minimum_size.x = sizes["name"]
	row.value_label.custom_minimum_size.x = sizes["value"]
	row.limit_label.custom_minimum_size.x = sizes["limit"]
	row.bar.custom_minimum_size.x = sizes["bar"]


func update_meters() -> void:
	day_label.text = words["day_line"].format({
		"day": mini(int(floor(GameState.surface["days_used"])) + 1, GameState.surface["days_total"]),
		"total": GameState.surface["days_total"],
	})
	power_row.show_value(GameState.get_surface_power(), GameState.get_limits()["power"])
	for id in supply_rows:
		supply_rows[id].show_supply(GameState.crew_supplies[id], GameState.get_supply_capacity(id), GameState.get_supply_status(id))


# --- Playing ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if hold_left > 0.0:
		hold_left -= delta
	if not mission_over:
		GameState.advance_surface(delta)
		if GameState.has_crew():
			for id in GameState.check_empty_supplies():   # a supply hit zero: a finding was added
				say(Data.voice["flight"]["empty_" + id])
		check_days()
	update_meters()
	update_prompt()


# Warn when the days get few. When they are over, the stay ends.
func check_days() -> void:
	var left: int = GameState.get_surface_days_left()
	if GameState.is_surface_time_up():
		if not GameState.is_surface_done():
			banner.text = words["banner_over"]
			say(lines["out_of_days"])
			finish(true)
		return
	if left != last_days_left:
		if last_days_left != -1 and hold_left <= 0.0:
			if left == 1:
				say(lines["last_day"])
			elif left <= 3:
				say(lines["day_warning"].format({"day": GameState.surface["days_total"] - left + 1, "left": left}))
		last_days_left = left


func update_prompt() -> void:
	if mission_over or press_running:
		prompt_label.text = ""
	elif in_sample_zone and not GameState.surface["sample"]:
		prompt_label.text = words["prompts"]["sample"].format({"material": material_name})
	elif in_instrument_zone:
		prompt_label.text = words["prompts"]["instrument_done" if GameState.surface["instrument"] else "instrument"]
	elif in_lander_zone:
		if GameState.surface["instrument"] and not GameState.surface["send_done"]:
			prompt_label.text = words["prompts"]["send"]
		elif GameState.surface["send_done"]:
			prompt_label.text = words["prompts"]["send_done"]
		else:
			prompt_label.text = words["prompts"]["lander"]
	else:
		prompt_label.text = ""


func _on_zone_entered(body: Node3D, which: String) -> void:
	if body.is_in_group("player"):
		set_zone(which, true)


func _on_zone_exited(body: Node3D, which: String) -> void:
	if body.is_in_group("player"):
		set_zone(which, false)


func set_zone(which: String, inside: bool) -> void:
	if which == "sample":
		in_sample_zone = inside
	elif which == "instrument":
		in_instrument_zone = inside
	else:
		in_lander_zone = inside


func _unhandled_input(event: InputEvent) -> void:
	if mission_over or press_running:
		return
	if event.is_action_pressed("interact"):
		if in_sample_zone and not GameState.surface["sample"]:
			start_press("sample")
		elif in_instrument_zone:
			if GameState.surface["instrument"]:
				say(lines["instrument_already"])
			else:
				start_press("instrument")
		elif in_lander_zone:
			if GameState.surface["send_done"]:
				say(lines["sent_already"])
			elif GameState.surface["instrument"] and GameState.surface["stored"] > 0.0:
				start_press("send")
			else:
				say(lines["nothing_to_send"])   # the instrument has not stored anything yet


# One timed press (task = sample, instrument or send). The player stands still while the ring closes.
func start_press(task: String) -> void:
	press_kind = task
	press_running = true
	player.set_physics_process(false)
	press.visible = true
	var speed: float = numbers["press_speed"]["value"]
	var tightness: float = numbers["press_tightness"]["value"]
	var label: String = words["sample_label"]
	var start_line: String = lines["sample_start"]
	if task == "instrument":
		speed = numbers["instrument_press_speed"]["value"]
		tightness = numbers["instrument_press_tightness"]["value"]
		label = words["instrument_label"]
		start_line = lines["instrument_start"]
	elif task == "send":
		speed = numbers["send_press_speed"]["value"]
		tightness = numbers["send_press_tightness"]["value"]
		label = words["send_label"]
		start_line = lines["send_start"]
	say(start_line)
	press.start(label, speed, tightness, press.ACTION_E)


func _on_press_finished(result: String) -> void:
	press_running = false
	player.set_physics_process(true)
	match press_kind:
		"sample":
			GameState.record_press("surface", "collect_sample", result)
			GameState.collect_sample(result)
			var line: String = lines["results"][result]
			if GameState.surface["sample"]:
				sample_marker.visible = false
				var bonus_text := bonus_line()
				if bonus_text != "":
					line += " " + bonus_text
			say(line)
		"instrument":
			GameState.record_press("surface", "run_instrument", result)
			var stored: float = GameState.run_instrument(result)
			say(lines["instrument_results"][result].format({"gb": GameState.fmt(stored)}))
		"send":
			GameState.record_press("surface", "send_data", result)
			var sent: float = GameState.send_surface_data(result)
			var line: String = lines["send_results"][result].format({"gb": GameState.fmt(sent)})
			if GameState.surface["stored"] > 0.0:
				line += " " + lines["send_antenna_slow"]   # some data is still waiting: the link was the limit
			say(line)
	update_banner()
	if GameState.is_surface_done():
		finish(false)
	var tree := get_tree()
	await tree.create_timer(numbers["result_show_seconds"]["value"]).timeout
	if is_inside_tree() and not press_running:
		press.visible = false


# The banner at the top shows the next task to do (sample, then the instrument, then sending the data home).
func update_banner() -> void:
	var next := ""
	if not GameState.surface["sample"]:
		next = "sample"
	elif not GameState.surface["instrument"]:
		next = "instrument"
	elif not GameState.surface["send_done"]:
		next = "send"
	if next == "":
		banner.text = words["banner_all_done"]
	else:
		banner.text = words["next_task"][next].format({"material": material_name})


# "The ice melts into extra supplies for the crew: ..." when the site's material gave the crew something (ice at Arcadia), else "".
func bonus_line() -> String:
	var list: String = GameState.get_surface_bonus_text()
	if list == "":
		return ""
	return lines["bonus"].format({"material": material_name, "list": list})


# The stay is over (sample collected, or the days ran out). Wait so the player can read, then the report.
func finish(out_of_days: bool) -> void:
	if mission_over:
		return
	mission_over = true
	if press_running:
		press.running = false
		press_running = false
		press.visible = false
		player.set_physics_process(true)
	if not out_of_days:
		say(lines["done"])
	if GameState.get_surface_power() < 0.0:
		say(lines["power_red"])
	await get_tree().create_timer(float(numbers["end_read_seconds"]["value"])).timeout
	if is_inside_tree():
		end_surface()


func end_surface() -> void:
	GameState.add_end_of_surface_failures()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	StageManager.go_next()


func say(line: String) -> void:
	inner_voice.say(line)
	hold_left = Data.game_data["walk"]["voice_hold_seconds"]
