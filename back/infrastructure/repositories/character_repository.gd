extends RefCounted

class_name CharacterRepository

var _by_id: Dictionary[int, CharacterProfile] = {}

func _init(profiles: Array[CharacterProfile] = []) -> void:
	for profile in profiles:
		assert(not _by_id.has(profile.id), "Duplicate character profile ID.")
		_by_id[profile.id] = profile.copy()

func get_by_id(id: int) -> CharacterProfile:
	var profile: CharacterProfile = _by_id.get(id)
	return profile.copy() if profile != null else null

func get_all() -> Array[CharacterProfile]:
	var result: Array[CharacterProfile] = []
	for profile: CharacterProfile in _by_id.values():
		result.append(profile.copy())
	return result

func has_id(id: int) -> bool:
	return _by_id.has(id)

func count() -> int:
	return _by_id.size()
