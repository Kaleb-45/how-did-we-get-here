# flyby.gd
# Stage 4 for a FLYBY destination (Europa): the flyby.
# Nobody rides on the spacecraft and nobody can land. The player works from
# MISSION CONTROL on Earth, so the player cannot move: SPACE is the key
# (a click works too), like the Launch. (Agent's choice for Kaleb, 2026-11-13.)
#
# Radio takes a long time: the real one-way delay (data/destinations.json) is
# on the screen. A command sent now reaches Europa 33 to 54 minutes later, so
# the player must send every command EARLY. Four timed presses:
#   point the instrument, capture, protect the computer from radiation, send the data.
#   Perfect or Good: sent on time. Miss: sent too early or too late.
# The math (how much is captured, lost to radiation, sent home) is in
# GameState.apply_flyby_press(). Numbers: data/events.json "flyby_pass" and
# data/timing.json "flyby". The words are in story.json "flyby_screen".
# MISSION SUCCESS needs at least the planned data sent home (GameState.add_end_of_flyby_failures).
extends Control

@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var screens: VBoxContainer = %Screens
@onready var timeline: HBoxContainer = %Timeline
@onready var press: Control = %TimedPress
@onready var summary_box: PanelContainer = %SummaryBox
@onready var summary_title: Label = %SummaryTitle
@onready var summary_lines: VBoxContainer = %SummaryLines
@onready var next_button: Button = %NextButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary             # "flyby_screen" from story.json
var voice_lines: Dictionary       # "flyby" from inner_voice.json
var moment_ids: Array = []
var moment_labels: Array = []     # one Label per command in the timeline
var status_body: Label            # the STATUS screen's text
var result_counts: Dictionary = {}
var longest_delay: float = 0.0    # minutes: the real longest one-way radio delay (destinations.json)


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	if GameState.destination_id == "" or GameState.get_arrival_type() != "flyby":
		GameState.destination_id = "europa_flyby"
	GameState.fill_default_choices()
	GameState.start_flyby()

	words = Data.story["flyby_screen"]
	voice_lines = Data.voice["flyby"]
	title_label.text = words["title"]
	hint_label.text = words["hint"]
	next_button.text = words["next_button"]
	next_button.pressed.connect(_on_next_pressed)
	summary_box.visible = false
	screens.custom_minimum_size.x = Data.game_data["flyby_screen_layout"]["screen_width"]

	var delay: Dictionary = GameState.get_destination()["signal_delay_minutes"]["value"]
	longest_delay = float(delay["max"])
	moment_ids = Data.timing["flyby"]["moment_ids"]
	build_screens(delay)
	build_timeline()
	inner_voice.say(voice_lines["start"].format({"min": GameState.fmt(delay["min"]), "max": GameState.fmt(delay["max"])}))
	run_flyby()


# Three small "screens" like the ones in mission control: radio delay, planned data, status.
func build_screens(delay: Dictionary) -> void:
	var delay_text: String = words["delay_line"].format({"min": GameState.fmt(delay["min"]), "max": GameState.fmt(delay["max"])})
	delay_text += "\n" + words["delay_note"].format({"min": GameState.fmt(delay["min"]), "max": GameState.fmt(delay["max"])})
	var width: int = int(Data.game_data["flyby_screen_layout"]["screen_width"])
	add_screen(words["delay_title"], delay_text, width)
	add_screen(words["planned_title"], words["planned_line"].format({"gb": GameState.fmt(GameState.flyby["planned"])}), width)
	status_body = add_screen(words["status_title"], words["status_waiting"], width)


func add_screen(title: String, body: String, width: int) -> Label:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"NavyPanel"
	panel.custom_minimum_size = Vector2(width, 0)
	screens.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.theme_type_variation = &"AccentText"
	heading.text = title
	column.add_child(heading)
	var text := Label.new()
	text.theme_type_variation = &"SmallText"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.text = body
	column.add_child(text)
	return text


# One small label per command: its name, and its result under it.
func build_timeline() -> void:
	for moment_id in moment_ids:
		var label := Label.new()
		label.theme_type_variation = &"SmallText"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(Data.game_data["flyby_screen_layout"]["command_width"], 0)
		label.text = words["moments"][moment_id] + "\n" + words["waiting"]
		timeline.add_child(label)
		moment_labels.append(label)


# The four commands one by one, then the pass, then the summary.
func run_flyby() -> void:
	var numbers: Dictionary = Data.timing["flyby"]
	for i in moment_ids.size():
		var moment_id: String = moment_ids[i]
		moment_labels[i].theme_type_variation = &"AccentText"   # the current one is orange
		press.show_waiting(words["get_ready"])
		await get_tree().create_timer(numbers["ready_seconds"]["value"]).timeout
		var caption: String = words["caption"].format({"moment": words["moments"][moment_id]})
		press.start(caption, numbers["press_speed"]["value"], numbers["press_tightness"]["value"], press.ACTION_SPACE)
		var result: String = await press.finished

		GameState.record_press("flyby", moment_id, result)
		GameState.apply_flyby_press(moment_id, result)
		moment_labels[i].text = words["moments"][moment_id] + "\n" + words["results"][result]
		moment_labels[i].theme_type_variation = &"SmallText"
		status_body.text = words["status_sent"].format({"moment": words["moments"][moment_id]})
		var lines: Array = voice_lines["results"][result]
		inner_voice.say(lines[result_counts.get(result, 0) % lines.size()])
		result_counts[result] = result_counts.get(result, 0) + 1
		if i + 1 < moment_ids.size():
			press.show_waiting(words["get_ready"])
		await get_tree().create_timer(numbers["between_seconds"]["value"]).timeout
	await run_pass()
	show_summary()


# Closest approach: the commands arrive. A short countdown of the radio minutes.
func run_pass() -> void:
	press.visible = false
	inner_voice.say(voice_lines["pass"])
	var seconds: float = float(Data.events["flyby_pass"]["pass_seconds"]["value"])
	var tween := create_tween()
	tween.tween_method(show_arrival, longest_delay, 0.0, seconds)
	await tween.finished


func show_arrival(minutes: float) -> void:
	status_body.text = words["pass_line"] + "\n" + GameState.fmt(minutes) + " " + words["minutes_unit"]


# After the pass: what was captured, lost to radiation and sent home. Then a Next button.
func show_summary() -> void:
	summary_title.text = words["summary_title"]
	var data: Dictionary = GameState.flyby
	add_line(words["captured_line"].format({"gb": GameState.fmt(data["captured"])}))
	add_line(words["lost_line"].format({"gb": GameState.fmt(data["lost"])}))
	add_line(words["sent_line"].format({"gb": GameState.fmt(data["sent"]), "planned": GameState.fmt(data["planned"])}))
	var enough: bool = data["sent"] >= data["planned"]
	add_line(words["enough"] if enough else words["not_enough"])
	status_body.text = words["enough"] if enough else words["not_enough"]
	inner_voice.say(voice_lines["summary_enough"] if enough else voice_lines["summary_short"])
	summary_box.visible = true
	# No focus on Next: a kid still pressing Space must not skip the summary.


func add_line(text: String) -> Label:
	var line := Label.new()
	line.theme_type_variation = &"SmallText"
	line.text = text
	summary_lines.add_child(line)
	return line


# Lock the button at once, so a double click cannot skip two screens. The failures are written down first.
func _on_next_pressed() -> void:
	next_button.disabled = true
	GameState.add_end_of_flyby_failures()
	StageManager.go_next()
