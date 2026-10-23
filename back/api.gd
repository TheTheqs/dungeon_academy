extends RefCounted

class_name GameApi

# Services
var _runtime_id_generator: RuntimeIdGenerator
var _snapshot_mapper: SnapshotMapper
var _coordinates: GridCoordinates
var _pathfinding_service: PathfindingService
#Use cases
var _move_character_use_case: MoveCharacterUseCase
var _start_game_use_case: StartGameUseCase
var _step_game_use_case: StepGameUseCase
# States
var _game_state: GameState
var last_error: String = ""

func _init(data_gateway: DataGateway, runtime_id_generator: RuntimeIdGenerator, snapshot_mapper: SnapshotMapper, coordinates: GridCoordinates, pathfinding_service: PathfindingService, character_movement: CharacterMovement) -> void:
	assert(data_gateway != null and data_gateway.is_ready, "GameApi requires a loaded DataGateway.")
	_step_game_use_case = StepGameUseCase.new(character_movement, snapshot_mapper)
	_runtime_id_generator = runtime_id_generator
	_snapshot_mapper = snapshot_mapper
	_coordinates = coordinates
	_pathfinding_service = pathfinding_service
	
	_move_character_use_case = MoveCharacterUseCase.new(_pathfinding_service, _coordinates)
	_start_game_use_case = StartGameUseCase.new(data_gateway, _runtime_id_generator, _coordinates)

func start_game(character_id: int, map_profile_id: int) -> bool:
	var next_state := _start_game_use_case.execute(character_id, map_profile_id)
	last_error = _start_game_use_case.last_error
	if next_state == null:
		return false
	_game_state = next_state
	return true

func get_game_state() -> GameStateDto:
	if _game_state == null:
		last_error = "Start a game before requesting its snapshot."
		return null
	last_error = ""
	return _snapshot_mapper.game_state_to_dto(_game_state)

func move_character(runtime_character_id: String, goal_position_dto: MapPositionDto) -> bool:
	if _game_state == null:
		last_error = "Start a game before trying to move a character"
		return false
	if goal_position_dto == null or not is_finite(goal_position_dto.x) or not is_finite(goal_position_dto.y):
		last_error = "Map position must contain finite x and y coordinates."
		return false
	last_error = ""
	var goal_position := MapPosition.new()
	goal_position.x = goal_position_dto.x
	goal_position.y = goal_position_dto.y
	
	var accepted := _move_character_use_case.execute(runtime_character_id, goal_position, _game_state)
	last_error = _move_character_use_case.last_error
	return accepted

## Advances exactly one fixed logical tick and returns its resulting snapshot.
func step_game() -> GameStateDto:
	if _game_state == null:
		last_error = "Start a game before advancing the simulation."
		return null
	last_error = ""
	return _step_game_use_case.execute(_game_state)
