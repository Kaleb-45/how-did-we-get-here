# walk.gd
# The 3D walk-around scene.
#  - Builds the spacecraft from the player's choices (Step 8).
#  - Shows "Press E" when the player is near a part, and the inner voice
#    explains that part when E is pressed (Step 9).
#  - The shadow pass (Mars blocks the Sun) and its "Power low" alarm: the player must reroute power
#    at the power panel in time (the Reroute Power mini-game).
#  - The mission ends when the mission clock reaches the mission length.
#
# This one scene is used for TWO stages:
#   "walk"   = Arrival: the mission clock, the shadow pass and Reroute Power.
#   "flight" = Stage 3, one flight leg (scenes/flight.tscn is this scene again).
#              No shadow pass and no mission clock. The Life Support stations
#              and the water leak run, and the leg ends after its length.
# StageManager tells us which one we are (the scene's file name), see _ready().
extends Node3D

@onready var inner_voice: PanelContainer = %InnerVoiceBar
@onready var controls_hint: Label = %ControlsHint
@onready var prompt_label: Label = %PromptLabel
@onready var alarm_banner: Label = %AlarmBanner
@onready var science_banner: Label = %ScienceBanner   # the calm banner of the science pass
@onready var red_flash: ColorRect = %RedFlash
@onready var ship: Node3D = $Ship                 # the ship interior (built from data)
@onready var spacecraft: Node3D = $Spacecraft
@onready var power_panel: Node3D = $PowerPanel   # the panel in the Power room
@onready var reroute_panel: PanelContainer = %ReroutePanel   # its 2D switch screen
@onready var player: CharacterBody3D = $Player
@onready var arm: Node3D = $Player/Head/Camera/Arm   # the wrist light lives here
@onready var dashboard: PanelContainer = %Dashboard
@onready var wrist_panel: Control = %WristPanel   # holds the dashboard, above the wrist
@onready var camera: Camera3D = $Player/Head/Camera
@onready var hud: CanvasLayer = $HUD

# The Life Support stations (food, water, air): see life_support.gd.
var life_support: Node = preload("res://scripts/life_support.gd").new()

# The science pass (capture, then downlink): Arrival only, see science_pass.gd.
var science: Node = null

var arm_is_up: bool = false
var has_crew: bool = true       # false for a trip with no crew (Europa): no crew supplies
var flight_mode: bool = false   # true in Stage 3 Flight, false in the Arrival walk

# The shadow pass and its alarm go through these stages:
#   "waiting"  - counting down until the shadow pass starts
#   "ringing"  - power doesn't fit: the player has time_to_fix_seconds
#   "fixed"    - power fits (fixed in time, or there was enough anyway).
#                If it stops fitting while the shadow pass is on, it rings again.
#   "failed"   - time ran out: the batteries are empty
var alarm_stage: String = "waiting"
var seconds_left: float = 0.0   # counts down in "waiting" and in "ringing"
var storm_left: float = 0.0     # seconds until the shadow pass is over
var flashing: Tween
var mission_over: bool = false   # true once the walk is finishing
var more_legs: bool = false      # Flight: true when another leg follows this one

# The reach zones the player is standing in right now.
var zones_player_is_in: Array[Area3D] = []

# The part the player would use if they pressed E now ("" = none).
var nearby_part: String = ""


func _ready() -> void:
	flight_mode = StageManager.get_current() == "flight"
	has_crew = GameState.has_crew()
	# Safety net for running this scene by itself (F6).
	# (The Reroute Power panel starts before this, so it fills the parts itself.)
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	ship.build(has_crew or not flight_mode)   # a Flight with no crew has no Life Support markers
	if flight_mode:
		# The Science and Comms stations only work in Mars orbit: say so on their labels.
		for kind in ship.science_labels:
			ship.science_labels[kind].text = Data.story["ship"]["flight_stations"][kind]
	spacecraft.build()   # (parked outside the ship for now: the parts move to the windows later)
	power_panel.build()
	put_player_at_start()

	# Listen to every reach zone: "a body came in" / "a body went out".
	# The power panel's zone works the same way as the spacecraft's.
	life_support.setup(self, hud, inner_voice)
	add_child(life_support)
	var zones: Array = spacecraft.reach_zones.duplicate()
	if flight_mode:
		if has_crew:
			zones += ship.station_zones.values()   # the Life Support stations only work in Flight, and only with a crew
	else:
		zones.append(power_panel.reach_zone)   # the power panel only works in Arrival (switching off costs nothing in Flight)
		# The science pass stations (Science bay and Comms room) only work in Arrival too.
		science = preload("res://scripts/science_pass.gd").new()
		science.setup(self, hud, inner_voice, science_banner, ship)
		add_child(science)
		zones += ship.science_zones.values()
	for zone in zones:
		zone.body_entered.connect(_on_zone_entered.bind(zone))
		zone.body_exited.connect(_on_zone_exited.bind(zone))

	controls_hint.text = Data.story["walk_screen"]["controls_hint"]
	reroute_panel.switch_changed.connect(_on_switch_changed)
	prompt_label.text = ""

	# The crew supplies. Flight stocks the ship; Arrival goes on with what is left.
	# No crew (Europa) means no crew supplies at all.
	if has_crew:
		if flight_mode:
			if GameState.flight_leg == 0:
				GameState.start_supplies()   # the first leg stocks the ship; the next legs go on with what is left
			GameState.begin_leg()
		else:
			GameState.ensure_supplies()
	elif flight_mode:
		GameState.begin_leg()   # no crew: no supplies, but the trip still has its days

	# The mission clock starts at zero. The dashboard is hidden until Tab.
	GameState.start_mission()
	remember_build_colors()
	dashboard.set_compact(false)   # the full dashboard, with the "Tab =" hint
	update_dashboard(false)
	if flight_mode:
		var start_key: String = "start" if has_crew else "start_no_crew"
		if has_crew and GameState.flight_leg > 0:
			start_key = "start_next"   # leg 2, leg 3
		say(Data.voice["flight"][start_key].format({
			"days": GameState.fmt(GameState.get_flight_leg_days()),
			"leg": GameState.flight_leg + 1,
			"legs": GameState.get_flight_legs(),
		}))
	else:
		say(Data.voice["walk"]["start"])

	# Start the countdown to the alarm (the number comes from game_data.json).
	alarm_banner.visible = false
	red_flash.visible = false
	seconds_left = Data.game_data["events"]["power_low"]["start_after_seconds"]


# The player starts on the Bridge (the spot comes from game_data.json "ship").
func put_player_at_start() -> void:
	var start: Array = Data.game_data["ship"]["player_start"]
	player.global_position = Vector3(start[0], start[1], start[2])
	player.rotation_degrees.y = Data.game_data["ship"]["player_facing_degrees"]


func _on_zone_entered(body: Node3D, zone: Area3D) -> void:
	if body.is_in_group("player"):
		zones_player_is_in.append(zone)


func _on_zone_exited(body: Node3D, zone: Area3D) -> void:
	if body.is_in_group("player"):
		zones_player_is_in.erase(zone)


# Runs every frame. delta = seconds since the last frame (about 1/60).
func _process(delta: float) -> void:
	if not mission_over:
		if not flight_mode:
			GameState.advance_mission(delta)   # mission time moves forward (it stops at the end)
		if has_crew:
			GameState.advance_supplies(crew_days_passed(delta))   # the crew eats, drinks and breathes
			for id in GameState.check_empty_supplies():   # a supply hit zero: a finding was added
				say(Data.voice["flight"]["empty_" + id])
	update_dashboard()
	update_wrist_panel()
	if flight_mode:
		update_flight_end()   # no shadow pass in Flight: the leg ends after its length
		if has_crew:
			life_support.update(delta)   # the water leak
		else:
			life_support.elapsed += delta   # the leg clock still runs (no leak without a crew)
	else:
		update_alarm(delta)
		science.update(delta)   # opens and closes the capture and downlink windows
		update_mission_end()
	update_prompt()
	update_voice(delta)


# How many game days the crew supplies lose this frame.
#   Flight:  one leg stands for leg_days real days, played in leg_seconds.
#   Arrival: the mission clock's real days (24 months = about 730 days).
func crew_days_passed(delta: float) -> float:
	if flight_mode:
		return delta * GameState.get_flight_leg_days() / GameState.get_flight_leg_seconds()
	var clock: Dictionary = Data.game_data["mission_clock"]
	return delta * clock["months_per_second"] * clock["days_per_month"]


# GameState works out the live numbers; the dashboard draws them.
# check_warnings = false for the very first draw: at mission time 0
# nothing has been collected yet, so the colors aren't meaningful.
func update_dashboard(check_warnings: bool = true) -> void:
	var values: Dictionary = GameState.get_live_values()
	var limits: Dictionary = GameState.get_live_limits()
	dashboard.show_values(values, limits, true)
	if has_crew:
		dashboard.show_supplies(GameState.crew_supplies, GameState.get_supply_statuses())   # Crew supplies group
	if check_warnings:
		check_for_warnings(values, limits)
		# The wrist light shows the worst row: green, yellow or red.
		var worst_supply: String = GameState.get_worst_supply_status() if has_crew else "safe"
		arm.show_status(worse_of(GameState.get_worst_status(values, limits), worst_supply))
	else:
		# First frame: use the build's colors (what the player saw on Review).
		arm.show_status(GameState.get_worst_status(GameState.get_totals(), GameState.get_limits()))


# The worse of two colors: "danger" beats "warning" beats "safe".
func worse_of(a: String, b: String) -> String:
	if a == "danger" or b == "danger":
		return "danger"
	if a == "warning" or b == "warning":
		return "warning"
	return "safe"


# Each row's color last frame, for example { "power": "safe", ... }
var last_status: Dictionary = {}


# Start from the colors the player already saw on the Build and Review
# screens, so nothing is announced just because the walk started.
func remember_build_colors() -> void:
	var totals: Dictionary = GameState.get_totals()
	var limits: Dictionary = GameState.get_limits()
	for res_id in totals:
		last_status[res_id] = GameState.get_status(totals[res_id], limits[res_id])
	if has_crew:
		for id in GameState.SUPPLY_IDS:
			last_status[id] = GameState.get_supply_status(id)


# When a row CHANGES to yellow or red, the inner voice warns us.
# (Only on a change, so it doesn't repeat the same warning every frame.)
func check_for_warnings(values: Dictionary, limits: Dictionary) -> void:
	for res_id in values:
		var status: String = GameState.get_status(values[res_id], limits[res_id])
		var before: String = last_status.get(res_id, "")
		last_status[res_id] = status

		if status == before or status == "safe":
			continue   # no change, or it got better: say nothing
		if res_id == "power" and alarm_stage != "waiting":
			continue   # the shadow pass has started: the alarm lines already talk about power
		say_warning(GameState.get_hint_text(res_id, Data.voice["dashboard_warnings"][res_id][status]))

	# The crew supplies warn the same way: only when a color changes.
	for id in GameState.SUPPLY_IDS if has_crew else []:
		var supply_status: String = GameState.get_supply_status(id)
		var supply_before: String = last_status.get(id, "")
		last_status[id] = supply_status
		if supply_status != supply_before and supply_status != "safe":
			say_warning(GameState.get_hint_text(id, Data.voice["dashboard_warnings"][id][supply_status]))


# --- Talking ----------------------------------------------------------------
# Every inner-voice line goes through say(). After a line, warnings wait
# voice_hold_seconds, so they don't talk over something important.
var hold_left: float = 0.0          # seconds until warnings may talk
var waiting_warning: String = ""    # the newest warning that is waiting


func say(line: String) -> void:
	inner_voice.say(line)
	hold_left = Data.game_data["walk"]["voice_hold_seconds"]


func say_warning(line: String) -> void:
	if hold_left > 0:
		waiting_warning = line   # say it later (only the newest one)
	else:
		say(line)


# Runs every frame from _process: counts down the hold, then says
# the waiting warning, if there is one.
func update_voice(delta: float) -> void:
	if hold_left > 0:
		hold_left -= delta
	elif waiting_warning != "":
		say(waiting_warning)
		waiting_warning = ""


# The alarm's clock. Only "waiting" and "ringing" count down.
func update_alarm(delta: float) -> void:
	# The shadow pass's own clock: when it runs out, the sun comes back.
	if GameState.storm_active and alarm_stage != "failed":
		storm_left -= delta
		if storm_left <= 0:
			end_storm()
			return

	if alarm_stage == "waiting":
		seconds_left -= delta
		if seconds_left <= 0:
			start_storm()

	elif alarm_stage == "ringing":
		seconds_left -= delta
		# For example:  POWER LOW! Go to the power panel: 17
		var numbers := {"seconds": ceili(seconds_left)}
		alarm_banner.text = Data.voice["walk"]["alarm_banner"].format(numbers)
		# The panel covers the banner, so the panel shows its own countdown.
		alarm_banner.visible = not reroute_panel.visible
		reroute_panel.show_countdown(Data.voice["reroute"]["countdown"].format(numbers))

		if GameState.is_power_ok():
			alarm_fixed()        # power fits: success!
		elif seconds_left <= 0:
			alarm_failed()       # out of time

	elif alarm_stage == "fixed":
		# The shadow pass is still on. If a switch goes back on and power stops
		# fitting, the alarm rings again, with a fresh countdown.
		if GameState.storm_active and not GameState.is_power_ok():
			ring_alarm(Data.voice["walk"]["alarm_again"])


func start_storm() -> void:
	# Mars blocks the Sun: solar power drops, the batteries take over (see GameState).
	GameState.storm_active = true
	storm_left = Data.game_data["events"]["power_low"]["storm_seconds"]

	# Enough spare power to ride out the shadow pass? Then no alarm at all.
	if GameState.is_power_ok():
		alarm_stage = "fixed"
		say(Data.voice["walk"]["storm_ok"])
	else:
		ring_alarm(Data.voice["walk"]["alarm"])


func ring_alarm(line: String) -> void:
	alarm_stage = "ringing"
	seconds_left = GameState.get_alarm_seconds()   # the picked battery gives more or less time
	alarm_banner.visible = true
	say(line)
	dashboard.set_flashing("power", true)

	# Make the screen pulse red, over and over, until the alarm stops.
	red_flash.visible = true
	if flashing:
		flashing.kill()
	flashing = create_tween().set_loops()
	flashing.tween_property(red_flash, "color:a", 0.25, 0.4)
	flashing.tween_property(red_flash, "color:a", 0.0, 0.4)


func stop_alarm_effects() -> void:
	alarm_banner.visible = false
	red_flash.visible = false
	reroute_panel.show_countdown("")
	dashboard.set_flashing("power", false)
	if flashing:
		flashing.kill()


# Power fits again. The mission goes on (the shadow pass is still on).
func alarm_fixed() -> void:
	alarm_stage = "fixed"
	stop_alarm_effects()
	say(Data.voice["walk"]["alarm_fixed"])


# The shadow pass is over: full solar power again. Now the player can switch
# systems back on at the power panel (and should: everything that is off
# is still costing data, communications or mission lifetime).
func end_storm() -> void:
	GameState.storm_active = false
	if alarm_stage == "ringing":
		stop_alarm_effects()   # only if it rang again near the end of the shadow pass
	alarm_stage = "fixed"
	if GameState.parts_off.is_empty():
		say(Data.voice["walk"]["storm_over_all_on"])
	else:
		say(Data.voice["walk"]["storm_over"])


func alarm_failed() -> void:
	alarm_stage = "failed"
	stop_alarm_effects()
	say(Data.voice["walk"]["alarm_failed"])

	# Write it down, so the debrief can explain what went wrong.
	GameState.event_failures.append("power_event")
	finish_mission(Data.game_data["walk"]["failed_read_seconds"])


# The mission is over when the mission clock reaches the mission length
# (the "need at least" lifetime, for example 24 months). It waits while
# the alarm is ringing: the player gets their full countdown.
func update_mission_end() -> void:
	if mission_over or alarm_stage == "ringing" or alarm_stage == "failed":
		return
	if GameState.is_mission_time_up():
		say(Data.voice["walk"]["mission_complete"])
		finish_mission(Data.game_data["walk"]["end_read_seconds"])


# Flight: the leg is over once it has lasted leg_seconds. The voice says so,
# then StageManager.go_next() goes to the Arrival walk.
func update_flight_end() -> void:
	if mission_over:
		return
	if life_support.elapsed >= GameState.get_flight_leg_seconds():
		life_support.stop_tasks()   # close a station screen or a ring that is still open
		var leg: int = GameState.flight_leg + 1
		var result: Dictionary = GameState.end_leg()   # skipped tasks cost supplies; the next leg is counted
		more_legs = result["more"]
		var arrival: String = GameState.get_arrival_type()
		var line: String
		if more_legs:
			line = Data.voice["flight"]["leg_end_next"].format({"leg": leg, "legs": GameState.get_flight_legs()})
		else:
			line = Data.voice["flight"]["leg_end" if arrival == "orbit" else "leg_end_" + arrival]   # Mars orbit, a landing, or Europa
		if not result["skipped"].is_empty():
			var names: Dictionary = Data.story["crew_supplies"]["names"]
			var list: PackedStringArray = []
			for id in result["lost"]:
				list.append("%s %s" % [GameState.fmt(result["lost"][id]), names[id].to_lower()])
			line += " " + Data.voice["flight"]["skipped"].format({"list": ", ".join(list)})
		say(line)
		finish_mission(Data.game_data["walk"]["end_read_seconds"])


# Wait `seconds` so the player can read the last line, then the debrief.
func finish_mission(seconds: float) -> void:
	mission_over = true
	if science:
		science.stop_tasks()   # a ring that is still closing stops
	await get_tree().create_timer(seconds).timeout
	if is_inside_tree():   # unless the player already left this screen
		end_walk()


func end_walk() -> void:
	# Last look at the dashboard: anything still red counts as a failure.
	# (Flight is only the trip, so only Arrival does this.)
	if not flight_mode:
		GameState.add_end_of_mission_failures()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if flight_mode and more_legs:
		StageManager.go_to("flight")   # the same screen again: the next leg
		return
	StageManager.go_next()


# Work out which part is nearby and show the "Press E" prompt.
func update_prompt() -> void:
	nearby_part = find_nearest_part()

	if nearby_part == "" or reroute_panel.visible or life_support.is_busy() or (science and science.is_busy()):
		prompt_label.text = ""   # nothing nearby, or a panel is open
	elif nearby_part.begins_with("science_"):
		prompt_label.text = science.prompt_for(nearby_part)   # a science pass station
	elif nearby_part.begins_with("station_"):
		prompt_label.text = life_support.prompt_for(nearby_part)   # a Life Support station
	elif nearby_part == "power_panel":
		# For example:  Press E: Power panel
		prompt_label.text = "%s: %s" % [Data.voice["walk"]["press_e_hint"], Data.voice["walk"]["panel_name"]]
	else:
		# For example:  Press E: Camera (High resolution)
		var part: Dictionary = Data.parts[nearby_part]
		var version_name: String = part["versions"][GameState.choices[nearby_part]]["name"]
		prompt_label.text = "%s: %s (%s)" % [Data.voice["walk"]["press_e_hint"], GameState.get_part_name(nearby_part), version_name]


# Zones can overlap, so if the player is in more than one,
# pick the zone whose center is closest to the player.
func find_nearest_part() -> String:
	var best_part := ""
	var best_distance := INF   # INF = infinity, bigger than any real distance
	for zone in zones_player_is_in:
		var offset: Vector3 = zone.global_position - player.global_position
		offset.y = 0   # only count distance across the floor, not up/down
		if offset.length() < best_distance:
			best_distance = offset.length()
			best_part = zone.get_meta("part_id")
	return best_part


func _unhandled_input(event: InputEvent) -> void:
	# The leg or mission is over: nothing may be used while the last line is read.
	if mission_over:
		return

	# While a Life Support screen is open, E or Esc closes it (and nothing else).
	if life_support.panel_open():
		life_support.handle_input(event)
		return

	# While the switch panel is open, E or Esc closes it (and nothing else).
	if reroute_panel.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			close_reroute_panel()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and nearby_part != "":
		use_part(nearby_part)

	if event.is_action_pressed("toggle_dashboard"):
		toggle_dashboard()


# Tab: raise the arm to look at the wrist, or lower it again.
func toggle_dashboard() -> void:
	arm_is_up = not arm_is_up
	arm.set_raised(arm_is_up)


# Runs every frame. The dashboard shows only when the arm is all the way up,
# and sits just above the wrist light.
func update_wrist_panel() -> void:
	wrist_panel.visible = arm.is_fully_raised()
	if not wrist_panel.visible:
		return

	# unproject_position = "where on the screen is this 3D point?"
	var light_on_screen: Vector2 = camera.unproject_position(arm.get_light_position())
	var gap: float = Data.game_data["arm"]["panel_gap_pixels"]
	var panel_size: Vector2 = dashboard.size

	# Anchored: we center using the dashboard's FIXED width (set in walk.tscn,
	# Custom Minimum Size), not its current width. So when a number gets
	# longer, the dashboard does not slide sideways.
	var fixed_width: float = dashboard.custom_minimum_size.x

	# Centered above the light, but never off the edge of the screen.
	var spot := Vector2(light_on_screen.x - fixed_width / 2, light_on_screen.y - gap - panel_size.y)
	var screen: Vector2 = get_viewport().get_visible_rect().size
	spot.x = clampf(spot.x, 0, screen.x - fixed_width)
	spot.y = clampf(spot.y, 0, screen.y - panel_size.y)
	wrist_panel.position = spot


# The player pressed E on a part.
func use_part(part_id: String) -> void:
	# A Life Support station: life_support.gd does the work.
	if part_id.begins_with("station_"):
		life_support.use_station(part_id)
		return

	# A science pass station: science_pass.gd does the work.
	if part_id.begins_with("science_"):
		science.use_station(part_id)
		return

	# The power panel on the wall: open its switch screen.
	if part_id == "power_panel":
		open_reroute_panel()
		return

	# A spacecraft part: the inner voice explains it and its numbers.
	# (Switching parts off and on happens at the power panel.)
	var version_id: String = GameState.choices[part_id]
	var explanation: String = Data.voice["parts"][part_id][version_id]
	var effects: Dictionary = GameState.get_version_effects(part_id, version_id)
	var numbers: String = GameState.effects_text(effects, ", ")
	explanation = explanation.format({"percent": GameState.fmt(GameState.get_sunlight_factor() * 100.0)})   # the RTG line uses it
	say(explanation + " " + Data.voice["walk"]["numbers_intro"] + " " + numbers + ".")


# --- The power panel's switch screen (Reroute Power) -------------------------

# Free the mouse so the player can click the switches, and stop the player
# walking and looking around. The mission clock keeps running!
func open_reroute_panel() -> void:
	reroute_panel.open()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)


func close_reroute_panel() -> void:
	reroute_panel.close()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)


# A switch on the power panel was flipped: change the mission, and show it
# on the spacecraft. The dashboard picks up the new numbers by itself.
func _on_switch_changed(system_id: String, on: bool) -> void:
	GameState.set_system_on(system_id, on)
	if on:
		spacecraft.turn_on_part(system_id)
	else:
		spacecraft.turn_off_part(system_id)
