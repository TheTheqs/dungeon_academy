extends SceneTree

class RecordingApi extends GameApi:
	var calls: int = 0
	var destination: MapPositionDto
	func _init(gateway: DataGateway) -> void:
		super(gateway,RuntimeIdGenerator.new(),SnapshotMapper.new(),GridCoordinates.new(),PathfindingService.new(),CharacterMovement.new(GridCoordinates.new()))
	func move_character(runtime_id: String, goal: MapPositionDto) -> bool:
		calls += 1
		destination = MapPositionDto.new(goal.x,goal.y)
		return super.move_character(runtime_id,goal)

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)

func send_click(position: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	root.push_input(event,true)

func run() -> void:
	var gateway := DataGateway.new()
	check(gateway.load_all(), "load")
	var api := RecordingApi.new(gateway)
	check(api.start_game(0,0), "start")
	var screen = load("res://front/screens/game_screen.tscn").instantiate()
	screen.configure(api,TextureLoader.new())
	root.add_child(screen)
	for i in range(6): await process_frame
	var click_position: Vector2 = screen.world.position+Vector2(72,136)
	send_click(click_position,MOUSE_BUTTON_RIGHT,true)
	check(api.calls==1 and api.destination.x==72 and api.destination.y==136,"right-click supplies map-local destination")
	check(api.get_game_state().characters["1"].state==RuntimeCharacter.CharacterState.WALKING,"click registers movement")
	send_click(click_position,MOUSE_BUTTON_RIGHT,false)
	check(api.calls==1,"release ignored")
	send_click(click_position,MOUSE_BUTTON_LEFT,true)
	send_click(click_position,MOUSE_BUTTON_LEFT,false)
	check(api.calls==1,"left click ignored")
	var overlay := Control.new()
	overlay.size=Vector2(640,360)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	screen.add_child(overlay)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position=click_position
	root.push_input(motion,true)
	send_click(click_position,MOUSE_BUTTON_RIGHT,true)
	send_click(click_position,MOUSE_BUTTON_RIGHT,false)
	check(api.calls==1,"overlay consumes input")
	overlay.queue_free()
	await process_frame
	screen.world.position=Vector2(100,40)
	screen.world.scale=Vector2(2,2)
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_RIGHT
	event.pressed=true
	event.position=screen.world.position+Vector2(24,136)*2
	screen._gui_input(event)
	check(api.calls==2 and api.destination.x==24 and api.destination.y==136,"world transform respected")
	check(not api.has_method("inspect_map_position"),"diagnostic endpoint removed")
	screen.queue_free()
	await process_frame
	print("RESULT: %d movement input checks, %d failures" % [_checks,_failures])
	quit(0 if _failures==0 else 1)
