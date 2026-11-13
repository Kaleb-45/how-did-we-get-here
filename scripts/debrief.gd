# debrief.gd
# The last screen: a MISSION REPORT.
#   Header:   the mission, who designed it, how long it ran, and a stamp:
#             MISSION SUCCESS (green) or MISSION FAILED (red).
#   Findings: one numbered card per problem: what failed, why, how to fix it.
#   Readings: the six resources at the end of the mission, OK or not.
# All the words come from data/inner_voice.json ("debrief") and story.json.
# The green and red come from game_data.json ("dashboard.colors"), so the
# report uses the same colors as the dashboard on your wrist.
extends Control

@onready var mission_name: Label = %MissionName
@onready var report_label: Label = %ReportLabel
@onready var details: Label = %Details
@onready var stamp: PanelContainer = %Stamp
@onready var stamp_text: Label = %StampText
@onready var findings_label: Label = %FindingsLabel
@onready var findings_list: VBoxContainer = %Findings
@onready var readings_label: Label = %ReadingsLabel
@onready var readings: GridContainer = %Readings
@onready var log_label: Label = %LogLabel
@onready var log_box: VBoxContainer = %Log
@onready var retry_button: Button = %RetryButton
@onready var retry_note: Label = %RetryNote
@onready var same_design_button: Button = %SameDesignButton
@onready var start_fresh_button: Button = %StartFreshButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary
var ok_color: Color
var bad_color: Color
var warn_color: Color
var report_words: Dictionary   # "report_screen" from story.json


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	words = Data.voice["debrief"]
	var colors: Dictionary = Data.game_data["dashboard"]["colors"]
	ok_color = Color.html(colors["safe"])
	bad_color = Color.html(colors["danger"])
	warn_color = Color.html(colors["warning"])
	report_words = Data.story["report_screen"]

	setup_buttons()

	fill_header()
	var failures: Array = GameState.get_all_failures()
	if failures.is_empty() and not is_arrival_built():
		# An arrival type that is not built (not in setup pickable_arrival_types): a neutral stamp, never MISSION SUCCESS.
		show_stamp(report_words["trip_ended_title"], warn_color)
		inner_voice.say(words["trip_ended_text"])
		findings_label.visible = false
	elif failures.is_empty():
		show_stamp(words["success_title"], ok_color)
		var arrival: String = GameState.get_arrival_type()
		inner_voice.say(words["success_text"] if arrival == "orbit" else words["success_text_" + arrival])
		add_success_note()
	else:
		show_stamp(words["failed_title"], bad_color)
		inner_voice.say(words["failed_intro"])
		for i in failures.size():
			add_finding(i + 1, failures[i])
	fill_readings()
	fill_log()


# The three report buttons. All their words are in story.json ("report_screen").
func setup_buttons() -> void:
	var button_words: Dictionary = Data.story["report_screen"]
	retry_button.text = button_words["retry_button"]
	same_design_button.text = button_words["same_design_button"]
	start_fresh_button.text = button_words["start_fresh_button"]
	# Retry needs a saved checkpoint. Without one, the button is off.
	if not GameState.can_retry():
		retry_button.disabled = true
		if GameState.get_failed_resources().is_empty():
			retry_button.tooltip_text = button_words["no_checkpoint_tip"]
		else:
			retry_button.tooltip_text = button_words["red_build_tip"]
		retry_note.text = retry_button.tooltip_text
		retry_note.visible = true
	retry_button.pressed.connect(_on_retry_pressed)
	same_design_button.pressed.connect(_on_same_design_pressed)
	start_fresh_button.pressed.connect(_on_start_fresh_pressed)


# The top of the report: mission name, designer, mission time.
func fill_header() -> void:
	report_label.text = words["report_label"]
	var arrival: String = GameState.get_arrival_type()
	if arrival == "orbit":
		mission_name.text = Data.story["missions"][GameState.mission_id]["name"]
	else:
		mission_name.text = Data.story["arrival_goals"][arrival]["name"]   # for example "Collect a rock sample"
	var designer: String = Data.story["characters"][GameState.character_id]["name"]
	if GameState.player_name != "":
		designer = GameState.player_name + " (" + designer + ")"   # for example: Sam (The Janitor)
	var months: String = GameState.fmt(GameState.mission_months) + " " + Data.resources["mission_lifetime"]["unit"]
	if arrival == "orbit":
		details.text = "%s %s      %s %s" % [words["designer_label"], designer, words["time_label"], months]
	else:
		var place: String = Data.story["destinations"][GameState.get_destination_id()]["name"]
		details.text = "%s %s      %s %s" % [words["designer_label"], designer, report_words["destination_label"], place]


# The big stamp: a colored box with a thick colored border, like a rubber
# stamp on a paper report.
func show_stamp(title: String, color: Color) -> void:
	stamp_text.text = title.to_upper()
	stamp_text.add_theme_color_override("font_color", color)

	var style: StyleBoxFlat = get_theme_stylebox("panel", &"NavyPanel").duplicate()
	style.border_color = color
	style.set_border_width_all(4)
	style.bg_color = Color(color, 0.12)   # the same color, almost see-through
	stamp.add_theme_stylebox_override("panel", style)


# One numbered card for one problem, with what / why / fix side by side.
func add_finding(number: int, failure_id: String) -> void:
	var text: Dictionary = Data.voice["resource_failures"][failure_id]

	# Start from the theme's navy panel, and make its border red: a problem.
	var card := PanelContainer.new()
	var style: StyleBoxFlat = get_theme_stylebox("panel", &"NavyPanel").duplicate()
	style.border_color = bad_color
	card.add_theme_stylebox_override("panel", style)
	findings_list.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	# "Finding 1: Data"
	var title := Label.new()
	var card_title: String = text.get("title", resource_name(failure_id))   # a card can have its own title
	title.text = "%s %d: %s" % [words["finding_word"], number, card_title]
	title.theme_type_variation = &"HeadingText"
	title.add_theme_color_override("font_color", bad_color)
	column.add_child(title)

	# The three parts in three columns. fill_blanks() puts in the real numbers.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	column.add_child(row)
	add_part(row, words["what_label"], GameState.fill_blanks(text["what"], failure_id))
	add_part(row, words["why_label"], text["why"])
	add_part(row, words["fix_label"], text["fix"])

	# Which choice did the player make in Stage 1 that caused this finding?
	var cause := Label.new()
	cause.text = report_words["cause_label"] + " " + cause_text(failure_id)
	cause.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cause.theme_type_variation = &"SmallText"
	column.add_child(cause)


# An orange heading with its text underneath, as one of the three columns.
func add_part(row: HBoxContainer, heading: String, body: String) -> void:
	var part := VBoxContainer.new()
	part.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 3 equal columns
	part.add_theme_constant_override("separation", 2)
	row.add_child(part)

	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.theme_type_variation = &"AccentText"   # orange, from the theme
	part.add_child(heading_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.theme_type_variation = &"BodyText"
	part.add_child(body_label)


# "data_live" and "power_event" are about Data and Power: show those names.
func resource_name(failure_id: String) -> String:
	var res_id: String = failure_id.trim_suffix("_live").trim_suffix("_event")
	if Data.resources.has(res_id):
		return Data.resources[res_id]["name"]
	return failure_id


# No problems: one green card instead of the findings.
func add_success_note() -> void:
	findings_label.visible = false
	var card := PanelContainer.new()
	var style: StyleBoxFlat = get_theme_stylebox("panel", &"NavyPanel").duplicate()
	style.border_color = ok_color
	card.add_theme_stylebox_override("panel", style)
	findings_list.add_child(card)

	var note := Label.new()
	var arrival: String = GameState.get_arrival_type()
	note.text = words["success_note"] if arrival == "orbit" else words["success_note_" + arrival]
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.theme_type_variation = &"BodyText"
	note.add_theme_color_override("font_color", ok_color)
	card.add_child(note)


# The table of the six resources. It shows what the dashboard showed when
# the mission ended (end_values), or the build totals if there was no walk.
func fill_readings() -> void:
	readings_label.text = words["readings_label"]
	for key in ["header_resource", "header_end", "header_limit", "header_result"]:
		add_cell(words[key], get_theme_color("font_color", &"AccentText"))

	var ended: bool = not GameState.end_values.is_empty()
	var values: Dictionary = GameState.end_values if ended else GameState.get_totals()
	var limits: Dictionary = GameState.end_limits if ended else GameState.get_limits()
	var review_words: Dictionary = Data.story["review_screen"]
	var build_words: Dictionary = Data.story["build_screen"]

	for res_id in Data.resources:
		var resource: Dictionary = Data.resources[res_id]
		var limit: Dictionary = limits[res_id]
		var ok: bool = GameState.is_ok(values[res_id], limit)
		var unit: String = resource.get("live_unit", resource["unit"]) if ended else resource["unit"]
		var rule_word: String = build_words["max_word"] if limit["rule"] == "max" else build_words["min_word"]

		var result: String = review_words["ok_word"]
		if not ok:
			result = review_words["over_word"] if limit["rule"] == "max" else review_words["under_word"]
		var color: Color = ok_color if ok else bad_color

		add_cell(resource["name"], color)
		add_cell(GameState.fmt(values[res_id]) + " " + unit, color)
		add_cell(rule_word + " " + GameState.fmt(limit["value"]), Color.WHITE)
		add_cell(result, color)


func add_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.theme_type_variation = &"BodyText"
	cell.add_theme_color_override("font_color", color)
	readings.add_child(cell)


# Lock all three buttons at once, so a double click cannot skip two screens.
func lock_buttons() -> void:
	retry_button.disabled = true
	same_design_button.disabled = true
	start_fresh_button.disabled = true


# Retry from checkpoint: the newest checkpoint comes back, and we go to the
# screen after it (Launch, Flight or the orbit burn).
func _on_retry_pressed() -> void:
	lock_buttons()
	if not StageManager.retry_from_checkpoint():
		push_error("debrief: there was no checkpoint to go back to")


# Same design / new destination: the parts stay. We go to the destination
# question (all five destinations can be picked; parts that do not fit the new one are swapped on Build).
func _on_same_design_pressed() -> void:
	lock_buttons()
	GameState.keep_design_new_destination()
	StageManager.go_to("destination")


# Start fresh: everything is cleared, and we start with the name question.
func _on_start_fresh_pressed() -> void:
	lock_buttons()
	GameState.reset_all()
	StageManager.go_to("name")


# --- Finding causes ------------------------------------------------------------

# "Rocket: Medium rocket, Solar panel: Medium". The list of which choices can
# cause which finding is in game_data.json ("report").
func cause_text(failure_id: String) -> String:
	if report_words["cause_overrides"].has(failure_id):
		return report_words["cause_overrides"][failure_id]
	var slots: Array = Data.game_data["report"]["failure_causes"].get(failure_id, [])
	if slots.is_empty():
		return report_words["no_stage1_choice"]
	var parts: PackedStringArray = []
	for slot in slots:
		if slot == "launch_vehicle":
			var rocket_name: String = Data.story["launch_vehicles"][GameState.get_launch_vehicle_id()]["name"]
			parts.append(report_words["slot_names"][slot] + ": " + rocket_name)
		else:
			var part: Dictionary = Data.parts[slot]
			if not GameState.choices.has(slot):
				continue   # this slot does not exist at this destination (for example the landing parts at Europa)
			parts.append(GameState.get_part_name(slot) + ": " + part["versions"][GameState.choices[slot]]["name"])
	return ", ".join(parts)


# --- What happened on the way ---------------------------------------------------

func fill_log() -> void:
	log_label.text = report_words["log_label"]
	add_costs()
	add_supplies()
	var arrival: String = GameState.get_arrival_type()
	if not is_arrival_built():
		add_placeholder_note()   # this kind of trip is not built yet
	elif arrival == "orbit":
		add_science()
	elif arrival == "surface":
		add_surface()
	else:
		add_flyby()
	add_timing()


# One line in the log. heading = an orange title, otherwise a normal line.
func add_log_line(text: String, color: Color = Color.WHITE, heading: bool = false) -> void:
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if heading:
		line.theme_type_variation = &"AccentText"
		if log_box.get_child_count() > 0:
			log_box.add_child(HSeparator.new())   # a thin line between sections
	else:
		line.theme_type_variation = &"SmallText"
		line.add_theme_color_override("font_color", color)
	log_box.add_child(line)


# The cost of each missed press (launch, orbit burn and landing; other presses cost nothing), then crew damage.
func add_costs() -> void:
	add_log_line(report_words["costs_title"], Color.WHITE, true)
	var any_cost := false
	for entry in GameState.timing_results:
		if entry["result"] != "Miss":
			continue
		var cost: Dictionary
		var moment_name: String
		if entry["stage"] == "launch":
			cost = Data.timing["launch_moments"][entry["moment"]]["miss_cost"]
			moment_name = Data.story["launch_screen"]["moments"][entry["moment"]]
		elif entry["stage"] == "landing":
			cost = GameState.get_landing_miss_cost(entry["moment"])
			moment_name = Data.story["landing_screen"]["moments"][entry["moment"]]
		elif entry["stage"] == "orbit_burn":
			cost = Data.timing["orbit_burn"]["miss_cost"]
			moment_name = Data.story["orbit_burn_screen"]["title"]
		else:
			continue   # other presses (oxygen generator, science pass) have no damage cost
		var cost_text: String = Data.story["launch_screen"]["cost_kinds"][cost["kind"]].format({"amount": GameState.fmt(cost["amount"])})
		add_log_line(report_words["cost_line"].format({"moment": moment_name, "cost": cost_text}), bad_color)
		any_cost = true
	if GameState.damage.get("crew", 0.0) > 0.0:
		add_log_line(report_words["crew_damage_line"].format({"amount": GameState.fmt(GameState.damage["crew"])}), bad_color)
		any_cost = true
	if not any_cost:
		add_log_line(report_words["no_costs"], ok_color)


# Food, water and air that are left. Only if the ship was stocked (Flight or Arrival).
func add_supplies() -> void:
	if not GameState.supplies_started:
		return
	add_log_line(report_words["supplies_title"], Color.WHITE, true)
	var names: Dictionary = Data.story["crew_supplies"]
	for id in GameState.SUPPLY_IDS:
		var status: String = GameState.get_supply_status(id)
		var color: Color = ok_color
		if status == "warning":
			color = warn_color
		elif status == "danger":
			color = bad_color
		add_log_line(report_words["supply_line"].format({
			"name": names["names"][id],
			"left": GameState.fmt(GameState.crew_supplies[id]),
			"unit": names["units"][id],
			"full": GameState.fmt(GameState.get_supply_capacity(id)),
		}), color)


# Science sent home. It is an info line: it does not change the stamp yet.
func add_science() -> void:
	add_log_line(report_words["science_title"], Color.WHITE, true)
	add_log_line(report_words["science_line"].format({"gb": GameState.fmt(GameState.science_returned)}))
	if GameState.science_stored > 0.0:
		add_log_line(report_words["science_left_line"].format({"gb": GameState.fmt(GameState.science_stored)}))
	add_log_line(report_words["science_note"], get_theme_color("font_color", &"AccentText"))


# Is this kind of trip built? (game_data.json setup, pickable_arrival_types)
func is_arrival_built() -> bool:
	return Data.game_data["setup"]["pickable_arrival_types"]["value"].has(GameState.get_arrival_type())


# The surface work: the sample, the days and the power.
func add_surface() -> void:
	if GameState.surface.is_empty():
		return   # the trip ended before the surface work
	add_log_line(report_words["surface_title"], Color.WHITE, true)
	var material_name: String = Data.story["destination_materials"][GameState.get_destination()["materials"]["value"][0]]
	var sample_ok: bool = GameState.surface["sample"]
	add_log_line(report_words["surface_sample_yes" if sample_ok else "surface_sample_no"].format({"material": material_name}), ok_color if sample_ok else bad_color)
	add_log_line(report_words["surface_days_line"].format({"used": GameState.fmt(minf(GameState.surface["days_used"], GameState.surface["days_total"])), "total": GameState.fmt(GameState.surface["days_total"])}))
	var power_left: float = GameState.get_surface_power()
	add_log_line(report_words["surface_power_line"].format({"w": GameState.fmt(power_left)}), ok_color if power_left >= 0.0 else bad_color)


# The Europa flyby: captured, lost to radiation, sent home.
func add_flyby() -> void:
	add_log_line(report_words["flyby_title"], Color.WHITE, true)
	var delay: Dictionary = GameState.get_destination()["signal_delay_minutes"]["value"]
	add_log_line(report_words["flyby_delay_line"].format({"min": GameState.fmt(delay["min"]), "max": GameState.fmt(delay["max"])}))
	if GameState.flyby.is_empty():
		return   # the trip ended before the flyby
	add_log_line(report_words["flyby_captured_line"].format({"gb": GameState.fmt(GameState.flyby["captured"])}))
	add_log_line(report_words["flyby_lost_line"].format({"gb": GameState.fmt(GameState.flyby["lost"])}))
	var enough: bool = GameState.flyby["sent"] >= GameState.flyby["planned"]
	add_log_line(report_words["flyby_sent_line"].format({"gb": GameState.fmt(GameState.flyby["sent"]), "planned": GameState.fmt(GameState.flyby["planned"])}), ok_color if enough else bad_color)


# A trip that is not built yet ends here: say so clearly.
func add_placeholder_note() -> void:
	add_log_line(report_words["placeholder_title"], Color.WHITE, true)
	add_log_line(report_words[GameState.get_arrival_type() + "_placeholder"], warn_color)


# How many Perfect, Good and Miss, for each stage and in all.
func add_timing() -> void:
	add_log_line(report_words["timing_title"], Color.WHITE, true)
	if GameState.timing_results.is_empty():
		add_log_line(report_words["no_presses"])
		return
	var by_stage: Dictionary = {}   # stage id -> { "Perfect": n, "Good": n, "Miss": n }
	var all: Dictionary = {"Perfect": 0, "Good": 0, "Miss": 0}
	for entry in GameState.timing_results:
		var stage: String = entry["stage"]
		if not by_stage.has(stage):
			by_stage[stage] = {"Perfect": 0, "Good": 0, "Miss": 0}
		by_stage[stage][entry["result"]] += 1
		all[entry["result"]] += 1
	for stage in by_stage:
		var stage_name: String = report_words["stage_names"].get(stage, stage)
		add_log_line(timing_text(report_words["timing_line"], stage_name, by_stage[stage]))
	if by_stage.size() > 1:
		add_log_line(timing_text(report_words["timing_total_line"], "", all))


func timing_text(template: String, stage_name: String, counts: Dictionary) -> String:
	return template.format({"stage": stage_name, "perfect": counts["Perfect"], "good": counts["Good"], "miss": counts["Miss"]})
