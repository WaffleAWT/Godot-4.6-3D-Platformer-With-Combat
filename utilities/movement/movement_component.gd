class_name MovementComponent
extends Node

@export_group("Movement")
@export var max_speed: float = 7.4
@export var acceleration: float = 24.0
@export var deceleration: float = 18.0

@export_group("Gravity")
@export var normal_gravity: float = 1.60
@export var fall_gravity_multiplier: float = 1.75
@export var max_fall_speed: float = 45.0

@export_group("Jump")
@export var jump_velocity: float = 5.7

@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") as float) * normal_gravity

func accelerate(velocity: Vector3, wish_dir: Vector3, delta: float) -> Vector3:
	var target: Vector3 = wish_dir * max_speed
	var current_h: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target_h: Vector3 = Vector3(target.x, 0.0, target.z)
	var next_h: Vector3 = current_h.move_toward(target_h, acceleration * delta)
	return Vector3(next_h.x, velocity.y, next_h.z)

func decelerate(velocity: Vector3, delta: float) -> Vector3:
	var current_h: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var next_h: Vector3 = current_h.move_toward(Vector3.ZERO, deceleration * delta)
	return Vector3(next_h.x, velocity.y, next_h.z)

func apply_gravity(velocity: Vector3, delta: float) -> Vector3:
	return apply_gravity_scaled(velocity, delta, 1.0)

func apply_gravity_scaled(velocity: Vector3, delta: float, gravity_multiplier: float) -> Vector3:
	var g: float = gravity * gravity_multiplier
	if velocity.y < 0.0:
		g *= fall_gravity_multiplier
	
	var next_y: float = velocity.y - g * delta
	if next_y < -max_fall_speed:
		next_y = -max_fall_speed
	
	return Vector3(velocity.x, next_y, velocity.z)

func apply_jump(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, jump_velocity, velocity.z)

func apply_jump_cut(velocity: Vector3, cut_multiplier: float) -> Vector3:
	if velocity.y <= 0.0:
		return velocity
	return Vector3(velocity.x, velocity.y * cut_multiplier, velocity.z)
