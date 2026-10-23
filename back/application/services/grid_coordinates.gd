extends RefCounted

class_name GridCoordinates

const CELL_SIZE: float = 16.0

var _origin_x: float
var _origin_y: float

func _init(origin_x: float = 0.0, origin_y: float = 0.0) -> void:
	_origin_x = origin_x
	_origin_y = origin_y

func position_to_cell(position: MapPosition) -> Cell:
	var row := floori((position.y - _origin_y) / CELL_SIZE)
	var column := floori((position.x - _origin_x) / CELL_SIZE)
	return Cell.new(row, column)

func cell_to_center(cell: Cell) -> MapPosition:
	var position := MapPosition.new()
	position.x = _origin_x + (cell.column + 0.5) * CELL_SIZE
	position.y = _origin_y + (cell.row + 0.5) * CELL_SIZE
	return position
