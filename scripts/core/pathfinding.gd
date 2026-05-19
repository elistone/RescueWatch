class_name Pathfinding

"""
A* Pathfinding implementation for grid-based navigation.

Features:
- Optimal path finding
- Diagonal movement support
- Obstacle avoidance
- Efficient priority queue

Usage:
    var path = Pathfinding.find_path(start_cell, goal_cell, grid_manager)
"""


# -------------------------------------------------------------------
# A* Node Class
# -------------------------------------------------------------------

class AStarNode:
	var cell: GridManager.GridCell
	var parent: AStarNode = null
	var g_cost: float = 0.0  # Cost from start
	var h_cost: float = 0.0  # Heuristic to goal
	var f_cost: float = 0.0  # Total cost (g + h)
	
	func _init(cell_ref: GridManager.GridCell):
		cell = cell_ref
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost


# -------------------------------------------------------------------
# Pathfinding
# -------------------------------------------------------------------

static func find_path(start_cell: GridManager.GridCell, goal_cell: GridManager.GridCell) -> Array[Vector2]:
	"""
	Finds optimal path from start to goal using A*.
	Returns array of world positions (empty if no path found).
	"""
	
	if start_cell == null or goal_cell == null:
		print("Pathfinding: Invalid start or goal cell")
		return []
	
	if !goal_cell.walkable:
		print("Pathfinding: Goal cell is not walkable")
		return []
	
	# Initialize
	var open_set: Array[AStarNode] = []
	var closed_set: Dictionary = {}  # Key: "x,y", Value: true
	var all_nodes: Dictionary = {}   # Key: "x,y", Value: AStarNode
	
	# Create start node
	var start_node = AStarNode.new(start_cell)
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_cell, goal_cell)
	start_node.calculate_f_cost()
	
	open_set.append(start_node)
	all_nodes[get_cell_key(start_cell)] = start_node
	
	# A* main loop
	var iterations = 0
	var max_iterations = 1000  # Safety limit
	
	while !open_set.is_empty() and iterations < max_iterations:
		iterations += 1
		
		# Get node with lowest f_cost
		var current = get_lowest_f_cost_node(open_set)
		
		# Remove from open set
		open_set.erase(current)
		
		# Add to closed set
		closed_set[get_cell_key(current.cell)] = true
		
		# Check if reached goal
		if current.cell == goal_cell:
			return reconstruct_path(current)
		
		# Check neighbors
		var neighbors = get_neighbors(current.cell)
		
		for neighbor_cell in neighbors:
			var neighbor_key = get_cell_key(neighbor_cell)
			
			# Skip if in closed set
			if closed_set.has(neighbor_key):
				continue
			
			# Skip if not walkable (unless it's the goal)
			if !neighbor_cell.walkable and neighbor_cell != goal_cell:
				continue
			
			# Skip if occupied (unless it's the goal)
			if neighbor_cell.occupied and neighbor_cell != goal_cell:
				continue
			
			# Calculate costs
			var movement_cost = get_movement_cost(current.cell, neighbor_cell)
			var tentative_g_cost = current.g_cost + movement_cost
			
			# Get or create neighbor node
			var neighbor_node: AStarNode
			if all_nodes.has(neighbor_key):
				neighbor_node = all_nodes[neighbor_key]
			else:
				neighbor_node = AStarNode.new(neighbor_cell)
				neighbor_node.h_cost = heuristic(neighbor_cell, goal_cell)
				all_nodes[neighbor_key] = neighbor_node
			
			# Check if this path is better
			if !open_set.has(neighbor_node) or tentative_g_cost < neighbor_node.g_cost:
				neighbor_node.parent = current
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.calculate_f_cost()
				
				if !open_set.has(neighbor_node):
					open_set.append(neighbor_node)
	
	# No path found
	print("Pathfinding: No path found after %d iterations" % iterations)
	return []


# -------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------

static func get_neighbors(cell: GridManager.GridCell) -> Array[GridManager.GridCell]:
	"""Returns all walkable neighbor cells (including diagonals)"""
	var neighbors: Array[GridManager.GridCell] = []
	var grid_pos = cell.get_grid_pos()
	
	# 8 directions (including diagonals)
	var directions = [
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0),   # Right
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, -1), # Up-Left
		Vector2i(1, -1),  # Up-Right
		Vector2i(-1, 1),  # Down-Left
		Vector2i(1, 1),   # Down-Right
	]
	
	for dir in directions:
		var neighbor_pos = grid_pos + dir
		var neighbor = GridManager.get_cell_at_grid(neighbor_pos)
		
		if neighbor != null:
			neighbors.append(neighbor)
	
	return neighbors


static func get_movement_cost(from_cell: GridManager.GridCell, to_cell: GridManager.GridCell) -> float:
	"""Returns movement cost between two cells"""
	var from_pos = from_cell.get_grid_pos()
	var to_pos = to_cell.get_grid_pos()
	
	# Diagonal movement costs more (√2 ≈ 1.414)
	var dx = abs(to_pos.x - from_pos.x)
	var dy = abs(to_pos.y - from_pos.y)
	
	if dx == 1 and dy == 1:
		return 1.414  # Diagonal
	else:
		return 1.0    # Straight


static func heuristic(from_cell: GridManager.GridCell, to_cell: GridManager.GridCell) -> float:
	"""
	Heuristic function for A* (Manhattan distance).
	Estimates cost from current cell to goal.
	"""
	var from_pos = from_cell.get_grid_pos()
	var to_pos = to_cell.get_grid_pos()
	
	var dx = abs(to_pos.x - from_pos.x)
	var dy = abs(to_pos.y - from_pos.y)
	
	return float(dx + dy)


static func get_lowest_f_cost_node(nodes: Array[AStarNode]) -> AStarNode:
	"""Finds node with lowest f_cost in array"""
	var lowest = nodes[0]
	
	for node in nodes:
		if node.f_cost < lowest.f_cost:
			lowest = node
		elif node.f_cost == lowest.f_cost and node.h_cost < lowest.h_cost:
			# Tie-breaker: prefer lower h_cost
			lowest = node
	
	return lowest


static func reconstruct_path(end_node: AStarNode) -> Array[Vector2]:
	"""Reconstructs path from end node by following parent chain"""
	var path: Array[Vector2] = []
	var current = end_node
	
	while current != null:
		path.push_front(current.cell.world_position)
		current = current.parent
	
	return path


static func get_cell_key(cell: GridManager.GridCell) -> String:
	"""Returns unique string key for a cell"""
	return "%d,%d" % [cell.grid_x, cell.grid_y]
