class_name CharacterPreview
extends Control

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	resized.connect(_center_sprite)
	_center_sprite()

func _center_sprite() -> void:
	# Sprite2D does not use Control anchors; center it in its allocated column.
	sprite.position = size / 2.0

func set_character(texture: Texture2D, flip_h: bool) -> void:
	sprite.texture = texture
	sprite.flip_h = flip_h
	start_animation()

func start_animation() -> void:
	if sprite.texture == null:
		return
	animation_player.play("idle")

# Preview-only sequence. Gameplay will select animations from match actions.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"idle":
			animation_player.play("run")
		"run":
			animation_player.play("attack")
		"attack":
			animation_player.play("action")
		"action":
			animation_player.play("death")
		"death":
			animation_player.play("idle")
