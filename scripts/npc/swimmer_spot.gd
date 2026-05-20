class_name SwimmerSpot
extends RefCounted

## Represents a swimmer's claimed beach spot (towel, umbrella, bag).
##
## A spot occupies one cell and belongs to one group.
## Swimmers return here between water trips.

var cell: GridCell = null
var owner: Node = null  # The swimmer or group that owns this spot
var is_set_up: bool = false

# Adjacent cells belonging to the same group
var group_spots: Array[SwimmerSpot] = []


func claim(grid_cell: GridCell, new_owner: Node) -> bool:
	if grid_cell == null:
		return false
	if grid_cell.occupied and grid_cell.occupant != new_owner:
		return false

	cell = grid_cell
	owner = new_owner
	# Don't mark as occupied — swimmer can leave and come back
	# Instead we use a separate "reserved" concept
	cell.set_meta("reserved_by", new_owner)
	return true


func release() -> void:
	if cell:
		cell.remove_meta("reserved_by")
	cell = null
	owner = null
	is_set_up = false


func is_valid() -> bool:
	return cell != null


func get_position() -> Vector2:
	if cell:
		return cell.world_position
	return Vector2.ZERO
