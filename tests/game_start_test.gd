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
	check(gateway.load_all(), "real database loads")
	var api := GameApi.new(gateway)
	check(api.get_game_state() == null and not api.last_error.is_empty(), "state unavailable before starting")
	check(not api.start_game(999,0), "unknown character rejected")
	check(not api.start_game(0,999), "unknown map rejected")
	check(api.start_game(0,0), "real game starts")
	var snapshot := api.get_game_state()
	check(snapshot.characters.size() == 1 and snapshot.current_map.id == 0, "snapshot contains requested entities")
	var character: CharacterDto = snapshot.characters.values()[0]
	check(character.runtime_id == "1", "invalid requests do not consume IDs")
	check(character.state == RuntimeCharacter.CharacterState.IDLE, "starts idle")
	check(character.position.x == 24.0 and character.position.y == 136.0, "spawn uses cell center converter")
	var position := MapPosition.new()
	position.x = character.position.x
	position.y = character.position.y
	check(api._game_state.current_map.is_walkable(GridCoordinates.new().position_to_cell(position)), "spawn is walkable")
	check(character.textures == ["swordsman_m"], "character texture ID in DTO")
	character.textures.clear()
	check(api.get_game_state().characters["1"].textures == ["swordsman_m"], "character texture list defensively copied")
	check(not api.start_game(0,999) and api.get_game_state().characters.has("1"), "failed restart preserves existing game")
	check(api.start_game(0,0) and api.get_game_state().characters.has("2"), "restart gets a fresh runtime ID")
	var loader := TextureLoader.new()
	check(loader.load_map_texture("map01_texture").get_size() == Vector2(272,240), "map identifier resolves to real PNG")

	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in range(8): await process_frame
	var screen = main.get_node("ScreenRoot/ScreenHost").get_child(0)
	check(screen is GameScreen, "Main displays game screen")
	check(screen.entities.get_child_count() == 1, "exactly one character view")
	var view = screen.entities.get_child(0)
	check(view.position == Vector2(24,136), "front uses snapshot position")
	check(screen.world.position == Vector2(184,60), "map centered without scaling logical coordinates")
	check(not screen.map_sprite.centered, "PNG origin is top-left")
	var initial_view_id: int = view.get_instance_id()
	screen.apply_snapshot(main._api.get_game_state())
	check(screen.entities.get_child_count() == 1 and screen.entities.get_child(0).get_instance_id() == initial_view_id, "snapshot updates reuse view")
	await create_timer(1.7).timeout
	check(view.animation_player.current_animation == "idle", "idle loops instead of preview animation sequence")
	check(view.position == Vector2(24,136), "no movement introduced")
	var removed: GameStateDto = main._api.get_game_state()
	removed.characters.clear()
	screen.apply_snapshot(removed)
	check(screen.entities.get_child_count() == 0, "absent entities removed")
	screen.apply_snapshot(main._api.get_game_state())
	check(screen.entities.get_child_count() == 1, "entity can be recreated from snapshot")
	for i in range(4): await process_frame
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(arguments[0])
	main.queue_free()
	await process_frame
	print("RESULT: %d game startup checks, %d failures" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
