class_name Swimmer
extends NPCBase

## Swimmer NPC — a beach visitor that performs random activities.
##
## Controls its own lifecycle: how many activities to do,
## whether to leave, and what to do next.

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

## Set to -1 for infinite activities (never leaves), 0+ for a limit.
@export var max_activities: int = -1

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

var target_cell: GridCell = null
var activities_completed: int = 0

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var body: ColorRect = $Body
@onready var debug_label: Label = $DebugLabel

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------

func _on_ready() -> void:
	add_to_group("swimmers")
	state_machine.change_state(SwimmerStateSpawning.new())


# -------------------------------------------------------------------
# Decision Making
# -------------------------------------------------------------------

func pick_next_state() -> NPCState:
	## Called by states when they finish. Swimmer decides what to do next.

	# Check if we should leave
	if max_activities >= 0 and activities_completed >= max_activities:
		return SwimmerStateLeaving.new()

	# Pick a new activity destination
	var destination := _pick_destination()
	if destination and request_path_to(destination):
		target_cell = destination
		return SwimmerStateMoving.new()

	# Couldn't path anywhere — try leaving
	return SwimmerStateLeaving.new()


func on_activity_complete() -> void:
	## Called by activity state when it finishes.
	activities_completed += 1


# -------------------------------------------------------------------
# Destination Picking
# -------------------------------------------------------------------

func _pick_destination() -> GridCell:
	## Weighted random destination. Override or expand as needed.
	var roll := randf()

	if roll < 0.5:
		return GridManager.find_random_cell_of_type(GridCell.Type.BEACH)
	elif roll < 0.8:
		return GridManager.find_random_cell_of_type(GridCell.Type.SHALLOW)
	else:
		return GridManager.find_random_cell_of_type(GridCell.Type.DEEP)


# -------------------------------------------------------------------
# Activity Config
# -------------------------------------------------------------------

func get_activity_for_cell(cell: GridCell) -> Dictionary:
	## Returns activity config for a given cell type.
	## Each activity is self-contained — no follow-up.
	match cell.type:
		GridCell.Type.BEACH:
			return {
				"name": "SUNBATHING",
				"duration": randf_range(3.0, 6.0),
				"color": Color.ORANGE,
			}
		GridCell.Type.SHALLOW:
			return {
				"name": "WADING",
				"duration": randf_range(2.0, 4.0),
				"color": Color.LIGHT_BLUE,
			}
		GridCell.Type.DEEP:
			return {
				"name": "SWIMMING",
				"duration": randf_range(4.0, 8.0),
				"color": Color.DODGER_BLUE,
			}
		_:
			return {
				"name": "IDLE",
				"duration": 1.0,
				"color": Color.WHITE,
			}


# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func set_color(color: Color) -> void:
	if body:
		body.color = color


# -------------------------------------------------------------------
# Debug
# -------------------------------------------------------------------

func _update_debug() -> void:
	if debug_label == null:
		return

	var text := debug_status

	if current_cell:
		text += "\n(%d,%d)" % [current_cell.grid_position.x, current_cell.grid_position.y]

	if max_activities >= 0:
		text += "\n%d/%d" % [activities_completed, max_activities]

	debug_label.text = text
