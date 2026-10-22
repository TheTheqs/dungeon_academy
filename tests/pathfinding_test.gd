extends SceneTree

# Only this executable adapter uses SceneTree. The tested backend uses RefCounted.
var _service := PathfindingService.new()
var _checks := 0
var _failures := 0
var _queries := 0
const EPSILON: float = 0.000001

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	_test_contract()
	_test_map()
	_demo()
	_test_all_small_maps()
	_test_seeded_maps()
	print("RESULT: %d checks, %d route comparisons, %d failures" % [_checks, _queries, _failures])
	quit(0 if _failures == 0 else 1)

func _test_contract() -> void:
	var map := RuntimeMap.new(4, 5)
	check(_service.find_path(null, Cell.new(0,0), map).is_empty(), "null start")
	check(_service.find_path(Cell.new(0,0), null, map).is_empty(), "null goal")
	check(_service.find_path(Cell.new(0,0), Cell.new(1,1), null).is_empty(), "null map")
	for invalid in [Cell.new(-1,0), Cell.new(0,-1), Cell.new(4,0), Cell.new(0,5)]:
		check(_service.find_path(invalid, Cell.new(0,0), map).is_empty(), "start out of bounds")
		check(_service.find_path(Cell.new(0,0), invalid, map).is_empty(), "goal out of bounds")
	check(_service.find_path(Cell.new(0,0), Cell.new(0,0), RuntimeMap.new(0,0)).is_empty(), "empty map")
	check(_service.find_path(Cell.new(0,0), Cell.new(0,0), RuntimeMap.new(-2,-3)).is_empty(), "negative dimensions")
	var start := Cell.new(1,1)
	var same := _service.find_path(start, Cell.new(1,1), map)
	check(same.size() == 1 and same[0].equals(start), "start equals goal")
	same[0].row = 3
	check(start.row == 1, "result does not alias start")
	var goal := Cell.new(2,3)
	var route := _service.find_path(start, goal, map)
	route[0].row = 3
	route[-1].column = 0
	check(start.row == 1 and goal.column == 3, "route endpoints are copies")
	_compare(Cell.new(0,0), Cell.new(0,6), RuntimeMap.new(1,7), "one row")
	_compare(Cell.new(0,0), Cell.new(6,0), RuntimeMap.new(7,1), "one column")
	var corner := RuntimeMap.new(2,2,[Cell.new(0,1)])
	var corner_route := _service.find_path(Cell.new(0,0),Cell.new(1,1),corner)
	check(corner_route.size() == 3, "one blocked side also forbids diagonal")
	corner.occupy(Cell.new(1,0))
	check(_service.find_path(Cell.new(0,0),Cell.new(1,1),corner).is_empty(), "cannot squeeze between two corners")

func _test_map() -> void:
	var source := Cell.new(1,1)
	var map := RuntimeMap.new(3,3,[source, Cell.new(1,1),Cell.new(9,9)])
	check(map.get_occupied_cells().size() == 1, "duplicate and out-of-range obstacles")
	source.row = 0
	check(map.is_occupied(Cell.new(1,1)) and not map.is_occupied(source), "map copies input obstacles")
	var copy := map.get_occupied_cells()
	copy[0].row = 0
	copy.clear()
	check(map.is_occupied(Cell.new(1,1)), "obstacle getter returns defensive copies")
	map.release(Cell.new(1,1))
	map.release(Cell.new(1,1))
	map.occupy(null)
	map.release(null)
	check(map.is_walkable(Cell.new(1,1)), "release removes obstacle from index")
	map.occupy(Cell.new(1,1))
	check(not map.is_walkable(Cell.new(1,1)), "occupy restores obstacle")

func _demo() -> void:
	var obstacles: Array[Cell] = []
	for row in range(4): obstacles.append(Cell.new(row,3))
	var map := RuntimeMap.new(6,7,obstacles)
	var start := Cell.new(1,1)
	var goal := Cell.new(1,5)
	_compare(start,goal,map,"wall detour demo")
	var route := _service.find_path(start,goal,map)
	var route_keys := {}
	var sequence: Array[String] = []
	for cell in route:
		route_keys[cell.get_key()] = true
		sequence.append(cell.get_key())
	print("DEMO (row,column): ", " -> ".join(sequence))
	print("DEMO cost: ", _path_cost(route))
	for row in range(map.rows):
		var line := ""
		for column in range(map.columns):
			var cell := Cell.new(row,column)
			var mark := "."
			if map.is_occupied(cell): mark = "#"
			elif cell.equals(start): mark = "S"
			elif cell.equals(goal): mark = "G"
			elif route_keys.has(cell.get_key()): mark = "*"
			line += mark + " "
		print(line)
	# Reuse the same service after a map mutation; there must be no stale search state.
	map.release(Cell.new(1,3))
	_compare(start,goal,map,"wall opening after previous search")
	check(absf(_path_cost(_service.find_path(start,goal,map))-4.0)<EPSILON,"opened direct corridor")

func _test_all_small_maps() -> void:
	# Every obstacle arrangement in a 3x3 grid, every ordered start/goal pair.
	for mask in range(512):
		var map := RuntimeMap.new(3,3)
		for index in range(9):
			if mask & (1 << index): map.occupy(Cell.new(index / 3,index % 3))
		for start_index in range(9):
			for goal_index in range(9):
				_compare(Cell.new(start_index / 3,start_index % 3),Cell.new(goal_index / 3,goal_index % 3),map,"exhaustive mask %d" % mask)
	print("PASS: all 512 small maps and 41,472 ordered endpoint combinations")

func _test_seeded_maps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261021
	for sample in range(200):
		var map := RuntimeMap.new(8,10)
		for row in range(map.rows):
			for column in range(map.columns):
				if rng.randf() < 0.28: map.occupy(Cell.new(row,column))
		var start := Cell.new(rng.randi_range(0,7),rng.randi_range(0,9))
		var goal := Cell.new(rng.randi_range(0,7),rng.randi_range(0,9))
		map.release(start)
		map.release(goal)
		_compare(start,goal,map,"seeded map %d" % sample)
	print("PASS: 200 deterministic larger maps")

func _compare(start: Cell, goal: Cell, map: RuntimeMap, context: String) -> void:
	_queries += 1
	var route := _service.find_path(start,goal,map)
	var expected := _reference_cost(start,goal,map)
	if is_inf(expected):
		check(route.is_empty(),context+": unreachable must return []")
		return
	check(not route.is_empty(),context+": reachable must return a route")
	if route.is_empty(): return
	check(route[0].equals(start) and route[-1].equals(goal),context+": endpoints")
	check(absf(_path_cost(route)-expected)<EPSILON,context+": minimum cost vs Dijkstra")
	var visited := {}
	for index in range(route.size()):
		var cell := route[index]
		check(map.is_walkable(cell),context+": walkable cell")
		check(not visited.has(cell.get_key()),context+": no cycles")
		visited[cell.get_key()] = true
		if index == 0: continue
		var previous := route[index-1]
		var dr := absi(cell.row-previous.row)
		var dc := absi(cell.column-previous.column)
		check(dr<=1 and dc<=1 and dr+dc>0,context+": adjacent cells, no smoothing")
		if dr==1 and dc==1:
			check(map.is_walkable(Cell.new(previous.row,cell.column)) and map.is_walkable(Cell.new(cell.row,previous.column)),context+": no corner cutting")

func _path_cost(route: Array[Cell]) -> float:
	var cost := 0.0
	for index in range(1,route.size()):
		var a := route[index-1]
		var b := route[index]
		cost += sqrt(2.0) if a.row!=b.row and a.column!=b.column else 1.0
	return cost

func _reference_cost(start: Cell, goal: Cell, map: RuntimeMap) -> float:
	# Independent Dijkstra: numeric indices, dense arrays, no heuristic,
	# no production helpers, no predecessor reconstruction.
	if not map.is_walkable(start) or not map.is_walkable(goal): return INF
	var count := map.rows*map.columns
	var distance: Array[float] = []
	var done: Array[bool] = []
	distance.resize(count)
	distance.fill(INF)
	done.resize(count)
	done.fill(false)
	distance[start.row*map.columns+start.column] = 0.0
	for iteration in range(count):
		var best := -1
		for index in range(count):
			if not done[index] and (best == -1 or distance[index] < distance[best]): best = index
		if best == -1 or is_inf(distance[best]): return INF
		if best == goal.row*map.columns+goal.column: return distance[best]
		done[best] = true
		var row: int = best / map.columns
		var column: int = best % map.columns
		for nr in range(maxi(0,row-1),mini(map.rows,row+2)):
			for nc in range(maxi(0,column-1),mini(map.columns,column+2)):
				var index := nr*map.columns+nc
				if index==best or done[index] or not map.is_walkable(Cell.new(nr,nc)): continue
				var diagonal := nr!=row and nc!=column
				if diagonal and (map.is_occupied(Cell.new(row,nc)) or map.is_occupied(Cell.new(nr,column))): continue
				var candidate := distance[best]+(sqrt(2.0) if diagonal else 1.0)
				if candidate<distance[index]: distance[index]=candidate
	return INF
