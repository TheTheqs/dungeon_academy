extends Node2D

class_name CharacterView

var runtime_id: String

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func configure(texture: Texture2D) -> void:
	sprite.texture = texture
	animation_player.play("idle")

func apply_snapshot(character: CharacterDto) -> void:
	runtime_id = character.runtime_id
	position = Vector2(character.position.x, character.position.y)
	# The source sprite faces right; the back sends an orientation, not a flip flag.
	sprite.flip_h = character.facing_x < 0
	var animation: StringName = &"run" if character.state == RuntimeCharacter.CharacterState.WALKING else &"idle"
	if animation_player.current_animation != animation:
		animation_player.play(animation)
