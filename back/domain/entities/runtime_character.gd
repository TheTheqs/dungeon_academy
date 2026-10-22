class_name RuntimeCharacter
extends RefCounted

enum CharacterState { IDLE, WALKING }

var runtime_id: String
# Private-to-this-runtime copy of the static definition, never repository storage.
var character_profile: CharacterProfile
var state: CharacterState = CharacterState.IDLE
var position: MapPosition = MapPosition.new()
var path: Array[Cell] = []
var next_cell_index: int = 0

func _init(nruntime_id: String = "", profile: CharacterProfile = null) -> void:
	runtime_id = nruntime_id
	character_profile = profile.copy() if profile != null else null
