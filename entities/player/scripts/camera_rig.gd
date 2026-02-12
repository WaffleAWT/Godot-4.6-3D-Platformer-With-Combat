class_name CameraRig
extends Node3D

@export_group("Data")
@export var sensitivity: float = 0.0025
@export var min_pitch: float = deg_to_rad(-80.0)
@export var max_pitch: float = deg_to_rad(80.0)

@export_group("Refrences")
@export var pitch_pivot: Node3D

var _pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pitch = pitch_pivot.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		rotation.y -= mm.relative.x * sensitivity
		_pitch = clamp(_pitch - mm.relative.y * sensitivity, min_pitch, max_pitch)
		pitch_pivot.rotation.x = _pitch

func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, rotation.y)
