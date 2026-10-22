class_name DataGateway
extends RefCounted

var _characters := CharacterRepository.new()
var _maps := MapRepository.new()
var _is_ready: bool = false
var _last_error: String = ""

# Repositories expose queries only. Their queries also return defensive copies.
var characters: CharacterRepository:
	get: return _characters
var maps: MapRepository:
	get: return _maps
var is_ready: bool:
	get: return _is_ready
var last_error: String:
	get: return _last_error

## Load once before constructing consumers. Publish only after ALL files pass.
func load_all(characters_path: String = "res://assets/data/characters.json", maps_path: String = "res://assets/data/maps.json") -> bool:
	if _is_ready: return true
	_last_error = ""
	var loader := GameDataLoader.new()
	var character_records := loader.read_records(characters_path)
	if not loader.error_message.is_empty(): return _fail(loader.error_message)
	var character_profiles := loader.map_characters(character_records)
	if not loader.error_message.is_empty(): return _fail(loader.error_message)
	var map_records := loader.read_records(maps_path)
	if not loader.error_message.is_empty(): return _fail(loader.error_message)
	var map_profiles := loader.map_maps(map_records)
	if not loader.error_message.is_empty(): return _fail(loader.error_message)
	# Future inter-profile reference resolution belongs before publication here.
	var character_repository := CharacterRepository.new(character_profiles)
	var map_repository := MapRepository.new(map_profiles)
	_characters = character_repository
	_maps = map_repository
	_is_ready = true
	return true

func get_character(id: int) -> CharacterProfile:
	return _characters.get_by_id(id)

func get_map(id: int) -> MapProfile:
	return _maps.get_by_id(id)

func _fail(message: String) -> bool:
	_last_error = message
	return false
