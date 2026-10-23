extends RefCounted

class_name MapProfile

var id: int
var map_name: String
var rows: int
var columns: int
var textures: Array[String] = []
var occupied_cells: Array[Cell] = []

func _init(nid: int, nname: String, nrows: int, ncolumns: int, ntextures: Array[String], noccupied_cells: Array[Cell]) -> void:
	id = nid
	map_name = nname
	rows = nrows
	columns = ncolumns
	textures.assign(ntextures)
	for cell in noccupied_cells:
		occupied_cells.append(Cell.new(cell.row, cell.column))

func copy() -> MapProfile:
	return MapProfile.new(id, map_name, rows, columns, textures, occupied_cells)
