# life_support.gd
# The three stations in the Life Support room: Food, Water and Air.
# walk.gd makes one of these and asks it three things:
#   prompt_for(part_id)    the "Press E: ..." line for a station
#   use_station(part_id)   the player pressed E at a station
#   handle_input(event)    a key press while a station screen is open
# The numbers are in data/supplies.json. The words are in story.json (flight)
# and inner_voice.json (flight).
extends Node

const PANEL_SCENE = preload("res://scenes/station_panel.tscn")
const PRESS_SCENE = preload("res://scenes/timed_press.tscn")

var walk: Node3D                 # the walk scene (it has say(), player and the HUD)
var panel: PanelContainer        # the Food station's screen
var press: Control               # the timed press (Air station: run the oxygen generator)
var press_running: bool = false  # true while the ring is closing
var elapsed: float = 0.0         # seconds since the stations started (the leak's clock)
var leak_started: bool = false   # the leak starts once, then the player fixes it
var words: Dictionary            # story.json "flight"
var lines: Dictionary            # inner_voice.json "flight"


func setup(walk_scene: Node3D, hud: CanvasLayer, voice_bar: Control) -> void:
	walk = walk_scene
	words = Data.story["flight"]
	lines = Data.voice["flight"]

	panel = PANEL_SCENE.instantiate()
	hud.add_child(panel)
	hud.move_child(panel, voice_bar.get_index())   # under the voice bar, so it never hides the bar
	panel.action_pressed.connect(_on_ration_pressed)

	# The timed press sits in the middle of the screen, a little high, and starts hidden.
	press = PRESS_SCENE.instantiate()
	hud.add_child(press)
	hud.move_child(press, voice_bar.get_index())
	press.set_anchors_preset(Control.PRESET_CENTER)
	press.offset_left = -press.custom_minimum_size.x / 2.0      # centered left to right
	press.offset_right = press.custom_minimum_size.x / 2.0
	press.offset_top = -press.custom_minimum_size.y / 2.0 - 90.0   # a little above the middle
	press.offset_bottom = press.custom_minimum_size.y / 2.0 - 90.0
	press.visible = false
	press.finished.connect(_on_generator_press_finished)


# Called every frame by walk.gd. It starts the water leak on time, and the
# leak pours out water until the player fixes it (events.json "water_leak").
func update(delta: float) -> void:
	elapsed += delta
	var leak: Dictionary = Data.events["water_leak"]
	if not leak_started and elapsed >= leak["start_after_seconds"]["value"]:
		start_leak()
	GameState.drain_leak(delta)


# The leg is over: close a station screen and stop a ring that is still closing.
func stop_tasks() -> void:
	if panel.visible:
		close_panel()
	if press_running:
		press.running = false
		press_running = false
		walk.player.set_physics_process(true)
	press.visible = false


# Is a station screen open? (walk.gd then leaves the keys to us.)
func panel_open() -> bool:
	return panel.visible


# Something is going on at a station, so no "Press E" prompt.
func is_busy() -> bool:
	return panel.visible or press_running


# E or Esc closes the open screen.
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		close_panel()
		walk.get_viewport().set_input_as_handled()


# The "Press E: ..." line near a station.
func prompt_for(part_id: String) -> String:
	var hint: String = Data.voice["walk"]["press_e_hint"]
	var prompts: Dictionary = words["prompts"]
	match part_id:
		"station_food":
			if GameState.rationing:
				return prompts["food_done"]
			return "%s: %s" % [hint, prompts["food"]]
		"station_air":
			if GameState.generator_run:
				return prompts["air_done"]
			return "%s: %s" % [hint, prompts["air"]]
		"station_water":
			if GameState.leak_active:
				return "%s: %s" % [hint, prompts["water"]]
			return prompts["water_none"]
	return ""


func use_station(part_id: String) -> void:
	match part_id:
		"station_food":
			use_food()
		"station_air":
			use_air()
		"station_water":
			use_water()


# --- Food: ration ---------------------------------------------------------------

func use_food() -> void:
	if GameState.rationing:
		walk.say(lines["ration_already"])
		return
	var ration: Dictionary = words["ration_panel"]
	panel.open(ration["title"], ration["body"], ration["button"], ration["close_hint"])
	freeze_player(true)
	walk.say(lines["ration_explain"])


func _on_ration_pressed() -> void:
	GameState.rationing = true
	walk.say(lines["ration_on"])
	close_panel()


func close_panel() -> void:
	panel.close()
	freeze_player(false)


# While a screen is open the player stands still, with a free mouse
# (the same way the Reroute Power panel works).
func freeze_player(frozen: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if frozen else Input.MOUSE_MODE_CAPTURED
	walk.player.set_physics_process(not frozen)
	walk.player.set_process_unhandled_input(not frozen)


# --- Air: run the oxygen generator ---------------------------------------------------------
# One timed press with the E key (the ring closes on the target). The result
# decides how much air comes back (supplies.json "tasks" > "oxygen_generator"). Even a
# Miss runs the generator, just less well.

func use_air() -> void:
	if GameState.generator_run:
		walk.say(lines["generator_already"])
		return
	var generator: Dictionary = Data.supplies["tasks"]["oxygen_generator"]
	press_running = true
	walk.player.set_physics_process(false)   # stand still while the ring closes
	press.visible = true
	walk.say(lines["generator_start"])
	press.start(words["generator_label"], generator["press_speed"]["value"], generator["press_tightness"]["value"], press.ACTION_E)


func _on_generator_press_finished(result: String) -> void:
	var amount: float = Data.supplies["tasks"]["oxygen_generator"]["restore"][result]["value"]
	GameState.add_supply("air", amount)
	GameState.generator_run = true
	GameState.record_press("flight", "oxygen_generator", result)
	walk.say(lines["generator_" + result.to_lower()])
	press_running = false
	walk.player.set_physics_process(true)
	var tree := get_tree()
	await tree.create_timer(Data.supplies["tasks"]["oxygen_generator"]["result_show_seconds"]["value"]).timeout
	if is_inside_tree():   # the scene may have changed while we waited
		press.visible = false


# --- Water: the leak -------------------------------------------------------------------
# The leak is the one Flight event (data/events.json "water_leak"). It starts on its
# own, the voice warns, and the water meter falls fast. Pressing E at the Water
# station stops it. (It is not the Mars shadow pass.)

func start_leak() -> void:
	leak_started = true
	GameState.leak_active = true
	walk.say(lines["leak_warning"])
	walk.alarm_banner.text = words["leak_banner"]
	walk.alarm_banner.visible = true
	walk.dashboard.set_flashing(Data.events["water_leak"]["supply"], true)   # the Water row flashes


func use_water() -> void:
	if not GameState.leak_active:
		walk.say(lines["no_leak"])
		return
	GameState.leak_active = false
	walk.alarm_banner.visible = false
	walk.dashboard.set_flashing(Data.events["water_leak"]["supply"], false)
	walk.say(lines["leak_fixed"])
