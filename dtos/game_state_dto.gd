class_name GameStateDto
extends RefCounted

var characters: Dictionary[String, CharacterDto] = {}
var current_map: MapDto

func _init(ncharacters: Dictionary[String, CharacterDto], nmap: MapDto) -> void:
	current_map = nmap
	for runtime_id in ncharacters:
		characters[runtime_id] = ncharacters[runtime_id]
