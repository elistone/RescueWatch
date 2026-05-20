class_name SwimmerStateFindingSpot
extends NPCState

## Walks toward the beach looking for a free spot to claim.
## Once found, transitions to setting up.

var _searching: bool = false
var _repath_attempts: int = 0
const MAX_ATTEMPTS := 5


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "FINDING SPOT"
	swimmer.set_color(Color(0.9, 0.85, 0.7))

	# Slow walking speed (carrying stuff)
	swimmer.move_speed = swimmer.profile.walk_in_speed

	_find_and_path_to_spot(swimmer)


func exit() -> void:
	# Restore normal speed
	var swimmer: Swimmer = npc as Swimmer
	swimmer.move_speed = swimmer.profile.move_speed


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	if not _searching:
		return SwimmerStateLeaving.new()

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
			# Arrived at spot — set it up
			return SwimmerStateSettingUp.new()

		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "FINDING SPOT (WAIT)"

		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			if _repath_attempts >= MAX_ATTEMPTS:
				return SwimmerStateLeaving.new()
			_find_and_path_to_spot(swimmer)

		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "FINDING SPOT"

	return null


func _find_and_path_to_spot(swimmer: Swimmer) -> void:
	## Finds an unreserved beach cell and paths to it.

	# If swimmer already has a spot assigned (by group), go there
	if swimmer.spot and swimmer.spot.is_valid():
		swimmer.target_cell = swimmer.spot.cell
		if swimmer.request_path_to(swimmer.spot.cell):
			_searching = true
			return

	# Find a free beach cell (not reserved by anyone)
	var spot_cell := _find_free_beach_cell()
	if spot_cell == null:
		_searching = false
		return

	# Claim it as our spot
	var spot := SwimmerSpot.new()
	if spot.claim(spot_cell, swimmer):
		swimmer.spot = spot
		swimmer.target_cell = spot_cell
		if swimmer.request_path_to(spot_cell):
			_searching = true
		else:
			spot.release()
			swimmer.spot = null
			_searching = false
	else:
		_searching = false


func _find_free_beach_cell() -> GridCell:
	## Finds a beach cell that isn't reserved by another swimmer.
	var all_cells := GridManager.get_all_cells()
	var candidates: Array[GridCell] = []

	for cell in all_cells:
		if cell.type != GridCell.Type.BEACH:
			continue
		if not cell.walkable:
			continue
		if cell.occupied:
			continue
		if cell.has_meta("reserved_by"):
			continue
		candidates.append(cell)

	if candidates.is_empty():
		return null

	return candidates[randi() % candidates.size()]
