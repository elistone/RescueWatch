class_name NPCBase
extends Node2D

## Base class for all grid-based NPCs.
##
## Handles:
## - Cell-to-cell discrete movement
## - Cell claiming (claim next, release previous)
## - Path following with blocked-cell handling
## - State machine integration

# -------------------------------------------------------------------
# Movement
# -------------------------------------------------------------------

@export var move_speed: float = 100.0

var current_cell: GridCell = null
var path: Array[Vector2i] = []
var path_index: int = 0

## Movement state for cell-to-cell interpolation
var _moving: bool = false
var _move_from: Vector2 = Vector2.ZERO
var _move_to: Vector2 = Vector2.ZERO
var _move_progress: float = 0.0

## Blocked handling
var _blocked_time: float = 0.0
var _max_wait: float = 0.0  # Randomized per block event

# -------------------------------------------------------------------
# State Machine
# -------------------------------------------------------------------

var state_machine: StateMachine = null

# -------------------------------------------------------------------
# Debug
# -------------------------------------------------------------------

var debug_status: String = ""

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
	add_to_group("npcs")
	state_machine = StateMachine.new(self)
	_on_ready()


func _process(delta: float) -> void:
	state_machine.process(delta)
	_update_debug()


## Override in subclass for custom setup.
func _on_ready() -> void:
	pass


## Override in subclass for custom debug display.
func _update_debug() -> void:
	pass


# -------------------------------------------------------------------
# Grid Placement
# -------------------------------------------------------------------

func place_at_cell(cell: GridCell) -> bool:
	## Places NPC at a cell immediately (no movement).
	if cell == null:
		return false

	# Release old cell
	if current_cell:
		current_cell.release()

	# Claim new cell
	if not cell.claim(self):
		return false

	current_cell = cell
	position = cell.world_position
	return true


# -------------------------------------------------------------------
# Pathfinding
# -------------------------------------------------------------------

func request_path_to(target_cell: GridCell) -> bool:
	## Calculates and stores a path to the target cell.
	## Returns true if a valid path was found.
	if target_cell == null:
		return false
	if current_cell == null:
		return false

	var new_path := Pathfinding.find_path(current_cell, target_cell)

	if new_path.is_empty():
		return false

	path = new_path
	path_index = 0
	_moving = false

	# Skip the first waypoint if it's our current cell
	if path.size() > 1 and path[0] == current_cell.grid_position:
		path_index = 1

	return true


func clear_path() -> void:
	path.clear()
	path_index = 0
	_moving = false


func has_path() -> bool:
	return path_index < path.size()


func is_path_complete() -> bool:
	return not path.is_empty() and path_index >= path.size()


# -------------------------------------------------------------------
# Cell-to-Cell Movement
# -------------------------------------------------------------------

enum MoveResult {
	MOVING,      ## Currently interpolating to next cell
	ARRIVED,     ## Reached end of path
	BLOCKED,     ## Next cell is occupied, waiting
	REPATH,      ## Waited too long, needs new path
}


func step_movement(delta: float) -> MoveResult:
	## Call this each frame during movement states.
	## Returns the current movement status.

	# Currently interpolating between cells
	if _moving:
		_move_progress += (move_speed * delta) / GridManager.CELL_SIZE
		if _move_progress >= 1.0:
			_finish_step()
			if not has_path():
				return MoveResult.ARRIVED
		else:
			position = _move_from.lerp(_move_to, _move_progress)
			return MoveResult.MOVING
		return MoveResult.MOVING

	# Need to start next step
	if not has_path():
		return MoveResult.ARRIVED

	# Try to claim next cell
	var next_grid_pos: Vector2i = path[path_index]
	var next_cell := GridManager.get_cell(next_grid_pos)

	if next_cell == null:
		return MoveResult.REPATH

	if next_cell.is_available_for(self):
		_start_step(next_cell)
		_blocked_time = 0.0
		return MoveResult.MOVING
	else:
		# Cell is blocked — wait with jitter
		_blocked_time += delta
		if _max_wait == 0.0:
			_max_wait = randf_range(0.8, 2.0)  # Jittered wait

		if _blocked_time >= _max_wait:
			_blocked_time = 0.0
			_max_wait = 0.0
			return MoveResult.REPATH

		return MoveResult.BLOCKED


func _start_step(next_cell: GridCell) -> void:
	## Begin interpolation to next cell.
	# Claim next cell
	next_cell.claim(self)

	# Release current cell
	if current_cell and current_cell != next_cell:
		current_cell.release()

	_move_from = position
	_move_to = next_cell.world_position
	_move_progress = 0.0
	_moving = true
	current_cell = next_cell
	path_index += 1


func _finish_step() -> void:
	## Snap to cell position after interpolation.
	position = _move_to
	_moving = false
