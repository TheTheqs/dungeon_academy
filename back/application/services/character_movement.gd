extends RefCounted

class_name CharacterMovement

var _coordinates: GridCoordinates

func _init(coordinates: GridCoordinates) -> void:
	assert(coordinates != null, "CharacterMovement requires GridCoordinates.")
	_coordinates = coordinates

## Updates logical movement only. No nodes, textures, snapshots or frame callbacks.
## Speed is 80 world units/second multiplied by the static character agility.
func update(character: RuntimeCharacter, delta: float) -> void:
	if character == null:
		return
	if character.state != RuntimeCharacter.CharacterState.WALKING:
		return
	if character.path.is_empty() or character.next_cell_index < 0 or character.next_cell_index >= character.path.size():
		character.stop_movement()
		return
	if not is_finite(delta) or delta <= 0.0:
		return
	if character.character_profile == null:
		return
	var movement_speed: float = 80.0 * character.character_profile.agility
	if not is_finite(movement_speed) or movement_speed <= 0.0:
		return
	var remaining_distance := movement_speed * delta
	if not is_finite(remaining_distance):
		return

	while character.next_cell_index < character.path.size():
		var target := _coordinates.cell_to_center(character.path[character.next_cell_index])
		var dx := target.x - character.position.x
		var dy := target.y - character.position.y
		var distance := sqrt(dx * dx + dy * dy)

		# An already reached waypoint must not cause division by zero.
		if distance <= 0.000001:
			character.position.x = target.x
			character.position.y = target.y
			character.next_cell_index += 1
			continue
		if remaining_distance <= 0.0:
			break

		# Only change facing for a segment that actually advances horizontally.
		# Do not replace it with zero for vertical movement or reset it on stop.
		if absf(dx) > 0.000001:
			character.facing_x = -1 if dx < 0.0 else 1

		if remaining_distance + 0.000001 >= distance:
			# Reach exactly, then spend any remainder on the following segment.
			character.position.x = target.x
			character.position.y = target.y
			remaining_distance = maxf(0.0, remaining_distance - distance)
			character.next_cell_index += 1
		else:
			# Normalize the direction so diagonals have the same actual speed.
			character.position.x += (dx / distance) * remaining_distance
			character.position.y += (dy / distance) * remaining_distance
			break

	if character.next_cell_index >= character.path.size():
		character.stop_movement()
