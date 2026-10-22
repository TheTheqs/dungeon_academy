class_name GameApi
extends RefCounted

var _data_gateway: DataGateway

func _init(data_gateway: DataGateway) -> void:
	assert(data_gateway != null and data_gateway.is_ready, "GameApi requires a loaded DataGateway.")
	_data_gateway = data_gateway

func get_player_character() -> String:
	var profile := _data_gateway.get_character(0)
	if profile == null:
		push_error("Character profile 0 is missing.")
		return ""
	return profile.textures[0]

func get_enemy_character() -> String:
	# Temporary animation preview. There is no enemy record in characters.json yet.
	return "wingpink"
