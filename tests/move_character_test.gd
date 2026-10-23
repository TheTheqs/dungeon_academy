extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var gateway := DataGateway.new()
	check(gateway.load_all(), "load database")
	var api := GameApi.new(gateway,RuntimeIdGenerator.new(),SnapshotMapper.new(),GridCoordinates.new(),PathfindingService.new(), CharacterMovement.new(GridCoordinates.new()))
	check(not api.move_character("1",MapPositionDto.new(72,136)), "reject before start")
	check(api.start_game(0,0), "start game")
	var character: RuntimeCharacter = api._game_state.get_character("1")
	check(api.move_character("1",MapPositionDto.new(72,136)), "accept valid path")
	check(character.state == RuntimeCharacter.CharacterState.WALKING and character.path.size() > 1, "route and walking committed together")
	check(character.next_cell_index == 1, "already reached origin center skipped")
	check(character.position.x == 24 and character.position.y == 136, "intention does not displace character")
	var keys: Array[String] = []
	for cell in character.path: keys.append(cell.get_key())
	for destination in [MapPositionDto.new(8,8),MapPositionDto.new(-1,136),MapPositionDto.new(232,136),MapPositionDto.new(NAN,0),null]:
		check(not api.move_character("1",destination), "invalid destination rejected")
		check(not api.last_error.is_empty(), "rejection diagnostic")
		var current_keys: Array[String] = []
		for cell in character.path: current_keys.append(cell.get_key())
		check(current_keys == keys and character.next_cell_index == 1 and character.state == RuntimeCharacter.CharacterState.WALKING, "rejection preserves old intention")
	check(not api.move_character("unknown",MapPositionDto.new(72,136)) and not api.last_error.is_empty(), "unknown ID propagated")
	check(api.move_character("1",MapPositionDto.new(24,136)), "own center accepted")
	check(character.state == RuntimeCharacter.CharacterState.IDLE and character.path.is_empty() and character.next_cell_index == 0, "own center stops pending intention")
	var route: Array[Cell] = [Cell.new(8,1),Cell.new(8,2)]
	check(character.begin_movement(route), "entity accepts route")
	route[1].row = 99
	check(character.path[1].row == 8, "cells are deep copied")
	check(character.begin_movement(character.path) and character.path.size() == 2, "self assignment safe")
	check(not character.begin_movement([]) and character.path.size() == 2, "empty assignment rejected atomically")
	var invalid: Array[Cell] = [Cell.new(8,1),null]
	check(not character.begin_movement(invalid) and character.path.size() == 2, "null cell rejected atomically")
	check(not character.begin_movement(route,99) and character.path.size() == 2, "invalid progress rejected")
	character.stop_movement()
	check(character.state == RuntimeCharacter.CharacterState.IDLE and character.next_cell_index == 0 and character.path.is_empty(), "stop resets all fields")
	# Same cell but not at its center still requires reaching that center.
	character.position.x = 25
	check(api.move_character("1",MapPositionDto.new(24,136)), "off-center position accepted")
	check(character.state == RuntimeCharacter.CharacterState.WALKING and character.next_cell_index == 0 and character.path.size() == 1, "off-center origin not blindly skipped")

	var screen = load("res://front/screens/game_screen.tscn").instantiate()
	screen.configure(api,TextureLoader.new(),"1")
	root.add_child(screen)
	for i in range(4): await process_frame
	var view = screen.entities.get_child(0)
	check(view.animation_player.current_animation == "run", "snapshot selects walking visual")
	await create_timer(0.7).timeout
	check(view.animation_player.current_animation == "run", "run loops without snapshot spam")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = screen.world.position + Vector2(72,136)
	screen._gui_input(click)
	check(screen.controlled_runtime_id == "1" and screen.last_move_error.is_empty(), "explicit controlled character")
	check(view.animation_player.current_animation == "run", "accepted click refreshes state")
	click.position = screen.world.position + Vector2(8,8)
	screen._gui_input(click)
	check(not screen.last_move_error.is_empty() and character.state == RuntimeCharacter.CharacterState.WALKING, "rejected click preserves walking and exposes message")
	character.position.x = 24
	click.position = screen.world.position + Vector2(24,136)
	screen._gui_input(click)
	check(view.animation_player.current_animation == "idle", "click current center refreshes idle")
	screen.queue_free()
	await process_frame
	print("RESULT: %d movement intention checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
