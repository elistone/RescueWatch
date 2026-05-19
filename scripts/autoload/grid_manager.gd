extends Node

## GridManager — Central grid system for spatial organization.
##
## Manages grid layout, cell queries, and cell claiming.
## Singleton accessed via: GridManager.get_cell(pos)

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

const CELL_SIZE: int = 64
const GRID_WIDTH: int = 20   # 1280 / 64
const GRID_HEIGHT: int = 11  # 704 / 64 (rounded)

# -------------------------------------------------------------------
# Grid Data
# -------------------------------------------------------------------

var _cells: Array[GridCell] = []
var _grid: Array = []  # 2D: _grid[x][y]

# -------------------------------------------------------------------
# Initialization
# -------------------------------------------------------------------

func _ready() -> void:
	_build_grid()


func _build_grid() -> void:
	_cells.clear()
	_grid.clear()

	for x in range(GRID_WIDTH):
		_grid.append([])
		for y in range(GRID_HEIGHT):
			var cell_type := _determine_type(x, y)
			var world_pos := _grid_to_world(Vector2i(x, y))
			var cell := GridCell.new(Vector2i(x, y), world_pos, cell_type)
			_cells.append(cell)
			_grid[x].append(cell)


func _determine_type(x: int, y: int) -> GridCell.Type:
	# Obstacles (testing)
	if x >= 8 and x <= 10 and y >= 3 and y <= 4:
		return GridCell.Type.OBSTACLE
	if x >= 14 and x <= 15 and y >= 7 and y <= 8:
		return GridCell.Type.OBSTACLE

	# Layout by row
	if y <= 1:
		return GridCell.Type.ENTRANCE
	elif y <= 5:
		return GridCell.Type.BEACH
	elif y <= 8:
		return GridCell.Type.SHALLOW
	else:
		return GridCell.Type.DEEP


# -------------------------------------------------------------------
# Coordinate Conversion
# -------------------------------------------------------------------

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return _grid_to_world(grid_pos)


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)


# -------------------------------------------------------------------
# Cell Queries
# -------------------------------------------------------------------

func get_cell(grid_pos: Vector2i) -> GridCell:
	if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH:
		return null
	if grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:
		return null
	return _grid[grid_pos.x][grid_pos.y]


func get_cell_at_world(world_pos: Vector2) -> GridCell:
	return get_cell(world_to_grid(world_pos))


func get_all_cells() -> Array[GridCell]:
	return _cells


func find_random_cell_of_type(type: GridCell.Type) -> GridCell:
	var candidates: Array[GridCell] = []
	for cell in _cells:
		if cell.type == type and not cell.occupied and cell.walkable:
			candidates.append(cell)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


# -------------------------------------------------------------------
# Pathfinding Helpers
# -------------------------------------------------------------------

func get_neighbors(cell: GridCell) -> Array[GridCell]:
	## Returns all valid neighbor cells (8 directions).
	var neighbors: Array[GridCell] = []
	var pos := cell.grid_position

	for dir in [
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]:
		var neighbor := get_cell(pos + dir)
		if neighbor != null:
			neighbors.append(neighbor)

	return neighbors


# -------------------------------------------------------------------
# Debug Helpers
# -------------------------------------------------------------------

func get_type_name(type: GridCell.Type) -> String:
	match type:
		GridCell.Type.ENTRANCE: return "Entrance"
		GridCell.Type.BEACH: return "Beach"
		GridCell.Type.SHALLOW: return "Shallow"
		GridCell.Type.DEEP: return "Deep"
		GridCell.Type.OBSTACLE: return "Obstacle"
		_: return "Invalid"
