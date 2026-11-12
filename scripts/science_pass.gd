# science_pass.gd
# The science pass in the Arrival walk (Stage 4). Two timed presses with E:
#   1. CAPTURE at the Science station, while the target is in view.
#   2. DOWNLINK at the Comms station, while the ground station is in view.
# Storage, power and antenna speed limit how much data gets home (the math is
# in GameState: capture_science() and downlink_science()).
#   - Camera switched off at the power panel = nothing captured.
#   - Antenna switched off at the power panel = nothing sent.
#   - A small antenna is slow, so less data fits through the link.
# The windows (in seconds after the walk starts) are in data/events.json
# "science_pass". They stay outside the shadow pass (20 to 40 s).
# The words are in story.json ("science") and inner_voice.json ("science").
# walk.gd makes one of these (Arrival only) and calls update() every frame.
extends Node

const PRESS_SCENE = preload("res://scenes/timed_press.tscn")

var walk: Node3D                 # the walk scene (it has say(), player and the HUD)
var banner: Label                # the calm banner at the top (NOT the alarm banner)
var ship: Node3D                 # to change the floating station labels
var press: Control               # the timed press
var press_running: bool = false  # true while the ring is closing
var elapsed: float = 0.0         # seconds since the walk started
var numbers: Dictionary          # events.json "science_pass"
var words: Dictionary            # story.json "science"
var lines: Dictionary            # inner_voice.json "science"

var capture_open: bool = false   # is the target in view now?
var downlink_open: bool = false  # is the ground station in view now?
var captured: bool = false       # the capture press was done
var downlinked: bool = false     # the downlink press was done
var sent_home_text: String = ""  # "Sent home: X Gb", shown in the banner after the downlink
var press_kind: String = ""      # "capture" or "downlink" while a ring runs


func setup(walk_scene: Node3D, hud: CanvasLayer, voice_bar: Control, banner_label: Label, ship_node: Node3D) -> void:
	walk = walk_scene
	banner = banner_label
	ship = ship_node
	numbers = Data.events["science_pass"]
	words = Data.story["science"]
	lines = Data.voice["science"]
	banner.visible = false

	# The timed press sits in the middle of the screen, a little high, and starts hidden
	# (the same place as the oxygen generator's ring).
	press = PRESS_SCENE.instantiate()
	hud.add_child(press)
	hud.move_child(press, voice_bar.get_index())
	press.set_anchors_preset(Control.PRESET_CENTER)
	press.offset_left = -press.custom_minimum_size.x / 2.0
	press.offset_right = press.custom_minimum_size.x / 2.0
	press.offset_top = -press.custom_minimum_size.y / 2.0 - 90.0
	press.offset_bottom = press.custom_minimum_size.y / 2.0 - 90.0
	press.visible = false
	press.finished.connect(_on_press_finished)


# Called every frame by walk.gd. It opens and closes the two windows on time.
func update(delta: float) -> void:
	elapsed += delta
	set_window("capture", elapsed >= numbers["capture_start_seconds"]["value"] and elapsed < numbers["capture_end_seconds"]["value"])
	set_window("downlink", elapsed >= numbers["downlink_start_seconds"]["value"] and elapsed < numbers["downlink_end_seconds"]["value"])
	update_banner()


# Opens or closes one window. The voice speaks when it opens and when it
# closes without being used.
func set_window(kind: String, is_open: bool) -> void:
	var was_open: bool = capture_open if kind == "capture" else downlink_open
	if is_open == was_open:
		return
	if kind == "capture":
		capture_open = is_open
	else:
		downlink_open = is_open
	var label: Label3D = ship.science_labels[kind]
	if is_open:
		label.text = words["station_" + kind + "_open"]
		walk.say(lines["target_in_view"] if kind == "capture" else lines["station_in_view"])
	else:
		label.text = words["station_" + kind]
		var done: bool = captured if kind == "capture" else downlinked
		if not done:
			walk.say(lines[kind + "_window_missed"])


# The calm banner: a countdown while a window is open, then the result.
func update_banner() -> void:
	var text := ""
	if capture_open and not captured:
		text = words["banner_capture"].format({"seconds": ceili(numbers["capture_end_seconds"]["value"] - elapsed)})
	elif downlink_open and not downlinked:
		text = words["banner_downlink"].format({"seconds": ceili(numbers["downlink_end_seconds"]["value"] - elapsed)})
	elif sent_home_text != "":
		text = sent_home_text
	banner.text = text
	banner.visible = text != ""


# The mission is over: stop a ring that is still closing.
func stop_tasks() -> void:
	if press_running:
		press.running = false
		press_running = false
		walk.player.set_physics_process(true)
	press.visible = false


# Something is going on at a station, so no "Press E" prompt.
func is_busy() -> bool:
	return press_running


# The "Press E: ..." line near a science station.
func prompt_for(part_id: String) -> String:
	var hint: String = Data.voice["walk"]["press_e_hint"]
	var prompts: Dictionary = words["prompts"]
	if part_id == "science_capture":
		if captured:
			return prompts["capture_done"]
		if capture_open:
			return "%s: %s" % [hint, prompts["capture"]]
		return prompts["capture_wait"]
	if downlinked:
		return prompts["downlink_done"]
	if downlink_open:
		return "%s: %s" % [hint, prompts["downlink"]]
	return prompts["downlink_wait"]


# The player pressed E at a science station.
func use_station(part_id: String) -> void:
	if press_running:
		return
	var kind: String = part_id.trim_prefix("science_")
	if kind == "capture":
		if captured or not capture_open:
			return
	else:
		if downlinked or not downlink_open:
			return
		if GameState.science_stored <= 0.0 and GameState.is_system_on("antenna"):
			walk.say(lines["nothing_to_send"])
			return
	press_kind = kind
	press_running = true
	walk.player.set_physics_process(false)   # stand still while the ring closes
	press.visible = true
	press.start(words[kind + "_label"], numbers["press_speed"]["value"], numbers["press_tightness"]["value"], press.ACTION_E)


func _on_press_finished(result: String) -> void:
	press_running = false
	walk.player.set_physics_process(true)
	var key: String = result.to_lower()
	if press_kind == "capture":
		captured = true
		var added: float = GameState.capture_science(result)
		if not GameState.is_system_on("camera"):
			walk.say(lines["capture_camera_off"])
		else:
			var line: String = lines["capture_" + key].format({"gb": GameState.fmt(added)})
			if GameState.is_science_storage_full():
				line += " " + lines["storage_full"].format({"gb": GameState.fmt(numbers["storage_gb"]["value"])})
			walk.say(line)
	else:
		downlinked = true
		var sent: float = GameState.downlink_science(result)
		sent_home_text = words["sent_home"].format({"gb": GameState.fmt(GameState.science_returned)})
		if not GameState.is_system_on("antenna"):
			walk.say(lines["downlink_antenna_off"])
		else:
			var line: String = lines["downlink_" + key].format({"gb": GameState.fmt(sent)})
			if GameState.science_stored > 0.0:
				line += " " + lines["small_antenna_slow"]   # some data is still waiting: the link was the limit
			walk.say(line)
	ship.science_labels[press_kind].text = words["station_" + press_kind]   # the station is done: back to its name
	var tree := get_tree()
	await tree.create_timer(numbers["result_show_seconds"]["value"]).timeout
	if is_inside_tree() and not press_running:   # the scene may have changed while we waited
		press.visible = false
