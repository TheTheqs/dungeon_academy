class_name PathfindingService
extends RefCounted

const STRAIGHT_COST: float = 1.0
const DIAGONAL_COST: float = 1.4142135623730951
const DIRECTIONS = [
	[-1, -1], [-1, 0], [-1, 1],
	[0, -1], [0, 1],
	[1, -1], [1, 0], [1, 1]
]

## Returns all adjacent cells, including start and goal, in traversal order.
## Empty means invalid input or unreachable goal. No pixels or smoothing.
func find_path(start: Cell, goal: Cell, map: Map) -> Array[Cell]:
	var empty_result: Array[Cell] = []
	if map == null or not map.is_walkable(start) or not map.is_walkable(goal):
		return empty_result
	if start.equals(goal):
		return [Cell.new(start.row, start.column)]

	# Search data belongs to this call, never to the map or to the service.
	var origin := Cell.new(start.row, start.column)
	var open_set: Array[Cell] = [origin]
	var open_index: Dictionary = {origin.get_key(): true}
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {origin.get_key(): 0.0}
	var f_score: Dictionary = {origin.get_key(): _heuristic(origin, goal)}

	while not open_set.is_empty():
		var current := _get_lowest_f(open_set, f_score)
		if current.equals(goal):
			return _reconstruct_path(came_from, current)

		var current_key := current.get_key()
		open_set.erase(current)
		open_index.erase(current_key)
		closed_set[current_key] = true

		for direction in DIRECTIONS:
			var row_offset: int = direction[0]
			var column_offset: int = direction[1]
			var neighbor := Cell.new(current.row + row_offset, current.column + column_offset)
			if not map.is_walkable(neighbor):
				continue
			var neighbor_key := neighbor.get_key()
			if closed_set.has(neighbor_key):
				continue

			var is_diagonal := row_offset != 0 and column_offset != 0
			if is_diagonal:
				# Both sides must be free, not only the diagonal destination.
				var side_a := Cell.new(current.row + row_offset, current.column)
				var side_b := Cell.new(current.row, current.column + column_offset)
				if not map.is_walkable(side_a) or not map.is_walkable(side_b):
					continue

			var movement_cost := DIAGONAL_COST if is_diagonal else STRAIGHT_COST
			var tentative_g: float = float(g_score[current_key]) + movement_cost
			if tentative_g >= float(g_score.get(neighbor_key, INF)):
				continue

			# Relaxation: replace a known route only when this one costs less.
			came_from[neighbor_key] = current
			g_score[neighbor_key] = tentative_g
			f_score[neighbor_key] = tentative_g + _heuristic(neighbor, goal)
			if not open_index.has(neighbor_key):
				open_set.append(neighbor)
				open_index[neighbor_key] = true

	return empty_result

## Octile distance: exact cost in an empty eight-direction grid.
func _heuristic(current: Cell, goal: Cell) -> float:
	var delta_row := absi(goal.row - current.row)
	var delta_column := absi(goal.column - current.column)
	var diagonal_steps := mini(delta_row, delta_column)
	var straight_steps := maxi(delta_row, delta_column) - diagonal_steps
	return diagonal_steps * DIAGONAL_COST + straight_steps * STRAIGHT_COST

func _get_lowest_f(open_set: Array[Cell], f_score: Dictionary) -> Cell:
	var best: Cell = open_set[0]
	var lowest: float = f_score[best.get_key()]
	for cell in open_set:
		var score: float = f_score[cell.get_key()]
		if score < lowest:
			lowest = score
			best = cell
	return best

func _reconstruct_path(came_from: Dictionary, current: Cell) -> Array[Cell]:
	var path: Array[Cell] = []
	while true:
		# Return independent values, not references to caller-owned cells.
		path.append(Cell.new(current.row, current.column))
		if not came_from.has(current.get_key()):
			break
		current = came_from[current.get_key()]
	path.reverse()
	return path
