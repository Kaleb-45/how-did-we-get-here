# cutscene_intro.gd
# Greybox mission control room. It does NOT animate yet.
# This script only fills in the name over each person's head.
# The words come from data/story.json ("cutscene_intro" > "labels"),
# and the letter size comes from the shared theme.
extends Node3D

func _ready() -> void:
	var names: Dictionary = Data.story.get("cutscene_intro", {}).get("labels", {})
	var theme_font_size: int = load("res://theme/game_theme.tres").default_font_size
	for person in $People.get_children():
		# "Person_Staff1" -> key "Staff1"
		var key := String(person.name).trim_prefix("Person_")
		var label: Label3D = person.get_node("Label")
		label.text = names.get(key, "MISSING: " + key)
		label.font_size = theme_font_size
