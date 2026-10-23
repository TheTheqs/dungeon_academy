extends RefCounted

class_name GameState

var characters: Dictionary[String, RuntimeCharacter] = {}
var current_map: RuntimeMap

func _init(ncharacters: Dictionary, nmap: RuntimeMap) -> void:
	current_map = nmap
	for key in ncharacters.keys():
		characters[key] = ncharacters[key]

func get_character(runtime_id: String) -> RuntimeCharacter:
	return characters.get(runtime_id)
