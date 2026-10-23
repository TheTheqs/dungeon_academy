extends RefCounted
class_name RuntimeCharacter

enum CharacterState { IDLE, WALKING }

var runtime_id: String
var character_profile: CharacterProfile
var state: CharacterState = CharacterState.IDLE
var position: MapPosition = MapPosition.new()
# Last horizontal facing: -1 = left, +1 = right. Kept when idle/vertical.
var facing_x: int = 1
var path: Array[Cell] = []
# Index of the cell center still to reach, not the cell just visited.
var next_cell_index: int = 0

func _init(nruntime_id: String = "", profile: CharacterProfile = null) -> void:
	runtime_id = nruntime_id
	character_profile = profile.copy() if profile != null else null

## A rejected assignment preserves the previous movement intention.
func begin_movement(new_path: Array[Cell], next_index: int = 0) -> bool:
	if new_path.is_empty() or next_index < 0 or next_index > new_path.size():
		return false
	# Build before changing fields: safe even for begin_movement(path).
	var owned_path: Array[Cell] = []
	for cell in new_path:
		if cell == null:
			return false
		owned_path.append(Cell.new(cell.row, cell.column))
	if next_index == owned_path.size():
		stop_movement()
		return true
	path = owned_path
	next_cell_index = next_index
	state = CharacterState.WALKING
	return true

func stop_movement() -> void:
	path = []
	next_cell_index = 0
	state = CharacterState.IDLE
