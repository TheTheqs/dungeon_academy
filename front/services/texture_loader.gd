extends RefCounted

class_name TextureLoader

const CHARACTER_TEXTURES_PATH: String = "res://assets/textures/sprites/characters/"
const MAP_TEXTURES_PATH: String = "res://assets/textures/scenario/maps/"
# Map profile identifiers need not be file names. Resolve them in presentation.
const MAP_TEXTURE_FILES: Dictionary = {"map01_texture": "map01.png"}

func load_character_texture(texture_id: String) -> Texture2D:
	return load(CHARACTER_TEXTURES_PATH + texture_id + ".png") as Texture2D

func load_map_texture(texture_id: String) -> Texture2D:
	if not MAP_TEXTURE_FILES.has(texture_id):
		push_error("Unknown map texture identifier: " + texture_id)
		return null
	return load(MAP_TEXTURES_PATH + str(MAP_TEXTURE_FILES[texture_id])) as Texture2D
