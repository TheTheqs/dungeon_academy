class_name Map
extends RefCounted

var rows: int
var columns: int

var _occupied_cells: Array[Cell] = []
var _occupied_index: Dictionary = {}

func _init(nrows: int, ncolumns: int, noccupied_cells: Array[Cell] = []) -> void:
	rows = maxi(0, nrows)
	columns = maxi(0, ncolumns)
	for cell in noccupied_cells:
		occupy(cell)

func occupy(cell: Cell) -> void:
	if not is_within_bounds(cell):
		return
	var key := cell.get_key()
	if _occupied_index.has(key):
		return
	_occupied_cells.append(Cell.new(cell.row, cell.column))
	_occupied_index[key] = true

func is_within_bounds(cell: Cell) -> bool:
	return cell != null and cell.row >= 0 and cell.row < rows and cell.column >= 0 and cell.column < columns

func is_occupied(cell: Cell) -> bool:
	return cell != null and _occupied_index.has(cell.get_key())

func release(cell: Cell) -> void:
	if cell == null:
		return
	var key := cell.get_key()
	if not _occupied_index.has(key):
		return
	_occupied_index.erase(key)
	for index in range(_occupied_cells.size()):
		if _occupied_cells[index].equals(cell):
			_occupied_cells.remove_at(index)
			break

func is_walkable(cell: Cell) -> bool:
	return is_within_bounds(cell) and not is_occupied(cell)

func get_occupied_cells() -> Array[Cell]:
	var result: Array[Cell] = []
	for cell in _occupied_cells:
		result.append(Cell.new(cell.row, cell.column))
	return result
