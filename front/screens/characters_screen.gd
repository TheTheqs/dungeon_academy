class_name CharactersScreen
extends Control

var _api: GameApi
var _texture_loader: TextureLoader

@onready var player: CharacterPreview = $CharactersRow/PlayerPreview
@onready var enemy: CharacterPreview = $CharactersRow/EnemyPreview

func configure(api: GameApi, texture_loader: TextureLoader) -> void:
	# Only store dependencies here: @onready children are not available yet.
	_api = api
	_texture_loader = texture_loader

func _ready() -> void:
	assert(_api != null, "CharactersScreen requires GameApi.")
	assert(_texture_loader != null, "CharactersScreen requires TextureLoader.")
	refresh_characters()

func refresh_characters() -> void:
	var player_name := _api.get_player_character()
	var enemy_name := _api.get_enemy_character()
	player.set_character(_texture_loader.load_character_texture(player_name), false)
	enemy.set_character(_texture_loader.load_character_texture(enemy_name), true)
