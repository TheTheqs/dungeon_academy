class_name SnapshotMapper
extends RefCounted

## Builds fresh DTOs; neither entities nor profile collections escape the back.
func game_state_to_dto(game_state: GameState) -> GameStateDto:
	assert(game_state != null, "A snapshot requires an initialized GameState.")
	var characters: Dictionary[String, CharacterDto] = {}
	for runtime_id in game_state.characters:
		characters[runtime_id] = character_to_dto(game_state.characters[runtime_id])
	return GameStateDto.new(characters, map_to_dto(game_state.current_map))

func map_to_dto(map: RuntimeMap) -> MapDto:
	assert(map != null and map.map_profile != null, "RuntimeMap requires a map profile for presentation.")
	var profile := map.map_profile
	return MapDto.new(profile.id, profile.map_name, map.rows, map.columns, profile.textures)

func character_to_dto(character: RuntimeCharacter) -> CharacterDto:
	assert(character != null and character.character_profile != null, "RuntimeCharacter requires a character profile.")
	return CharacterDto.new(
		character.runtime_id,
		character.character_profile.character_name,
		character.state,
		map_position_to_dto(character.position),
		character.character_profile.textures
	)

func map_position_to_dto(position: MapPosition) -> MapPositionDto:
	assert(position != null, "A position snapshot requires MapPosition.")
	return MapPositionDto.new(position.x, position.y)
