class_name Pathfinding
extends RefCounted

## A* pathfinding for 8-directional grid movement.
##
## NOTE: This does NOT check cell occupancy. Occupancy is transient —
## with 200+ NPCs, paths would constantly invalidate. Instead, NPCs
## handle blocked cells at move-time (wait + retry).

const STRAIGHT_COST := 1.0
const DIAGONAL_COST := 1.414


static func find_path(start: GridCell, goal: GridCell) -> Array[Vector2i]:
	## Returns array of grid positions from start to goal (inclusive).
	## Returns empty array if no path exists.

	if start == null or goal == null:
		return []
	if not goal.walkable:
		return []
	if start == goal:
		return [start.grid_position]

	var open_set: Array = []  # Array of _Node
	var closed: Dictionary = {}  # "x,y" -> true
	var nodes: Dictionary = {}  # "x,y" -> _Node

	var start_node := _Node.new(start)
	start_node.g = 0.0
	start_node.h = _heuristic(start, goal)
	start_node.f = start_node.h
	open_set.append(start_node)
	nodes[_key(start)] = start_node

	var iterations := 0

	while not open_set.is_empty() and iterations < 2000:
		iterations += 1

		# Get lowest f-cost node
		var current: _Node = _pop_lowest(open_set)
		var current_key := _key(current.cell)

		if current.cell == goal:
			return _reconstruct(current)

		closed[current_key] = true

		for neighbor_cell in GridManager.get_neighbors(current.cell):
			var nkey := _key(neighbor_cell)

			if closed.has(nkey):
				continue
			if not neighbor_cell.walkable:
				continue

			var move_cost := _movement_cost(current.cell, neighbor_cell)
			var tentative_g := current.g + move_cost

			var neighbor_node: _Node
			if nodes.has(nkey):
				neighbor_node = nodes[nkey]
			else:
				neighbor_node = _Node.new(neighbor_cell)
				neighbor_node.h = _heuristic(neighbor_cell, goal)
				nodes[nkey] = neighbor_node

			if tentative_g < neighbor_node.g:
				neighbor_node.parent = current
				neighbor_node.g = tentative_g
				neighbor_node.f = tentative_g + neighbor_node.h

				if neighbor_node not in open_set:
					open_set.append(neighbor_node)

	return []  # No path found


# -------------------------------------------------------------------
# Internals
# -------------------------------------------------------------------

static func _heuristic(a: GridCell, b: GridCell) -> float:
	var dx: int = abs(a.grid_position.x - b.grid_position.x)
	var dy: int = abs(a.grid_position.y - b.grid_position.y)
	return STRAIGHT_COST * (dx + dy) + (DIAGONAL_COST - 2.0 * STRAIGHT_COST) * min(dx, dy)


static func _movement_cost(from: GridCell, to: GridCell) -> float:
	var dx: int = abs(to.grid_position.x - from.grid_position.x)
	var dy: int = abs(to.grid_position.y - from.grid_position.y)
	if dx == 1 and dy == 1:
		return DIAGONAL_COST
	return STRAIGHT_COST


static func _key(cell: GridCell) -> String:
	return "%d,%d" % [cell.grid_position.x, cell.grid_position.y]


static func _pop_lowest(open_set: Array) -> _Node:
	var lowest_idx := 0
	var lowest_f: float = open_set[0].f

	for i in range(1, open_set.size()):
		if open_set[i].f < lowest_f or (open_set[i].f == lowest_f and open_set[i].h < open_set[lowest_idx].h):
			lowest_f = open_set[i].f
			lowest_idx = i

	var node = open_set[lowest_idx]
	open_set.remove_at(lowest_idx)
	return node


static func _reconstruct(end_node) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = end_node
	while current != null:
		path.push_front(current.cell.grid_position)
		current = current.parent
	return path


# -------------------------------------------------------------------
# Internal Node Class
# -------------------------------------------------------------------

class _Node:
	var cell: GridCell
	var parent: _Node = null
	var g: float = INF
	var h: float = 0.0
	var f: float = INF

	func _init(c: GridCell) -> void:
		cell = c
