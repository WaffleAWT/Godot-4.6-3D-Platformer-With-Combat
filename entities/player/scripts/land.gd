extends State

var _player: Player
var _finished: bool = false

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_player.buffer_jump()

func physics_update(delta: float) -> void:
	var wish: Vector3 = _player.get_wish_dir()
	
	_player.do_ground_movement(wish, delta)
	_player.do_move_and_slide()
	
	_player.update_graphics_facing(delta)
	_player.update_surface_alignment(delta)
	
	if not _player.is_on_floor():
		_player.start_coyote()
		state_machine.transition_to("Fall")
		return
	
	if _player.is_jump_buffered():
		state_machine.transition_to("Jump")
		return
	
	if wish.length_squared() > 0.0:
		state_machine.transition_to("Move")
		return
	
	if not _finished:
		return
	
	state_machine.transition_to("Idle")

func enter(_msg: Dictionary = {}) -> void:
	_player = actor as Player
	_finished = false
	
	_player.shadow.hide()
	_player.reset_jumps()
	_player.stop_coyote()
	_player.clear_jump_buffer()
	_player.on_landed(_player.get_surface_normal())
	_player.animator.play("locomotion/land", 0.2, 3.0)
	_player.animator.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)

func exit() -> void:
	if _player != null and _player.animator.animation_finished.is_connected(_on_anim_finished):
		_player.animator.animation_finished.disconnect(_on_anim_finished)

func _on_anim_finished(_name: StringName) -> void:
	_finished = true
