class_name MapDto
extends RefCounted

var id: int
var map_name: String
var rows: int
var columns: int
# Identifiers resolved by the presentation, never engine texture resources.
var textures: Array[String] = []

func _init(nid: int, nname: String, nrows: int, ncolumns: int, ntextures: Array[String]) -> void:
	id = nid
	map_name = nname
	rows = nrows
	columns = ncolumns
	textures.assign(ntextures)
