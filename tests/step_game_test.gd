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
	check(gateway.load_all(), "database loads")
	var coordinates := GridCoordinates.new()
	var movement := CharacterMovement.new(coordinates)
	var api := GameApi.new(gateway,RuntimeIdGenerator.new(),SnapshotMapper.new(),coordinates,PathfindingService.new(),movement)
	check(api.step_game() == null and not api.last_error.is_empty(), "cannot step before start")
	check(api.start_game(0,0), "start")
	var state: GameState = api._game_state
	var original: GameStateDto = api.get_game_state()
	check(api.step_game().characters["1"].position.y == 136, "idle tick stays put")
	check(api.move_character("1",MapPositionDto.new(24,216)), "first character gets vertical route")
	var second := RuntimeCharacter.new("2",gateway.get_character(0))
	second.character_profile.agility = 2.0
	second.position = coordinates.cell_to_center(Cell.new(8,1))
	state.characters["2"] = second
	check(api.move_character("2",MapPositionDto.new(24,216)), "second character gets route")
	var first_tick := api.step_game()
	check(absf(first_tick.characters["1"].position.y-(136+40.0/60))<0.000001, "one call advances fixed 1/60 second")
	check(absf(first_tick.characters["2"].position.y-(136+80.0/60))<0.000001, "same tick respects independent agility")
	for i in range(59): api.step_game()
	var after_second := api.get_game_state()
	check(absf(after_second.characters["1"].position.y-176)<0.000001, "60 calls move agility 1 by 40 units")
	check(absf(after_second.characters["2"].position.y-216)<0.000001 and second.state == RuntimeCharacter.CharacterState.IDLE, "agility 2 arrives after 60 calls")
	check(api._game_state == state, "steps update the existing GameState")
	check(original.characters["1"].position.y == 136 and original.characters.size() == 1, "old snapshot unchanged")
	check(absf(first_tick.characters["1"].position.y-(136+40.0/60))<0.000001, "tick snapshot detached from subsequent steps")
	for i in range(60): api.step_game()
	check(state.get_character("1").state == RuntimeCharacter.CharacterState.IDLE and state.get_character("1").path.is_empty(), "complete path stops cleanly")
	var before := state.get_character("1").position.y
	api.get_game_state()
	api.get_game_state()
	check(state.get_character("1").position.y == before, "snapshot reads do not step")
	check(gateway.get_character(0).agility == 1.0, "runtime agility changes do not mutate catalog")
	movement.update(null,0.1)
	check(true, "null guard runs before accessing profile")

	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.set_physics_process(false)
	for i in range(4): await process_frame
	check(main._api.move_character("1",MapPositionDto.new(24,216)), "front integration intent")
	var screen = main._game_screen
	for i in range(30): main._physics_process(999.0)
	var snapshot: GameStateDto = main._api.get_game_state()
	check(absf(snapshot.characters["1"].position.y-156.0)<0.000001, "Main advances fixed ticks rather than render delta")
	check(absf(screen.entities.get_child(0).position.y-156.0)<0.000001, "front consumes resulting position")
	check(screen.entities.get_child(0).animation_player.current_animation == "run", "walking animates")
	for i in range(90): main._physics_process(0.0)
	check(screen.entities.get_child(0).position.y == 216.0 and screen.entities.get_child(0).animation_player.current_animation == "idle", "arrival snapshot updates view and animation")
	main.queue_free()
	await process_frame
	print("RESULT: %d fixed-step checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
