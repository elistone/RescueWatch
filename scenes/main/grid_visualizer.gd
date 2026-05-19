extends Node2D

## GridVisualizer — Toggleable debug overlay.
##
## Keybinds:
##   F1 - Toggle grid overlay
##   F2 - Toggle NPC paths
##   F3 - Toggle occupancy overlay
##
## Tap two cells to test pathfinding manually.

# -------------------------------------------------------------------
# Toggle States
# -------------------------------------------------------------------

var show_grid: bool = true
var show_paths: bool = false
var show_occupancy: bool = false

# -------------------------------------------------------------------
# Pathfinding Test
# -------------------------------------------------------------------

var test_start: GridCell = null
var test_goal: GridCell = null
var test_path: Array[Vector2i] = []
var selecting_start: bool = true

# -------------------------------------------------------------------
# Redraw Timer
# -------------------------------------------------------------------

var _redraw_timer: float = 0.0
const REDRAW_INTERVAL := 0.25  # 4 fps for debug overlay

# -------------------------------------------------------------------
# Colors
# -------------------------------------------------------------------

const CELL_COLORS := {
	GridCell.Type.ENTRANCE: Color(0.5, 0.5, 0.5, 0.3),
	GridCell.Type.BEACH: Color(0.96, 0.87, 0.70, 0.3),
	GridCell.Type.SHALLOW: Color(0.62, 0.93, 0.94, 0.3),
	GridCell.Type.DEEP: Color(0.25, 0.53, 0.82, 0.3),
	GridCell.Type.OBSTACLE: Color(0.5, 0.3, 0.2, 0.5),
}

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var info_label: Label = $CanvasLayer/Control/CellInfoLabel

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
	info_label.text = "F1: Grid | F2: Paths | F3: Occupancy\nTap 2 cells to test pathfinding"


func _process(delta: float) -> void:
	_redraw_timer += delta
	if _redraw_timer >= REDRAW_INTERVAL:
		_redraw_timer = 0.0
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_grid"):
		show_grid = not show_grid
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_toggle_paths"):
		show_paths = not show_paths
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_toggle_occupancy"):
		show_occupancy = not show_occupancy
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
		get_viewport().set_input_as_handled()


# -------------------------------------------------------------------
# Drawing
# -------------------------------------------------------------------

func _draw() -> void:
	if show_grid:
		_draw_cells()
		_draw_grid_lines()

	if show_occupancy:
		_draw_occupancy()

	if show_paths:
		_draw_npc_paths()

	_draw_test_path()


func _draw_cells() -> void:
	for cell in GridManager.get_all_cells():
		var color: Color = CELL_COLORS.get(cell.type, Color.WHITE)
		var rect := Rect2(
			cell.world_position - Vector2(GridManager.CELL_SIZE / 2.0, GridManager.CELL_SIZE / 2.0),
			Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)
		)
		draw_rect(rect, color, true)


func _draw_grid_lines() -> void:
	var w := GridManager.GRID_WIDTH * GridManager.CELL_SIZE
	var h := GridManager.GRID_HEIGHT * GridManager.CELL_SIZE
	var line_color := Color(1, 1, 1, 0.15)

	for x in range(GridManager.GRID_WIDTH + 1):
		draw_line(Vector2(x * GridManager.CELL_SIZE, 0), Vector2(x * GridManager.CELL_SIZE, h), line_color, 1.0)
	for y in range(GridManager.GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * GridManager.CELL_SIZE), Vector2(w, y * GridManager.CELL_SIZE), line_color, 1.0)


func _draw_occupancy() -> void:
	for cell in GridManager.get_all_cells():
		if cell.occupied:
			var rect := Rect2(
				cell.world_position - Vector2(GridManager.CELL_SIZE / 2.0, GridManager.CELL_SIZE / 2.0),
				Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE)
			)
			draw_rect(rect, Color(1, 0, 0, 0.4), true)


func _draw_npc_paths() -> void:
	## Draw all NPC current paths.
	var npcs := get_tree().get_nodes_in_group("npcs")
	var colors := [Color.LIME_GREEN, Color.ORANGE, Color.HOT_PINK, Color.AQUA, Color.GOLD]

	for i in range(npcs.size()):
		var npc: NPCBase = npcs[i] as NPCBase
		if npc == null or npc.path.is_empty():
			continue

		var color: Color = colors[i % colors.size()]

		# Draw from NPC position to first remaining waypoint, then waypoint chain
		var points: Array[Vector2] = [npc.position]
		for j in range(npc.path_index, npc.path.size()):
			points.append(GridManager.grid_to_world(npc.path[j]))

		for j in range(points.size() - 1):
			draw_line(points[j], points[j + 1], Color(color.r, color.g, color.b, 0.6), 2.0)

		# Draw destination marker
		if points.size() > 1:
			draw_circle(points[points.size() - 1], 6.0, color)


func _draw_test_path() -> void:
	## Draw manual pathfinding test.
	if test_start:
		_draw_marker(test_start, Color.GREEN, "S")
	if test_goal:
		_draw_marker(test_goal, Color.RED, "G")

	if test_path.size() > 1:
		for i in range(test_path.size() - 1):
			var a := GridManager.grid_to_world(test_path[i])
			var b := GridManager.grid_to_world(test_path[i + 1])
			draw_line(a, b, Color.YELLOW, 3.0)

		for i in range(test_path.size()):
			var pos := GridManager.grid_to_world(test_path[i])
			draw_circle(pos, 6.0, Color.YELLOW)


func _draw_marker(cell: GridCell, color: Color, label: String) -> void:
	var center := cell.world_position
	var size := GridManager.CELL_SIZE * 0.8
	var rect := Rect2(center - Vector2(size / 2.0, size / 2.0), Vector2(size, size))

	draw_rect(rect, Color(color.r, color.g, color.b, 0.6), true)
	draw_rect(rect, color, false, 3.0)

	if label != "":
		var font := ThemeDB.fallback_font
		var font_size := 28
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size / 2.0 + Vector2(0, font_size / 2.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)


# -------------------------------------------------------------------
# Tap Handling
# -------------------------------------------------------------------

func _handle_tap(screen_pos: Vector2) -> void:
	var cell := GridManager.get_cell_at_world(screen_pos)
	if cell == null:
		return

	if selecting_start:
		test_start = cell
		test_goal = null
		test_path.clear()
		selecting_start = false
		info_label.text = "Start: (%d,%d) %s\nTap GOAL cell" % [
			cell.grid_position.x, cell.grid_position.y,
			GridManager.get_type_name(cell.type)
		]
	else:
		test_goal = cell
		selecting_start = true

		if test_start == test_goal:
			info_label.text = "Start and Goal are the same!\nTap again."
			test_goal = null
			selecting_start = false
			return

		# Calculate path
		test_path = Pathfinding.find_path(test_start, test_goal)

		if test_path.is_empty():
			info_label.text = "No path found!\n(%d,%d) → (%d,%d)\nTap to retry" % [
				test_start.grid_position.x, test_start.grid_position.y,
				test_goal.grid_position.x, test_goal.grid_position.y
			]
		else:
			info_label.text = "Path found! %d steps\n(%d,%d) → (%d,%d)\nTap for new path" % [
				test_path.size(),
				test_start.grid_position.x, test_start.grid_position.y,
				test_goal.grid_position.x, test_goal.grid_position.y
			]
