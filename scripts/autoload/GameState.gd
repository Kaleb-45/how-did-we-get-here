# GameState.gd
# The game's memory. It remembers what the player picked, so every
# screen can see it. Like Data.gd, it is an autoload, so any script
# can reach it by name, for example:  GameState.mission_id
#
# Data.gd    = what the game KNOWS   (the files, never changes)
# GameState  = what the player DID   (changes as they play)
extends Node

var character_id: String = ""   # for example "janitor"

# The player's level: "easy", "medium" or "hard". It is NOT stored. It is
# looked up from the character every time, so the two can never disagree.
# (The character -> level link is in game_data.json, "characters".)
var level: String:
	get:
		if character_id == "":
			return ""
		return Data.characters[character_id]["level"]

var mission_id: String = ""     # for example "mars_ice"

# Which version of each part the player picked.
# For example: { "solar_panel": "large", "camera": "basic", "antenna": "small" }
var choices: Dictionary = {}

# Problems that happened DURING the mission (not in the build),
# for example ["power_event"] if the player didn't fix the power alarm.
# Each name must match a section in inner_voice.json "resource_failures".
var event_failures: Array = []


# --- More things the game remembers: the setup answers, damage, timing, supplies ---
var player_name: String = ""          # what the player typed as their name
var destination_id: String = ""       # where the mission goes
var goal_id: String = ""              # what the mission wants to find out
var launch_vehicle_id: String = ""    # which rocket the player picked
var crew_supplies: Dictionary = { "food": 0.0, "water": 0.0, "air": 0.0 }
# Launch misses are saved here: "fuel" (percent of fuel lost) and part names
# like "solar_panel" (percent damaged). See add_damage().
var damage: Dictionary = {}
# One entry per timed press: { "stage": "launch", "moment": "liftoff", "result": "Perfect" }
# The result is "Perfect", "Good" or "Miss".
var timing_results: Array = []
var findings: Array = []              # things that went wrong on the way (crew supplies at zero)
# Crew supplies (data/supplies.json). crew_supplies above holds how much is left.
var supplies_started: bool = false    # true once the ship has been stocked
var rationing: bool = false           # true once the player rations the food (Food station)
var leak_active: bool = false         # true while a Flight event (a leak or spoil) is pouring out a supply
var flight_event: String = ""         # the id of the event that is pouring now (events.json), "" = none
var flight_leg: int = 0               # the Flight leg being played (0 = the first)
var fuel_days_added: float = 0.0      # extra trip days from fuel lost at the launch (set when Flight starts)
var leg_tasks_done: Array = []        # the tasks done in this leg, for example ["oxygen_generator"]
var generator_run: bool = false       # true once the player ran the oxygen generator (Air station)
# The surface work (Stage 4, surface destinations) and the flyby (Europa). See start_surface() and start_flyby().
var surface: Dictionary = {}          # days, sample, power used on the surface
var flyby: Dictionary = {}            # captured, lost, stored and sent data of the Europa flyby


func _ready() -> void:
	# Show the whole state once, so we can see it in the Output panel.
	print("GameState at startup: ", JSON.stringify(to_dict(), "  "))


# Turns the WHOLE state into one dictionary. A checkpoint saves it.
# (duplicate(true) makes a copy, so changing the copy never changes the game.)
func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"level": level,
		"character_id": character_id,
		"mission_id": mission_id,
		"destination_id": destination_id,
		"goal_id": goal_id,
		"launch_vehicle_id": launch_vehicle_id,
		"choices": choices.duplicate(true),
		"crew_supplies": crew_supplies.duplicate(true),
		"damage": damage.duplicate(true),
		"timing_results": timing_results.duplicate(true),
		"findings": findings.duplicate(true),
		"supplies_started": supplies_started,
		"rationing": rationing,
		"leak_active": leak_active,
		"flight_event": flight_event,
		"fuel_days_added": fuel_days_added,
		"generator_run": generator_run,
		"surface": surface.duplicate(true),
		"flyby": flyby.duplicate(true),
		"event_failures": event_failures.duplicate(true),
		"mission_months": mission_months,
		"data_collected": data_collected,
		"parts_off": parts_off.duplicate(true),
		"lifetime_lost": lifetime_lost,
		"storm_active": storm_active,
		"science_stored": science_stored,
		"science_returned": science_returned,
		"end_values": end_values.duplicate(true),
		"end_limits": end_limits.duplicate(true),
	}


# Puts a saved dictionary back into the game. A missing key, or a value of the
# wrong kind (for example from a broken save file), keeps its current value.
func from_dict(d: Dictionary) -> void:
	player_name = pick(d, "player_name", player_name)
	character_id = pick(d, "character_id", character_id)
	mission_id = pick(d, "mission_id", mission_id)
	destination_id = pick(d, "destination_id", destination_id)
	goal_id = pick(d, "goal_id", goal_id)
	launch_vehicle_id = pick(d, "launch_vehicle_id", launch_vehicle_id)
	choices = pick(d, "choices", choices)
	crew_supplies = pick(d, "crew_supplies", crew_supplies)
	damage = pick(d, "damage", damage)
	timing_results = pick(d, "timing_results", timing_results)
	findings = pick(d, "findings", findings)
	supplies_started = pick(d, "supplies_started", supplies_started)
	rationing = pick(d, "rationing", rationing)
	leak_active = pick(d, "leak_active", leak_active)
	flight_event = pick(d, "flight_event", flight_event)
	fuel_days_added = pick(d, "fuel_days_added", fuel_days_added)
	flight_leg = 0   # a saved game is always between legs: Flight starts from its first leg
	leg_tasks_done.clear()
	generator_run = pick(d, "generator_run", generator_run)
	surface = pick(d, "surface", surface)
	flyby = pick(d, "flyby", flyby)
	event_failures = pick(d, "event_failures", event_failures)
	mission_months = pick(d, "mission_months", mission_months)
	data_collected = pick(d, "data_collected", data_collected)
	parts_off = pick(d, "parts_off", parts_off)
	lifetime_lost = pick(d, "lifetime_lost", lifetime_lost)
	storm_active = pick(d, "storm_active", storm_active)
	science_stored = pick(d, "science_stored", science_stored)
	science_returned = pick(d, "science_returned", science_returned)
	end_values = pick(d, "end_values", end_values)
	end_limits = pick(d, "end_limits", end_limits)


# One value from a saved dictionary. If it is missing, null or the wrong kind,
# we keep the current value. Lists and dictionaries are copied.
func pick(d: Dictionary, key: String, current):
	if not d.has(key) or d[key] == null:
		return current
	var value = d[key]
	var both_numbers: bool = (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and (typeof(current) == TYPE_INT or typeof(current) == TYPE_FLOAT)
	if typeof(value) != typeof(current) and not both_numbers:
		return current
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	if both_numbers:
		return float(value)
	return value


# --- Checkpoints (GAME_PLAN 12b) -----------------------------------------
# A checkpoint is a saved copy of the WHOLE game state (to_dict).
#   1 = after Build   (saved when we leave Review)
#   2 = after Launch  (saved when we leave Launch)
#   3 = after Flight  (saved when we leave Flight, before the orbit burn)
# Where they are saved is in game_data.json: stages -> checkpoints.
# We keep them in memory (fast, always works) AND write them to a file in
# user:// . On the web, user:// is stored in the browser (IndexedDB), so a
# saved checkpoint survives a reload of the page.
var checkpoints: Dictionary = {}   # for example { 1: {...state...}, 2: {...} }


# Saves the state as checkpoint number n (1, 2 or 3).
func save_checkpoint(n: int) -> void:
	checkpoints[n] = to_dict()
	var path: String = Data.game_data["stages"]["checkpoints"]["save_file"]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Checkpoint ", n, " saved in memory only (could not open ", path, ")")
		return
	var text_keys: Dictionary = {}   # JSON keys must be text, so 1 becomes "1"
	for number in checkpoints:
		text_keys[str(number)] = checkpoints[number]
	file.store_string(JSON.stringify(text_keys))
	file.close()
	print("Checkpoint ", n, " saved (", path, ")")


# Called when a stage ends. If this stage ends with a checkpoint, save it.
func save_checkpoint_after(stage_id: String) -> void:
	var saved_when_leaving: Dictionary = Data.game_data["stages"]["checkpoints"]["saved_when_leaving"]
	if saved_when_leaving.has(stage_id):
		save_checkpoint(int(saved_when_leaving[stage_id]))


# Reads the checkpoint file back into memory, but only if memory is empty
# (for example after the web page was reloaded).
func load_checkpoints_from_file() -> void:
	var path: String = Data.game_data["stages"]["checkpoints"]["save_file"]
	if not checkpoints.is_empty() or not FileAccess.file_exists(path):
		return
	var parser := JSON.new()   # (JSON.new().parse gives an error code, not an engine error)
	var saved = parser.data if parser.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not saved is Dictionary:
		DirAccess.remove_absolute(path)   # a broken file: throw it away
		return
	for key in saved:
		if saved[key] is Dictionary and str(key).is_valid_int():   # skip anything else
			checkpoints[int(key)] = saved[key]


# The newest checkpoint number that exists (0 = none yet).
func get_latest_checkpoint() -> int:
	load_checkpoints_from_file()
	var latest := 0
	for number in checkpoints:
		latest = maxi(latest, int(number))
	return latest


# Which checkpoint "Retry" should use: the newest one saved BEFORE the first
# failure. A checkpoint that already holds a failure or crew damage would give
# the same bad ending again, so we step back to the one before it (never below 1).
func get_retry_checkpoint() -> int:
	var latest: int = get_latest_checkpoint()
	var n: int = latest
	# A crew supply that ended low was decided in Flight (tasks, rationing), and checkpoint 3 is saved AFTER Flight,
	# so a retry from it could never change the ending. Go back to checkpoint 2 (before Flight).
	for id in SUPPLY_IDS:
		if event_failures.has(id + "_low") or event_failures.has(id + "_empty"):
			n = mini(n, 2)
	while n > 1:
		var saved = checkpoints.get(n)
		if saved is Dictionary and saved.get("event_failures", []).is_empty() and float(saved.get("damage", {}).get("crew", 0.0)) <= 0.0:
			return n
		n -= 1
	return 1 if latest > 0 else 0


# Can Retry help? Not with a red build: every checkpoint holds the same build.
func can_retry() -> bool:
	return get_retry_checkpoint() > 0 and get_failed_resources().is_empty()


# Puts checkpoint n back into the game. Gives false if it does not exist.
func load_checkpoint(n: int) -> bool:
	load_checkpoints_from_file()
	if not checkpoints.get(n) is Dictionary:
		return false
	from_dict(checkpoints[n])
	print("Checkpoint ", n, " loaded")
	return true


# Forgets every checkpoint (memory and file). A new design needs new checkpoints.
func clear_checkpoints() -> void:
	checkpoints.clear()
	var path: String = Data.game_data["stages"]["checkpoints"]["save_file"]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# "Same design / new destination": the parts, name and character stay. The
# destination, the mission results and every checkpoint are forgotten, because
# a checkpoint belongs to one destination.
func keep_design_new_destination() -> void:
	start_new_attempt()
	start_mission()
	destination_id = ""
	goal_id = ""
	clear_checkpoints()


# "Start fresh": everything goes back to how the game starts, checkpoints too.
func reset_all() -> void:
	player_name = ""
	character_id = ""
	mission_id = ""
	destination_id = ""
	goal_id = ""
	launch_vehicle_id = ""
	choices.clear()
	swapped_parts.clear()
	start_new_attempt()
	start_mission()
	clear_checkpoints()


# Everything that went wrong: build problems first, then mission events.
func get_all_failures() -> Array:
	return get_failed_resources() + event_failures


# Clears what happened during the last mission, but keeps the part choices.
func start_new_attempt() -> void:
	event_failures.clear()
	# The launch starts again too. The parts, name, character and rocket stay.
	damage.clear()
	timing_results.clear()
	# The crew supplies, the findings and the leak start again too.
	clear_supplies()
	findings.clear()
	surface.clear()
	flyby.clear()


# --- The launch (timed presses) -------------------------------------------

# Call when the Launch screen opens: no damage and no results yet.
func start_launch() -> void:
	damage.clear()
	timing_results.clear()


# Saves one timed-press result.
func record_press(stage: String, moment_id: String, result: String) -> void:
	timing_results.append({ "stage": stage, "moment": moment_id, "result": result })


# Adds damage (or lost fuel). kind is "fuel" or a part name. amount is a percent.
func add_damage(kind: String, amount: float) -> void:
	damage[kind] = damage.get(kind, 0.0) + amount


# --- Crew supplies (food, water, air) --------------------------------------
# A separate group from the six resources. They show in Flight and Arrival.
# Every number is in data/supplies.json. Each one drops by:
#   (use per person per day) x (crew size) x (game days that passed)

const SUPPLY_IDS: Array = ["food", "water", "air"]


# The destination facts from destinations.json (Mars orbit if none is picked yet).
func get_destination() -> Dictionary:
	var id: String = destination_id
	if id == "":
		id = Data.destinations.keys()[0]
	return Data.destinations[id]


# The id of the destination (Mars orbit if none is picked yet).
func get_destination_id() -> String:
	if destination_id != "":
		return destination_id
	return Data.destinations.keys()[0]


# The first destination in destinations.json that ends its trip this way ("orbit", "surface" or "flyby").
# Screens use it when you press Play on them directly, so no site name is written in the code.
func get_first_destination_of(arrival_type: String) -> String:
	for id in Data.destinations:
		if Data.destinations[id]["arrival_type"]["value"] == arrival_type:
			return id
	return Data.destinations.keys()[0]


# One optional fact of the destination (destinations.json), for example "power_cost_factor".
# A site that does not list the fact gets the default.
func get_site_value(key: String, default):
	var facts: Dictionary = get_destination()
	if facts.has(key):
		return facts[key]["value"]
	return default


# How the trip ends: "orbit", "surface" or "flyby" (destinations.json).
func get_arrival_type() -> String:
	return get_destination()["arrival_type"]["value"]


# Is there a crew? Only then do the crew supplies (food, water, air) exist.
# Europa has no crew, so Flight shows no crew supplies there.
func has_crew() -> bool:
	return bool(get_destination()["crew"]["value"])


# How many legs the Flight has: the destination's flight_legs, or just one for a trip with no crew (events.json flight_plan).
func get_flight_legs() -> int:
	if not has_crew():
		return int(Data.events["flight_plan"]["no_crew_legs"]["value"])
	return int(get_destination()["flight_legs"]["value"])


# How many real days one Flight leg stands for: the trip's days split into the legs we play.
func get_flight_leg_days() -> float:
	return (float(get_destination()["trip_days"]["value"]) + fuel_days_added) / float(get_flight_legs())


# How many real seconds one Flight leg lasts when you play it.
func get_flight_leg_seconds() -> float:
	return float(get_destination()["flight_leg_seconds"]["value"])


# Stock the ship: every supply at its start amount, no rationing, no leak.
func start_supplies() -> void:
	for id in SUPPLY_IDS:
		crew_supplies[id] = float(Data.supplies["start_amount"][id]["value"])
	rationing = false
	leak_active = false
	flight_event = ""
	generator_run = false
	supplies_started = true
	flight_leg = 0
	leg_tasks_done.clear()
	findings.clear()
	for id in SUPPLY_IDS:   # old crew problems from a last try are gone
		event_failures.erase(id + "_empty")
		event_failures.erase(id + "_low")


# Safety net: if the walk starts without a Flight (Play on the walk scene), stock the ship.
# The Flight tasks never happened, so the ship starts as if they were done:
# rationing is on and the oxygen generator ran (supplies.json "walk_alone").
func ensure_supplies() -> void:
	if not supplies_started:
		start_supplies()
		rationing = true
		generator_run = true
		var result: String = Data.supplies["walk_alone"]["air_result"]["value"]
		add_supply("air", Data.supplies["tasks"]["oxygen_generator"]["restore"][result]["value"])


# Start of a new attempt or a fresh game: no supplies, no leak, no rationing. (Parts, name, character and rocket stay.)
func clear_supplies() -> void:
	for id in SUPPLY_IDS:
		crew_supplies[id] = 0.0
	rationing = false
	leak_active = false
	flight_event = ""
	generator_run = false
	supplies_started = false
	fuel_days_added = 0.0
	flight_leg = 0
	leg_tasks_done.clear()


# How much the whole crew uses in one game day.
func get_supply_use_per_day(id: String) -> float:
	var use: float = Data.supplies["per_person_per_day"][id]["value"] * Data.supplies["crew_size"]["value"]
	if id == "food" and rationing:
		use *= Data.supplies["tasks"]["ration"]["food_use_factor"]["value"]
	if id == "water":
		use *= float(get_part_fact("life_support", "water_use_factor", 1.0))   # a water recycler
	return use


# Some game days passed: the crew used some supplies.
func advance_supplies(days_passed: float) -> void:
	for id in SUPPLY_IDS:
		crew_supplies[id] = maxf(0.0, crew_supplies[id] - get_supply_use_per_day(id) * days_passed)


# A Flight event (water leak, air leak, food spoils) pours its supply out, drain_per_second every real second.
func drain_leak(delta: float) -> void:
	if leak_active and Data.events.has(flight_event):
		var event: Dictionary = Data.events[flight_event]
		var supply: String = event["supply"]
		crew_supplies[supply] = maxf(0.0, crew_supplies[supply] - float(event["drain_per_second"]["value"]) * delta)


# --- The Flight legs (events.json "flight_plan") ----------------------------------

# The plan of the leg being played: { "tasks": [...], "event": "water_leak" }.
# A trip with no crew has no tasks and no event.
func get_leg_plan() -> Dictionary:
	if not has_crew():
		return {"tasks": [], "event": ""}
	var legs: Array = Data.events["flight_plan"]["legs"]["value"]
	return legs[mini(flight_leg, legs.size() - 1)]


# The tasks of this leg that this ship can do (no harvest without a garden).
func get_leg_tasks() -> Array:
	var tasks: Array = []
	var catalog: Dictionary = Data.events["flight_plan"]["tasks"]
	for id in get_leg_plan()["tasks"]:
		var needs: String = catalog[id].get("needs_part", {}).get("value", "")
		if needs == "" or get_part_fact("life_support", needs, false):
			tasks.append(id)
	return tasks


# A new leg starts: its tasks are not done yet and nothing is pouring. Rationing stays on once it is on.
func begin_leg() -> void:
	if flight_leg == 0:
		# Fuel lost at the launch (a missed press) makes the trip longer: extra days for every percent lost.
		fuel_days_added = damage.get("fuel", 0.0) * float(Data.events["flight_plan"]["days_per_fuel_percent"]["value"])
	generator_run = false
	leak_active = false
	flight_event = ""
	leg_tasks_done.clear()


func start_flight_event(id: String) -> void:
	flight_event = id
	leak_active = true


func stop_flight_event() -> void:
	flight_event = ""
	leak_active = false


func is_task_done(task_id: String) -> bool:
	return leg_tasks_done.has(task_id)


# The leg is over. A task that was skipped costs its meter a part of its full size. A leak that was
# not fixed stops. Gives back { "skipped": [task ids], "lost": { supply: amount }, "more": true if another leg follows }.
func end_leg() -> Dictionary:
	var catalog: Dictionary = Data.events["flight_plan"]["tasks"]
	var skipped: Array = []
	var lost: Dictionary = {}
	for id in get_leg_tasks():
		if is_task_done(id) or (id == "ration" and rationing):
			continue
		var percent: float = float(catalog[id]["skip_loss_percent"]["value"])
		if percent <= 0.0:
			continue
		var supply: String = catalog[id]["supply"]
		var amount: float = get_supply_capacity(supply) * percent / 100.0
		var before: float = crew_supplies[supply]
		crew_supplies[supply] = maxf(0.0, before - amount)
		lost[supply] = before - crew_supplies[supply]
		skipped.append(id)
	stop_flight_event()
	flight_leg += 1
	var more: bool = flight_leg < get_flight_legs()
	if not more:
		flight_leg = 0   # the Flight is over: the next one starts from its first leg
	leg_tasks_done.clear()
	return {"skipped": skipped, "lost": lost, "more": more}


# Put air (or anything else) back, but never above the meter's capacity.
func add_supply(id: String, amount: float) -> void:
	crew_supplies[id] = minf(get_supply_capacity(id), crew_supplies[id] + amount)


func get_supply_capacity(id: String) -> float:
	return float(Data.supplies["capacity"][id]["value"])


# "safe" (green), "warning" (yellow) or "danger" (red). The thresholds are a
# percent of the meter's capacity (supplies.json "status").
func get_supply_status(id: String) -> String:
	var percent: float = crew_supplies[id] / get_supply_capacity(id) * 100.0
	if percent < Data.supplies["status"]["danger_percent"]["value"]:
		return "danger"
	if percent < Data.supplies["status"]["warning_percent"]["value"]:
		return "warning"
	return "safe"


func get_supply_statuses() -> Dictionary:
	var statuses: Dictionary = {}
	for id in SUPPLY_IDS:
		statuses[id] = get_supply_status(id)
	return statuses


# The worst of the three supply colors (the wrist light uses it).
func get_worst_supply_status() -> String:
	var worst := "safe"
	for id in SUPPLY_IDS:
		var status: String = get_supply_status(id)
		if status == "danger":
			return "danger"
		if status == "warning":
			worst = "warning"
	return worst


# A supply at zero is a finding and costs some damage. It happens once per supply.
# It gives back the supplies that just hit zero, so the screen can say something.
func check_empty_supplies() -> Array:
	var just_empty: Array = []
	if not supplies_started:
		return just_empty
	for id in SUPPLY_IDS:
		if crew_supplies[id] <= 0.0 and not event_failures.has(id + "_empty"):
			add_crew_finding(id)
			just_empty.append(id)
	return just_empty


func add_crew_finding(id: String) -> void:
	var cost: Dictionary = Data.supplies["empty_damage"]
	findings.append({ "supply": id, "finding": id + "_empty" })
	event_failures.append(id + "_empty")   # the debrief makes a card from it
	add_damage(cost["kind"], cost["amount"]["value"])


# At the end of Arrival: a supply that is still red is a failure (unless it
# already has its "ran out" finding).
func add_end_of_supply_failures() -> void:
	if not supplies_started:
		return
	for id in SUPPLY_IDS:
		if get_supply_status(id) == "danger" and not event_failures.has(id + "_empty") and not event_failures.has(id + "_low"):
			event_failures.append(id + "_low")


# --- The live mission (3D walk) ------------------------------------------

var mission_months: float = 0.0     # mission time so far, in months
var data_collected: float = 0.0     # science data collected so far
var parts_off: Array = []           # systems turned off, for example ["camera", "heater"]
var lifetime_lost: float = 0.0      # extra months lost while the heater was off
var storm_active: bool = false      # true during the shadow pass (no sunlight on the solar panels)
var science_stored: float = 0.0     # science pass: data captured and waiting in storage (Gb)
var science_returned: float = 0.0   # science pass: data that got home (Gb)

# The live numbers at the moment the mission ended (for the debrief's blanks).
var end_values: Dictionary = {}
var end_limits: Dictionary = {}


# Call when the walk starts: the clock goes back to zero.
func start_mission() -> void:
	mission_months = 0.0
	data_collected = 0.0
	parts_off.clear()
	lifetime_lost = 0.0
	storm_active = false
	science_stored = 0.0
	science_returned = 0.0
	end_values.clear()
	end_limits.clear()


# Call when the walk ends. Any dashboard row that is RED at the end is a
# failure: the player has to keep an eye on their goals the whole mission.
# Rows that already have their own explanation are skipped:
#   - a build failure (it was already red on the Review screen)
#   - power, when the power alarm already failed ("power_event")
# The failure is named "<resource>_live" (for example "data_live") when
# inner_voice.json has a card for it, otherwise just the resource name.
func add_end_of_mission_failures() -> void:
	end_values = get_live_values()
	end_limits = get_live_limits()
	var build_failures: Array = get_failed_resources()
	for res_id in end_values:
		if is_ok(end_values[res_id], end_limits[res_id]):
			continue
		if build_failures.has(res_id):
			continue
		if res_id == "power" and event_failures.has("power_event"):
			continue
		var failure_id: String = res_id + "_live"
		if not Data.voice["resource_failures"].has(failure_id):
			failure_id = res_id
		if not event_failures.has(failure_id):
			event_failures.append(failure_id)
	add_end_of_supply_failures()   # red crew supplies count too


# --- The science pass (Arrival) -------------------------------------------
# Two timed presses: capture (Science station), then downlink (Comms station).
# The numbers are in data/events.json "science_pass". The result is kept in
# science_stored / science_returned. It does NOT change the dashboard's Data row.

# Capture: the camera takes a picture. How much it holds = the camera's data
# (Gb per day) x capture_days_worth x the press result. The storage is limited.
# A camera that is switched off at the power panel takes nothing.
# Returns the Gb that were really stored.
func capture_science(result: String) -> float:
	if not is_system_on("camera"):
		return 0.0
	var pass_data: Dictionary = Data.events["science_pass"]
	var camera_gb_per_day: float = system_effects("camera")["data"]
	var wanted: float = camera_gb_per_day * pass_data["capture_days_worth"]["value"] * pass_data["result_factor"][result]["value"]
	var room: float = maxf(0.0, get_storage_gb(pass_data["storage_gb"]["value"]) - science_stored)
	var added: float = minf(wanted, room)
	science_stored += added
	return added


# True if the last capture wanted more than the storage could hold.
func is_science_storage_full() -> bool:
	return science_stored >= get_storage_gb(Data.events["science_pass"]["storage_gb"]["value"])


# How much data the ship can store (Gb): the number in events.json plus the picked computer's storage bonus (never below 1).
func get_storage_gb(base_gb: float) -> float:
	return maxf(1.0, base_gb + float(get_part_fact("computer", "storage_bonus_gb")))


# What the antenna could send during the pass (Gb) = speed (Mb/s) x hours x 3600 / 1000.
# The speed is the antenna's "communications" number (real NASA numbers).
func get_downlink_capacity() -> float:
	var pass_data: Dictionary = Data.events["science_pass"]
	var megabits_per_second: float = system_effects("antenna")["communications"]
	return megabits_per_second * pass_data["downlink_hours"]["value"] * 3600.0 / 1000.0


# Downlink: send the stored data home. sent = min(stored, what the antenna can
# send x the press result). An antenna that is switched off sends nothing.
# Returns the Gb that really got home.
func downlink_science(result: String) -> float:
	if not is_system_on("antenna"):
		return 0.0
	var factor: float = Data.events["science_pass"]["result_factor"][result]["value"]
	var sent: float = minf(science_stored, get_downlink_capacity() * factor)
	science_stored -= sent
	science_returned += sent
	return sent


# Call every frame during the walk. delta = real seconds since last frame.
func advance_mission(delta: float) -> void:
	var clock: Dictionary = Data.game_data["mission_clock"]
	var months_passed: float = delta * clock["months_per_second"]
	mission_months += months_passed
	# Data adds up: (data per day right now) x (days that just passed).
	var days_passed: float = months_passed * clock["days_per_month"]
	data_collected += get_running_values()["data"] * days_passed
	# Heater off: the cold wears out the batteries, so lifetime drops faster.
	if parts_off.has("heater"):
		lifetime_lost += delta * Data.game_data["reroute_power"]["heater"]["off_lifetime_months_per_second"] * float(get_part_fact("thermal", "cold_wear_factor", 1.0))


# Like get_totals(), but parts that are turned off stop giving or using
# the resources listed in "turned_off_parts_stop" (power, data, communications).
func get_running_values() -> Dictionary:
	var values: Dictionary = get_totals()
	var stops: Array = Data.game_data["mission_clock"]["turned_off_parts_stop"]
	for system_id in parts_off:
		var effects: Dictionary = system_effects(system_id)
		for res_id in stops:
			values[res_id] -= effects.get(res_id, 0.0)   # the heater only has power

	# Shadow pass: the solar part makes solar_drop_percent less power,
	# and the batteries give battery_power instead.
	if storm_active:
		var storm: Dictionary = Data.game_data["events"]["power_low"]
		var solar_id: String = storm["solar_part"]
		var solar_power: float = get_version_effects(solar_id, choices[solar_id])["power"]
		values["power"] -= solar_power * storm["solar_drop_percent"] / 100.0
		values["power"] += storm["battery_power"]
	return values


# --- The power panel's systems (Reroute Power) -------------------------------
# A "system" is something with a switch: camera, antenna (parts) or heater.

# What a system gives and uses: the picked version of a part, or the heater.
func system_effects(system_id: String) -> Dictionary:
	if system_id == "heater":
		return get_heater_effects()
	return get_version_effects(system_id, choices[system_id])


# What the heater uses: the normal number (game_data.json reroute_power) made smaller by the picked thermal part
# (good insulation means the heater has less to do).
func get_heater_effects() -> Dictionary:
	var effects: Dictionary = Data.game_data["reroute_power"]["heater"]["effects"].duplicate()
	effects["power"] = float(effects["power"]) + float(get_part_fact("thermal", "heater_power_saved_w"))
	return effects


# Flip a switch. Turned-off systems go in parts_off, and
# get_running_values() leaves out their power, data and communications.
func set_system_on(system_id: String, on: bool) -> void:
	if on:
		parts_off.erase(system_id)
	elif not parts_off.has(system_id):
		parts_off.append(system_id)


func is_system_on(system_id: String) -> bool:
	return not parts_off.has(system_id)


# What the solar panels make right now. During the shadow pass they make
# less (none at all), and the batteries give battery_power instead.
func get_power_available() -> float:
	var storm: Dictionary = Data.game_data["events"]["power_low"]
	var solar_id: String = storm["solar_part"]
	var solar: float = get_version_effects(solar_id, choices[solar_id])["power"]
	if storm_active:
		solar -= solar * storm["solar_drop_percent"] / 100.0
		solar += storm["battery_power"]
	return solar


# Seconds the player has to fix the shadow-pass alarm: the normal time (game_data.json events) plus the picked
# battery's alarm_extra_seconds. It always stays below storm_seconds, or a player who does nothing would be saved
# when the shadow pass ends.
func get_alarm_seconds() -> float:
	var storm: Dictionary = Data.game_data["events"]["power_low"]
	var seconds: float = float(storm["time_to_fix_seconds"]) + float(get_part_fact("battery", "alarm_extra_seconds"))
	return clampf(seconds, 1.0, float(storm["storm_seconds"]) - 1.0)


# What the body uses (always on). The data says -40, which means "uses 40 W".
func get_body_power_use() -> float:
	return -Data.game_data["spacecraft_base"]["effects"]["power"]


# What one system uses when it is ON.
func get_power_use(system_id: String) -> float:
	return -system_effects(system_id).get("power", 0.0)


# Everything that is using power right now: the body + every system that is ON.
func get_power_used() -> float:
	var used: float = get_body_power_use()
	for system_id in Data.game_data["reroute_power"]["systems"]:
		if is_system_on(system_id):
			used += get_power_use(system_id)
	return used


# Has the mission clock reached the mission length? The length is the
# mission's "need at least" lifetime (for example 24 months).
func is_mission_time_up() -> bool:
	return mission_months >= get_limits()["mission_lifetime"]["value"]


# Is spare power inside its limit right now? (Used by the alarm.)
func is_power_ok() -> bool:
	return is_ok(get_running_values()["power"], get_limits()["power"])


# The six values the dashboard shows during the walk.
func get_live_values() -> Dictionary:
	var values: Dictionary = get_running_values()
	values["data"] = data_collected                                     # total so far
	values["mission_lifetime"] = get_totals()["mission_lifetime"] - mission_months - lifetime_lost   # months left
	return values


# The limits during the walk. Two of them move with the mission clock:
#   data:     "should have by now" = the minimum rate x days so far
#   lifetime: "months still needed" = mission length - months so far
func get_live_limits() -> Dictionary:
	var limits: Dictionary = get_limits()
	var days_per_month: float = Data.game_data["mission_clock"]["days_per_month"]
	var days_so_far: float = mission_months * days_per_month
	var mission_days: float = limits["mission_lifetime"]["value"] * days_per_month

	var data: Dictionary = limits["data"]
	data["bar_max"] = data["bar_max"] * mission_days
	data["value"] = data["value"] * days_so_far
	data["warning"] = data["warning"] * days_so_far

	var lifetime: Dictionary = limits["mission_lifetime"]
	lifetime["value"] -= mission_months
	lifetime["warning"] -= mission_months
	return limits


# If a part has no choice yet, pick its FIRST version from the data file.
# (When the player comes back from the report, their old choices stay.)
func fill_default_choices() -> void:
	for part_id in Data.parts:
		var allowed: Array = get_allowed_versions(part_id)
		if allowed.is_empty():
			choices.erase(part_id)   # this slot does not exist at this destination
		elif not choices.has(part_id) or not allowed.has(choices[part_id]):
			var first: String = get_default_version(part_id, allowed)
			if choices.has(part_id):
				# The player had picked something that is not allowed here: remember it, so Build can say so.
				swapped_parts.append({"part": part_id, "from": choices[part_id], "to": first})
			choices[part_id] = first


# The version a slot starts with: the slot's "default" in the data if it is allowed here, otherwise the first allowed one.
# (The default version of the newer slots is already part of the spacecraft base, so it adds nothing.)
func get_default_version(part_id: String, allowed: Array) -> String:
	var wanted: String = Data.parts[part_id].get("default", "")
	if wanted != "" and allowed.has(wanted):
		return wanted
	return allowed[0]


# One number that belongs to the picked version of a slot (for example the battery's "alarm_extra_seconds").
# 0 (or the default you give) if the slot does not exist here, or the version has no such fact.
func get_part_fact(part_id: String, key: String, default = 0.0):
	if not choices.has(part_id) or not is_part_allowed(part_id, choices[part_id]):
		return default
	var version: Dictionary = Data.parts[part_id]["versions"][choices[part_id]]
	if version.has(key):
		return version[key]["value"]
	return default


# Parts that were swapped because they are not allowed at the new destination (Build shows a line, then clears this).
var swapped_parts: Array = []


# --- Parts per destination (batch 8) ----------------------------------------
# game_data.json "parts": allowed_at lists, name_at, scaling. See "_allowed_readme" there.
# Only parts that are allowed at the destination count (Build shows only those).
# A choice that is not allowed here (for example the RTG after changing from
# Europa to Mars) is replaced by the first allowed version by fill_default_choices().

# Does an allowed_at list include this destination (by id or by its arrival type)?
# The word "crew" in a list means "every destination that has a crew" (for example the life support slot).
func list_allows(allowed: Array) -> bool:
	return allowed.has(get_destination_id()) or allowed.has(get_arrival_type()) or (allowed.has("crew") and has_crew())


# Is this part version allowed at the destination? (A version without its own list uses its slot's list.)
func is_part_allowed(part_id: String, version_id: String) -> bool:
	var part: Dictionary = Data.parts[part_id]
	if not list_allows(part.get("allowed_at", ["orbit", "surface", "flyby"])):
		return false
	var version: Dictionary = part["versions"][version_id]
	if version.has("allowed_at"):
		return list_allows(version["allowed_at"])
	return true


# The version ids of a slot that can be picked at this destination, in the data file's order.
func get_allowed_versions(part_id: String) -> Array:
	var result: Array = []
	for version_id in Data.parts[part_id]["versions"]:
		if is_part_allowed(part_id, version_id):
			result.append(version_id)
	return result


# The slot's name at this destination (Europa calls the solar panel slot "Power source").
func get_part_name(part_id: String) -> String:
	var part: Dictionary = Data.parts[part_id]
	return part.get("name_at", {}).get(get_destination_id(), part["name"])


# How much of its Mars power a solar part makes here: this destination's sunlight
# divided by Mars orbit's (game_data.json "destination_scaling"). Mars gives exactly 1.0.
func get_sunlight_factor() -> float:
	var reference: String = Data.game_data["destination_scaling"]["reference_destination"]
	return float(get_destination()["sunlight_vs_earth"]["value"]) / float(Data.destinations[reference]["sunlight_vs_earth"]["value"])


# How much of its Mars data rate an antenna sends here: (reference delay / this delay) to the
# power of data_rate_exponent. Mars gives exactly 1.0.
func get_distance_factor() -> float:
	var scaling: Dictionary = Data.game_data["destination_scaling"]
	var reference: String = scaling["reference_destination"]
	var ratio: float = float(Data.destinations[reference]["signal_delay_minutes"]["value"]["max"]) / float(get_destination()["signal_delay_minutes"]["value"]["max"])
	return pow(ratio, float(scaling["data_rate_exponent"]["value"]))


# What a part version gives and uses AT THIS DESTINATION: the data file's numbers,
# with power (sunlight) and communications (distance) scaled where the version says so.
func get_version_effects(part_id: String, version_id: String) -> Dictionary:
	var version: Dictionary = Data.parts[part_id]["versions"][version_id]
	var effects: Dictionary = version["effects"].duplicate()
	var scaling: Array = version.get("scaling", [])
	if scaling.has("sunlight"):
		effects["power"] = effects["power"] * get_sunlight_factor()
	if scaling.has("distance"):
		effects["communications"] = effects["communications"] * get_distance_factor()
	return effects


# A missed press's cost, after the picked propulsion part: a better engine loses less fuel
# (propulsion "fuel_loss_factor", 1.0 = all). Other kinds of cost stay the same.
func scaled_cost(cost: Dictionary) -> Dictionary:
	var amount: float = float(cost["amount"])
	if cost["kind"] == "fuel":
		amount *= float(get_part_fact("propulsion", "fuel_loss_factor", 1.0))
	return {"kind": cost["kind"], "amount": amount}


# The cost of a missed landing press, made smaller by the Stage 1 landing part that guards it
# (timing.json landing_moments -> protected_by; the part's landing_cost_factor).
func get_landing_miss_cost(moment_id: String) -> Dictionary:
	var moment: Dictionary = Data.timing["landing_moments"][moment_id]
	var cost: Dictionary = moment["miss_cost"]
	var factor := 1.0
	var slot: String = moment.get("protected_by", "")
	if slot != "" and Data.parts.has(slot) and choices.has(slot) and is_part_allowed(slot, choices[slot]):
		factor = float(Data.parts[slot]["versions"][choices[slot]].get("landing_cost_factor", {}).get("value", 1.0))
	return scaled_cost({"kind": cost["kind"], "amount": float(cost["amount"]) * factor})


# Adds up the six resources:
# the spacecraft body + every part version the player picked.
func get_totals() -> Dictionary:
	var totals: Dictionary = {}

	# Start every resource at 0.
	for res_id in Data.resources:
		totals[res_id] = 0.0

	# Add the spacecraft body, and its heater (the heater is separate
	# because the player can switch it off on the power panel).
	add_effects(totals, Data.game_data["spacecraft_base"]["effects"])
	add_effects(totals, get_heater_effects())

	# Add the rocket's cost. (If no rocket is picked yet, use the default.)
	totals["budget"] += Data.game_data["launch_vehicles"]["vehicles"][get_launch_vehicle_id()]["cost"]

	# Add each chosen part version.
	for part_id in choices:
		var version_id: String = choices[part_id]
		if is_part_allowed(part_id, version_id):   # a part from another destination counts for nothing
			add_effects(totals, get_version_effects(part_id, version_id))

	return totals


# The picked rocket, or the default rocket if none is picked yet.
func get_launch_vehicle_id() -> String:
	if launch_vehicle_id != "":
		return launch_vehicle_id
	return Data.game_data["launch_vehicles"]["default"]


# Adds one list of effects into the totals.
func add_effects(totals: Dictionary, effects: Dictionary) -> void:
	for res_id in effects:
		totals[res_id] += effects[res_id]


# The limits for this mission. They are the same for every character.
# Gives back, for example: { "budget": { "rule": "max", "value": 450 }, ... }
func get_limits() -> Dictionary:
	var limits: Dictionary = {}
	var mission_limits: Dictionary = Data.missions[mission_id]["limits"]

	for res_id in mission_limits:
		limits[res_id] = {
			"rule": mission_limits[res_id]["rule"],
			"value": mission_limits[res_id]["value"],
			"warning": mission_limits[res_id]["warning"],
			"bar_max": mission_limits[res_id]["bar_max"],
		}
	# This destination can move the budget and mass limits (destinations.json "limit_changes").
	var changes: Dictionary = get_destination().get("limit_changes", {}).get("value", {})
	for res_id in changes:
		for key in ["value", "warning", "bar_max"]:
			limits[res_id][key] += changes[res_id]
	return limits


# The worst color among all rows: "danger" beats "warning" beats "safe".
# Used by the wrist light: one light that sums up the whole dashboard.
func get_worst_status(values: Dictionary, limits: Dictionary) -> String:
	var worst := "safe"
	for res_id in values:
		var status: String = get_status(values[res_id], limits[res_id])
		if status == "danger":
			return "danger"   # can't get worse than this, stop looking
		if status == "warning":
			worst = "warning"
	return worst


# Safe, close to the limit, or past it? Used by the dashboard.
#   "danger"  = past the limit (over a max, or under a min)  -> red
#   "warning" = still OK, but past the warning line          -> yellow
#   "safe"    = everything fine                               -> green
func get_status(total: float, limit: Dictionary) -> String:
	if not is_ok(total, limit):
		return "danger"
	if is_equal_approx(total, limit["warning"]):
		return "safe"   # exactly on the warning line counts as safe
	if limit["rule"] == "max" and total > limit["warning"]:
		return "warning"
	if limit["rule"] == "min" and total < limit["warning"]:
		return "warning"
	return "safe"


# Is this one resource inside its limit?
#   rule "max": the total must be AT or BELOW the limit.
#   rule "min": the total must be AT or ABOVE the limit.
func is_ok(total: float, limit: Dictionary) -> bool:
	# is_equal_approx = "equal, ignoring tiny rounding errors".
	# Without it, two numbers that should be equal (like 900.0000001 and 900)
	# can flicker between OK and not OK.
	if is_equal_approx(total, limit["value"]):
		return true
	if limit["rule"] == "max":
		return total <= limit["value"]
	return total >= limit["value"]


# A list of every resource that breaks its limit, for example ["mission_lifetime"].
# An empty list means the build is good.
func get_failed_resources() -> Array:
	var totals: Dictionary = get_totals()
	var limits: Dictionary = get_limits()
	var failed: Array = []
	for res_id in limits:
		if not is_ok(totals[res_id], limits[res_id]):
			failed.append(res_id)
	return failed


# Fills in the {value}, {limit} and {unit} blanks in an inner-voice line.
func fill_blanks(line: String, res_id: String) -> String:
	# "data_live": use the numbers from the END of the mission.
	if res_id.ends_with("_live"):
		var live_id: String = res_id.trim_suffix("_live")
		return line.format({
			"value": fmt(end_values[live_id]),
			"limit": fmt(end_limits[live_id]["value"]),
			"unit": Data.resources[live_id].get("live_unit", Data.resources[live_id]["unit"]),
		})
	if not Data.resources.has(res_id):
		return line   # for example "power_event", which has no blanks
	return line.format({
		"value": fmt(get_totals()[res_id]),
		"limit": fmt(get_limits()[res_id]["value"]),
		"unit": Data.resources[res_id]["unit"],
	})


# A hint for one problem, as long as this level allows.
# levels.json "hint_parts" says which pieces the level hears, in order: "warning", "problem", "part".
# "warning_line" is the warning piece (the caller picked it). The other pieces are
# in inner_voice.json "dashboard_warnings" > the resource or supply id. A piece can be one
# sentence for everybody, or a dictionary with one sentence per level (easy, medium, hard).
# There are no sentences in this code: only the names of the pieces.
func get_hint_text(res_id: String, warning_line: String) -> String:
	var parts: Array = ["warning"]   # the warning is always said
	if Data.levels.has(level):
		parts = Data.levels[level]["hint_parts"]
	var entry: Dictionary = Data.voice["dashboard_warnings"].get(res_id, {})
	var lines: PackedStringArray = []
	for piece in parts:
		if piece == "warning":
			lines.append(warning_line)
			continue
		var text = entry.get(piece, "")
		if text is Dictionary:
			text = text.get(level, "")   # one wording per level; a level with no wording says nothing for this piece
		if text != "":
			lines.append(text)
	return " ".join(lines)


# Lists what a part version changes, for example:
#   "Budget +40 million $, Power -50 W spare, Data +30 Gb/day"
# Used by the build screen (hover text) and the 3D walk (press E).
func effects_text(effects: Dictionary, separator: String) -> String:
	var lines: PackedStringArray = []
	for res_id in effects:
		var amount: float = effects[res_id]
		if amount != 0:
			var sign := "+" if amount > 0 else ""
			lines.append("%s %s%s %s" % [Data.resources[res_id]["name"], sign, fmt(amount), Data.resources[res_id]["unit"]])
	return separator.join(lines)


# Shows a number nicely: 450.0 becomes "450", 2.5 stays "2.5",
# 23.98 becomes "24", and big numbers like 2417.1 become "2417".
func fmt(value: float) -> String:
	if absf(value) >= 100:
		return str(int(round(value)))
	var text: String = "%.1f" % value
	if text.ends_with(".0"):
		text = text.trim_suffix(".0")
	if text == "-0":
		text = "0"
	return text


# --- The surface work (Stage 4, surface destinations) ------------------------
# A walkable area, a surface clock, and one task: collect the sample.
# All numbers: data/events.json "surface_work". The state is in the dictionary `surface`.

# Spare power (W) when the surface stay starts: the build's spare power, with the
# solar panel's landing damage taken off (a damaged panel makes less power).
func get_surface_start_power() -> float:
	var power: float = get_totals()["power"]
	var damaged_percent: float = damage.get("solar_panel", 0.0)
	if damaged_percent > 0.0 and choices.has("solar_panel") and is_part_allowed("solar_panel", choices["solar_panel"]):
		var solar: float = get_version_effects("solar_panel", choices["solar_panel"])["power"]
		power -= solar * minf(damaged_percent, 100.0) / 100.0
	return power


# How many surface days the parts give. The smallest of max_days and (spare power, minus the three tasks, divided by
# the power one day costs). With with_supplies = true the days the crew supplies from Flight last count too.
# It can be 0 or less: nothing forces a day the power cannot pay for.
func calc_surface_days(start_power: float, with_supplies: bool) -> int:
	var work: Dictionary = Data.events["surface_work"]
	var days: int = int(work["max_days"]["value"])
	# Power: leave room for one sample try, the instrument run and sending the data home, so doing the three tasks on the last day still works.
	var power_for_days: float = start_power - get_sample_power_cost() - float(work["instrument_power_cost_w"]["value"]) - float(work["send_power_cost_w"]["value"])
	days = mini(days, int(floor(power_for_days / get_surface_day_power_cost())))
	if with_supplies and has_crew():
		for id in SUPPLY_IDS:
			# Supplies: count the days only down to the red line (supplies.json status danger_percent), not to zero.
			var red_line: float = get_supply_capacity(id) * float(Data.supplies["status"]["danger_percent"]["value"]) / 100.0
			var per_day: float = get_supply_use_per_day(id) * float(work["supply_days_per_day"]["value"])
			days = mini(days, int(floor((crew_supplies[id] - red_line) / per_day)))
	return days


# The days this build gives, worked out from power alone (the Review screen uses it, before Flight).
func get_surface_days_estimate() -> int:
	return calc_surface_days(get_surface_start_power(), false)


# Call when the surface stage starts. The parts decide how many days there are.
func start_surface() -> void:
	var work: Dictionary = Data.events["surface_work"]
	var start_power: float = get_surface_start_power()
	if has_crew():
		ensure_supplies()
	var days: int = calc_surface_days(start_power, true)
	surface = {
		"days_total": maxi(0, days),
		"days_used": 0.0,
		"sample": false,
		"attempts": 0,
		"start_power": start_power,
		"extra_power_used": 0.0,
		"instrument": false,   # the instrument was run
		"stored": 0.0,         # Gb stored and waiting
		"captured": 0.0,       # Gb the instrument stored
		"sent": 0.0,           # Gb sent home
		"send_done": false,    # the send press was done
		"planned": float(work["planned_gb"]["value"]),
	}


# The surface clock moves: delta real seconds. The crew uses supplies too.
func advance_surface(delta: float) -> void:
	var work: Dictionary = Data.events["surface_work"]
	var days_passed: float = delta / float(work["seconds_per_day"]["value"])
	add_surface_days(days_passed)


# Adds surface days (the clock, or the days a missed try loses) and uses the supplies for them.
func add_surface_days(days_passed: float) -> void:
	surface["days_used"] += days_passed
	if has_crew():
		advance_supplies(days_passed * float(Data.events["surface_work"]["supply_days_per_day"]["value"]))


# Watts of spare power one surface day uses: the normal cost times this site's power_cost_factor (a cold site uses more).
func get_surface_day_power_cost() -> float:
	return float(Data.events["surface_work"]["power_cost_per_day_w"]["value"]) * float(get_site_value("power_cost_factor", 1.0))


# Watts one sample try uses: the normal cost times the picked surface tool's sample_power_factor (a drill is easier on power).
func get_sample_power_cost() -> float:
	return float(Data.events["surface_work"]["attempt_power_cost_w"]["value"]) * float(get_part_fact("surface_tools", "sample_power_factor", 1.0))


# Spare power now: it falls every day and with every sample try.
func get_surface_power() -> float:
	return surface["start_power"] - surface["days_used"] * get_surface_day_power_cost() - surface["extra_power_used"]


# Whole days left (never below 0).
func get_surface_days_left() -> int:
	return maxi(0, int(ceil(surface["days_total"] - surface["days_used"])))


func is_surface_time_up() -> bool:
	return surface["days_used"] >= surface["days_total"]


# One try at the sample. Perfect or Good collects it. A Miss loses a day. Every try uses power.
func collect_sample(result: String) -> void:
	var work: Dictionary = Data.events["surface_work"]
	surface["attempts"] += 1
	surface["extra_power_used"] += get_sample_power_cost()
	if result == "Miss":
		add_surface_days(float(work["miss_days_lost"]["value"]))
	else:
		surface["sample"] = true
		give_material_bonus()


# Task 2: run the instrument. Any result runs it (a Miss stores less). It uses power.
# Stored = camera Gb per day x capture_days_worth x the result's factor x the surface tool's instrument_data_factor,
# never more than the ship can store. Returns the Gb stored.
func run_instrument(result: String) -> float:
	var work: Dictionary = Data.events["surface_work"]
	surface["instrument"] = true
	surface["extra_power_used"] += float(work["instrument_power_cost_w"]["value"])
	var camera_gb_per_day: float = system_effects("camera")["data"]
	var wanted: float = camera_gb_per_day * float(work["capture_days_worth"]["value"]) * float(work["result_factor"][result]["value"]) * float(get_part_fact("surface_tools", "instrument_data_factor", 1.0))
	surface["captured"] = minf(wanted, get_storage_gb(float(work["storage_gb"]["value"])))
	surface["stored"] = surface["captured"]
	return surface["captured"]


# Task 3: send the data home from the lander. Any result sends (a Miss sends less). It uses power.
# Sent = the least of what is stored and (the antenna's real speed x downlink_hours x the result's factor). Returns the Gb sent.
func send_surface_data(result: String) -> float:
	var work: Dictionary = Data.events["surface_work"]
	surface["send_done"] = true
	surface["extra_power_used"] += float(work["send_power_cost_w"]["value"])
	var megabits_per_second: float = system_effects("antenna")["communications"]
	var capacity: float = megabits_per_second * float(work["downlink_hours"]["value"]) * 3600.0 / 1000.0 * float(work["result_factor"][result]["value"])
	var sent: float = minf(surface["stored"], capacity)
	surface["stored"] -= sent
	surface["sent"] += sent
	return sent


# What the site's material gave the crew, as words, for example "1500 L water, 300 kg air". "" if nothing.
func get_surface_bonus_text() -> String:
	var bonus: Dictionary = surface.get("bonus", {})
	var parts: PackedStringArray = []
	for id in bonus:
		if bonus[id] > 0.0:
			parts.append("%s %s %s" % [fmt(bonus[id]), Data.story["crew_supplies"]["units"][id], Data.story["crew_supplies"]["names"][id].to_lower()])
	return ", ".join(parts)


# All three tasks are done: the stay can end early.
func is_surface_done() -> bool:
	return surface["sample"] and surface["instrument"] and surface["send_done"]


# The site's material gives the crew something (destinations.json material_bonus), for example ice
# gives water and oxygen. Nothing happens at a site with no bonus. The amounts are kept for the report.
func give_material_bonus() -> void:
	var bonus: Dictionary = get_site_value("material_bonus", {})
	surface["bonus"] = {}
	if not has_crew():
		return
	for id in bonus:
		var before: float = crew_supplies[id]
		add_supply(id, float(bonus[id]))
		surface["bonus"][id] = crew_supplies[id] - before   # never more than the meter can hold


# The meters on the surface HUD: the power row's limits are the build's power limits.
func get_surface_power_status() -> String:
	return get_status(get_surface_power(), get_limits()["power"])


# At the end of the surface stay: what went wrong is written down as failures.
# A power failure is skipped if the build already had a red power row (it has its own card).
func add_end_of_surface_failures() -> void:
	if surface.is_empty():
		return
	if not surface["sample"] and not event_failures.has("surface_sample_missed"):
		event_failures.append("surface_sample_missed")
	# The instrument: not run is one finding. Run but too little data sent home is another (never both).
	if not surface["instrument"]:
		if not event_failures.has("surface_instrument_skipped"):
			event_failures.append("surface_instrument_skipped")
	elif not surface["send_done"]:
		if not event_failures.has("surface_data_not_sent"):
			event_failures.append("surface_data_not_sent")   # the instrument ran, but the data never went home
	elif surface["sent"] < surface["planned"] and not event_failures.has("surface_data_short"):
		event_failures.append("surface_data_short")
	if get_surface_power() < 0.0 and not get_failed_resources().has("power") and not event_failures.has("surface_power"):
		event_failures.append("surface_power")
	add_end_of_supply_failures()   # red crew supplies count too


# --- The Europa flyby (Stage 4, flyby destinations) --------------------------
# Four timed presses, then the pass. Numbers: data/events.json "flyby_pass".

# Call when the flyby starts.
func start_flyby() -> void:
	flyby = {
		"point": 0.0,      # how well the instrument was pointed (a factor)
		"captured": 0.0,   # Gb captured
		"stored": 0.0,     # Gb stored now
		"lost": 0.0,       # Gb destroyed by radiation
		"sent": 0.0,       # Gb sent home
		"planned": float(Data.events["flyby_pass"]["planned_gb"]["value"]),
		"capacity": 0.0,   # Gb the antenna could send
	}


# The result of one command press. moment_id: point_instrument, capture, protect_computer, send_data.
func apply_flyby_press(moment_id: String, result: String) -> void:
	var numbers: Dictionary = Data.events["flyby_pass"]
	var factor: float = float(numbers["result_factor"][result]["value"])
	match moment_id:
		"point_instrument":
			flyby["point"] = factor
		"capture":
			var camera_gb_per_day: float = system_effects("camera")["data"]
			var wanted: float = camera_gb_per_day * float(numbers["capture_days_worth"]["value"]) * flyby["point"] * factor
			flyby["captured"] = minf(wanted, get_storage_gb(float(numbers["storage_gb"]["value"])))
			flyby["stored"] = flyby["captured"]
		"protect_computer":
			var loss_percent: float = float(numbers["radiation_loss_percent"]["value"]) * (1.0 - get_radiation_protection() / 100.0) * float(numbers["radiation_result_loss"][result]["value"])
			var lost: float = flyby["stored"] * loss_percent / 100.0
			flyby["lost"] += lost
			flyby["stored"] -= lost
		"send_data":
			var megabits_per_second: float = system_effects("antenna")["communications"]
			flyby["capacity"] = megabits_per_second * float(numbers["downlink_hours"]["value"]) * 3600.0 / 1000.0 * factor
			flyby["sent"] = minf(flyby["stored"], flyby["capacity"])
			flyby["stored"] -= flyby["sent"]


# Percent of the radiation loss the picked radiation shield stops (0 if the slot is not here).
func get_radiation_protection() -> float:
	if not choices.has("radiation_shield") or not is_part_allowed("radiation_shield", choices["radiation_shield"]):
		return 0.0
	return float(Data.parts["radiation_shield"]["versions"][choices["radiation_shield"]]["radiation_protection"]["value"])


# At the end of the flyby: less data home than planned is a failure.
func add_end_of_flyby_failures() -> void:
	if flyby.is_empty():
		return
	if flyby["sent"] < flyby["planned"] and not event_failures.has("flyby_data_short"):
		event_failures.append("flyby_data_short")
