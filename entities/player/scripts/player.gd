class_name Player
extends CharacterBody3D

signal landed(normal: Vector3)

@export_group("Data")
@export var turn_speed: float = 14.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var max_jumps: int = 2
@export var surface_align_speed: float = 14.0
@export var surface_probe_distance: float = 1.35

@export_group("Jump Feel")
@export var jump_cut_multiplier: float = 0.45
@export var jump_hold_gravity_multiplier: float = 0.65
@export var jump_hold_time: float = 0.16

@export_group("Camera")
@export var jump_fov_boost: float = 6.0
@export var fov_in_time: float = 0.08
@export var fov_out_time: float = 0.12

@export_group("Squash & Stretch")
@export var squash_scale: Vector3 = Vector3(1.28, 0.78, 1.28)
@export var stretch_scale: Vector3 = Vector3(0.84, 1.20, 0.84)
@export var squash_time: float = 0.085
@export var stretch_time: float = 0.075
@export var return_time: float = 0.10

@export_group("Refrences")
@export var movement: MovementComponent
@export var camera_rig: CameraRig
@export var camera: Camera3D
@export var graphics: Node3D
@export var surface_ray: RayCast3D
@export var coyote_timer: Timer
@export var jump_buffer_timer: Timer
@export var vfx_landing_scene: PackedScene
@export var vfx_moving_trail: GPUParticles3D
@export var shadow: Decal
@export var animator: AnimationPlayer

var _jumps_left: int = 0
var _jump_hold_left: float = 0.0
var _coyote_active: bool = false
var _jump_buffered: bool = false
var _base_fov: float = 0.0
var _fov_tween: Tween
var _squash_tween: Tween

func _ready() -> void:
	_jumps_left = max_jumps
	
	coyote_timer.one_shot = true
	coyote_timer.wait_time = coyote_time
	if not coyote_timer.timeout.is_connected(_on_coyote_timeout):
		coyote_timer.timeout.connect(_on_coyote_timeout)
	
	jump_buffer_timer.one_shot = true
	jump_buffer_timer.wait_time = jump_buffer_time
	if not jump_buffer_timer.timeout.is_connected(_on_jump_buffer_timeout):
		jump_buffer_timer.timeout.connect(_on_jump_buffer_timeout)
	
	surface_ray.target_position = Vector3(0.0, -surface_probe_distance, 0.0)
	surface_ray.enabled = true
	
	_base_fov = camera.fov

func get_wish_dir() -> Vector3:
	var x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z: float = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")
	
	var input_dir: Vector3 = Vector3(x, 0.0, z)
	if input_dir.length_squared() == 0.0:
		return Vector3.ZERO
	
	input_dir = input_dir.normalized()
	var yaw_basis: Basis = camera_rig.get_yaw_basis()
	return (yaw_basis * input_dir).normalized()

func update_graphics_facing(delta: float) -> void:
	var planar: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if planar.length_squared() == 0.0:
		return
	
	var target_yaw: float = atan2(-planar.x, -planar.z)
	graphics.rotation.y = lerp_angle(graphics.rotation.y, target_yaw, turn_speed * delta)

func get_surface_normal() -> Vector3:
	if surface_ray.is_colliding():
		return (surface_ray.get_collision_normal() as Vector3).normalized()
	return Vector3.UP

func update_surface_alignment(delta: float) -> void:
	var target_normal: Vector3 = Vector3.UP
	var has_surface: bool = surface_ray.is_colliding()
	if has_surface:
		target_normal = (surface_ray.get_collision_normal() as Vector3).normalized()
	
	var forward: Vector3 = -graphics.global_transform.basis.z
	forward = forward - target_normal * forward.dot(target_normal)
	
	if forward.length_squared() < 0.0001:
		forward = -global_transform.basis.z
		forward = forward - target_normal * forward.dot(target_normal)
	
	if forward.length_squared() < 0.0001:
		return
	
	forward = forward.normalized()
	var right: Vector3 = forward.cross(target_normal).normalized()
	forward = target_normal.cross(right).normalized()
	
	var target_basis: Basis = Basis(right, target_normal, -forward).orthonormalized()
	var current_basis: Basis = graphics.global_transform.basis.orthonormalized()
	var t: float = clampf(surface_align_speed * delta, 0.0, 1.0)
	
	graphics.global_transform = Transform3D(
		current_basis.slerp(target_basis, t),
		graphics.global_transform.origin
	)

func buffer_jump() -> void:
	_jump_buffered = true
	jump_buffer_timer.wait_time = jump_buffer_time
	jump_buffer_timer.start()

func clear_jump_buffer() -> void:
	_jump_buffered = false
	if not jump_buffer_timer.is_stopped():
		jump_buffer_timer.stop()

func is_jump_buffered() -> bool:
	return _jump_buffered

func start_coyote() -> void:
	_coyote_active = true
	coyote_timer.wait_time = coyote_time
	coyote_timer.start()

func stop_coyote() -> void:
	_coyote_active = false
	if not coyote_timer.is_stopped():
		coyote_timer.stop()

func has_coyote() -> bool:
	return _coyote_active

func reset_jumps() -> void:
	_jumps_left = max_jumps

func use_ground_jump() -> void:
	_jumps_left = max_jumps - 1

func can_air_jump() -> bool:
	return _jumps_left > 0

func use_air_jump() -> void:
	_jumps_left -= 1

func start_jump_hold() -> void:
	_jump_hold_left = jump_hold_time

func apply_air_gravity(delta: float) -> void:
	var hold_mult: float = 1.0
	if _jump_hold_left > 0.0 and Input.is_action_pressed("jump") and velocity.y > 0.0:
		hold_mult = jump_hold_gravity_multiplier
		_jump_hold_left = maxf(_jump_hold_left - delta, 0.0)
	velocity = movement.apply_gravity_scaled(velocity, delta, hold_mult)

func apply_jump_cut_if_needed() -> void:
	if velocity.y > 0.0:
		velocity = movement.apply_jump_cut(velocity, jump_cut_multiplier)
	_jump_hold_left = 0.0

func do_ground_movement(wish: Vector3, delta: float) -> void:
	if wish.length_squared() > 0.0:
		velocity = movement.accelerate(velocity, wish, delta)
	else:
		velocity = movement.decelerate(velocity, delta)

func do_air_movement(wish: Vector3, delta: float) -> void:
	if wish.length_squared() > 0.0:
		velocity = movement.accelerate(velocity, wish, delta)

func do_jump() -> void:
	velocity = movement.apply_jump(velocity)

func do_move_and_slide() -> void:
	move_and_slide()

func on_landed(normal: Vector3) -> void:
	emit_signal("landed", normal)
	play_squash()
	pop_fov(_base_fov, fov_out_time)
	
	var vfx_landing: Node = vfx_landing_scene.instantiate()
	add_child(vfx_landing)
	if vfx_landing is Node3D:
		var fx: Node3D = vfx_landing as Node3D
		fx.global_transform.origin = global_transform.origin

func play_squash() -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	
	_squash_tween = create_tween()
	_squash_tween.tween_property(graphics, "scale", squash_scale, squash_time)
	_squash_tween.tween_property(graphics, "scale", Vector3.ONE, return_time)

func play_stretch() -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	
	_squash_tween = create_tween()
	_squash_tween.tween_property(graphics, "scale", stretch_scale, stretch_time)
	_squash_tween.tween_property(graphics, "scale", Vector3.ONE, return_time)

func pop_fov(target_fov: float, time: float) -> void:
	if _fov_tween != null and _fov_tween.is_valid():
		_fov_tween.kill()

	_fov_tween = create_tween()
	_fov_tween.tween_property(camera, "fov", target_fov, time)

func pop_jump_fov() -> void:
	pop_fov(_base_fov + jump_fov_boost, fov_in_time)

func restore_fov() -> void:
	pop_fov(_base_fov, fov_out_time)

func _on_coyote_timeout() -> void:
	_coyote_active = false

func _on_jump_buffer_timeout() -> void:
	_jump_buffered = false
