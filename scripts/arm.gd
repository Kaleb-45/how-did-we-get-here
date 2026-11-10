# arm.gd
# The player's first-person arm: a sleeve, a glove, and a wrist device
# with a small light. It is attached to the camera, so it moves with your view.
#
# The arm's materials have "No Depth Test" turned on: they draw ON TOP of
# everything, so the arm never disappears inside a wall. "Render Priority"
# sets the order the pieces are drawn in (glove first, light last).
#
# WHERE the arm sits is not in this script. It comes from two marker nodes
# in arm.tscn: LoweredPose (resting) and RaisedPose (checking the wrist,
# like looking at a watch). Move a marker in the editor to move that pose.
extends Node3D

@onready var pivot: Node3D = %Pivot              # everything that moves together
@onready var lowered_pose: Marker3D = %LoweredPose
@onready var raised_pose: Marker3D = %RaisedPose
@onready var light_mesh: MeshInstance3D = %WristLight
@onready var light_glow: OmniLight3D = %WristGlow

var light_material: StandardMaterial3D
var full_glow: float        # the bulb's glow strength, as set in arm.tscn
var full_light: float       # the glow light's strength, as set in arm.tscn
var current_status: String = ""
var blinking: Tween

# 0.0 = arm down, 1.0 = arm fully up. Everything in between is "on the way".
var raise_amount: float = 0.0
var raising: Tween


func _ready() -> void:
	# Start in the lowered (resting) position.
	set_raise_amount(0.0)

	# Cloth on the sleeve (a texture made in code, see Textures.gd).
	Textures.apply($Pivot/Sleeve.get_surface_override_material(0), "fabric")

	# Remember how bright the light is in the scene, so blinking can
	# go from "off" back to exactly that brightness.
	light_material = light_mesh.get_surface_override_material(0)
	full_glow = light_material.emission_energy_multiplier
	full_light = light_glow.light_energy

	show_status("safe")


# Shows "safe" (green), "warning" (yellow) or "danger" (red, blinking).
# Colors come from the dashboard colors in game_data.json.
func show_status(status: String) -> void:
	if status == current_status:
		return   # nothing changed: don't restart the blinking every frame
	current_status = status

	set_light_color(Color.html(Data.game_data["dashboard"]["colors"][status]))

	if blinking:
		blinking.kill()
	set_brightness(1.0)

	if status == "danger":
		# Blink: brightness goes 1 -> 0 -> 1, over and over.
		var speed: float = Data.game_data["arm"]["blink_seconds"]
		blinking = create_tween().set_loops()
		blinking.tween_method(set_brightness, 1.0, 0.0, speed)
		blinking.tween_method(set_brightness, 0.0, 1.0, speed)


# Changes the wrist light's color (the bulb and the glow around it).
func set_light_color(color: Color) -> void:
	light_material.albedo_color = color
	light_material.emission = color
	light_glow.light_color = color


# 1.0 = fully on, 0.0 = off. Used by the blinking.
func set_brightness(amount: float) -> void:
	light_material.emission_energy_multiplier = full_glow * amount
	light_glow.light_energy = full_light * amount


# --- Raising the arm (Tab) ---------------------------------------------------

# up = true raises the arm, false lowers it. The Tween slides raise_amount
# from where it is now to 1 or 0, so pressing Tab halfway also works.
func set_raised(up: bool) -> void:
	if raising:
		raising.kill()
	var target: float = 1.0 if up else 0.0
	var seconds: float = Data.game_data["arm"]["raise_seconds"]
	raising = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	raising.tween_method(set_raise_amount, raise_amount, target, seconds)


# Puts the arm part-way between the two markers.
# interpolate_with() blends position AND rotation: 0 = lowered, 1 = raised.
func set_raise_amount(amount: float) -> void:
	raise_amount = amount
	pivot.transform = lowered_pose.transform.interpolate_with(raised_pose.transform, amount)


func is_fully_raised() -> bool:
	return raise_amount >= 1.0


# Where the wrist light is in the 3D world (walk.gd turns this
# into a spot on the screen, to put the dashboard above it).
func get_light_position() -> Vector3:
	return light_mesh.global_position
