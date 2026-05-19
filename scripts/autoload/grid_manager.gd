extends Node

"""
GridManager - Central grid system for spatial organization (Mobile Landscape).

Manages:
- Grid cell layout (entrance, beach, water, obstacles)
- Cell occupancy tracking
- Pathfinding queries
- Debug visualization

Optimized for 1280x720 landscape mobile display.
Singleton accessed via: GridManager.get_cell_at(pos)
"""


# -------------------------------------------------------------------
# Grid Configuration (Mobile Landscape)
# -------------------------------------------------------------------

const CELL_SIZE: int = 64  # Pixels per cell
const GRID_WIDTH: int = 20  # Cells wide (1280 / 64)
const GRID_HEIGHT: int = 11  # Cells tall (704 / 64, rounded)

# Cell types
enum CellType {
	INVALID = -1,
	ENTRANCE = 0,    # Top area (spawning/leaving)
	BEACH = 1,       # Sand (sunbathing)
	SHALLOW = 2,     # Shallow water (wading)
	DEEP = 3,        # Deep water (swimming)
	OBSTACLE = 4     # Blocked (rocks, umbrellas)
}


# -------------------------------------------------------------------
# Grid Data
# -------------------------------------------------------------------

var cells: Array[GridCell] = []
var grid_2d: Array = []  # 2D array for quick lookup [x][y]


# -------------------------------------------------------------------
# Initialization
# -------------------------------------------------------------------

func _ready():
	print("=== GridManager Initializing (Mobile Landscape) ===")
	initialize_grid()
	print("Grid created: %d x %d = %d cells" % [GRID_WIDTH, GRID_HEIGHT, cells.size()])


func initialize_grid():
	"""Creates all grid cells with default types"""
	
	# Initialize 2D array
	grid_2d = []
	for x in range(GRID_WIDTH):
		grid_2d.append([])
		for y in range(GRID_HEIGHT):
			grid_2d[x].append(null)
	
	# Create cells
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell = GridCell.new()
			cell.grid_x = x
			cell.grid_y = y
			cell.world_position = grid_to_world(Vector2i(x, y))
			cell.type = determine_cell_type(x, y)
			cell.walkable = (cell.type != CellType.OBSTACLE)
			
			cells.append(cell)
			grid_2d[x][y] = cell
	
	print("Grid initialization complete")


func determine_cell_type(x: int, y: int) -> CellType:
	"""Determines what type a cell should be based on position"""
	
	# Mobile landscape layout (11 rows total):
	# Row 0-1: Entrance/Exit (2 rows)
	# Row 2-5: Beach (4 rows)
	# Row 6-8: Shallow water (3 rows)
	# Row 9-10: Deep water (2 rows)
	
	# Add some obstacles for testing pathfinding
	# Rock cluster in beach area
	if (x >= 8 and x <= 10) and (y >= 3 and y <= 4):
		return CellType.OBSTACLE
	
	# Another rock in water
	if (x >= 14 and x <= 15) and (y >= 7 and y <= 8):
		return CellType.OBSTACLE
	
	# Determine base type by row
	if y <= 1:
		return CellType.ENTRANCE
	elif y <= 5:
		return CellType.BEACH
	elif y <= 8:
		return CellType.SHALLOW
	else:
		return CellType.DEEP


# -------------------------------------------------------------------
# Grid Queries
# -------------------------------------------------------------------

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Converts world position to grid coordinates"""
	var grid_x = int(world_pos.x / CELL_SIZE)
	var grid_y = int(world_pos.y / CELL_SIZE)
	return Vector2i(grid_x, grid_y)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Converts grid coordinates to world position (cell center)"""
	var world_x = grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0
	var world_y = grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	return Vector2(world_x, world_y)


func get_cell_at_world(world_pos: Vector2) -> GridCell:
	"""Gets cell at world position"""
	var grid_pos = world_to_grid(world_pos)
	return get_cell_at_grid(grid_pos)


func get_cell_at_grid(grid_pos: Vector2i) -> GridCell:
	"""Gets cell at grid coordinates"""
	if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH:
		return null
	if grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:
		return null
	
	return grid_2d[grid_pos.x][grid_pos.y]


func is_cell_walkable(grid_pos: Vector2i) -> bool:
	"""Checks if cell can be walked on"""
	var cell = get_cell_at_grid(grid_pos)
	if cell == null:
		return false
	return cell.walkable and !cell.occupied


func is_cell_occupied(grid_pos: Vector2i) -> bool:
	"""Checks if cell is occupied by an NPC"""
	var cell = get_cell_at_grid(grid_pos)
	if cell == null:
		return true  # Out of bounds = occupied
	return cell.occupied


# -------------------------------------------------------------------
# Cell Claiming
# -------------------------------------------------------------------

func claim_cell(cell: GridCell, occupant: Node) -> bool:
	"""Claims a cell for an NPC"""
	if cell == null or cell.occupied:
		return false
	
	cell.occupied = true
	cell.occupant = occupant
	return true


func release_cell(cell: GridCell):
	"""Releases a cell"""
	if cell == null:
		return
	
	cell.occupied = false
	cell.occupant = null


func find_random_cell_of_type(type: CellType) -> GridCell:
	"""Finds a random unoccupied cell of the specified type"""
	var candidates: Array[GridCell] = []
	
	for cell in cells:
		if cell.type == type and !cell.occupied and cell.walkable:
			candidates.append(cell)
	
	if candidates.is_empty():
		return null
	
	return candidates[randi() % candidates.size()]


# -------------------------------------------------------------------
# Collision Avoidance
# -------------------------------------------------------------------

func is_cell_available_for(cell: GridCell, requester: Node) -> bool:
	"""Checks if a cell is available for an NPC to enter"""
	if cell == null:
		return false
	
	if !cell.walkable:
		return false
	
	# Cell is available if not occupied, or if occupied by the requester
	if !cell.occupied:
		return true
	
	if cell.occupant == requester:
		return true
	
	return false


# -------------------------------------------------------------------
# Pathfinding
# -------------------------------------------------------------------

func find_path(start_world: Vector2, goal_world: Vector2) -> Array[Vector2]:
	"""Finds path from start to goal (world positions)"""
	var start_cell = get_cell_at_world(start_world)
	var goal_cell = get_cell_at_world(goal_world)
	
	if start_cell == null or goal_cell == null:
		return []
	
	return Pathfinding.find_path(start_cell, goal_cell)


# -------------------------------------------------------------------
# Debug
# -------------------------------------------------------------------

func get_cell_type_name(type: CellType) -> String:
	"""Returns human-readable cell type name"""
	match type:
		CellType.ENTRANCE: return "Entrance"
		CellType.BEACH: return "Beach"
		CellType.SHALLOW: return "Shallow Water"
		CellType.DEEP: return "Deep Water"
		CellType.OBSTACLE: return "Obstacle"
		_: return "Invalid"


func get_cell_info(grid_pos: Vector2i) -> String:
	"""Returns debug info string for a cell"""
	var cell = get_cell_at_grid(grid_pos)
	if cell == null:
		return "Invalid cell"
	
	var info = "Cell (%d, %d)\n" % [grid_pos.x, grid_pos.y]
	info += "Type: %s\n" % get_cell_type_name(cell.type)
	info += "Occupied: %s\n" % ("Yes" if cell.occupied else "No")
	info += "Walkable: %s" % ("Yes" if cell.walkable else "No")
	
	return info


# -------------------------------------------------------------------
# GridCell Class
# -------------------------------------------------------------------

class GridCell:
	"""Represents a single grid cell"""
	
	var grid_x: int = 0
	var grid_y: int = 0
	var world_position: Vector2 = Vector2.ZERO
	var type: CellType = CellType.INVALID
	var walkable: bool = true
	var occupied: bool = false
	var occupant: Node = null
	
	func get_grid_pos() -> Vector2i:
		return Vector2i(grid_x, grid_y)
