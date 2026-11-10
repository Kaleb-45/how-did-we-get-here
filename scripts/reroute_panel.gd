# reroute_panel.gd
# The Reroute Power mini-game: a 2D panel with an ON/OFF switch for each
# system (camera, antenna, heater). It shows:
#   - power available (solar panels, or the batteries during the shadow pass)
#   - power used (the body, plus every system that is ON)
#   - a bar, and "It fits" or "Too much!"
#
# The numbers are LIVE: they come from GameState, and the panel redraws
# every frame while it is open (so you SEE the shadow pass take power away).
# Flipping a switch tells walk.gd (switch_changed), which turns the system
# off or on in GameState. The dashboard then shows the cost.
#
# Numbers: game_data.json ("reroute_power", the parts, spacecraft_base).
# Words:   inner_voice.json ("reroute").
extends PanelContainer

# Sent when a switch is flipped. walk.gd listens.
signal switch_changed(system_id: String, on: bool)
# Sent when the player closes the panel.
signal closed

@onready var title: Label = %Title
@onready var close_hint: Label = %CloseHint
@onready var countdown: Label = %Countdown
@onready var available_label: Label = %Available
@onready var rows: GridContainer = %Rows
@onready var used_label: Label = %Used
@onready var used_bar: ProgressBar = %UsedBar
@onready var status_label: Label = %Status

var words: Dictionary
var ok_color: Color
var bad_color: Color

var switches: Dictionary = {}     # { "camera": <Button>, ... }
var cost_labels: Dictionary = {}  # { "camera": <Label>, ... }  "Off: no data"
var bar_fill: StyleBoxFlat        # the bar's color, green or red


func _ready() -> void:
	words = Data.voice["reroute"]
	var colors: Dictionary = Data.game_data["dashboard"]["colors"]
	ok_color = Color.html(colors["safe"])
	bad_color = Color.html(colors["danger"])

	title.text = words["title"]
	title.add_theme_color_override("font_color", get_theme_color("font_color", &"AccentText"))
	close_hint.text = words["close_hint"]
	countdown.add_theme_color_override("font_color", bad_color)

	# The bar's filled part gets its own style, so we can color it.
	bar_fill = StyleBoxFlat.new()
	used_bar.add_theme_stylebox_override("fill", bar_fill)

	make_rows()
	refresh()
	visible = false


# One row per system: name | uses | switch | what it costs when off.
# The body comes first: it is always on, so it has no switch.
func make_rows() -> void:
	add_label(words["body_label"], &"BodyText")
	add_label(watts(GameState.get_body_power_use()), &"BodyText")
	add_label("", &"BodyText")
	add_label("", &"SmallText")

	for system_id in Data.game_data["reroute_power"]["systems"]:
		add_label(system_name(system_id), &"BodyText")
		add_label(watts(GameState.get_power_use(system_id)), &"BodyText")

		var switch := Button.new()
		switch.toggle_mode = true
		switch.button_pressed = GameState.is_system_on(system_id)
		switch.theme_type_variation = &"SmallButton"
		switch.custom_minimum_size = Vector2(110, 42)
		color_switch(switch)
		switch.toggled.connect(_on_switch_toggled.bind(system_id))
		rows.add_child(switch)
		switches[system_id] = switch

		# The "Off: ..." note gets a column with a fixed width, so the panel
		# does not change size when a note appears (anchored, like the dashboard).
		var cost := add_label("", &"SmallText")
		cost.custom_minimum_size.x = 400
		cost_labels[system_id] = cost


func add_label(text: String, style: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = style
	rows.add_child(label)
	return label


# ON = green with navy text, OFF = the theme's navy button.
func color_switch(switch: Button) -> void:
	var on_style: StyleBoxFlat = get_theme_stylebox("pressed", &"SmallButton").duplicate()
	on_style.bg_color = ok_color
	switch.add_theme_stylebox_override("pressed", on_style)
	switch.add_theme_stylebox_override("hover_pressed", on_style)


func _on_switch_toggled(on: bool, system_id: String) -> void:
	switch_changed.emit(system_id, on)   # first GameState changes...
	refresh()                            # ...then the panel shows it


# While the panel is open, redraw every frame: the shadow pass can change
# the power available at any moment.
func _process(_delta: float) -> void:
	if visible:
		refresh()


# Redraws the switch words, the totals, the bar and the message.
func refresh() -> void:
	var available: float = GameState.get_power_available()
	var used: float = GameState.get_power_used()
	for system_id in switches:
		var on: bool = GameState.is_system_on(system_id)
		switches[system_id].set_pressed_no_signal(on)   # match GameState, without "clicking" it
		switches[system_id].text = words["on_word"] if on else words["off_word"]
		cost_labels[system_id].text = "" if on else words["off_costs"][system_id]

	available_label.text = "%s: %s" % [words["available_label"], watts(available)]
	used_label.text = "%s: %s %s %s" % [words["used_label"], watts(used), words["of_word"], watts(available)]

	var fits: bool = used <= available
	used_bar.max_value = maxf(available, used)   # a full bar = the bigger number
	used_bar.value = used
	bar_fill.bg_color = ok_color if fits else bad_color
	status_label.text = words["fits"] if fits else words["too_much"]
	status_label.add_theme_color_override("font_color", ok_color if fits else bad_color)


# The alarm's countdown, at the top of the panel (the panel covers the
# big banner). An empty text hides it.
func show_countdown(text: String) -> void:
	countdown.text = text
	countdown.visible = text != ""


# --- Opening and closing ------------------------------------------------------

func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


# --- Names and units -----------------------------------------------------------

func system_name(system_id: String) -> String:
	if system_id == "heater":
		return words["heater_name"]
	return Data.parts[system_id]["name"]


func watts(amount: float) -> String:
	return GameState.fmt(amount) + " " + words["watt_unit"]
