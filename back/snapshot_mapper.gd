extends RefCounted

class_name SnapshotMapper

func character_to_dto(character: Character) -> CharacterDto:
	return CharacterDto.new(
		character.runtime_id,
		character.character_name,
		character.state,
		map_position_to_dto(character.position)
	)

func map_position_to_dto(map: MapPosition) -> MapPositionDto:
	return MapPositionDto.new(map.x, map.y)
