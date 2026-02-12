extends Node3D

func _input(event: InputEvent) -> void:
	if event is InputEventKey and Input.is_action_just_pressed("escape"):
		get_tree().quit()
