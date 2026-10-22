extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var gateway := DataGateway.new()
	check(gateway.load_all(), "load real profiles")
	var first := RuntimeCharacter.new("1", gateway.get_character(0))
	first.position.x = 24.0
	first.position.y = 72.0
	first.state = RuntimeCharacter.CharacterState.WALKING
	var second := RuntimeCharacter.new("2", gateway.get_character(0))
	var map := RuntimeMap.from_profile(gateway.get_map(0))
	var state := GameState.new({"1": first, "2": second},map)
	var mapper := SnapshotMapper.new()
	var dto := mapper.game_state_to_dto(state)
	check(dto.characters.size() == 2 and dto.characters.has("1") and dto.characters.has("2"), "runtime IDs preserved")
	check(dto.characters["1"].character_name == "Swordman", "profile name")
	check(dto.characters["1"].state == RuntimeCharacter.CharacterState.WALKING, "state")
	check(dto.characters["1"].position.x == 24.0 and dto.characters["1"].position.y == 72.0, "position")
	check(dto.current_map.id == 0 and dto.current_map.map_name == "Map01", "map identity")
	check(dto.current_map.rows == 15 and dto.current_map.columns == 17, "map dimensions")
	check(dto.current_map.textures == ["map01_texture"], "map texture identifier")
	dto.characters["1"].position.x = 999.0
	dto.characters["1"].character_name = "changed"
	dto.characters["1"].state = RuntimeCharacter.CharacterState.IDLE
	dto.characters.erase("2")
	dto.current_map.textures[0] = "changed"
	dto.current_map.rows = 999
	check(first.position.x == 24.0 and first.state == RuntimeCharacter.CharacterState.WALKING, "snapshot does not mutate runtime")
	check(first.character_profile.character_name == "Swordman" and state.characters.size() == 2, "snapshot does not mutate profiles or entity registry")
	check(map.map_profile.textures == ["map01_texture"] and map.rows == 15, "map data independent")
	var next := mapper.game_state_to_dto(state)
	check(next.characters.size() == 2 and next.characters["1"].position.x == 24.0, "next snapshot independent")
	first.position.x = 40.0
	map.map_profile.textures[0] = "new_local_texture"
	check(next.characters["1"].position.x == 24.0 and next.current_map.textures == ["map01_texture"], "later runtime changes do not change old snapshot")
	var empty := mapper.game_state_to_dto(GameState.new({},map))
	check(empty.characters.is_empty() and empty.current_map != null, "empty character registry")
	print("RESULT: %d snapshot checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
