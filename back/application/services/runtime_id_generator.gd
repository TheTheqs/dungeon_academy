class_name RuntimeIdGenerator
extends RefCounted

# Share one generator per match across all entities that need runtime IDs.
# IDs are unique within that instance's sequence, not across matches/processes.
var _next_id: int = 1

func generate_id() -> String:
	var runtime_id := str(_next_id)
	_next_id += 1
	return runtime_id
