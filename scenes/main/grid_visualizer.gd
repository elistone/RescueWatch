extends Node2D

"""
GridVisualizer - Debug overlay for grid system.

Features:
- Draw grid lines
- Color-code cell types
- Show cell occupancy
- Touch/click cell info
- Toggle visibility with F1

Mobile-optimized with touch support.
"""


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

var grid_visible: bool = true
var show_occupancy: bool = false

# Colors for cell types
const COLORS = {
	GridManager.CellType.ENTRANCE: Color(0.5, 0.5, 0.5, 0.3),  # Gray
	GridManager.CellType.BEACH: Color(0.96, 0.87, 0.70, 0.3),  # Sand
	GridManager.CellType.SHALLOW: Color(0.62, 0.93, 0.94, 0.3), # Cyan
	GridManager.CellType.DEEP: Color(0.25, 0.53, 0.82, 0.3),   # Blue
	GridManager.CellType.OBSTACLE: Color(0.5, 0.3, 0.2, 0.5),  # Brown
}

# Path visualization
var current_path: Array[Vector2] = []
var path_start_cell: GridManager.GridCell = null
var path_goal_cell: GridManager.GridCell = null
var selecting_start: bool = true  # true = selecting start, false = selecting goal

const GRID_LINE_COLOR = Color(1, 1, 1, 0.2)  # White, transparent
const OCCUPIED_COLOR = Color(1, 0, 0, 0.5)   # Red overlay for occupied


# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var cell_info_label: Label = $CanvasLayer/Control/CellInfoLabel


# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready():
	print("GridVisualizer ready")
	cell_info_label.text = "Press F1 to toggle grid\nTap 2 cells to see pathfinding"


func _process(_delta):
	# Only redraw when needed (triggered by input/changes)
	pass


func _input(event):
	# Toggle grid visibility
	if event.is_action_pressed("debug_toggle_grid"):
		grid_visible = !grid_visible
		print("Grid visibility: ", grid_visible)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	
	# Toggle occupancy overlay
	if event.is_action_pressed("debug_toggle_occupancy"):
		show_occupancy = !show_occupancy
		print("Occupancy overlay: ", show_occupancy)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	
	# Handle cell taps - ONLY use mouse events (works for both desktop and mobile with emulation)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_cell_tap(event.position)
			get_viewport().set_input_as_handled()
# -------------------------------------------------------------------
# Drawing
# -------------------------------------------------------------------

func _draw():
	if !grid_visible:
		return
	
	draw_grid_cells()
	draw_grid_lines()
	
	if show_occupancy:
		draw_occupancy_overlay()
	
	# Draw path FIRST (underneath markers)
	if current_path.size() > 1:
		draw_path()
	
	# Draw markers LAST (on top of everything)
	if path_start_cell:
		draw_cell_marker_silent(path_start_cell, Color.GREEN, "S")
	if path_goal_cell:
		draw_cell_marker_silent(path_goal_cell, Color.RED, "G")

func draw_grid_cells():
	"""Draw colored rectangles for each cell type"""
	for cell in GridManager.cells:
		var color = COLORS.get(cell.type, Color.WHITE)
		var cell_rect = Rect2(
			cell.world_position - Vector2(GridManager.CELL_SIZE / 2.0, GridManager.CELL_SIZE / 2.0),
			Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)
		)
		draw_rect(cell_rect, color, true)


func draw_grid_lines():
	"""Draw grid lines"""
	var grid_width = GridManager.GRID_WIDTH * GridManager.CELL_SIZE
	var grid_height = GridManager.GRID_HEIGHT * GridManager.CELL_SIZE
	
	# Vertical lines
	for x in range(GridManager.GRID_WIDTH + 1):
		var line_x = x * GridManager.CELL_SIZE
		draw_line(
			Vector2(line_x, 0),
			Vector2(line_x, grid_height),
			GRID_LINE_COLOR,
			1.0
		)
	
	# Horizontal lines
	for y in range(GridManager.GRID_HEIGHT + 1):
		var line_y = y * GridManager.CELL_SIZE
		draw_line(
			Vector2(0, line_y),
			Vector2(grid_width, line_y),
			GRID_LINE_COLOR,
			1.0
		)


func draw_occupancy_overlay():
	"""Draw red overlay on occupied cells"""
	for cell in GridManager.cells:
		if cell.occupied:
			var cell_rect = Rect2(
				cell.world_position - Vector2(GridManager.CELL_SIZE / 2.0, GridManager.CELL_SIZE / 2.0),
				Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)
			)
			draw_rect(cell_rect, OCCUPIED_COLOR, true)
			
			# Draw X in occupied cell
			var half_size = GridManager.CELL_SIZE / 2.0
			var center = cell.world_position
			draw_line(
				center + Vector2(-half_size * 0.5, -half_size * 0.5),
				center + Vector2(half_size * 0.5, half_size * 0.5),
				Color.RED,
				2.0
			)
			draw_line(
				center + Vector2(half_size * 0.5, -half_size * 0.5),
				center + Vector2(-half_size * 0.5, half_size * 0.5),
				Color.RED,
				2.0
			)


# -------------------------------------------------------------------
# Input Handling
# -------------------------------------------------------------------

func handle_cell_tap(screen_pos: Vector2):
	"""Handle tap/click on a cell"""
	var world_pos = screen_pos
	var cell = GridManager.get_cell_at_world(world_pos)
	
	if cell == null:
		cell_info_label.text = "No cell at this position"
		return
	
	print("\n=== Cell Tap ===")
	print("Clicked cell: (%d, %d)" % [cell.grid_x, cell.grid_y])
	print("selecting_start: %s" % selecting_start)
	print("path_start_cell: %s" % ("set" if path_start_cell else "null"))
	print("path_goal_cell: %s" % ("set" if path_goal_cell else "null"))
	
	# Path selection mode
	if selecting_start:
		# First click - set start
		print("→ Setting as START cell")
		path_start_cell = cell
		path_goal_cell = null  # Clear previous goal
		current_path.clear()   # Clear previous path
		selecting_start = false
		
		cell_info_label.text = "✓ Start: Cell (%d, %d) [%s]\n\nNow tap GOAL cell" % [
			cell.grid_x, 
			cell.grid_y,
			GridManager.get_cell_type_name(cell.type)
		]
		queue_redraw()
	else:
		# Second click - set goal and calculate
		print("→ Setting as GOAL cell")
		path_goal_cell = cell
		selecting_start = true
		
		# Safety check before calculating
		if path_start_cell == null:
			print("ERROR: Start cell is null! Resetting.")
			selecting_start = true
			queue_redraw()
			return
		
		if path_start_cell == path_goal_cell:
			print("WARNING: Start and goal are the same cell!")
			cell_info_label.text = "⚠️ Start and Goal are the same!\nTap a different cell."
			path_goal_cell = null
			selecting_start = false
			queue_redraw()
			return
		
		calculate_and_display_path()		
		
func calculate_and_display_path():
	"""Calculate path from start to goal and display it"""
	if path_start_cell == null:
		print("ERROR: Start cell is null!")
		cell_info_label.text = "ERROR: No start cell set"
		return
	
	if path_goal_cell == null:
		print("ERROR: Goal cell is null!")
		cell_info_label.text = "ERROR: No goal cell set"
		return
	
	if path_start_cell == path_goal_cell:
		print("ERROR: Start and goal are the same!")
		cell_info_label.text = "ERROR: Start and goal must be different"
		return
	
	print("\n=== Calculating Path ===")
	print("Start: (%d, %d) - %s" % [
		path_start_cell.grid_x, 
		path_start_cell.grid_y,
		GridManager.get_cell_type_name(path_start_cell.type)
	])
	print("Goal: (%d, %d) - %s" % [
		path_goal_cell.grid_x, 
		path_goal_cell.grid_y,
		GridManager.get_cell_type_name(path_goal_cell.type)
	])
	
	# Calculate path
	current_path = GridManager.find_path(
		path_start_cell.world_position,
		path_goal_cell.world_position
	)
	
	print("Path result: %d waypoints" % current_path.size())
	
	# Display results
	if current_path.is_empty():
		cell_info_label.text = "❌ No path found!\n\nStart: (%d, %d) %s\nGoal: (%d, %d) %s\n\nTap to try again" % [
			path_start_cell.grid_x, path_start_cell.grid_y,
			GridManager.get_cell_type_name(path_start_cell.type),
			path_goal_cell.grid_x, path_goal_cell.grid_y,
			GridManager.get_cell_type_name(path_goal_cell.type)
		]
	else:
		var path_length = 0.0
		for i in range(current_path.size() - 1):
			path_length += current_path[i].distance_to(current_path[i + 1])
		
		cell_info_label.text = "✓ Path found!\n\nStart: (%d, %d) %s\nGoal: (%d, %d) %s\n\nSteps: %d\nLength: %.0f px\n\nTap for new path" % [
			path_start_cell.grid_x, path_start_cell.grid_y,
			GridManager.get_cell_type_name(path_start_cell.type),
			path_goal_cell.grid_x, path_goal_cell.grid_y,
			GridManager.get_cell_type_name(path_goal_cell.type),
			current_path.size(),
			path_length
		]
	
	print("=== Path Calculation Complete ===\n")
	queue_redraw()

func display_cell_info(cell: GridManager.GridCell):
	"""Display info about a cell"""
	var info = "Cell (%d, %d)\n" % [cell.grid_x, cell.grid_y]
	info += "Type: %s\n" % GridManager.get_cell_type_name(cell.type)
	info += "World Pos: (%.0f, %.0f)\n" % [cell.world_position.x, cell.world_position.y]
	info += "Walkable: %s\n" % ("Yes" if cell.walkable else "No")
	info += "Occupied: %s" % ("Yes" if cell.occupied else "No")
	
	if cell.occupant:
		info += "\nOccupant: %s" % cell.occupant.name
	
	cell_info_label.text = info
	print(info)
	
func draw_path():
	"""Draw the calculated path"""
	# Draw path line
	for i in range(current_path.size() - 1):
		var start = current_path[i]
		var end = current_path[i + 1]
		draw_line(start, end, Color.YELLOW, 3.0)
	
	# Draw waypoints
	for i in range(current_path.size()):
		var pos = current_path[i]
		var color = Color.GREEN if i == 0 else (Color.RED if i == current_path.size() - 1 else Color.YELLOW)
		draw_circle(pos, 8.0, color)
		
		# Draw step number
		if i > 0 and i < current_path.size() - 1:
			var font = ThemeDB.fallback_font
			var font_size = 12
			draw_string(font, pos + Vector2(-6, -12), str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)

func draw_cell_marker_silent(cell: GridManager.GridCell, color: Color, label: String = ""):
	"""Draw a marker on a cell (no console output)"""
	var center = cell.world_position
	var size = GridManager.CELL_SIZE * 0.8
	
	# Draw a BIG rectangle (easier to see than circles)
	var rect = Rect2(
		center - Vector2(size / 2.0, size / 2.0),
		Vector2(size, size)
	)
	
	# Filled rectangle
	draw_rect(rect, Color(color.r, color.g, color.b, 0.7), true)
	
	# Border
	draw_rect(rect, color, false, 4.0)
	
	# Draw HUGE label
	if label != "":
		var font = ThemeDB.fallback_font
		var font_size = 32
		var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size / 2.0 + Vector2(0, font_size / 2.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)

func draw_cell_marker(cell: GridManager.GridCell, color: Color, label: String = ""):
	"""Draw a marker on a cell"""
	var center = cell.world_position
	var size = GridManager.CELL_SIZE * 0.4
	
	# DEBUG: Print where we're drawing
	print("Drawing marker '%s' at world: (%.0f, %.0f) grid: (%d, %d)" % [
		label, center.x, center.y, cell.grid_x, cell.grid_y
	])
	
	# Draw filled circle
	draw_circle(center, size, Color(color.r, color.g, color.b, 0.6))
	
	# Draw border
	draw_arc(center, size, 0, TAU, 32, color, 3.0)
	
	# Draw label
	if label != "":
		var font = ThemeDB.fallback_font
		var font_size = 20
		var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size / 2.0 + Vector2(0, font_size / 2.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

# -------------------------------------------------------------------
# UI Callbacks
# -------------------------------------------------------------------

func _on_toggle_grid_button_pressed():
	"""Called when toggle grid button pressed"""
	grid_visible = !grid_visible
	print("Grid visibility: ", grid_visible)
	queue_redraw()
