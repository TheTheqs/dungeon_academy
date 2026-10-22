class_name CharacterView
extends Node2D

var runtime_id: String

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func configure(texture: Texture2D) -> void:
	sprite.texture = texture
	animation_player.play("idle")

func apply_snapshot(character: CharacterDto) -> void:
	runtime_id = character.runtime_id
	position = Vector2(character.position.x, character.position.y)
	# This increment only presents idle. No simulation or movement in the view.
	if animation_player.current_animation != "idle":
		animation_player.play("idle")
