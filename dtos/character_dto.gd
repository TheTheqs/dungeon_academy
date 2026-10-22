extends RefCounted

class_name CharacterDto

var runtime_id: String
var character_name: String
var state: RuntimeCharacter.CharacterState
var position: MapPositionDto
var textures: Array[String] = []

func _init(nruntime_id: String, nname: String, nstate: RuntimeCharacter.CharacterState, nposition: MapPositionDto, ntextures: Array[String] = []) -> void:
	runtime_id = nruntime_id
	character_name = nname
	state = nstate
	position = nposition
	textures.assign(ntextures)
