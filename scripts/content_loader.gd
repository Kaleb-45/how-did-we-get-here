# content_loader.gd
# The content loader (GAME_PLAN.md 12f). Data.gd loads the base data first, then calls this.
# It looks in the pack folders (game_data.json "content_packs" > "folders"), for example
# res://content/ and user://content/. Each folder inside is one PACK, made by a student:
#   content/<pack name>/destination.json  : new places to go   { "destinations": { id: {...} } }
#   content/<pack name>/parts.json        : new part versions  { "parts": { slot: { "versions": { id: {...} } } } }
#   content/<pack name>/events.json       : new events         { "events": { id: {...} } }
#   content/<pack name>/mission.json      : new mission goals  { "missions": { id: {...} } }
#   content/<pack name>/inner_voice.json  : voice lines, same shape as data/inner_voice.json
#   content/<pack name>/story.json        : screen text, same shape as data/story.json
# MERGE BY ID: a new id is ADDED. If the id is already in the game, the game's version stays
# (a warning says so), so a pack can never break the base game by accident.
# A pack with a problem is SKIPPED WHOLE: nothing from it is added, a clear message is printed,
# and the game starts normally. This script has no game numbers: the lists of required fields
# are in game_data.json "content_packs".
extends RefCounted

# Which file in a pack goes where. The second part is the key inside the file (empty = the whole file).
# "where" names the place in Data where the content merges.
const PACK_FILES := {
	"destination.json": {"key": "destinations", "where": "destinations"},
	"parts.json": {"key": "parts", "where": "parts"},
	"events.json": {"key": "events", "where": "events"},
	"mission.json": {"key": "missions", "where": "missions"},
	"inner_voice.json": {"key": "", "where": "voice"},
	"story.json": {"key": "", "where": "story"},
}

var data: Node                      # the Data autoload
var rules: Dictionary = {}          # game_data.json "content_packs"
var loaded_packs: Array = []        # names of packs that were added
var skipped_packs: Array = []       # names of packs that were skipped


# Loads every pack. Returns the list of messages (also printed), for the Output panel and tests.
func load_all(data_node: Node) -> Array:
	data = data_node
	rules = data.game_data.get("content_packs", {})
	var messages: Array = []
	for folder in rules.get("folders", []):
		for pack_name in list_pack_folders(folder):
			load_pack(folder.path_join(pack_name), pack_name, messages)
	if loaded_packs.is_empty() and skipped_packs.is_empty():
		print("Content packs: none found")
	else:
		print("Content packs loaded: ", loaded_packs, "   skipped: ", skipped_packs)
	return messages


# The folder names inside a pack folder (sorted). A folder that starts with "_" or "." is switched off.
func list_pack_folders(folder: String) -> Array:
	var names: Array = []
	var dir := DirAccess.open(folder)
	if dir == null:
		return names   # the folder does not exist: that is fine
	for sub in dir.get_directories():
		var off := false
		for prefix in rules.get("skip_folder_prefixes", []):
			if sub.begins_with(prefix):
				off = true
		if not off:
			names.append(sub)
	names.sort()
	return names


# Reads, checks and merges one pack. Any problem skips the WHOLE pack.
func load_pack(path: String, pack_name: String, messages: Array) -> void:
	var problems: Array = []
	var files: Dictionary = {}   # file name -> the dictionary inside it
	for file_name in PACK_FILES:
		var file_path: String = path.path_join(file_name)
		if not FileAccess.file_exists(file_path):
			continue
		var content = read_json(file_path, file_name, problems)
		if content == null:
			continue
		var key: String = PACK_FILES[file_name]["key"]
		if key != "":
			if not content.has(key) or not content[key] is Dictionary:
				problems.append("%s: it must start with { \"%s\": { ... } }" % [file_name, key])
				continue
			content = content[key]
		files[file_name] = content
	if files.is_empty() and problems.is_empty():
		problems.append("no pack files found (use one of: %s)" % ", ".join(PACK_FILES.keys()))

	# Merge into a copy: if a check fails afterwards, the copy is thrown away and the game keeps its data.
	var backup: Dictionary = {}
	for file_name in PACK_FILES:
		var where: String = PACK_FILES[file_name]["where"]
		backup[where] = get_target(where).duplicate(true)
	if problems.is_empty():
		for file_name in files:
			merge_add(get_target(PACK_FILES[file_name]["where"]), files[file_name], file_name, problems)
		check_new_content(files, problems)
	var warnings: Array = []
	for problem in problems:
		if problem.begins_with("note:"):
			warnings.append(problem)
	problems = problems.filter(func(p): return not p.begins_with("note:"))

	if problems.is_empty():
		loaded_packs.append(pack_name)
		print("Content pack '%s' loaded." % pack_name)
		for note in warnings:
			report(messages, "Content pack '%s' %s" % [pack_name, note.trim_prefix("note:").strip_edges()], false)
		return
	# Put everything back, as it was before this pack.
	for where in backup:
		set_target(where, backup[where])
	skipped_packs.append(pack_name)
	for problem in problems:
		report(messages, "Content pack '%s' was SKIPPED: %s" % [pack_name, problem], true)


# One clear line: printed, and a warning in the editor.
func report(messages: Array, text: String, is_problem: bool) -> void:
	messages.append(text)
	if is_problem:
		push_warning(text)
	else:
		print(text)


# Reads one JSON file. Returns the Dictionary, or null (and a problem line) if it is broken.
func read_json(file_path: String, file_name: String, problems: Array):
	var text := FileAccess.get_file_as_string(file_path)
	var parser := JSON.new()
	var error: int = parser.parse(text)
	if error != OK:
		problems.append("%s has a typo on line %d: %s" % [file_name, parser.get_error_line(), parser.get_error_message()])
		return null
	if not parser.data is Dictionary:
		problems.append("%s must be a { ... } object at the top" % file_name)
		return null
	return parser.data


# Where a kind of content lives in Data.
func get_target(where: String) -> Dictionary:
	match where:
		"destinations":
			return data.destinations
		"events":
			return data.events
		"parts":
			return data.game_data["parts"]
		"missions":
			return data.game_data["missions"]
		"voice":
			return data.voice
		_:
			return data.story


func set_target(where: String, value: Dictionary) -> void:
	match where:
		"destinations":
			data.destinations = value
		"events":
			data.events = value
		"parts":
			data.game_data["parts"] = value
		"missions":
			data.game_data["missions"] = value
		"voice":
			data.voice = value
		_:
			data.story = value


# Adds what is new. An id that already exists keeps the game's version (a "note:" line says so).
# Names that start with "_" (like "_readme") are notes for people and are left out.
func merge_add(base: Dictionary, add: Dictionary, path: String, problems: Array) -> void:
	for key in add:
		if key.begins_with("_"):
			continue
		var here: String = path + " > " + key
		if not base.has(key):
			base[key] = add[key].duplicate(true) if (add[key] is Dictionary or add[key] is Array) else add[key]
		elif base[key] is Dictionary and add[key] is Dictionary:
			merge_add(base[key], add[key], here, problems)
		elif base[key] != add[key]:
			problems.append("note: tried to change \"%s\" which is already in the game, so the game's version stays." % here)


# After merging: does everything the new content needs exist? Adds a problem line for each thing missing.
func check_new_content(files: Dictionary, problems: Array) -> void:
	var resource_ids: Array = data.game_data["resources"].keys()   # (Data.resources is filled after the loader runs)
	if files.has("parts.json"):
		var packed: Dictionary = files["parts.json"]
		for slot_id in packed:
			if slot_id.begins_with("_"):
				continue
			var slot: Dictionary = data.game_data["parts"].get(slot_id, {})
			check_keys(slot, rules.get("slot_keys", []), "parts.json > %s" % slot_id, problems)
			var new_versions: Dictionary = packed[slot_id].get("versions", {}) if packed[slot_id] is Dictionary else {}
			for version_id in new_versions:
				if version_id.begins_with("_"):
					continue
				var here := "parts.json > %s > %s" % [slot_id, version_id]
				var version = slot.get("versions", {}).get(version_id, null)
				if not version is Dictionary:
					problems.append("%s must be a { ... } object" % here)
					continue
				check_keys(version, rules.get("version_keys", []), here, problems)
				var effects = version.get("effects", {})
				if effects is Dictionary:
					for res_id in resource_ids:
						if not effects.has(res_id) or not (effects[res_id] is float or effects[res_id] is int):
							problems.append("%s > effects needs a number for \"%s\"" % [here, res_id])
				var look = version.get("look", {})
				if look is Dictionary and not look.has("size"):
					problems.append("%s > look needs a \"size\"" % here)
				# The voice line that explains the part (press E on the ship).
				var line = data.voice.get("parts", {}).get(slot_id, {}).get(version_id, null)
				if not line is String:
					problems.append("%s needs a voice line: inner_voice.json > parts > %s > %s" % [here, slot_id, version_id])
	if files.has("destination.json"):
		for dest_id in files["destination.json"]:
			if dest_id.begins_with("_"):
				continue
			var here_dest := "destination.json > %s" % dest_id
			check_keys(data.destinations.get(dest_id, {}), rules.get("destination_keys", []), here_dest, problems)
			if not data.story.get("destinations", {}).has(dest_id):
				problems.append("%s needs its words: story.json > destinations > %s" % [here_dest, dest_id])
			var lines = data.voice.get("setup", {}).get("destination", {}).get(dest_id, {})
			for level in data.levels:
				if not lines is Dictionary or not lines.has(level):
					problems.append("%s needs an inner voice line for level \"%s\": inner_voice.json > setup > destination > %s > %s" % [here_dest, level, dest_id, level])
	if files.has("mission.json"):
		for mission_id in files["mission.json"]:
			if mission_id.begins_with("_"):
				continue
			var here_mission := "mission.json > %s" % mission_id
			check_keys(data.game_data["missions"].get(mission_id, {}), rules.get("mission_keys", []), here_mission, problems)
			if not data.story.get("missions", {}).has(mission_id):
				problems.append("%s needs its words: story.json > missions > %s" % [here_mission, mission_id])
			var goal_lines = data.voice.get("setup", {}).get("goal", {}).get(mission_id, {})
			for level in data.levels:
				if not goal_lines is Dictionary or not goal_lines.has(level):
					problems.append("%s needs an inner voice line for level \"%s\": inner_voice.json > setup > goal > %s > %s" % [here_mission, level, mission_id, level])


# Each name in "needed" must be a key of "thing".
func check_keys(thing: Dictionary, needed: Array, here: String, problems: Array) -> void:
	for key in needed:
		if not thing.has(key):
			problems.append("%s is missing \"%s\"" % [here, key])
