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
# MERGE BY ID. A destination, mission, event, part slot or part version id that the game already
# has is CLOSED: that entry is skipped whole and a note is printed. A new part version can be
# added to an existing slot (only under "versions"). Only story.json and inner_voice.json are merged
# deeper, and they too only add new keys.
# A pack with a problem is SKIPPED WHOLE: nothing from it is added, a clear message is printed,
# and the game starts normally. Every check looks at the type of a value before it uses it, so
# a wrong value (a word where a number belongs) is a message, not a crash.
# This script has no game numbers: the lists of required fields are in game_data.json "content_packs".
extends RefCounted

# Which file in a pack goes where. "key" = the key inside the file (empty = the whole file).
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
		print("Content packs: none switched on")
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
	var problems: Array = []   # a problem skips the pack
	var notes: Array = []      # a note is only printed (an entry was left out, a file was not known)
	var files: Dictionary = {}   # file name -> the content to merge
	check_unknown_files(path, pack_name, notes)
	for file_name in PACK_FILES:
		var file_path: String = path.path_join(file_name)
		if not FileAccess.file_exists(file_path):
			continue
		var content = read_json(file_path, file_name, problems)
		if content == null:
			continue
		var key: String = PACK_FILES[file_name]["key"]
		if key != "":
			if not content.has(key) or typeof(content[key]) != TYPE_DICTIONARY:
				problems.append("%s: it must start with { \"%s\": { ... } }" % [file_name, key])
				continue
			content = content[key]
		files[file_name] = content
	if files.is_empty() and problems.is_empty():
		problems.append("no pack files found (use one of: %s)" % ", ".join(PACK_FILES.keys()))

	# Merge into the game's data. If a check fails afterwards, the saved copy is put back.
	var backup: Dictionary = {}
	for file_name in PACK_FILES:
		var where: String = PACK_FILES[file_name]["where"]
		backup[where] = get_target(where).duplicate(true)
	if problems.is_empty():
		var clean: Dictionary = {}
		for file_name in files:
			clean[file_name] = close_existing_ids(file_name, files[file_name], notes)
		for file_name in clean:
			merge_add(get_target(PACK_FILES[file_name]["where"]), clean[file_name], file_name, notes)
		check_new_content(clean, problems)

	for note in notes:
		report(messages, "Content pack '%s': %s" % [pack_name, note], false)
	if problems.is_empty():
		loaded_packs.append(pack_name)
		print("Content pack '%s' loaded." % pack_name)
		return
	# Put everything back, as it was before this pack.
	for where in backup:
		set_target(where, backup[where])
	skipped_packs.append(pack_name)
	for problem in problems:
		report(messages, "Content pack '%s' was SKIPPED: %s" % [pack_name, problem], true)


# One clear line: printed (a note), or a warning in the editor (a problem).
func report(messages: Array, text: String, is_problem: bool) -> void:
	messages.append(text)
	if is_problem:
		push_warning(text)
	else:
		print(text)


# A file in the pack folder that the loader does not know (for example destinations.json) is named in a note.
func check_unknown_files(path: String, pack_name: String, notes: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		if PACK_FILES.has(file_name) or file_name.begins_with("_") or file_name.begins_with(".") or file_name.ends_with(".import") or file_name.ends_with(".uid"):
			continue
		if file_name.ends_with(".json"):
			notes.append("the file \"%s\" is not a pack file, so it is ignored. The names the loader knows: %s" % [file_name, ", ".join(PACK_FILES.keys())])


# Reads one JSON file. Returns the Dictionary, or null (and a problem line) if it is broken.
func read_json(file_path: String, file_name: String, problems: Array):
	var text := FileAccess.get_file_as_string(file_path)
	var parser := JSON.new()
	var error: int = parser.parse(text)
	if error != OK:
		problems.append("%s has a typo on line %d: %s" % [file_name, parser.get_error_line(), parser.get_error_message()])
		return null
	if typeof(parser.data) != TYPE_DICTIONARY:
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


# Closed ids. A destination, mission, event, part slot or part version the game already has cannot be
# changed by a pack: that entry is left out whole, with a note. Inside an existing part slot only new
# ids under "versions" are allowed. story.json and inner_voice.json are returned as they are.
func close_existing_ids(file_name: String, content: Dictionary, notes: Array) -> Dictionary:
	var base: Dictionary = get_target(PACK_FILES[file_name]["where"])
	if file_name == "inner_voice.json" or file_name == "story.json":
		return content
	var clean: Dictionary = {}
	for id in content:
		if id.begins_with("_"):
			continue
		if not base.has(id):
			clean[id] = content[id]
			continue
		if file_name != "parts.json":
			notes.append("\"%s\" in %s is already in the game, so that entry is left out." % [id, file_name])
			continue
		# An existing part slot: only new version ids under "versions".
		if typeof(content[id]) != TYPE_DICTIONARY:
			clean[id] = content[id]   # the check below says what is wrong
			continue
		for key in content[id]:
			if key != "versions" and not key.begins_with("_"):
				notes.append("\"%s\" in parts.json is already in the game: only new versions can be added to it, so \"%s\" is left out." % [id, key])
		var versions = content[id].get("versions", {})
		if typeof(versions) != TYPE_DICTIONARY:
			clean[id] = {"versions": versions}   # the check below says what is wrong
			continue
		var new_versions: Dictionary = {}
		for version_id in versions:
			if version_id.begins_with("_"):
				continue
			if base[id]["versions"].has(version_id):
				notes.append("the version \"%s\" of \"%s\" is already in the game, so it is left out." % [version_id, id])
			else:
				new_versions[version_id] = versions[version_id]
		if not new_versions.is_empty():
			clean[id] = {"versions": new_versions}
	return clean


# Adds what is new (story.json and inner_voice.json go deeper). A name that is already there keeps the game's
# value and gets a note. Names that start with "_" (like "_readme") are notes for people and are left out.
func merge_add(base: Dictionary, add: Dictionary, path: String, notes: Array) -> void:
	for key in add:
		if key.begins_with("_"):
			continue
		var here: String = path + " > " + key
		if not base.has(key):
			base[key] = add[key].duplicate(true) if typeof(add[key]) in [TYPE_DICTIONARY, TYPE_ARRAY] else add[key]
		elif typeof(base[key]) == TYPE_DICTIONARY and typeof(add[key]) == TYPE_DICTIONARY:
			merge_add(base[key], add[key], here, notes)
		elif typeof(base[key]) != typeof(add[key]) or base[key] != add[key]:
			notes.append("tried to change \"%s\" which is already in the game, so the game's version stays." % here)


# After merging: is everything the new content needs there, and is every value the right kind?
# Adds a problem line for each thing wrong. "clean" = what this pack really added.
func check_new_content(clean: Dictionary, problems: Array) -> void:
	var resource_ids: Array = data.game_data["resources"].keys()   # (Data.resources is filled after the loader runs)
	if clean.has("parts.json"):
		check_parts(clean["parts.json"], resource_ids, problems)
	if clean.has("destination.json"):
		check_destinations(clean["destination.json"], problems)
	if clean.has("mission.json"):
		check_missions(clean["mission.json"], resource_ids, problems)
	if clean.has("events.json"):
		for event_id in clean["events.json"]:
			if typeof(clean["events.json"][event_id]) != TYPE_DICTIONARY:
				problems.append("events.json > %s must be a { ... } object" % event_id)


func is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func check_parts(packed: Dictionary, resource_ids: Array, problems: Array) -> void:
	for slot_id in packed:
		var slot = data.game_data["parts"].get(slot_id, null)
		var here_slot := "parts.json > %s" % slot_id
		if typeof(packed[slot_id]) != TYPE_DICTIONARY or typeof(slot) != TYPE_DICTIONARY:
			problems.append("%s must be a { ... } object" % here_slot)
			continue
		check_keys(slot, rules.get("slot_keys", []), here_slot, problems)
		if slot.has("name") and typeof(slot["name"]) != TYPE_STRING:
			problems.append("%s > name must be text" % here_slot)
		if slot.has("allowed_at") and typeof(slot["allowed_at"]) != TYPE_ARRAY:
			problems.append("%s > allowed_at must be a list like [\"orbit\"]" % here_slot)
		if slot.has("look") and typeof(slot["look"]) != TYPE_DICTIONARY:
			problems.append("%s > look must be a { ... } object" % here_slot)
		var new_versions = packed[slot_id].get("versions", {})
		if typeof(new_versions) != TYPE_DICTIONARY:
			problems.append("%s > versions must be a { ... } object" % here_slot)
			continue
		for version_id in new_versions:
			var here := "%s > %s" % [here_slot, version_id]
			var version = slot.get("versions", {}).get(version_id, null)
			if typeof(version) != TYPE_DICTIONARY:
				problems.append("%s must be a { ... } object" % here)
				continue
			check_keys(version, rules.get("version_keys", []), here, problems)
			if version.has("name") and typeof(version["name"]) != TYPE_STRING:
				problems.append("%s > name must be text" % here)
			if version.has("source") and typeof(version["source"]) != TYPE_STRING:
				problems.append("%s > source must be text" % here)
			if version.has("allowed_at") and typeof(version["allowed_at"]) != TYPE_ARRAY:
				problems.append("%s > allowed_at must be a list like [\"orbit\"]" % here)
			if version.has("scaling") and typeof(version["scaling"]) != TYPE_ARRAY:
				problems.append("%s > scaling must be a list like [\"sunlight\"]" % here)
			var effects = version.get("effects", null)
			if effects != null:
				if typeof(effects) != TYPE_DICTIONARY:
					problems.append("%s > effects must be a { ... } object" % here)
				else:
					for res_id in resource_ids:
						if not effects.has(res_id) or not is_number(effects[res_id]):
							problems.append("%s > effects needs a number for \"%s\"" % [here, res_id])
					for res_id in effects:
						if not resource_ids.has(res_id):
							problems.append("%s > effects has \"%s\", which is not one of the six resources (%s)" % [here, res_id, ", ".join(resource_ids)])
			var look = version.get("look", null)
			if look != null:
				if typeof(look) != TYPE_DICTIONARY or not look.has("size") or typeof(look["size"]) != TYPE_ARRAY:
					problems.append("%s > look needs a \"size\" list like [1.5, 0.06, 1.2]" % here)
			# The voice line that explains the part (press E on the ship).
			var voice_parts = data.voice.get("parts", {})
			var voice_slot = voice_parts.get(slot_id, {}) if typeof(voice_parts) == TYPE_DICTIONARY else {}
			var line = voice_slot.get(version_id, null) if typeof(voice_slot) == TYPE_DICTIONARY else null
			if typeof(line) != TYPE_STRING:
				problems.append("%s needs a voice line: inner_voice.json > parts > %s > %s" % [here, slot_id, version_id])


# Every fact of a destination is { "value": ..., "source": ... }.
func check_destinations(packed: Dictionary, problems: Array) -> void:
	for dest_id in packed:
		var here := "destination.json > %s" % dest_id
		var dest = data.destinations.get(dest_id, null)
		if typeof(dest) != TYPE_DICTIONARY:
			problems.append("%s must be a { ... } object" % here)
			continue
		check_keys(dest, rules.get("destination_keys", []), here, problems)
		for fact_id in dest:
			var fact = dest[fact_id]
			if typeof(fact) != TYPE_DICTIONARY:
				problems.append("%s > %s must look like { \"value\": ..., \"source\": ... }" % [here, fact_id])
				continue
			check_keys(fact, rules.get("fact_wrapper_keys", []), "%s > %s" % [here, fact_id], problems)
		var story_dests = data.story.get("destinations", {})
		if typeof(story_dests) != TYPE_DICTIONARY or not story_dests.has(dest_id):
			problems.append("%s needs its words: story.json > destinations > %s" % [here, dest_id])
		check_level_lines(data.voice.get("setup", {}), "destination", dest_id, here, problems)


# A new mission: six limits, each with every limit field, goal rules, words and a voice line for each level.
func check_missions(packed: Dictionary, resource_ids: Array, problems: Array) -> void:
	for mission_id in packed:
		var here := "mission.json > %s" % mission_id
		var mission = data.game_data["missions"].get(mission_id, null)
		if typeof(mission) != TYPE_DICTIONARY:
			problems.append("%s must be a { ... } object" % here)
			continue
		check_keys(mission, rules.get("mission_keys", []), here, problems)
		var limits = mission.get("limits", null)
		if limits != null:
			if typeof(limits) != TYPE_DICTIONARY:
				problems.append("%s > limits must be a { ... } object" % here)
			else:
				for res_id in resource_ids:
					if not limits.has(res_id):
						problems.append("%s > limits is missing \"%s\"" % [here, res_id])
						continue
					var limit = limits[res_id]
					var here_limit := "%s > limits > %s" % [here, res_id]
					if typeof(limit) != TYPE_DICTIONARY:
						problems.append("%s must be a { ... } object" % here_limit)
						continue
					check_keys(limit, rules.get("limit_keys", []), here_limit, problems)
					if limit.has("rule") and not (typeof(limit["rule"]) == TYPE_STRING and limit["rule"] in ["max", "min"]):
						problems.append("%s > rule must be \"max\" or \"min\"" % here_limit)
					for number_key in ["value", "warning", "bar_max"]:
						if limit.has(number_key) and not is_number(limit[number_key]):
							problems.append("%s > %s must be a number" % [here_limit, number_key])
		var goal = mission.get("goal_rules", null)
		if goal != null:
			if typeof(goal) != TYPE_DICTIONARY or typeof(goal.get("resources", null)) != TYPE_ARRAY:
				problems.append("%s > goal_rules needs a list: \"resources\": [\"data\", ...]" % here)
			else:
				for res_id in goal["resources"]:
					if not resource_ids.has(res_id):
						problems.append("%s > goal_rules > resources has \"%s\", which is not one of the six resources" % [here, res_id])
		var story_missions = data.story.get("missions", {})
		if typeof(story_missions) != TYPE_DICTIONARY or not story_missions.has(mission_id):
			problems.append("%s needs its words: story.json > missions > %s" % [here, mission_id])
		check_level_lines(data.voice.get("setup", {}), "goal", mission_id, here, problems)


# The inner voice line for each level (easy, medium, hard): inner_voice.json > setup > <section> > <id> > <level>.
func check_level_lines(setup, section: String, id: String, here: String, problems: Array) -> void:
	var section_lines = setup.get(section, {}) if typeof(setup) == TYPE_DICTIONARY else {}
	var lines = section_lines.get(id, {}) if typeof(section_lines) == TYPE_DICTIONARY else {}
	for level in data.levels:
		if typeof(lines) != TYPE_DICTIONARY or typeof(lines.get(level, null)) != TYPE_STRING:
			problems.append("%s needs an inner voice line for level \"%s\": inner_voice.json > setup > %s > %s > %s" % [here, level, section, id, level])


# Each name in "needed" must be a key of "thing".
func check_keys(thing: Dictionary, needed: Array, here: String, problems: Array) -> void:
	for key in needed:
		if not thing.has(key):
			problems.append("%s is missing \"%s\"" % [here, key])
