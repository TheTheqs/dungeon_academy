extends RefCounted
class_name MoveCharacterUseCase

var last_error: String = ""
var _pathfinding_service: PathfindingService
var _coordinates: GridCoordinates

func _init(pathfinding_service: PathfindingService, coordinates: GridCoordinates) -> void:
	_pathfinding_service = pathfinding_service
	_coordinates = coordinates

func execute(runtime_character_id: String, goal_position: MapPosition, game_state: GameState) -> bool:
	last_error = ""
	if game_state == null or game_state.current_map == null:
		return _fail("Start a game before trying to move a character.")
	if goal_position == null or not is_finite(goal_position.x) or not is_finite(goal_position.y):
		return _fail("Map position must contain finite x and y coordinates.")
	var character := game_state.get_character(runtime_character_id)
	if character == null:
		return _fail("There is no character for the provided runtime ID.")
	var start := _coordinates.position_to_cell(character.position)
	var goal := _coordinates.position_to_cell(goal_position)
	var path := _pathfinding_service.find_path(start, goal, game_state.current_map)
	if path.is_empty():
		return _fail("No valid path to the destination.")

	# Skip only centers already reached. Do not blindly skip the origin cell:
	# a future moving character may be between cell centers when rerouted.
	var next_index := 0
	while next_index < path.size():
		var center := _coordinates.cell_to_center(path[next_index])
		if absf(center.x - character.position.x) > 0.000001 or absf(center.y - character.position.y) > 0.000001:
			break
		next_index += 1
	if not character.begin_movement(path, next_index):
		return _fail("Invalid movement path.")
	return true

func _fail(message: String) -> bool:
	last_error = message
	return false
