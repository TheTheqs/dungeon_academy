extends RefCounted

class_name CharacterDto

var runtime_id: String
var character_name: String
var state: Character.CharacterState
var position: MapPositionDto

func _init(nruntime_id: String, nname: String, nstate: Character.CharacterState, nposition: MapPositionDto) -> void:
	runtime_id = nruntime_id
	character_name = nname
	state = nstate
	position = nposition
