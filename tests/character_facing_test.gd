extends SceneTree

var _checks := 0
var _failures := 0
var _coordinates := GridCoordinates.new()
var _movement := CharacterMovement.new(_coordinates)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)

func make_character() -> RuntimeCharacter:
	var character := RuntimeCharacter.new("1",CharacterProfile.new(0,"test",1.0,["swordsman_m"]))
	character.position = _coordinates.cell_to_center(Cell.new(2,2))
	return character

func run() -> void:
	var character := make_character()
	check(character.facing_x == 1, "default faces right")
	for offsets in [[0,-1],[-1,-1],[1,-1],[0,1],[-1,1],[1,1]]:
		character = make_character()
		character.facing_x = 1 if offsets[1] < 0 else -1
		var route: Array[Cell] = [Cell.new(2,2),Cell.new(2+offsets[0],2+offsets[1])]
		character.begin_movement(route)
		_movement.update(character,0.01)
		check(character.facing_x == (-1 if offsets[1]<0 else 1), "horizontal/diagonal facing follows actual segment")
		_movement.update(character,1.0)
		check(character.facing_x == (-1 if offsets[1]<0 else 1) and character.state == RuntimeCharacter.CharacterState.IDLE, "arrival preserves facing")
	for initial in [-1,1]:
		for row in [1,3]:
			character = make_character()
			character.facing_x = initial
			character.begin_movement([Cell.new(2,2),Cell.new(row,2)])
			_movement.update(character,0.01)
			check(character.facing_x == initial, "vertical movement preserves previous side")
	character = make_character()
	character.begin_movement([Cell.new(2,2),Cell.new(2,1),Cell.new(2,2)])
	_movement.update(character,1.0)
	check(character.facing_x == 1 and character.state == RuntimeCharacter.CharacterState.IDLE, "last actual segment wins when crossing several points")
	character = make_character()
	character.begin_movement([Cell.new(2,1)])
	_movement.update(character,0.0)
	check(character.facing_x == 1, "zero elapsed time does not turn")
	character.character_profile.agility = 0
	_movement.update(character,1.0)
	check(character.facing_x == 1, "zero speed does not turn")
	character.character_profile.agility = 1
	_movement.update(character,1.0)
	_movement.update(character,1.0)
	check(character.facing_x == -1, "idle update preserves last facing")

	var map_profile := MapProfile.new(0,"test",5,5,["map01_texture"],[])
	var state := GameState.new({"1":character},RuntimeMap.from_profile(map_profile))
	var mapper := SnapshotMapper.new()
	var snapshot := mapper.game_state_to_dto(state)
	check(snapshot.characters["1"].facing_x == -1, "snapshot includes logical facing")
	snapshot.characters["1"].facing_x = 1
	check(character.facing_x == -1, "snapshot cannot mutate runtime facing")
	var view = load("res://front/components/entities/character_view.tscn").instantiate()
	root.add_child(view)
	view.configure(TextureLoader.new().load_character_texture("swordsman_m"))
	view.apply_snapshot(mapper.character_to_dto(character))
	check(view.sprite.flip_h, "left maps to flip_h=true")
	character.facing_x = 1
	view.apply_snapshot(mapper.character_to_dto(character))
	check(not view.sprite.flip_h, "right maps to flip_h=false")
	character.facing_x = -1
	character.stop_movement()
	view.apply_snapshot(mapper.character_to_dto(character))
	check(view.sprite.flip_h and view.animation_player.current_animation == "idle", "idle presentation preserves orientation")
	view.queue_free()
	await process_frame
	print("RESULT: %d character facing checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
