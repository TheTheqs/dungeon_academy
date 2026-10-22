class_name GameApi
extends RefCounted

var _data_gateway: DataGateway
var _runtime_id_generator := RuntimeIdGenerator.new()
var _snapshot_mapper := SnapshotMapper.new()
var _start_game_use_case: StartGameUseCase
var _game_state: GameState
var last_error: String = ""

func _init(data_gateway: DataGateway) -> void:
	assert(data_gateway != null and data_gateway.is_ready, "GameApi requires a loaded DataGateway.")
	_data_gateway = data_gateway
	_start_game_use_case = StartGameUseCase.new(data_gateway, _runtime_id_generator, GridCoordinates.new())

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

# Kept for the isolated Sprint 0 preview scene.
func get_player_character() -> String:
	var profile := _data_gateway.get_character(0)
	return profile.textures[0] if profile != null else ""

func get_enemy_character() -> String:
	return "wingpink"
