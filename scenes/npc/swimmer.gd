extends Node2D
class_name Swimmer

"""
Swimmer NPC - Grid-based beach visitor.

Features:
- Grid-based pathfinding
- Smooth cell-to-cell movement
- Simple state machine
- Activity lifecycle

States:
- SPAWNING: Just created, planning activities
- MOVING: Walking/swimming to target cell
- ACTIVITY: Doing something (sunbathing, swimming)
- LEAVING: Exiting the beach
"""


# -------------------------------------------------------------------
# State Machine
# -------------------------------------------------------------------

enum State {
	SPAWNING,
	MOVING,
	ACTIVITY,
	LEAVING,
	EXITED
}

var current_state: State = State.SPAWNING


# -------------------------------------------------------------------
# Movement
# -------------------------------------------------------------------

var current_cell: GridManager.GridCell = null
var target_cell: GridManager.GridCell = null
var path: Array[Vector2] = []
var path_index: int = 0

var move_speed: float = 100.0  # Pixels per second
var arrival_threshold: float = 5.0


# -------------------------------------------------------------------
# Activity
# -------------------------------------------------------------------

var activity_timer: float = 0.0
var activity_duration: float = 0.0


# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var body: ColorRect = $Body
@onready var debug_label: Label = $DebugLabel


# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready():
	print("[Swimmer] Created at position: %s" % position)
	
	# Start at a random entrance cell
	spawn_at_entrance()
	
	# Plan first activity
	plan_beach_visit()


func _process(delta):
	# Update state machine
	match current_state:
		State.SPAWNING:
			process_spawning(delta)
		State.MOVING:
			process_moving(delta)
		State.ACTIVITY:
			process_activity(delta)
		State.LEAVING:
			process_leaving(delta)
		State.EXITED:
			process_exited(delta)
	
	# Update debug display
	update_debug_label()


# -------------------------------------------------------------------
# State Handlers
# -------------------------------------------------------------------

func process_spawning(_delta):
	"""Initial state - planning first activity"""
	# Already planned in _ready(), just transition
	change_state(State.MOVING)


func process_moving(delta):
	"""Moving along path to target cell"""
	if path.is_empty():
		print("[Swimmer] No path - arriving at destination")
		arrive_at_target()
		return
	
	# Get current waypoint
	var waypoint = path[path_index]
	
	# Move toward waypoint
	var direction = (waypoint - position).normalized()
	var distance = position.distance_to(waypoint)
	
	if distance < arrival_threshold:
		# Reached waypoint
		path_index += 1
		
		if path_index >= path.size():
			# Reached end of path
			arrive_at_target()
		else:
			# Move to next waypoint
			print("[Swimmer] Reached waypoint %d/%d" % [path_index, path.size()])
	else:
		# Move toward waypoint
		position += direction * move_speed * delta


func process_activity(delta):
	"""Doing an activity (sunbathing, swimming, etc)"""
	activity_timer += delta
	
	if activity_timer >= activity_duration:
		print("[Swimmer] Activity complete")
		finish_activity()


func process_leaving(delta):
	"""Moving to exit"""
	process_moving(delta)


func process_exited(_delta):
	"""Off-screen, ready to be removed"""
	pass


# -------------------------------------------------------------------
# State Transitions
# -------------------------------------------------------------------

func change_state(new_state: State):
	"""Changes state with logging"""
	print("[Swimmer] State change: %s → %s" % [get_state_name(current_state), get_state_name(new_state)])
	current_state = new_state


func get_state_name(state: State) -> String:
	"""Returns human-readable state name"""
	match state:
		State.SPAWNING: return "SPAWNING"
		State.MOVING: return "MOVING"
		State.ACTIVITY: return "ACTIVITY"
		State.LEAVING: return "LEAVING"
		State.EXITED: return "EXITED"
		_: return "UNKNOWN"


# -------------------------------------------------------------------
# Spawning
# -------------------------------------------------------------------

func spawn_at_entrance():
	"""Spawns swimmer at random entrance cell"""
	var entrance_cell = GridManager.find_random_cell_of_type(GridManager.CellType.ENTRANCE)
	
	if entrance_cell == null:
		push_error("[Swimmer] No entrance cells available!")
		return
	
	position = entrance_cell.world_position
	current_cell = entrance_cell
	
	print("[Swimmer] Spawned at cell (%d, %d)" % [entrance_cell.grid_x, entrance_cell.grid_y])


# -------------------------------------------------------------------
# Activity Planning
# -------------------------------------------------------------------

func plan_beach_visit():
	"""Plans a simple beach visit: entrance → beach → sunbathe → exit"""
	print("[Swimmer] Planning beach visit")
	
	# Find a beach cell to visit
	var beach_cell = GridManager.find_random_cell_of_type(GridManager.CellType.BEACH)
	
	if beach_cell == null:
		print("[Swimmer] No beach cells available! Leaving.")
		plan_exit()
		return
	
	# Move to beach
	move_to_cell(beach_cell)


func plan_exit():
	"""Plans exit from beach"""
	print("[Swimmer] Planning exit")
	
	var exit_cell = GridManager.find_random_cell_of_type(GridManager.CellType.ENTRANCE)
	
	if exit_cell == null:
		print("[Swimmer] No exit cells available!")
		change_state(State.EXITED)
		queue_free()
		return
	
	change_state(State.LEAVING)
	move_to_cell(exit_cell)


# -------------------------------------------------------------------
# Movement
# -------------------------------------------------------------------

func move_to_cell(cell: GridManager.GridCell):
	"""Starts movement to target cell using pathfinding"""
	if cell == null:
		print("[Swimmer] Cannot move to null cell")
		return
	
	target_cell = cell
	
	# Calculate path
	path = GridManager.find_path(position, cell.world_position)
	path_index = 0
	
	if path.is_empty():
		print("[Swimmer] No path found to (%d, %d)" % [cell.grid_x, cell.grid_y])
		# Try alternative: just leave
		plan_exit()
		return
	
	print("[Swimmer] Moving to cell (%d, %d) - path has %d waypoints" % [
		cell.grid_x, cell.grid_y, path.size()
	])
	
	# Release current cell
	if current_cell:
		GridManager.release_cell(current_cell)
	
	# Claim target cell
	if GridManager.claim_cell(target_cell, self):
		print("[Swimmer] Claimed cell (%d, %d)" % [target_cell.grid_x, target_cell.grid_y])
	else:
		print("[Swimmer] Could not claim cell (%d, %d) - already occupied!" % [target_cell.grid_x, target_cell.grid_y])


func arrive_at_target():
	"""Called when swimmer reaches target cell"""
	print("[Swimmer] Arrived at target cell")
	
	current_cell = target_cell
	target_cell = null
	path.clear()
	path_index = 0
	
	# Decide what to do based on current state
	if current_state == State.MOVING:
		# Start activity
		start_activity()
	elif current_state == State.LEAVING:
		# Exit complete
		change_state(State.EXITED)
		GridManager.release_cell(current_cell)
		queue_free()
		print("[Swimmer] Exited beach")


# -------------------------------------------------------------------
# Activities
# -------------------------------------------------------------------

func start_activity():
	"""Starts an activity at current cell"""
	if current_cell == null:
		return
	
	# Determine activity based on cell type
	match current_cell.type:
		GridManager.CellType.BEACH:
			start_sunbathing()
		GridManager.CellType.SHALLOW:
			start_wading()
		GridManager.CellType.DEEP:
			start_swimming()
		_:
			# Unknown activity, just leave
			finish_activity()


func start_sunbathing():
	"""Sunbathe on beach"""
	print("[Swimmer] Starting sunbathing")
	change_state(State.ACTIVITY)
	activity_duration = randf_range(3.0, 6.0)
	activity_timer = 0.0
	body.color = Color.ORANGE  # Orange for sunbathing


func start_wading():
	"""Wade in shallow water"""
	print("[Swimmer] Starting wading")
	change_state(State.ACTIVITY)
	activity_duration = randf_range(2.0, 4.0)
	activity_timer = 0.0
	body.color = Color.LIGHT_BLUE  # Light blue for wading


func start_swimming():
	"""Swim in deep water"""
	print("[Swimmer] Starting swimming")
	change_state(State.ACTIVITY)
	activity_duration = randf_range(4.0, 8.0)
	activity_timer = 0.0
	body.color = Color.DODGER_BLUE  # Blue for swimming


func finish_activity():
	"""Called when activity completes"""
	print("[Swimmer] Finishing activity")
	
	# After activity, leave the beach
	plan_exit()


# -------------------------------------------------------------------
# Debug
# -------------------------------------------------------------------

func update_debug_label():
	"""Updates debug label"""
	var text = get_state_name(current_state)
	
	if current_cell:
		text += "\n(%d,%d)" % [current_cell.grid_x, current_cell.grid_y]
	
	if current_state == State.ACTIVITY:
		text += "\n%.1fs" % (activity_duration - activity_timer)
	
	debug_label.text = text
