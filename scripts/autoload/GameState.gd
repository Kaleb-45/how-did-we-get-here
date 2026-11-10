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


# --- More things the game will remember later (not used by any screen yet) ---
# They start empty or at zero. Later steps will fill them in.
var player_name: String = ""          # what the player typed as their name
var destination_id: String = ""       # where the mission goes
var goal_id: String = ""              # what the mission wants to find out
var launch_vehicle_id: String = ""    # which rocket the player picked
var crew_supplies: Dictionary = { "food": 0.0, "water": 0.0, "air": 0.0 }
var damage: Dictionary = {}           # damage the ship took, by part
var timing_results: Array = []        # "Perfect", "Good" or "Miss" from timed presses
var findings: Array = []              # science the mission found


func _ready() -> void:
	# Show the whole state once, so we can see it in the Output panel.
	print("GameState at startup: ", JSON.stringify(to_dict(), "  "))


# Turns the WHOLE state into one dictionary. Later, a checkpoint will save it.
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
		"event_failures": event_failures.duplicate(true),
		"mission_months": mission_months,
		"data_collected": data_collected,
		"parts_off": parts_off.duplicate(true),
		"lifetime_lost": lifetime_lost,
		"storm_active": storm_active,
		"end_values": end_values.duplicate(true),
		"end_limits": end_limits.duplicate(true),
	}


# Puts a saved dictionary back into the game. A missing key keeps its
# current value, so an older save still loads.
func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", player_name)
	character_id = d.get("character_id", character_id)
	mission_id = d.get("mission_id", mission_id)
	destination_id = d.get("destination_id", destination_id)
	goal_id = d.get("goal_id", goal_id)
	launch_vehicle_id = d.get("launch_vehicle_id", launch_vehicle_id)
	choices = d.get("choices", choices).duplicate(true)
	crew_supplies = d.get("crew_supplies", crew_supplies).duplicate(true)
	damage = d.get("damage", damage).duplicate(true)
	timing_results = d.get("timing_results", timing_results).duplicate(true)
	findings = d.get("findings", findings).duplicate(true)
	event_failures = d.get("event_failures", event_failures).duplicate(true)
	mission_months = d.get("mission_months", mission_months)
	data_collected = d.get("data_collected", data_collected)
	parts_off = d.get("parts_off", parts_off).duplicate(true)
	lifetime_lost = d.get("lifetime_lost", lifetime_lost)
	storm_active = d.get("storm_active", storm_active)
	end_values = d.get("end_values", end_values).duplicate(true)
	end_limits = d.get("end_limits", end_limits).duplicate(true)


# Everything that went wrong: build problems first, then mission events.
func get_all_failures() -> Array:
	return get_failed_resources() + event_failures


# Clears what happened during the last mission, but keeps the part choices,
# so "Try again" lets the player change just one thing.
func start_new_attempt() -> void:
	event_failures.clear()


# --- The live mission (3D walk) ------------------------------------------

var mission_months: float = 0.0     # mission time so far, in months
var data_collected: float = 0.0     # science data collected so far
var parts_off: Array = []           # systems turned off, for example ["camera", "heater"]
var lifetime_lost: float = 0.0      # extra months lost while the heater was off
var storm_active: bool = false      # true during the shadow pass (no sunlight on the solar panels)

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
		lifetime_lost += delta * Data.game_data["reroute_power"]["heater"]["off_lifetime_months_per_second"]


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
		var solar_power: float = Data.parts[solar_id]["versions"][choices[solar_id]]["effects"]["power"]
		values["power"] -= solar_power * storm["solar_drop_percent"] / 100.0
		values["power"] += storm["battery_power"]
	return values


# --- The power panel's systems (Reroute Power) -------------------------------
# A "system" is something with a switch: camera, antenna (parts) or heater.

# What a system gives and uses: the picked version of a part, or the heater.
func system_effects(system_id: String) -> Dictionary:
	if system_id == "heater":
		return Data.game_data["reroute_power"]["heater"]["effects"]
	return Data.parts[system_id]["versions"][choices[system_id]]["effects"]


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
	var solar: float = Data.parts[solar_id]["versions"][choices[solar_id]]["effects"]["power"]
	if storm_active:
		solar -= solar * storm["solar_drop_percent"] / 100.0
		solar += storm["battery_power"]
	return solar


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
# (When the player comes back with "Try again", their old choices stay.)
func fill_default_choices() -> void:
	for part_id in Data.parts:
		if not choices.has(part_id):
			var versions: Dictionary = Data.parts[part_id]["versions"]
			choices[part_id] = versions.keys()[0]


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
	add_effects(totals, Data.game_data["reroute_power"]["heater"]["effects"])

	# Add each chosen part version.
	for part_id in choices:
		var version_id: String = choices[part_id]
		add_effects(totals, Data.parts[part_id]["versions"][version_id]["effects"])

	return totals


# Adds one list of effects into the totals.
func add_effects(totals: Dictionary, effects: Dictionary) -> void:
	for res_id in effects:
		totals[res_id] += effects[res_id]


# The limits for this mission, after the level's multipliers (data/levels.json).
# Gives back, for example: { "budget": { "rule": "max", "value": 450 }, ... }
func get_limits() -> Dictionary:
	var limits: Dictionary = {}
	var mission_limits: Dictionary = Data.missions[mission_id]["limits"]
	var multipliers: Dictionary = Data.levels[level]["limit_multipliers"]

	for res_id in mission_limits:
		var multiplier: float = multipliers.get(res_id, 1.0)
		limits[res_id] = {
			"rule": mission_limits[res_id]["rule"],
			"value": mission_limits[res_id]["value"] * multiplier,
			"warning": mission_limits[res_id]["warning"] * multiplier,
			"bar_max": mission_limits[res_id]["bar_max"],
		}
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
