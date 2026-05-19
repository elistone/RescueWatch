class_name Swimmer
extends NPCBase

## Swimmer NPC — a beach visitor that sunbathes, wades, or swims.
##
## All movement and state logic is inherited from NPCBase.
## This class only defines swimmer-specific behavior.

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

var target_cell: GridCell = null

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
# Swimmer-Specific Logic
# -------------------------------------------------------------------

func pick_activity_destination() -> GridCell:
	## Picks a random destination based on weighted preferences.
	## Swimmers prefer beach > shallow > deep.
	var roll := randf()

	if roll < 0.5:
		return GridManager.find_random_cell_of_type(GridCell.Type.BEACH)
	elif roll < 0.8:
		return GridManager.find_random_cell_of_type(GridCell.Type.SHALLOW)
	else:
		return GridManager.find_random_cell_of_type(GridCell.Type.DEEP)


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

	debug_label.text = text
