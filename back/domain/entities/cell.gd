class_name Cell
extends RefCounted

var row: int
var column: int

func _init(nrow: int, ncolumn: int) -> void:
	row = nrow
	column = ncolumn

func equals(other: Cell) -> bool:
	return other != null and row == other.row and column == other.column

func get_key() -> String:
	return "%d:%d" % [row, column]

func _to_string() -> String:
	return "Cell(%d, %d)" % [row, column]
