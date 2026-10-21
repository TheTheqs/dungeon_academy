extends RefCounted

class_name Character

var runtime_id: String
var character_name: String
var state: CharacterState
var position: MapPosition
var path: Array[Cell]
var next_cell_index: int
var movement_speed: float

enum CharacterState {
	IDLE,
	WALKING
}
