class_name GameScreen
extends Control

const CHARACTER_SCENE: PackedScene = preload("res://front/components/entities/character_view.tscn")

var _api: GameApi
var _texture_loader: TextureLoader
var _character_views: Dictionary[String, CharacterView] = {}
var _map_id: int = -1
var _map_texture_id: String = ""

@onready var world: Node2D = $World
@onready var map_sprite: Sprite2D = $World/MapSprite
@onready var entities: Node2D = $World/Entities

func configure(api: GameApi, texture_loader: TextureLoader) -> void:
	_api = api
	_texture_loader = texture_loader

func _ready() -> void:
	assert(_api != null and _texture_loader != null, "Configure GameScreen before adding it.")
	resized.connect(_center_world)
	# Read after successful start_game; presentation only consumes the DTO.
	var snapshot := _api.get_game_state()
	if snapshot == null:
		push_error(_api.last_error)
		return
	apply_snapshot(snapshot)

func apply_snapshot(snapshot: GameStateDto) -> void:
	var map := snapshot.current_map
	if map.textures.is_empty():
		push_error("Map snapshot has no texture identifier.")
		return
	var texture_id := map.textures[0]
	if map.id != _map_id or texture_id != _map_texture_id:
		var texture := _texture_loader.load_map_texture(texture_id)
		if texture == null: return
		map_sprite.texture = texture
		_map_id = map.id
		_map_texture_id = texture_id
	_center_world()

	for runtime_id in snapshot.characters:
		var character: CharacterDto = snapshot.characters[runtime_id]
		if not _character_views.has(runtime_id):
			if character.textures.is_empty():
				push_error("Character snapshot has no texture identifier.")
				continue
			var view := CHARACTER_SCENE.instantiate() as CharacterView
			entities.add_child(view)
			view.configure(_texture_loader.load_character_texture(character.textures[0]))
			_character_views[runtime_id] = view
		_character_views[runtime_id].apply_snapshot(character)

	for runtime_id in _character_views.keys():
		if not snapshot.characters.has(runtime_id):
			var view: CharacterView = _character_views[runtime_id]
			entities.remove_child(view)
			view.queue_free()
			_character_views.erase(runtime_id)

func _center_world() -> void:
	if map_sprite.texture != null:
		# Only a display offset. Logical map origin stays at (0,0).
		world.position = ((size - map_sprite.texture.get_size()) / 2.0).floor()
