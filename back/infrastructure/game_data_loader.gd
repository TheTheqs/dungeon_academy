extends RefCounted

class_name GameDataLoader

var error_message: String = ""

func read_records(path: String) -> Array:
	error_message = ""
	if not FileAccess.file_exists(path):
		_fail("File does not exist: " + path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open: " + path)
		return []
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		_fail("%s, line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return []
	if not json.data is Dictionary or not json.data.get("data") is Array:
		_fail(path + ": expected an object containing a data array.")
		return []
	return json.data["data"]

func map_characters(records: Array) -> Array[CharacterProfile]:
	error_message = ""
	var result: Array[CharacterProfile] = []
	var seen := {}
	for index in range(records.size()):
		var record = records[index]
		var context := "characters[%d]" % index
		if not _base_record(record, "character_name", seen, context): return []
		var agility = record.get("agility")
		if not _number(agility) or float(agility) < 0.0:
			_fail(context + ": agility must be a finite non-negative number.")
			return []
		var textures := _textures(record["textures"])
		result.append(CharacterProfile.new(int(record["id"]), record["character_name"], float(agility), textures))
	return result

func map_maps(records: Array) -> Array[MapProfile]:
	error_message = ""
	var result: Array[MapProfile] = []
	var seen := {}
	for index in range(records.size()):
		var record = records[index]
		var context := "maps[%d]" % index
		if not _base_record(record, "map_name", seen, context): return []
		var size = record.get("map_size")
		# Existing JSON contract: map_size = [rows, columns].
		if not size is Array or size.size() != 2:
			_fail(context + ": map_size must be [rows, columns].")
			return []
		if not _integer(size[0]) or not _integer(size[1]) or float(size[0]) <= 0 or float(size[1]) <= 0:
			_fail(context + ": map dimensions must be positive integers.")
			return []
		var rows := int(size[0])
		var columns := int(size[1])
		var occupied = record.get("occupied_cells")
		if not occupied is Array:
			_fail(context + ": occupied_cells must be an array.")
			return []
		var cells: Array[Cell] = []
		var cell_index := {}
		for coordinates in occupied:
			if not coordinates is Array or coordinates.size() != 2:
				_fail(context + ": occupied cell must be [row, column].")
				return []
			if not _integer(coordinates[0]) or not _integer(coordinates[1]):
				_fail(context + ": cell coordinates must be integers.")
				return []
			var row := int(coordinates[0])
			var column := int(coordinates[1])
			if row < 0 or row >= rows or column < 0 or column >= columns:
				_fail(context + ": occupied cell is outside the map.")
				return []
			var cell := Cell.new(row, column)
			if cell_index.has(cell.get_key()):
				_fail(context + ": duplicate occupied cell " + cell.get_key())
				return []
			cell_index[cell.get_key()] = true
			cells.append(cell)
		result.append(MapProfile.new(int(record["id"]), record["map_name"], rows, columns, _textures(record["textures"]), cells))
	return result

func _base_record(record: Variant, name_field: String, seen: Dictionary, context: String) -> bool:
	if not record is Dictionary:
		return _fail(context + ": expected an object.")
	var id = record.get("id")
	if not _integer(id) or float(id) < 0:
		return _fail(context + ": id must be a non-negative integer.")
	if seen.has(int(id)):
		return _fail(context + ": duplicate id %d." % int(id))
	seen[int(id)] = true
	var name_value = record.get(name_field)
	if not name_value is String or name_value.strip_edges().is_empty():
		return _fail(context + ": missing or empty " + name_field)
	var textures = record.get("textures")
	if not textures is Array or textures.is_empty():
		return _fail(context + ": textures must be a non-empty array of identifiers.")
	for texture in textures:
		if not texture is String or texture.strip_edges().is_empty():
			return _fail(context + ": invalid texture identifier.")
	return true

func _textures(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values: result.append(value)
	return result

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _integer(value: Variant) -> bool:
	# JSON numbers can arrive as floats. Keep conversion within exact integer range.
	return _number(value) and absf(float(value)) <= 9007199254740991.0 and float(value) == floor(float(value))

func _fail(message: String) -> bool:
	error_message = message
	return false
