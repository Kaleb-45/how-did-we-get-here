# cutscene_intro.gd
# The intro cutscene in the mission control war room.
# The AnimationPlayer node plays one animation called "intro" by itself
# (Autoplay). The animation moves the camera and the people, shows and
# hides the subtitles, and fades to black at the end.
# The people are character scenes (scenes/characters). The animation also
# calls talk() and point_at_camera() on them, and turns their heads.
# This script does two small jobs:
#   1. It shows and hides the subtitle when the animation asks.
#   2. When the animation ends, it goes to the name screen.
# The words come from data/story.json ("cutscene_intro").
extends Node3D

@onready var subtitle_box: PanelContainer = $CanvasLayer/SubtitleBox
@onready var subtitle: Label = $CanvasLayer/SubtitleBox/Subtitle
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# When the animation is over, move on to the next screen.
	animation_player.animation_finished.connect(_on_animation_finished)


# The animation calls this (a "method track") to show one subtitle line.
func show_subtitle(key: String) -> void:
	var lines: Dictionary = Data.story.get("cutscene_intro", {}).get("subtitles", {})
	subtitle.text = lines.get(key, "MISSING: " + key)
	subtitle_box.visible = true


func hide_subtitle() -> void:
	subtitle_box.visible = false


# Go to the name screen. StageManager is the same way every other screen
# moves on (the screen list is in data/game_data.json, "stages").
func _on_animation_finished(_animation_name: StringName) -> void:
	StageManager.go_to("name")
