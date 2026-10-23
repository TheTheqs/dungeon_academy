extends Control

class_name GameScreen

const CHARACTER_SCENE: PackedScene = preload("res://front/components/entities/character_view.tscn")

var controlled_runtime_id: String = ""
var last_move_error: String = ""

var _api: GameApi
var _texture_loader: TextureLoader
var _character_views: Dictionary[String, CharacterView] = {}
var _map_id: int = -1
var _map_texture_id: String = ""

@onready var world: Node2D = $World
@onready var map_sprite: Sprite2D = $World/MapSprite
@onready var entities: Node2D = $World/Entities

func configure(api: GameApi, texture_loader: TextureLoader, runtime_id: String = "") -> void:
	controlled_runtime_id = runtime_id
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
	# The MVP has one character. Bind once; never pick the first view per click.
	if controlled_runtime_id.is_empty() and snapshot.characters.size() == 1:
		controlled_runtime_id = snapshot.characters.keys()[0]
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

# GUI input belongs to this full-screen gameplay view. Overlay UI can consume
# its own events without also issuing commands through an _input() callback.
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_RIGHT or not event.pressed:
		return
	if map_sprite.texture == null:
		return
	# GUI event.position is local to GameScreen. Transform it into World space
	# rather than subtracting a hardcoded centering offset or window scale.
	var canvas_position: Vector2 = get_global_transform_with_canvas() * event.position
	var map_position: Vector2 = world.get_global_transform_with_canvas().affine_inverse() * canvas_position

	if not controlled_runtime_id.is_empty():
		var accepted := _api.move_character(controlled_runtime_id, MapPositionDto.new(map_position.x, map_position.y))
		last_move_error = _api.last_error
		if accepted:
			var snapshot := _api.get_game_state()
			if snapshot != null:
				apply_snapshot(snapshot)
	accept_event()
