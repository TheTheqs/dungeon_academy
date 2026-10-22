class_name Main
extends Control

const CHARACTERS_SCENE: PackedScene = preload("res://front/screens/characters_screen.tscn")

var _data_gateway := DataGateway.new()
var _api: GameApi
var _texture_loader := TextureLoader.new()

@onready var screen_root: ScreenRoot = $ScreenRoot

func _ready() -> void:
	# Complete database loading before constructing consumers or showing a screen.
	if not _data_gateway.load_all():
		push_error("Cannot initialize game data: " + _data_gateway.last_error)
		return
	_api = GameApi.new(_data_gateway)
	var screen := CHARACTERS_SCENE.instantiate() as CharactersScreen
	screen.configure(_api, _texture_loader)
	screen_root.show_screen(screen)
