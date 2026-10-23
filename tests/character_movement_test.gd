extends SceneTree

var _checks := 0
var _failures := 0
var _coordinates := GridCoordinates.new()
var _movement := CharacterMovement.new(_coordinates)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)

func make_character(route: Array[Cell], row: int = 0, column: int = 0) -> RuntimeCharacter:
	var character := RuntimeCharacter.new("test", CharacterProfile.new(0,"test",2.0,["test"]))
	character.position = _coordinates.cell_to_center(Cell.new(row,column))
	character.begin_movement(route)
	return character

func run() -> void:
	var default_speed_character := make_character([Cell.new(0,0),Cell.new(0,1)])
	_movement.update(default_speed_character,0.1)
	check(default_speed_character.position.x == 16.0, "agility 2 yields 80 world units per second")
	var agility_one := make_character([Cell.new(0,0),Cell.new(0,1)])
	agility_one.character_profile.agility = 1.0
	_movement.update(agility_one,0.1)
	check(agility_one.position.x == 12.0, "agility 1 yields 40 world units per second")
	var horizontal: Array[Cell] = [Cell.new(0,0),Cell.new(0,1),Cell.new(0,2)]
	var character := make_character(horizontal)
	_movement.update(character,0.1)
	check(character.position.x == 16.0 and character.position.y == 8.0, "speed times delta advances 8 units")
	check(character.next_cell_index == 1 and character.state == RuntimeCharacter.CharacterState.WALKING, "origin skipped and segment remains active")
	_movement.update(character,0.1)
	check(character.position.x == 24.0 and character.next_cell_index == 2, "exact intermediate arrival")
	_movement.update(character,0.2)
	check(character.position.x == 40.0 and character.position.y == 8.0, "exact final arrival")
	check(character.state == RuntimeCharacter.CharacterState.IDLE and character.path.is_empty() and character.next_cell_index == 0, "completion clears route/index/state")
	_movement.update(character,1.0)
	check(character.position.x == 40.0, "idle does not move")

	character = make_character(horizontal)
	_movement.update(character,0.3)
	check(character.position.x == 32.0 and character.next_cell_index == 2, "leftover distance crosses a waypoint")
	_movement.update(character,100.0)
	check(character.position.x == 40.0 and character.state == RuntimeCharacter.CharacterState.IDLE, "large delta never overshoots destination")

	var diagonal: Array[Cell] = [Cell.new(0,0),Cell.new(1,1)]
	character = make_character(diagonal)
	_movement.update(character,0.1)
	var dx := character.position.x-8.0
	var dy := character.position.y-8.0
	check(absf(sqrt(dx*dx+dy*dy)-8.0)<0.000001, "diagonal speed is normalized")
	check(absf(dx-dy)<0.000001, "diagonal direction")
	_movement.update(character,1.0)
	check(character.position.x == 24.0 and character.position.y == 24.0 and character.state == RuntimeCharacter.CharacterState.IDLE, "diagonal arrival")

	var turning: Array[Cell] = [Cell.new(0,0),Cell.new(0,1),Cell.new(1,1),Cell.new(1,2),Cell.new(2,3)]
	var single := make_character(turning)
	var partitioned := make_character(turning)
	_movement.update(single,0.7)
	for i in range(70): _movement.update(partitioned,0.01)
	check(absf(single.position.x-partitioned.position.x)<0.000001 and absf(single.position.y-partitioned.position.y)<0.000001, "same elapsed time gives same position across frame partition")
	check(single.next_cell_index == partitioned.next_cell_index, "same route progress across frame partition")

	character = make_character([Cell.new(0,0),Cell.new(0,0),Cell.new(0,1)])
	_movement.update(character,0.2)
	check(character.position.x == 24.0 and character.state == RuntimeCharacter.CharacterState.IDLE, "coincident points do not divide by zero")
	character = make_character([Cell.new(0,0)])
	_movement.update(character,0.1)
	check(character.state == RuntimeCharacter.CharacterState.IDLE, "already at sole waypoint")

	for invalid_delta in [0.0,-1.0,NAN,INF]:
		character = make_character(horizontal)
		_movement.update(character,invalid_delta)
		check(character.position.x == 8.0 and character.path.size() == 3, "invalid elapsed time leaves intention unchanged")
	for invalid_speed in [0.0,-1.0,NAN,INF]:
		character = make_character(horizontal)
		character.character_profile.agility = invalid_speed / 40.0
		_movement.update(character,0.1)
		check(character.position.x == 8.0 and character.path.size() == 3, "invalid speed leaves intention unchanged")
	character = make_character(horizontal)
	_movement.update(null,0.1)
	check(character.position.x == 8.0, "null character ignored")
	for invalid_index in [-1,3,9]:
		character = make_character(horizontal)
		character.next_cell_index = invalid_index
		_movement.update(character,0.1)
		check(character.state == RuntimeCharacter.CharacterState.IDLE and character.path.is_empty() and character.next_cell_index == 0, "invalid progress stops safely")
	character = make_character(horizontal)
	character.path.clear()
	_movement.update(character,0.1)
	check(character.state == RuntimeCharacter.CharacterState.IDLE, "walking with empty route stops")

	# Real profiles/map/pathfinding, then consume the complete route without visuals.
	var gateway := DataGateway.new()
	check(gateway.load_all(), "real database")
	var api := GameApi.new(gateway,RuntimeIdGenerator.new(),SnapshotMapper.new(),_coordinates,PathfindingService.new(), CharacterMovement.new(GridCoordinates.new()))
	check(api.start_game(0,0) and api.move_character("1",MapPositionDto.new(152,216)), "real map route accepted")
	character = api._game_state.get_character("1")
	for i in range(1000):
		_movement.update(character,0.01)
		if character.state == RuntimeCharacter.CharacterState.IDLE: break
	check(character.state == RuntimeCharacter.CharacterState.IDLE and character.position.x == 152 and character.position.y == 216, "real route reaches requested cell center")
	var snapshot := api.get_game_state()
	check(snapshot.characters["1"].position.x == 152 and snapshot.characters["1"].state == RuntimeCharacter.CharacterState.IDLE, "snapshot reflects completed logical movement")
	print("RESULT: %d character movement checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
