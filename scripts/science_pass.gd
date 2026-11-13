# science_pass.gd
# The science passes in the Arrival walk (Stage 4). There are three (GAME_PLAN 7).
# Each pass is two timed presses with E:
#   1. CAPTURE at the Science station, while the target is in view.
#   2. DOWNLINK at the Comms station, while the ground station is in view.
# Storage, power and antenna speed limit how much data gets home (the math is
# in GameState: capture_science() and downlink_science()).
#   - Camera switched off at the power panel = nothing captured.
#   - Antenna switched off at the power panel = nothing sent.
#   - A small antenna is slow, so less data fits through the link, and the
#     storage can fill up before the next capture.
# The windows (in seconds after the walk starts) are in data/events.json
# "science_pass" > passes. They stay outside the shadow pass (20 to 40 s).
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

var passes: Array = []                 # the windows of every pass: { "capture": [start, end], "downlink": [start, end] }
var capture_open_index: int = -1       # the pass whose capture window is open now (-1 = none)
var downlink_open_index: int = -1      # the pass whose downlink window is open now (-1 = none)
var capture_done: Array = []           # per pass: the capture press was done
var downlink_done: Array = []          # per pass: the downlink press was done
var sent_home_text: String = ""  # "Sent home: X Gb", shown in the banner after a downlink
var downlink_line_waiting: bool = false   # the "ground station in view" line waits until all parts are back on
var capture_line_waiting: bool = false    # the "target in view" line waits the same way
var press_kind: String = ""      # "capture" or "downlink" while a ring runs
var press_pass: int = 0          # the pass the ring is for


func setup(walk_scene: Node3D, hud: CanvasLayer, voice_bar: Control, banner_label: Label, ship_node: Node3D) -> void:
	walk = walk_scene
	banner = banner_label
	ship = ship_node
	numbers = Data.events["science_pass"]
	words = Data.story["science"]
	lines = Data.voice["science"]
	passes = numbers["passes"]["value"]
	for i in passes.size():
		capture_done.append(false)
		downlink_done.append(false)
	banner.visible = false

	# The timed press sits in the middle of the screen, a little high, and starts hidden
	# (the same place as the oxygen generator's ring).
	press = PRESS_SCENE.instantiate()
	hud.add_child(press)
	hud.move_child(press, voice_bar.get_index())
	press.set_anchors_preset(Control.PRESET_CENTER)
	press.offset_left = -press.custom_minimum_size.x / 2.0
	press.offset_right = press.custom_minimum_size.x / 2.0
	var lift: float = Data.game_data["walk"]["ring_lift_pixels"]
	press.offset_top = -press.custom_minimum_size.y / 2.0 - lift
	press.offset_bottom = press.custom_minimum_size.y / 2.0 - lift
	press.visible = false
	press.finished.connect(_on_press_finished)


# Called every frame by walk.gd. It opens and closes the windows on time.
func update(delta: float) -> void:
	elapsed += delta
	set_window("capture", window_index("capture"))
	set_window("downlink", window_index("downlink"))
	if downlink_line_waiting and downlink_open_index >= 0 and GameState.parts_off.is_empty():
		downlink_line_waiting = false
		walk.say(lines["station_in_view"])
	if capture_line_waiting and capture_open_index >= 0 and GameState.parts_off.is_empty():
		capture_line_waiting = false
		walk.say(lines["target_in_view"])
	update_banner()


# The pass whose window of this kind is open now, or -1.
func window_index(kind: String) -> int:
	for i in passes.size():
		var window: Array = passes[i][kind]
		if elapsed >= window[0] and elapsed < window[1]:
			return i
	return -1


# Opens or closes the window of one kind. The voice speaks when it opens and when it
# closes without being used.
func set_window(kind: String, index: int) -> void:
	var was: int = capture_open_index if kind == "capture" else downlink_open_index
	if index == was:
		return
	if kind == "capture":
		capture_open_index = index
	else:
		downlink_open_index = index
	var label: Label3D = ship.science_labels[kind]
	if index >= 0:
		label.text = words["station_" + kind + "_open"]
		if kind == "capture":
			if GameState.parts_off.is_empty():
				walk.say(lines["target_in_view"])
			else:
				capture_line_waiting = true   # do not hide the "switch things back on" reminder
		elif GameState.parts_off.is_empty():
			walk.say(lines["station_in_view"])
		else:
			downlink_line_waiting = true   # do not hide the "switch things back on" reminder
	else:
		label.text = words["station_" + kind]
		downlink_line_waiting = false
		capture_line_waiting = false
		var done: bool = capture_done[was] if kind == "capture" else downlink_done[was]
		if not done:
			walk.say(lines[kind + "_window_missed"])


# The calm banner: a countdown while a window is open, then the result.
func update_banner() -> void:
	var text := ""
	if capture_open_index >= 0 and not capture_done[capture_open_index]:
		text = words["banner_capture"].format({"seconds": ceili(passes[capture_open_index]["capture"][1] - elapsed), "n": capture_open_index + 1, "total": passes.size()})
	elif downlink_open_index >= 0 and not downlink_done[downlink_open_index]:
		text = words["banner_downlink"].format({"seconds": ceili(passes[downlink_open_index]["downlink"][1] - elapsed), "n": downlink_open_index + 1, "total": passes.size()})
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
		if capture_open_index < 0:
			return prompts["capture_wait"]
		if capture_done[capture_open_index]:
			return prompts["capture_done"]
		return "%s: %s" % [hint, prompts["capture"]]
	if downlink_open_index < 0:
		return prompts["downlink_wait"]
	if downlink_done[downlink_open_index]:
		return prompts["downlink_done"]
	return "%s: %s" % [hint, prompts["downlink"]]


# The player pressed E at a science station.
func use_station(part_id: String) -> void:
	if press_running:
		return
	var kind: String = part_id.trim_prefix("science_")
	if kind == "capture":
		if capture_open_index < 0 or capture_done[capture_open_index]:
			return
		press_pass = capture_open_index
	else:
		if downlink_open_index < 0 or downlink_done[downlink_open_index]:
			return
		if GameState.science_stored <= 0.0 and GameState.is_system_on("antenna"):
			walk.say(lines["nothing_to_send"])
			return
		press_pass = downlink_open_index
	press_kind = kind
	press_running = true
	walk.player.set_physics_process(false)   # stand still while the ring closes
	press.visible = true
	press.start(words[kind + "_label"], numbers["press_speed"]["value"], numbers["press_tightness"]["value"], press.ACTION_E)


func _on_press_finished(result: String) -> void:
	press_running = false
	walk.player.set_physics_process(true)
	var key: String = result.to_lower()
	GameState.record_press("arrival", press_kind, result)   # shows in the report's timed presses
	if press_kind == "capture":
		capture_done[press_pass] = true
		var added: float = GameState.capture_science(result)
		if not GameState.is_system_on("camera"):
			walk.say(lines["capture_camera_off"])
		else:
			var line: String = lines["capture_" + key].format({"gb": GameState.fmt(added)})
			if GameState.is_science_storage_full():
				line += " " + lines["storage_full"].format({"gb": GameState.fmt(GameState.get_storage_gb(numbers["storage_gb"]["value"]))})
			walk.say(line)
	else:
		downlink_done[press_pass] = true
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
