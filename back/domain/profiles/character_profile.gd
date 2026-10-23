extends RefCounted

class_name CharacterProfile

var id: int
var character_name: String
var agility: float
var textures: Array[String] = []

func _init(nid: int, nname: String, nagility: float, ntextures: Array[String]) -> void:
	id = nid
	character_name = nname
	agility = nagility
	textures.assign(ntextures)

## An independent value for repository consumers, including nested collections.
func copy() -> CharacterProfile:
	return CharacterProfile.new(id, character_name, agility, textures)
