class_name TextureLoader
extends RefCounted

const CHARACTER_TEXTURES_PATH: String = "res://assets/textures/sprites/characters/"

func load_character_texture(character_name: String) -> Texture2D:
	return load(CHARACTER_TEXTURES_PATH + character_name + ".png") as Texture2D
