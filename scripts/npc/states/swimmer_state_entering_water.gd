class_name SwimmerStateEnteringWater
extends NPCState

## Walks from current position to a water cell.
## First paths to shallow, then optionally moves deeper.
## On arrival, starts roaming/swimming.

var _repath_attempts: int = 0
const MAX_ATTEMPTS := 3
var _pathed: bool = false


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "GOING TO WATER"
	swimmer.set_color(Color.CYAN)

	_path_to_water(swimmer)


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	if not _pathed:
		return SwimmerStateReturning.new()  # Can't get to water, go back to spot

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
			# In the water — start swimming/wading activity
			var config := swimmer.get_activity_for_cell(swimmer.current_cell)
			if config["roaming"]:
				return SwimmerStateRoaming.new(config)
			else:
				return SwimmerStateActivity.new()

		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "TO WATER (WAIT)"

		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			if _repath_attempts >= MAX_ATTEMPTS:
				return SwimmerStateReturning.new()
			_path_to_water(swimmer)

		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "GOING TO WATER"
			swimmer.set_color(Color.CYAN)

	return null


func _path_to_water(swimmer: Swimmer) -> void:
	## Path to appropriate water zone based on profile.
	var target_type := swimmer.get_water_target_type()

	# Try to find a cell of the target depth
	var water_cell := GridManager.find_random_cell_of_type(target_type)

	# Fallback to shallow if deep isn't available
	if water_cell == null and target_type == GridCell.Type.DEEP:
		water_cell = GridManager.find_random_cell_of_type(GridCell.Type.SHALLOW)

	if water_cell == null:
		_pathed = false
		return

	swimmer.target_cell = water_cell
	if swimmer.request_path_to(water_cell):
		_pathed = true
	else:
		_pathed = false
