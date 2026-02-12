extends State

var _player: Player

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_player.buffer_jump()
	if event.is_action_released("jump"):
		_player.apply_jump_cut_if_needed()

func physics_update(delta: float) -> void:
	var wish: Vector3 = _player.get_wish_dir()
	
	_player.apply_air_gravity(delta)
	_player.do_air_movement(wish, delta)
	_player.do_move_and_slide()
	
	_player.update_graphics_facing(delta)
	_player.update_surface_alignment(delta)
	
	if _player.is_on_floor():
		state_machine.transition_to("Land")
		return
	
	if _player.is_jump_buffered():
		if _player.has_coyote():
			state_machine.transition_to("Jump")
			return
		if _player.can_air_jump():
			state_machine.transition_to("Jump", {"double": true})
			return

func enter(_msg: Dictionary = {}) -> void:
	_player = actor as Player
	_player.shadow.show()
	_player.animator.play("locomotion/air", 0.2, 2.0)

func exit() -> void:
	pass
