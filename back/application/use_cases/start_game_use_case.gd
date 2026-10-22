class_name StartGameUseCase
extends RefCounted

var last_error: String = ""
var _gateway: DataGateway
var _ids: RuntimeIdGenerator
var _coordinates: GridCoordinates

func _init(gateway: DataGateway, ids: RuntimeIdGenerator, coordinates: GridCoordinates) -> void:
	_gateway = gateway
	_ids = ids
	_coordinates = coordinates

func execute(character_id: int, map_id: int) -> GameState:
	last_error = ""
	var character_profile := _gateway.get_character(character_id)
	var map_profile := _gateway.get_map(map_id)
	if character_profile == null or map_profile == null:
		last_error = "Character or map profile not found."
		return null
	var map := RuntimeMap.from_profile(map_profile)
	# Temporary explicit spawn for the MVP map; later belongs in map configuration.
	var spawn := Cell.new(8, 1)
	if not map.is_walkable(spawn):
		last_error = "Initial cell (8, 1) is not walkable in this map."
		return null
	var character := RuntimeCharacter.new(_ids.generate_id(), character_profile)
	character.position = _coordinates.cell_to_center(spawn)
	character.state = RuntimeCharacter.CharacterState.IDLE
	return GameState.new({character.runtime_id: character}, map)
