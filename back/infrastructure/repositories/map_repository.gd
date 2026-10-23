extends RefCounted

class_name MapRepository

var _by_id: Dictionary[int, MapProfile] = {}

func _init(profiles: Array[MapProfile] = []) -> void:
	for profile in profiles:
		assert(not _by_id.has(profile.id), "Duplicate map profile ID.")
		_by_id[profile.id] = profile.copy()

func get_by_id(id: int) -> MapProfile:
	var profile: MapProfile = _by_id.get(id)
	return profile.copy() if profile != null else null

func get_all() -> Array[MapProfile]:
	var result: Array[MapProfile] = []
	for profile: MapProfile in _by_id.values():
		result.append(profile.copy())
	return result

func has_id(id: int) -> bool:
	return _by_id.has(id)

func count() -> int:
	return _by_id.size()
