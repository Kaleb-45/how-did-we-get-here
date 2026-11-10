# Data.gd
# This script reads our JSON files ONE time, when the game starts.
# It is an "autoload": Godot keeps it alive the whole game, and every
# other script can reach it by its name, like this:  Data.parts
#
# There are NO game numbers in this file. They all live in data/game_data.json.
extends Node

# These variables hold what we read from the files.
# Other scripts read them, for example: Data.parts["camera"]
var game_data: Dictionary = {}
var story: Dictionary = {}
var voice: Dictionary = {}

# Shortcuts to the parts of game_data we use the most.
var resources: Dictionary = {}
var parts: Dictionary = {}
var missions: Dictionary = {}
var characters: Dictionary = {}
var destinations: Dictionary = {}   # from data/destinations.json
var timing: Dictionary = {}   # from data/timing.json (launch moments)
var levels: Dictionary = {}   # from data/levels.json: what each level changes


# _ready() runs automatically when this node starts.
func _ready() -> void:
	game_data = load_json("res://data/game_data.json")
	story = load_json("res://data/story.json")
	voice = load_json("res://data/inner_voice.json")
	levels = load_json("res://data/levels.json").get("levels", {})
	timing = load_json("res://data/timing.json")
	destinations = load_json("res://data/destinations.json").get("destinations", {})

	resources = game_data.get("resources", {})
	parts = game_data.get("parts", {})
	missions = game_data.get("missions", {})
	characters = game_data.get("characters", {})

	print_summary()


# Opens one JSON file and turns it into a Dictionary
# (a list of "name: value" pairs).
func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing file: " + path)
		return {}

	var text := FileAccess.get_file_as_string(path)
	var result = JSON.parse_string(text)

	# If someone made a typo in the JSON (like a missing comma),
	# parse_string gives back null. We say so clearly.
	if result == null:
		push_error("This file has a typo and could not be read: " + path)
		return {}

	return result


# Prints what we loaded, so we can check it in the Output panel.
func print_summary() -> void:
	print("=== Data loaded ===")
	print("Resources: ", resources.keys())

	for part_id in parts:
		var part: Dictionary = parts[part_id]
		print(part["name"], " versions: ", part["versions"].keys())

	for mission_id in missions:
		print("Mission ", mission_id, " limits:")
		var limits: Dictionary = missions[mission_id]["limits"]
		for res_id in limits:
			var limit: Dictionary = limits[res_id]
			print("   ", res_id, "  ", limit["rule"], " ", limit["value"], "  (", limit["source"], ")")

	print("Story intro, the general says: ", story["intro"]["general_says"])
	print("Inner voice, walk start: ", voice["walk"]["start"])
	print("=== End of data ===")
