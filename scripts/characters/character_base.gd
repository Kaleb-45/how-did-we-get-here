@tool
# character_base.gd
# A cute toy-like person made only from Godot's built-in shapes (no model files).
# Change the numbers in the Inspector and the person rebuilds itself.
#
# The nodes (all inside "Rig", which sits on the floor):
#   Rig            the whole person. Squash Rig's Y scale to make the person crouch.
#   Rig/Head       the head with the jaw. Turn Head's Y rotation to look around.
#   Rig/Head/LidHinge/Lid   the top of the head. It hinges at the BACK and flips
#                  open when the person talks. Eyes, brows, hair and hats are on it.
#   Rig/ArmL, Rig/ArmR      the two arms. Turn ArmR to point.
# The person faces forward (the -Z direction).
extends Node3D

@export var height: float = 1.8:
	set(v):
		height = v
		_queue_rebuild()
@export var top_width: float = 0.5:
	set(v):
		top_width = v
		_queue_rebuild()
@export var bottom_width: float = 0.5:
	set(v):
		bottom_width = v
		_queue_rebuild()
@export var skin_color: Color = Color(0.93, 0.74, 0.6):
	set(v):
		skin_color = v
		_queue_rebuild()
@export var body_color: Color = Color(0.6, 0.65, 0.75):
	set(v):
		body_color = v
		_queue_rebuild()
# How far the lid flips open when talking (radians) and how long one flap takes.
@export var mouth_open_angle: float = 0.5
@export var talk_flap_seconds: float = 0.2
# Idle bobbing: the person moves up and down a tiny bit so they look alive.
# Turn it off with idle_bob. It only moves Rig's position and sway, so it does
# not fight the animation tracks (Rig scale for crouching, Head turns, arms).
@export var idle_bob: bool = true
@export var bob_height: float = 0.012
@export var bob_speed: float = 2.2

# Art numbers (shape proportions). They are looks, not game numbers.
const LEG_FRACTION := 0.18      # legs are this part of the height
const DOME_FRACTION := 0.8      # head dome height compared to its radius
const JAW_FRACTION := 0.35      # jaw height compared to the head radius
const BOTTOM_CAP_FRACTION := 0.4

var top_r: float
var bottom_r: float
var dome_h: float
var jaw_h: float
var arm_len: float
var arm_r: float

var _talk_tween: Tween
var _point_tween: Tween
var _rebuild_queued := false
var _bob_time := 0.0
var _bob_phase := 0.0

@onready var rig: Node3D = $Rig
@onready var head: Node3D = $Rig/Head
@onready var lid_hinge: Node3D = $Rig/Head/LidHinge
@onready var lid: Node3D = $Rig/Head/LidHinge/Lid
@onready var arm_l: Node3D = $Rig/ArmL
@onready var arm_r_node: Node3D = $Rig/ArmR


func _ready() -> void:
	_bob_phase = randf() * TAU   # each person bobs at a different moment
	_rebuild()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not idle_bob:
		rig.position.y = 0.0
		rig.rotation.z = 0.0
		return
	_bob_time += delta
	var wave := _bob_time * bob_speed + _bob_phase
	rig.position.y = (sin(wave) * 0.5 + 0.5) * bob_height
	rig.rotation.z = sin(wave * 0.5) * 0.012


func _queue_rebuild() -> void:
	if not is_node_ready() or _rebuild_queued:
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


# ---------- public jobs ----------

# Flip the lid open and closed quickly for "seconds", then stay closed.
func talk(seconds: float) -> void:
	if _talk_tween:
		_talk_tween.kill()
	var flaps := maxi(1, int(seconds / talk_flap_seconds))
	_talk_tween = create_tween()
	for i in flaps:
		# a little variety so it does not look like a machine
		var open := mouth_open_angle * (0.65 + 0.35 * float((i * 3) % 4) / 3.0)
		_talk_tween.tween_property(lid_hinge, "rotation:x", open, talk_flap_seconds * 0.45)
		_talk_tween.tween_property(lid_hinge, "rotation:x", 0.0, talk_flap_seconds * 0.55)
	_talk_tween.tween_callback(func() -> void: lid_hinge.rotation.x = 0.0)


# Lift the right arm and point it forward (the person should face the camera).
func point_at_camera() -> void:
	if _point_tween:
		_point_tween.kill()
	_point_tween = create_tween()
	_point_tween.tween_property(arm_r_node, "rotation", Vector3(1.5, 0.0, 0.0), 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func lower_arm() -> void:
	if _point_tween:
		_point_tween.kill()
	_point_tween = create_tween()
	_point_tween.tween_property(arm_r_node, "rotation", Vector3(0.0, 0.0, _arm_tilt), 0.3)


# ---------- building the shapes ----------

var _arm_tilt := 0.15


func _rebuild() -> void:
	_rebuild_queued = false
	for n: Node3D in [rig, head, lid_hinge, lid, arm_l, arm_r_node]:
		_clear(n)
	lid_hinge.rotation = Vector3.ZERO
	top_r = top_width * 0.5
	bottom_r = bottom_width * 0.5
	dome_h = top_r * DOME_FRACTION
	jaw_h = top_r * JAW_FRACTION
	arm_r = 0.035 * height + 0.01
	arm_len = 0.2 * height

	var skin := _color_material(skin_color)
	var cloth := _color_material(body_color)
	var shoe: Material = load("res://materials/char_shoe.tres")
	var dark: Material = load("res://materials/char_mouth_dark.tres")

	# --- body: a tapered tube with a rounded bottom ---
	var leg_h := LEG_FRACTION * height
	var cap_h := BOTTOM_CAP_FRACTION * bottom_r
	var head_base_y := height - dome_h - jaw_h
	var tube_bottom := leg_h + cap_h
	var tube_h := maxf(head_base_y - tube_bottom, 0.1)
	var tube := CylinderMesh.new()
	tube.top_radius = top_r
	tube.bottom_radius = bottom_r
	tube.height = tube_h
	tube.radial_segments = 32
	tube.rings = 1
	_add(rig, tube, cloth, Vector3(0, tube_bottom + tube_h * 0.5, 0))
	var cap := SphereMesh.new()
	cap.radius = bottom_r
	cap.height = bottom_r
	cap.is_hemisphere = true
	cap.radial_segments = 32
	cap.rings = 8
	_add(rig, cap, cloth, Vector3(0, tube_bottom, 0), Vector3(1, BOTTOM_CAP_FRACTION, 1), Vector3(PI, 0, 0))

	# --- legs and round shoes ---
	var leg_r := 0.045 * height + 0.01
	for side in [-1, 1]:
		var x: float = side * bottom_r * 0.45
		var leg := CapsuleMesh.new()
		leg.radius = leg_r
		leg.height = leg_h * 1.1
		_add(rig, leg, cloth, Vector3(x, leg_h * 0.5 + 0.03, 0))
		var shoe_mesh := SphereMesh.new()
		shoe_mesh.radius = leg_r * 1.35
		shoe_mesh.height = leg_r * 2.7
		_add(rig, shoe_mesh, shoe, Vector3(x, leg_r * 0.8, -leg_r * 0.7), Vector3(1, 0.6, 1.5))

	# --- arms: small capsules with round hands ---
	var shoulder_y := head_base_y - arm_r * 1.6
	var t := inverse_lerp(tube_bottom, head_base_y, shoulder_y)
	var r_shoulder := lerpf(bottom_r, top_r, t)
	var r_tip := lerpf(bottom_r, top_r, inverse_lerp(tube_bottom, head_base_y, shoulder_y - arm_len))
	var shoulder_x := r_shoulder + arm_r * 0.4
	_arm_tilt = clampf(atan2(r_tip + arm_r * 1.6 - shoulder_x, arm_len), 0.12, 0.9)
	for pair in [[arm_l, -1], [arm_r_node, 1]]:
		var arm: Node3D = pair[0]
		var s: int = pair[1]
		arm.position = Vector3(s * shoulder_x, shoulder_y, 0)
		arm.rotation = Vector3(0, 0, s * _arm_tilt)
		var capsule := CapsuleMesh.new()
		capsule.radius = arm_r
		capsule.height = arm_len
		_add(arm, capsule, cloth, Vector3(0, -arm_len * 0.5, 0))
		var hand := SphereMesh.new()
		hand.radius = arm_r * 1.4
		hand.height = arm_r * 2.8
		_add(arm, hand, skin, Vector3(0, -arm_len - arm_r * 0.3, 0))

	# --- head: jaw (stays), dark mouth, then the lid on a back hinge ---
	head.position = Vector3(0, head_base_y, 0)
	var jaw := CylinderMesh.new()
	jaw.top_radius = top_r
	jaw.bottom_radius = top_r
	jaw.height = jaw_h
	jaw.radial_segments = 32
	jaw.rings = 1
	_add(head, jaw, skin, Vector3(0, jaw_h * 0.5, 0))
	var mouth := CylinderMesh.new()
	mouth.top_radius = top_r * 1.01
	mouth.bottom_radius = top_r * 1.01
	mouth.height = 0.03
	mouth.radial_segments = 32
	mouth.rings = 1
	_add(head, mouth, dark, Vector3(0, jaw_h - 0.014, 0))
	lid_hinge.position = Vector3(0, jaw_h, top_r)
	lid.position = Vector3(0, 0, -top_r)
	var dome := SphereMesh.new()
	dome.radius = top_r
	dome.height = top_r
	dome.is_hemisphere = true
	dome.radial_segments = 32
	dome.rings = 12
	_add(lid, dome, skin, Vector3.ZERO, Vector3(1, DOME_FRACTION, 1))
	var underside := CylinderMesh.new()
	underside.top_radius = top_r * 0.99
	underside.bottom_radius = top_r * 0.99
	underside.height = 0.02
	underside.radial_segments = 32
	underside.rings = 1
	_add(lid, underside, dark, Vector3(0, -0.004, 0))

	# --- face: black oval eyes and thin brows on the lid ---
	var eye_mat: Material = load("res://materials/char_eye_black.tres")
	for side in [-1, 1]:
		var eye := SphereMesh.new()
		eye.radius = 1.0
		eye.height = 2.0
		eye.radial_segments = 16
		eye.rings = 8
		var eye_basis := dome_basis(side * 0.36, 0.42)
		var eye_node := _add(lid, eye, eye_mat, dome_point(side * 0.36, 0.42, 0.0))
		eye_node.basis = eye_basis * Basis.from_scale(Vector3(0.12, 0.19, 0.07) * top_r)
		var brow := BoxMesh.new()
		brow.size = Vector3(0.3, 0.05, 0.04) * top_r
		var brow_node := _add(lid, brow, eye_mat, dome_point(side * 0.38, 0.62, 0.01))
		brow_node.basis = dome_basis(side * 0.38, 0.62) * Basis(Vector3.BACK, side * -0.2)

	_build_extras()


# Subclasses (General, Janitor, ...) add their mustache, hair or hat here.
func _build_extras() -> void:
	pass


# ---------- helpers for the shapes ----------

# A point on the dome surface. xf is across the face (-1 left .. 1 right),
# yf is up the dome (0 mouth line .. 1 top). "out" pushes the point outward.
func dome_point(xf: float, yf: float, out: float = 0.0) -> Vector3:
	var z := -sqrt(maxf(0.0, 1.0 - xf * xf - yf * yf))
	var p := Vector3(xf * top_r, yf * dome_h, z * top_r)
	return p + dome_normal(xf, yf) * out


func dome_normal(xf: float, yf: float) -> Vector3:
	var z := -sqrt(maxf(0.0, 1.0 - xf * xf - yf * yf))
	var n := Vector3(xf / top_r, yf / dome_h, z / top_r)
	return n.normalized()


# A rotation whose front (-Z) points straight out of the dome at that spot.
func dome_basis(xf: float, yf: float) -> Basis:
	var n := dome_normal(xf, yf)
	var up := Vector3.UP if absf(n.y) < 0.95 else Vector3.BACK
	return Basis.looking_at(n, up)


# Two gray mustache halves just above the mouth line (they ride on the lid).
# "size" 1.0 is normal; 1.5 is large and droopy.
func add_mustache(size: float) -> void:
	var mat: Material = load("res://materials/char_mustache_gray.tres")
	for side in [-1, 1]:
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = 16
		m.rings = 8
		var node := _add(lid, m, mat, dome_point(side * 0.3 * size, 0.17, 0.0))
		node.basis = dome_basis(side * 0.3 * size, 0.17) \
			* Basis(Vector3.BACK, side * 0.35 * size) \
			* Basis.from_scale(Vector3(0.42, 0.14 * size, 0.14) * top_r * Vector3(size, 1, 1))


# Add one shape under a parent. Remembers it so a rebuild can delete it.
func add_shape(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO,
		scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	return _add(parent, mesh, material, pos, scl, rot)


func _add(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO,
		scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.set_meta("gen", true)
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	return mi


func _clear(node: Node3D) -> void:
	for child in node.get_children():
		if child.has_meta("gen"):
			node.remove_child(child)
			child.queue_free()


func _color_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m
