class_name Main
extends Control

const GAME_SCENE: PackedScene = preload("res://front/screens/game_screen.tscn")

var _data_gateway := DataGateway.new()
var _api: GameApi
var _texture_loader := TextureLoader.new()

@onready var screen_root: ScreenRoot = $ScreenRoot

func _ready() -> void:
	if not _data_gateway.load_all():
		push_error("Cannot initialize game data: " + _data_gateway.last_error)
		return
	_api = GameApi.new(_data_gateway)
	if not _api.start_game(0, 0):
		push_error("Cannot start game: " + _api.last_error)
		return
	var screen := GAME_SCENE.instantiate() as GameScreen
	screen.configure(_api, _texture_loader)
	screen_root.show_screen(screen)
