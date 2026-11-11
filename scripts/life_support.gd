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

var walk: Node3D                 # the walk scene (it has say(), player and the HUD)
var panel: PanelContainer        # the Food station's screen
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


# Is a station screen open? (walk.gd then leaves the keys to us.)
func panel_open() -> bool:
	return panel.visible


# Something is going on at a station, so no "Press E" prompt.
func is_busy() -> bool:
	return panel.visible


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
	return ""


func use_station(part_id: String) -> void:
	match part_id:
		"station_food":
			use_food()


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
