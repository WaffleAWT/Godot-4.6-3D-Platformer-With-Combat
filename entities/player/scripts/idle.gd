extends State

var _player: Player

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_player.buffer_jump()

func physics_update(delta: float) -> void:
	var wish: Vector3 = _player.get_wish_dir()
	
	_player.do_ground_movement(wish, delta)
	_player.do_move_and_slide()
	
	_player.update_graphics_facing(delta)
	_player.update_surface_alignment(delta)
	
	if _player.is_jump_buffered():
		state_machine.transition_to("Jump")
		return
	
	if not _player.is_on_floor():
		_player.start_coyote()
		state_machine.transition_to("Fall")
		return
	
	if wish.length_squared() > 0.0:
		state_machine.transition_to("Move")
		return

func enter(_msg: Dictionary = {}) -> void:
	_player = actor as Player
	_player.shadow.hide()
	_player.animator.play("locomotion/idle", 0.2, 1.0)

func exit() -> void:
	pass
