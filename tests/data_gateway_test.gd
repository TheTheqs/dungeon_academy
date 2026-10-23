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
	_test_gateway()
	_test_repository_inputs()
	_test_validation()
	_test_startup()
	print("RESULT: %d data gateway checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_gateway() -> void:
	var gateway := DataGateway.new()
	check(not gateway.is_ready, "starts unloaded")
	check(gateway.get_character(0) == null, "nothing published before loading")
	check(gateway.load_all(), "real JSONs load")
	check(gateway.is_ready and gateway.last_error.is_empty(), "ready only after successful load")
	check(gateway.characters.count() == 1 and gateway.maps.count() == 1, "one static character and map")
	check(gateway.characters.has_id(0) and gateway.maps.has_id(0), "indexed by integer ID")
	check(gateway.get_character(999) == null and gateway.get_map(999) == null, "unknown IDs return null")
	var character := gateway.get_character(0)
	check(character.character_name == "Swordman" and character.agility == 1.0, "character fields mapped")
	check(character.textures == ["swordsman_m"], "texture identifier preserved")
	character.id = 55
	character.character_name = "changed"
	character.agility = 999
	character.textures[0] = "changed"
	character.textures.append("extra")
	var fresh := gateway.get_character(0)
	check(fresh.id == 0 and fresh.character_name == "Swordman" and fresh.agility == 1.0, "character scalars are isolated")
	check(fresh.textures == ["swordsman_m"], "character nested texture array is isolated")
	var all_characters := gateway.characters.get_all()
	all_characters[0].textures.clear()
	all_characters.clear()
	check(gateway.characters.count() == 1 and gateway.get_character(0).textures.size() == 1, "get_all protects character storage")
	var direct_character := gateway.characters.get_by_id(0)
	direct_character.character_name = "direct mutation"
	check(gateway.get_character(0).character_name == "Swordman", "direct repository query also copies")

	var map := gateway.get_map(0)
	check(map.rows == 15 and map.columns == 17, "map_size interpreted as rows,columns")
	check(map.occupied_cells.size() == 95 and map.textures == ["map01_texture"], "map fields mapped")
	map.occupied_cells[0].row = 14
	map.occupied_cells[0].column = 16
	map.occupied_cells.clear()
	map.rows = 1
	map.columns = 1
	map.map_name = "changed"
	map.textures.clear()
	var fresh_map := gateway.get_map(0)
	check(fresh_map.rows == 15 and fresh_map.columns == 17 and fresh_map.map_name == "Map01", "map scalar fields protected")
	check(fresh_map.occupied_cells.size() == 95 and fresh_map.occupied_cells[0].equals(Cell.new(0,0)), "map cells deeply copied")
	check(fresh_map.textures == ["map01_texture"], "map textures protected")
	var all_maps := gateway.maps.get_all()
	all_maps[0].occupied_cells[0].row = 99
	all_maps.clear()
	check(gateway.maps.count() == 1 and gateway.get_map(0).occupied_cells[0].row == 0, "get_all protects nested map cells")
	var direct_map := gateway.maps.get_by_id(0)
	direct_map.occupied_cells[0].row = 99
	check(gateway.get_map(0).occupied_cells[0].row == 0, "direct map repository also copies")

	var runtime_map := RuntimeMap.from_profile(fresh_map)
	check(runtime_map.rows == 15 and runtime_map.is_occupied(Cell.new(0,0)), "runtime map built from profile")
	runtime_map.release(Cell.new(0,0))
	runtime_map.occupy(Cell.new(4,0))
	runtime_map.map_profile.occupied_cells[0].row = 99
	check(fresh_map.occupied_cells[0].row == 0, "runtime profile does not alias caller profile")
	check(gateway.get_map(0).occupied_cells.size() == 95 and gateway.get_map(0).occupied_cells[0].row == 0, "runtime changes do not mutate catalog")
	check(RuntimeMap.from_profile(gateway.get_map(0)).is_occupied(Cell.new(0,0)), "new match receives original map")
	var runtime := RuntimeCharacter.new("1", fresh)
	fresh.character_name = "outside"
	check(runtime.character_profile.character_name == "Swordman", "runtime character owns a copied profile")
	runtime.character_profile.textures.clear()
	check(gateway.get_character(0).textures.size() == 1, "runtime character cannot mutate database")
	var dto := SnapshotMapper.new().character_to_dto(runtime)
	check(dto.character_name == "Swordman" and dto.runtime_id == "1", "mapper follows character_profile")
	var state := GameState.new({"1": runtime},runtime_map)
	check(state.get_character("1") == runtime and state.get_character("missing") == null, "GameState uses RuntimeCharacter")
	check(gateway.load_all("res://missing.json","res://missing.json"), "loaded gateway does not reread files")
	var api := GameApi.new(gateway, RuntimeIdGenerator.new(), SnapshotMapper.new(), GridCoordinates.new(), PathfindingService.new(), CharacterMovement.new(GridCoordinates.new()))
	check(api.start_game(0, 0) and api.get_game_state().characters.values()[0].textures == ["swordsman_m"], "API consumes injected database")

func _test_repository_inputs() -> void:
	var textures: Array[String] = ["original"]
	var original := CharacterProfile.new(10,"test",2.0,textures)
	var repo := CharacterRepository.new([original])
	textures.clear()
	original.textures[0] = "changed"
	original.id = 20
	check(repo.get_by_id(10).textures == ["original"] and not repo.has_id(20), "repository copies input profiles")
	var cells: Array[Cell] = [Cell.new(0,0)]
	var map := MapProfile.new(10,"test",3,3,["texture"],cells)
	var maps := MapRepository.new([map])
	cells[0].row = 99
	map.occupied_cells[0].column = 99
	map.textures.clear()
	check(maps.get_by_id(10).occupied_cells[0].equals(Cell.new(0,0)), "map constructor and repository both deep copy")
	check(maps.get_by_id(10).textures == ["texture"], "map repository copies textures on input")

func _test_validation() -> void:
	var loader := GameDataLoader.new()
	var record := {"id":0,"character_name":"test","agility":1,"textures":["texture"]}
	for field in ["id","character_name","agility","textures"]:
		var invalid: Dictionary = record.duplicate(true)
		invalid.erase(field)
		check(loader.map_characters([invalid]).is_empty() and not loader.error_message.is_empty(), "missing character field: " + field)
	for invalid_id in [-1,0.5,"0",true,null]:
		var invalid: Dictionary = record.duplicate(true)
		invalid.id = invalid_id
		check(loader.map_characters([invalid]).is_empty() and not loader.error_message.is_empty(), "invalid ID")
	check(loader.map_characters([record,record]).is_empty() and not loader.error_message.is_empty(), "duplicate character IDs rejected")
	for invalid_agility in [-1,INF,NAN,"fast",null]:
		var invalid: Dictionary = record.duplicate(true)
		invalid.agility = invalid_agility
		check(loader.map_characters([invalid]).is_empty() and not loader.error_message.is_empty(), "invalid agility rejected")
	for invalid_textures in [[],[""],[5],"texture",null]:
		var invalid: Dictionary = record.duplicate(true)
		invalid.textures = invalid_textures
		check(loader.map_characters([invalid]).is_empty() and not loader.error_message.is_empty(), "invalid texture identifiers")
	check(loader.map_characters([null]).is_empty() and not loader.error_message.is_empty(), "non-object record")
	var map := {"id":0,"map_name":"test","map_size":[3,4],"textures":["texture"],"occupied_cells":[[0,0]]}
	for size in [[0,4],[-1,4],[2.5,4],[3],"3x4",null]:
		var invalid: Dictionary = map.duplicate(true)
		invalid.map_size = size
		check(loader.map_maps([invalid]).is_empty() and not loader.error_message.is_empty(), "invalid map size")
	for cells in [[[3,0]],[[0,4]],[[-1,0]],[[0.5,0]],[[0]],[[0,0],[0,0]],null]:
		var invalid: Dictionary = map.duplicate(true)
		invalid.occupied_cells = cells
		check(loader.map_maps([invalid]).is_empty() and not loader.error_message.is_empty(), "invalid map obstacle")
	check(loader.map_maps([map,map]).is_empty() and not loader.error_message.is_empty(), "duplicate map IDs")
	check(loader.map_characters([]).is_empty() and loader.error_message.is_empty(), "empty table is valid")
	check(loader.map_maps([]).is_empty() and loader.error_message.is_empty(), "empty map table is valid")
	loader.read_records("res://tests/fixtures/gateway_malformed.json")
	check(not loader.error_message.is_empty(), "malformed JSON gives diagnostic")
	loader.read_records("res://tests/fixtures/gateway_wrong_root.json")
	check(not loader.error_message.is_empty(), "wrong root gives diagnostic")

	var gateway := DataGateway.new()
	check(not gateway.load_all("res://assets/data/characters.json","res://does_not_exist.json"), "missing map file fails load")
	check(not gateway.is_ready and not gateway.last_error.is_empty(), "failure reported and not ready")
	check(gateway.characters.count() == 0 and gateway.maps.count() == 0, "no partially loaded catalog")
	check(gateway.load_all() and gateway.last_error.is_empty(), "can retry after correcting load failure")

func _test_startup() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	check(main._data_gateway.is_ready, "Main loads database before screen")
	check(main.get_node("ScreenRoot/ScreenHost").get_child_count() == 1, "preview screen still initialized")
	main.queue_free()
