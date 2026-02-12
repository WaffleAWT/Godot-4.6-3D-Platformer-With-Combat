extends State

var _player: Player
var _is_double: bool = false
var _finished: bool = false

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
	
	if _player.is_jump_buffered() and _player.can_air_jump():
		state_machine.transition_to("Jump", {"double": true})
		return
	
	if not _finished:
		return
	
	if _player.velocity.y <= 0.0:
		state_machine.transition_to("Fall")
		return
	
	state_machine.transition_to("Air")

func enter(msg: Dictionary = {}) -> void:
	_player = actor as Player
	_finished = false
	_is_double = false
	
	if msg.has("double"):
		_is_double = msg["double"] as bool
	
	var grounded_or_coyote: bool = _player.is_on_floor() or _player.has_coyote()
	if grounded_or_coyote and not _is_double:
		_player.clear_jump_buffer()
		_player.stop_coyote()
		_player.use_ground_jump()
		_player.start_jump_hold()
		_player.do_jump()
		_player.play_stretch()
		_player.pop_jump_fov()
		_player.shadow.show()
		_player.animator.play("locomotion/jump", 0.2, 2.0)
		_player.animator.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	elif _player.can_air_jump():
		_player.clear_jump_buffer()
		_player.use_air_jump()
		_player.start_jump_hold()
		_player.do_jump()
		_player.play_stretch()
		_player.pop_jump_fov()
		_player.shadow.show()
		_player.animator.play("locomotion/double_jump", 0.2, 2.0)
		_player.animator.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	else:
		state_machine.transition_to("Fall")

func exit() -> void:
	if _player != null and _player.animator.animation_finished.is_connected(_on_anim_finished):
		_player.animator.animation_finished.disconnect(_on_anim_finished)

func _on_anim_finished(_name: StringName) -> void:
	_finished = true
