# life_support.gd
# The three stations in the Life Support room: Food, Water and Air.
# Each Flight leg has its own tasks and one event (data/events.json "flight_plan").
# walk.gd makes one of these and asks it three things:
#   prompt_for(part_id)    the "Press E: ..." line for a station
#   use_station(part_id)   the player pressed E at a station
#   handle_input(event)    a key press while a station screen is open
# The numbers are in data/supplies.json. The words are in story.json (flight)
# and inner_voice.json (flight).
extends Node

const PANEL_SCENE = preload("res://scenes/station_panel.tscn")
const PRESS_SCENE = preload("res://scenes/timed_press.tscn")

# For each timed task: the start of its inner-voice lines (<prefix>_start, <prefix>_perfect, ...) and its label in story.json "flight".
const TASK_WORDS: Dictionary = {
	"oxygen_generator": ["generator", "generator_label"],
	"water_filter": ["filter", "water_filter_label"],
	"harvest": ["harvest", "harvest_label"],
}

var walk: Node3D                 # the walk scene (it has say(), player and the HUD)
var panel: PanelContainer        # the Food station's screen
var press: Control               # the timed press (oxygen generator, water filter, garden harvest)
var press_running: bool = false  # true while the ring is closing
var press_task: String = ""      # which task the ring is for: oxygen_generator, water_filter or harvest
var elapsed: float = 0.0         # seconds since the stations started (the event's clock)
var event_started: bool = false  # this leg's event starts once, then the player fixes it
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
	press.finished.connect(_on_task_press_finished)


# Called every frame by walk.gd. This leg's event starts on time, and pours out its supply
# until the player fixes it (events.json "flight_plan" and the event).
func update(delta: float) -> void:
	elapsed += delta
	var event_id: String = GameState.get_leg_plan()["event"]
	if event_id != "" and not event_started and elapsed >= Data.events[event_id]["start_after_seconds"]["value"]:
		start_event(event_id)
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


# Is this leg's event pouring now, at this station?
func event_here(station: String) -> bool:
	return GameState.leak_active and Data.events[GameState.flight_event]["station"]["value"] == station


# The "Press E: ..." line near a station.
func prompt_for(part_id: String) -> String:
	var hint: String = Data.voice["walk"]["press_e_hint"]
	var prompts: Dictionary = words["prompts"]
	var station: String = part_id.trim_prefix("station_")
	var tasks: Array = GameState.get_leg_tasks()
	if event_here(station):
		return "%s: %s" % [hint, prompts[station + "_event"]]
	match station:
		"food":
			if not GameState.rationing:
				return "%s: %s" % [hint, prompts["food"]]
			if tasks.has("harvest"):
				if GameState.is_task_done("harvest"):
					return prompts["harvest_done"]
				return "%s: %s" % [hint, prompts["harvest"]]
			return prompts["food_done"]
		"air":
			if GameState.generator_run:
				return prompts["air_done"]
			return "%s: %s" % [hint, prompts["air"]]
		"water":
			if tasks.has("water_filter"):
				if GameState.is_task_done("water_filter"):
					return prompts["water_filter_done"]
				return "%s: %s" % [hint, prompts["water_filter"]]
			return prompts["water_none"]
	return ""


func use_station(part_id: String) -> void:
	var station: String = part_id.trim_prefix("station_")
	if event_here(station):
		fix_event()
		return
	var tasks: Array = GameState.get_leg_tasks()
	match station:
		"food":
			if not GameState.rationing:
				use_food()
			elif tasks.has("harvest") and not GameState.is_task_done("harvest"):
				start_task("harvest")
			elif tasks.has("harvest"):
				walk.say(lines["harvest_already"])
			else:
				walk.say(lines["ration_already"])
		"air":
			if GameState.generator_run:
				walk.say(lines["generator_already"])
			else:
				start_task("oxygen_generator")
		"water":
			if not tasks.has("water_filter"):
				walk.say(lines["nothing_here"])
			elif GameState.is_task_done("water_filter"):
				walk.say(lines["filter_already"])
			else:
				start_task("water_filter")


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
	GameState.leg_tasks_done.append("ration")
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


# --- Timed tasks: oxygen generator (air), water filter (water), garden harvest (food) -------
# One timed press with the E key (the ring closes on the target). The result decides how much
# of the supply comes back (supplies.json "tasks"). Even a Miss does the task, just less well.

func start_task(task_id: String) -> void:
	var task: Dictionary = Data.supplies["tasks"][task_id]
	var task_words: Array = TASK_WORDS[task_id]
	press_task = task_id
	press_running = true
	walk.player.set_physics_process(false)   # stand still while the ring closes
	press.visible = true
	walk.say(lines[task_words[0] + "_start"])
	press.start(words[task_words[1]], task["press_speed"]["value"], task["press_tightness"]["value"], press.ACTION_E)


func _on_task_press_finished(result: String) -> void:
	var task_id: String = press_task
	var task: Dictionary = Data.supplies["tasks"][task_id]
	var supply: String = Data.events["flight_plan"]["tasks"][task_id]["supply"]
	GameState.add_supply(supply, task["restore"][result]["value"])
	GameState.leg_tasks_done.append(task_id)
	if task_id == "oxygen_generator":
		GameState.generator_run = true
	GameState.record_press("flight", task_id, result)
	walk.say(lines[TASK_WORDS[task_id][0] + "_" + result.to_lower()])
	press_running = false
	walk.player.set_physics_process(true)
	var tree := get_tree()
	await tree.create_timer(task["result_show_seconds"]["value"]).timeout
	if is_inside_tree():   # the scene may have changed while we waited
		press.visible = false


# --- The leg's event: a leak or spoil ------------------------------------------------------
# It starts on its own, the voice warns, and the supply falls fast. Pressing E at the
# supply's station stops it. (It is not the Mars shadow pass.)

func start_event(event_id: String) -> void:
	event_started = true
	GameState.start_flight_event(event_id)
	walk.say(lines[event_id + "_warning"])
	walk.alarm_banner.text = words["event_banners"][event_id]
	walk.alarm_banner.visible = true
	walk.dashboard.set_flashing(Data.events[event_id]["supply"], true)   # the supply's row flashes


func fix_event() -> void:
	var event_id: String = GameState.flight_event
	GameState.stop_flight_event()
	walk.alarm_banner.visible = false
	walk.dashboard.set_flashing(Data.events[event_id]["supply"], false)
	walk.say(lines[event_id + "_fixed"])
