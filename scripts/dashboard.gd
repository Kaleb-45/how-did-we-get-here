# dashboard.gd
# The mission dashboard: one row per resource.
# It does NOT calculate anything. The screen that owns it hands it the
# six values, and the dashboard draws them:
#     %Dashboard.show_values(GameState.get_totals())
# Reusable: the same scene goes on the Build screen and in the 3D walk.
extends PanelContainer

# The row blueprint (one row = one resource).
const ROW = preload("res://scenes/dashboard_row.tscn")

@onready var title_label: Label = %DashboardTitle
@onready var hint_label: Label = %DashboardHint
@onready var rows_box: VBoxContainer = %Rows

# One row per resource, for example { "budget": <row>, ... }
var rows: Dictionary = {}


func _ready() -> void:
	title_label.text = Data.story["dashboard"]["title"]

	# One row for each resource in game_data.json, in the file's order.
	for res_id in Data.resources:
		var row = ROW.instantiate()
		rows_box.add_child(row)
		row.setup(res_id)
		rows[res_id] = row


# Small (corner) or big (full) version, with a hint about the Tab key.
# Screens that never call this (like Build) show the big version, no hint.
func set_compact(compact: bool) -> void:
	for res_id in rows:
		rows[res_id].set_compact(compact)
	var words: Dictionary = Data.story["dashboard"]
	hint_label.text = words["hint_small"] if compact else words["hint_big"]
	hint_label.visible = true


# Make one row flash (for example "power" during the alarm), or stop it.
func set_flashing(res_id: String, on: bool) -> void:
	rows[res_id].set_flashing(on)


# Draw all six values. values = { "budget": 330, "mass": 690, ... }
# limits: leave out to use the normal build limits.
# live = true uses the "live_unit" names, like "Gb collected".
func show_values(values: Dictionary, limits: Dictionary = {}, live: bool = false) -> void:
	if limits.is_empty():
		limits = GameState.get_limits()
	for res_id in rows:
		rows[res_id].show_value(values[res_id], limits[res_id], live)
