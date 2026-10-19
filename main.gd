class_name Main
extends Control

const CHARACTERS_SCENE: PackedScene = preload("res://front/screens/characters_screen.tscn")

# Composition root: dependencies are created once and handed to the screen.
var _api := GameApi.new()
var _texture_loader := TextureLoader.new()

@onready var screen_root: ScreenRoot = $ScreenRoot

func _ready() -> void:
	var screen := CHARACTERS_SCENE.instantiate() as CharactersScreen
	# Configure before add_child(), which triggers the screen's _ready().
	screen.configure(_api, _texture_loader)
	screen_root.show_screen(screen)
