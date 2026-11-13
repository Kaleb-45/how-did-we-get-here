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
@onready var retry_button: Button = %RetryButton
@onready var same_design_button: Button = %SameDesignButton
@onready var start_fresh_button: Button = %StartFreshButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary
var ok_color: Color
var bad_color: Color


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

	setup_buttons()

	fill_header()
	var failures: Array = GameState.get_all_failures()
	if failures.is_empty():
		show_stamp(words["success_title"], ok_color)
		inner_voice.say(words["success_text"])
		add_success_note()
	else:
		show_stamp(words["failed_title"], bad_color)
		inner_voice.say(words["failed_intro"])
		for i in failures.size():
			add_finding(i + 1, failures[i])
	fill_readings()


# The three report buttons. All their words are in story.json ("report_screen").
func setup_buttons() -> void:
	var button_words: Dictionary = Data.story["report_screen"]
	retry_button.text = button_words["retry_button"]
	same_design_button.text = button_words["same_design_button"]
	start_fresh_button.text = button_words["start_fresh_button"]
	# Retry needs a saved checkpoint. Without one, the button is off.
	if GameState.get_latest_checkpoint() == 0:
		retry_button.disabled = true
		retry_button.tooltip_text = button_words["no_checkpoint_tip"]
	retry_button.pressed.connect(_on_retry_pressed)
	same_design_button.pressed.connect(_on_same_design_pressed)
	start_fresh_button.pressed.connect(_on_start_fresh_pressed)


# The top of the report: mission name, designer, mission time.
func fill_header() -> void:
	report_label.text = words["report_label"]
	mission_name.text = Data.story["missions"][GameState.mission_id]["name"]
	var designer: String = Data.story["characters"][GameState.character_id]["name"]
	if GameState.player_name != "":
		designer = GameState.player_name + " (" + designer + ")"   # for example: Sam (The Janitor)
	var months: String = GameState.fmt(GameState.mission_months) + " " + Data.resources["mission_lifetime"]["unit"]
	details.text = "%s %s      %s %s" % [words["designer_label"], designer, words["time_label"], months]


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
	note.text = words["success_note"]
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
# question (right now Mars orbit is the only destination you can pick).
func _on_same_design_pressed() -> void:
	lock_buttons()
	GameState.keep_design_new_destination()
	StageManager.go_to("destination")


# Start fresh: everything is cleared, and we start with the name question.
func _on_start_fresh_pressed() -> void:
	lock_buttons()
	GameState.reset_all()
	StageManager.go_to("name")
