# dashboard_row.gd
# ONE row of the dashboard: name, value, limit, a bar, and a color.
# The dashboard makes one of these for each resource.
# Sizes and layout live in dashboard_row.tscn; numbers come from the data.
extends HBoxContainer

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel
@onready var limit_label: Label = %LimitLabel
@onready var bar: ProgressBar = %Bar
@onready var limit_marker: ColorRect = %LimitMarker

var res_id: String = ""
var fill_style: StyleBoxFlat   # the colored inside of the bar
var compact: bool = false      # true = small corner version
var flashing: Tween            # the running flash, if any


# Flash the whole row red, over and over (for alarms). false = stop.
func set_flashing(on: bool) -> void:
	if flashing:
		flashing.kill()
	modulate = Color.WHITE   # normal colors
	if not on:
		return
	var red: Color = Color.html(Data.game_data["dashboard"]["colors"]["danger"])
	var speed: float = Data.game_data["dashboard"]["flash_seconds"]
	flashing = create_tween().set_loops()
	flashing.tween_property(self, "modulate", red, speed)
	flashing.tween_property(self, "modulate", Color.WHITE, speed)


# Call once, after the row is added to the screen.
func setup(resource_id: String) -> void:
	res_id = resource_id
	name_label.text = Data.resources[res_id]["name"]

	# Give this row its own copy of the bar's fill style,
	# so changing its color doesn't change every other row's bar too.
	fill_style = bar.get_theme_stylebox("fill").duplicate()
	bar.add_theme_stylebox_override("fill", fill_style)


# Compact = the small corner version: only the name and the bar.
# The name takes the green/yellow/red color instead of the value,
# and the white marker on the bar still shows where the limit is.
func set_compact(is_compact: bool) -> void:
	compact = is_compact
	value_label.visible = not compact
	limit_label.visible = not compact
	if not compact:
		name_label.remove_theme_color_override("font_color")   # back to white


# Show one value. limit = { rule, value, warning, bar_max } from GameState.
func show_value(value: float, limit: Dictionary, live: bool = false) -> void:
	var unit: String = Data.resources[res_id]["unit"]
	if live and Data.resources[res_id].has("live_unit"):
		unit = Data.resources[res_id]["live_unit"]
	var words: Dictionary = Data.story["build_screen"]
	var rule_word: String = words["max_word"] if limit["rule"] == "max" else words["min_word"]

	value_label.text = GameState.fmt(value) + " " + unit
	limit_label.text = rule_word + " " + GameState.fmt(limit["value"])

	# The bar: empty at 0, full at bar_max. (ProgressBar keeps the
	# value inside that range by itself, so a negative number shows empty.)
	bar.max_value = limit["bar_max"]
	bar.value = value

	# The thin white line on the bar shows where the limit is.
	# Anchors go from 0.0 (left edge) to 1.0 (right edge).
	var marker_spot: float = clampf(limit["value"] / limit["bar_max"], 0.0, 1.0)
	limit_marker.anchor_left = marker_spot
	limit_marker.anchor_right = marker_spot

	# Green, yellow or red, using the colors from game_data.json.
	var status: String = GameState.get_status(value, limit)
	var color: Color = Color.html(Data.game_data["dashboard"]["colors"][status])
	value_label.add_theme_color_override("font_color", color)
	fill_style.bg_color = color
	if compact:
		name_label.add_theme_color_override("font_color", color)
