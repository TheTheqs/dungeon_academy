class_name SnapshotMapper
extends RefCounted

func character_to_dto(character: RuntimeCharacter) -> CharacterDto:
	assert(character.character_profile != null, "RuntimeCharacter requires a character profile.")
	return CharacterDto.new(
		character.runtime_id,
		character.character_profile.character_name,
		character.state,
		map_position_to_dto(character.position)
	)

func map_position_to_dto(position: MapPosition) -> MapPositionDto:
	return MapPositionDto.new(position.x, position.y)
