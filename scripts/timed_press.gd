# timed_press.gd
# A reusable "timed press". A ring closes on a target. The player presses a
# key (or clicks / taps) when the ring lines up with the target.
# It tells the screen how it went with the "finished" signal:
# "Perfect", "Good" or "Miss".
#
# How to use it from another screen:
#     press.finished.connect(_on_press_finished)
#     press.start("LIFTOFF", 1.0, 1.0, "timed_space")
#       label       = the words above the ring
#       speed       = 1.0 is normal; 2.0 closes twice as fast (harder)
#       tightness   = the rocket's window tightness (bigger = smaller windows)
#       action_name = "timed_space" (Launch) or "timed_e" (ship and surface)
#
# The numbers (how long the ring takes, how big the windows are) are in
# data/timing.json under "timed_press". The colors come from the theme.
# Timing is the same for every character level.
extends Control

signal finished(result: String)

const ACTION_SPACE := "timed_space"   # Space: used in Launch
const ACTION_E := "timed_e"           # E: used on the ship and the surface

# The ring is drawn inside a square under the label.
const RING_START_RADIUS := 130.0   # where the ring starts (pixels)
const TARGET_RADIUS := 58.0        # where it should be when you press (pixels)

@onready var caption: Label = %Caption

var action_name: String = ACTION_SPACE
var running: bool = false
var elapsed: float = 0.0
var close_time: float = 1.6        # seconds the ring takes to reach the target
var perfect_seconds: float = 0.1   # press this close to the target = Perfect
var good_seconds: float = 0.25     # press this close = Good
var last_result: String = ""


func _ready() -> void:
	make_input_actions()
	custom_minimum_size = Vector2(300, 340)


# Makes the two key actions, the same way player.gd does (no Input Map setup needed).
static func make_input_actions() -> void:
	var keys := { ACTION_SPACE: KEY_SPACE, ACTION_E: KEY_E }
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)


# Starts one ring.
func start(label: String, speed: float, tightness: float, key_action: String) -> void:
	var numbers: Dictionary = Data.timing["timed_press"]
	action_name = key_action
	caption.text = label
	close_time = numbers["close_seconds"] / (numbers["base_speed"] * speed)
	# The windows are a share of the ring's trip. A faster ring gives less time.
	# Bigger tightness = smaller windows.
	perfect_seconds = close_time * numbers["perfect_window"] / tightness
	good_seconds = close_time * numbers["good_window"] / tightness
	elapsed = 0.0
	last_result = ""
	running = true
	queue_redraw()


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	# The ring went past the target and the Good window too: too late.
	if elapsed > close_time + good_seconds:
		finish("Miss")
	queue_redraw()


# Only the chosen key counts (the other key does nothing).
func _unhandled_input(event: InputEvent) -> void:
	if running and event.is_action_pressed(action_name) and not event.is_echo():
		get_viewport().set_input_as_handled()
		finish(judge(elapsed - close_time))


# A mouse click or a tap counts too, anywhere on the screen. We use _input
# (not _unhandled_input) because a screen's background panel eats clicks.
# But a click on a real button is left for that button.
func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_viewport().gui_get_hovered_control() is BaseButton:
			return
		get_viewport().set_input_as_handled()
		finish(judge(elapsed - close_time))


# Turns "how many seconds off the target" into Perfect, Good or Miss.
# (Negative = early, positive = late. Early and late count the same.)
func judge(seconds_off: float) -> String:
	var off: float = absf(seconds_off)
	if off <= perfect_seconds:
		return "Perfect"
	if off <= good_seconds:
		return "Good"
	return "Miss"


func finish(result: String) -> void:
	running = false
	last_result = result
	queue_redraw()
	finished.emit(result)


# Draws the target, the two windows and the closing ring.
func _draw() -> void:
	var middle := Vector2(size.x / 2.0, size.y - 150.0 - 4.0)
	var backdrop: Color = get_theme_color("backdrop_color", &"TimedPress")
	draw_circle(middle, RING_START_RADIUS + 8.0, backdrop)

	# The windows are rings around the target. The trip is from start to target.
	var trip: float = RING_START_RADIUS - TARGET_RADIUS
	var good_half: float = trip * good_seconds / close_time
	var perfect_half: float = trip * perfect_seconds / close_time
	draw_arc(middle, TARGET_RADIUS, 0.0, TAU, 96, get_theme_color("good_zone_color", &"TimedPress"), good_half * 2.0)
	draw_arc(middle, TARGET_RADIUS, 0.0, TAU, 96, get_theme_color("perfect_zone_color", &"TimedPress"), perfect_half * 2.0)
	draw_arc(middle, TARGET_RADIUS, 0.0, TAU, 96, get_theme_color("target_color", &"TimedPress"), 3.0)

	# The closing ring. It keeps going a little past the target, then it is a Miss.
	if running or last_result != "":
		var progress: float = elapsed / close_time   # 0 = start, 1 = on the target
		var radius: float = RING_START_RADIUS - trip * progress
		if radius > 2.0:
			draw_arc(middle, radius, 0.0, TAU, 96, get_theme_color("ring_color", &"TimedPress"), 6.0)
