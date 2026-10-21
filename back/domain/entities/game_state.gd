extends RefCounted

class_name GameState

var characters: Dictionary = {}
var current_map: Map

func _init(ncharacters: Dictionary, nmap: Map) -> void:
	current_map = nmap
	for key in ncharacters.keys():
		characters[key] = ncharacters[key]

func get_character(runtime_id: String) -> Character:
	if characters.has(runtime_id):
		return characters[runtime_id] as Character
	return null
