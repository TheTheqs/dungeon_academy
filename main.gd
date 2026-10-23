extends Control

class_name Main

const GAME_SCENE: PackedScene = preload("res://front/screens/game_screen.tscn")

var _data_gateway := DataGateway.new()
var _runtime_id_generator := RuntimeIdGenerator.new()
var _snapshot_mapper := SnapshotMapper.new()
var _pathfinding_service := PathfindingService.new()
var _coordinates := GridCoordinates.new()
var _character_movement := CharacterMovement.new(_coordinates)
var _game_screen: GameScreen
var _texture_loader := TextureLoader.new()
var _api: GameApi

@onready var screen_root: ScreenRoot = $ScreenRoot

func _ready() -> void:
	if not _data_gateway.load_all():
		push_error("Cannot initialize game data: " + _data_gateway.last_error)
		return
	_api = GameApi.new(_data_gateway, _runtime_id_generator, _snapshot_mapper, _coordinates, _pathfinding_service, _character_movement)
	if not _api.start_game(0, 0):
		push_error("Cannot start game: " + _api.last_error)
		return
	var screen := GAME_SCENE.instantiate() as GameScreen
	screen.configure(_api, _texture_loader)
	_game_screen = screen
	screen_root.show_screen(screen)

# The single simulation driver. Rendering and individual views never call step.
func _physics_process(_delta: float) -> void:
	if _api == null or not is_instance_valid(_game_screen) or not _game_screen.is_inside_tree():
		return
	var snapshot := _api.step_game()
	if snapshot != null:
		_game_screen.apply_snapshot(snapshot)
