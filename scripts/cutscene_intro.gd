# cutscene_intro.gd
# The intro cutscene in the bright mission control room (about 29.3 seconds).
# The AnimationPlayer node plays one animation called "intro" by itself
# (Autoplay). The animation moves the camera and the people, shows and
# hides the subtitles, shakes the camera and fades in and out.
# The people are character scenes (scenes/characters). The animation also
# calls talk() and point_at_camera() on them, and turns their heads.
#
# SHOT LIST (each shot is a hard cut; the times are in the animation):
#   Shot 0   0.0  fade in from black
#   Shot 1   0.0  high wide shot of the room (tall window and rocket at the top), slow push in
#   Shot 2   3.0  low angle on the Commander, snap zoom on "I quit!"
#   Shot 3   5.0  door shot from the walkway, the door slides, he leaves
#   Shot 4   7.3  close up of the General, held still (silent pause)
#   Shot 5   8.1  low angle medium shot of the General: "Who will run it?"
#   Shot 6  12.0  three cuts, each with a short frozen "uh-oh" hold (comedy) and then
#                 a quick move: Staff 1 ducks (12.0), Staff 2 ducks (13.3), Staff 3 dives
#                 into the closet, then a wide beat of the empty consoles
#   Shot 7  16.4  over the General's shoulder: "I need somebody. Anybody!"
#   Shot 8  19.2  same shot held, pause, his head turns toward us
#   Shot 9  20.0  front close up, punch in and shake: "You. I want you."
#   Shot 10 22.8  front three shot: Assistant Scientist, Janitor, Student
#   Shot 11 27.3  fade to black, then the name screen
#
# LOOK (the "Space Station" palette, see docs/ART_DIRECTION.md):
#   Colours are in the material library: res://materials (see materials/README.md).
#   Lights are in the Lights node and the WorldEnvironment node. Short version:
#     KEY  = KeyLight (the one warm Directional light, makes the soft shadows).
#            It shines from the front right. A Directional light's direction comes
#            from its ROTATION; its position does nothing. Edit light_color / light_energy.
#     FILL = WorldEnvironment ambient light (cool and gentle)
#     RIM  = RimThreeA, RimThreeB, RimGeneral (dim cool outline lights)
#     FACE = KeyGeneral, KeyThree, KeyGeneralBack (dim warm spots, no shadows)
#     The FILL colour and strength are ambient_light_color / ambient_light_energy
#     in the WorldEnvironment node. RIM and FACE are SpotLight3D nodes (edit
#     light_color and light_energy). FACE lights cast no shadows.
#   Glow (WorldEnvironment) is low with a high threshold, so only the cyan screens
#   and console lights bloom. There is NO fog on purpose.
#   (Comments inside .tscn and .tres files disappear when Godot saves them, so the
#   real notes live here and in materials/README.md.)
#   SUBTITLE panel: rounded, slightly see-through navy box, set by the theme.
#   Subtitle colours and sizes are in theme/game_theme.tres (SubtitlePanel,
#   SubtitleSpeaker, SubtitleLine).
#
# This script does four small jobs:
#   1. show_subtitle() / hide_subtitle(): speaker name (amber) and line (white).
#   2. shake_camera(): a quick camera shake that the animation can call.
#   3. Soft dark "blob" spots on the floor under every person and console, so
#      they look grounded (the Compatibility renderer has no contact shadows).
#   4. When the animation ends, it goes to the name screen.
# The words come from data/story.json ("cutscene_intro").
extends Node3D

var _shake_left := 0.0
var _shake_total := 0.0
var _shake_strength := 0.0

# The soft blob spots: how big they are (meters across) under each kind of thing.
const BLOB_SIZE_PERSON := 1.5
const BLOB_SIZE_CONSOLE := Vector2(2.4, 1.4)
const BLOB_SIZE_TABLE := Vector2(5.4, 7.8)
const BLOB_SHADER := preload("res://shaders/blob_shadow.gdshader")

@onready var subtitle_box: PanelContainer = $CanvasLayer/BarBottom/SubtitleBox
@onready var speaker: Label = $CanvasLayer/BarBottom/SubtitleBox/Lines/Speaker
@onready var subtitle: Label = $CanvasLayer/BarBottom/SubtitleBox/Lines/Subtitle
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# When the animation is over, move on to the next screen.
	animation_player.animation_finished.connect(_on_animation_finished)
	subtitle_box.visible = false
	_add_blob_shadows()


# Put a soft round dark spot (a flat quad) on the floor under each person,
# console and the table. The quad is a child, so it moves with the person.
func _add_blob_shadows() -> void:
	for person in $People.get_children():
		var size := BLOB_SIZE_PERSON * (0.6 if person.name == "Person_Student" else 1.0)
		_add_blob(person, Vector2(size, size), Vector3(0, 0.02, 0))
	for row in ["ConsolesRowBack", "ConsolesRowFront"]:
		for console in $Furniture.get_node(row).get_children():
			_add_blob(console, BLOB_SIZE_CONSOLE, Vector3(0, 0.02, 0))
	for fg in $Furniture/ForegroundConsoles.get_children():
		_add_blob(fg, BLOB_SIZE_CONSOLE, Vector3(0, 0.02, 0))
	_add_blob($Furniture/Table, BLOB_SIZE_TABLE, Vector3(0, 0.02, 0))


func _add_blob(parent: Node3D, size: Vector2, pos: Vector3) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var mat := ShaderMaterial.new()
	mat.shader = BLOB_SHADER
	var blob := MeshInstance3D.new()
	blob.name = "BlobShadow"
	blob.mesh = quad
	blob.material_override = mat
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blob.position = pos
	blob.rotation.x = -PI / 2.0     # lie flat on the floor
	parent.add_child(blob)


# The animation calls this (a "method track") to show one subtitle line.
func show_subtitle(key: String) -> void:
	var lines: Dictionary = Data.story.get("cutscene_intro", {}).get("subtitles", {})
	var line: Dictionary = lines.get(key, {})
	speaker.text = line.get("speaker", "")
	subtitle.text = line.get("text", "MISSING: " + key)
	subtitle_box.visible = true


func hide_subtitle() -> void:
	subtitle_box.visible = false


# The animation calls this to shake the camera for "seconds".
# "strength" is how far the picture jumps (0.02 is small).
func shake_camera(seconds: float, strength: float) -> void:
	_shake_left = seconds
	_shake_total = seconds
	_shake_strength = strength


# The shake moves the camera's h_offset and v_offset, so it never fights the
# animation tracks that move the camera's position and rotation.
func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		var fade := clampf(_shake_left / _shake_total, 0.0, 1.0)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake_strength * fade
		camera.v_offset = randf_range(-1.0, 1.0) * _shake_strength * fade
	elif camera.h_offset != 0.0 or camera.v_offset != 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


# Go to the name screen. StageManager is the same way every other screen
# moves on (the screen list is in data/game_data.json, "stages").
func _on_animation_finished(_animation_name: StringName) -> void:
	StageManager.go_to("name")
