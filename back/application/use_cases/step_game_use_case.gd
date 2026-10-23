extends RefCounted

class_name StepGameUseCase

const STEPS_PER_SECOND: int = 60
const STEP_SECONDS: float = 1.0 / STEPS_PER_SECOND

var _movement: CharacterMovement
var _snapshot_mapper: SnapshotMapper

func _init(movement: CharacterMovement, snapshot_mapper: SnapshotMapper) -> void:
	_movement = movement
	_snapshot_mapper = snapshot_mapper

## One call is one logical tick. No wall clock, input, nodes or rendering.
func execute(game_state: GameState) -> GameStateDto:
	for character: RuntimeCharacter in game_state.characters.values():
		# CharacterMovement dispatches only the WALKING behavior; IDLE is a no-op.
		_movement.update(character, STEP_SECONDS)
	# Snapshot only after all entities have been updated.
	return _snapshot_mapper.game_state_to_dto(game_state)
