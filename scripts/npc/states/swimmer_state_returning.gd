class_name SwimmerStateReturning
extends NPCState

## Returns to the swimmer's claimed beach spot.

var _repath_attempts: int = 0
const MAX_ATTEMPTS := 3
var _pathed: bool = false


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "RETURNING"
	swimmer.set_color(Color(0.8, 0.75, 0.6))  # Wet sand color

	_path_to_spot(swimmer)


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	if not _pathed:
		# No spot or can't path — just pick next action
		return swimmer.pick_state_after_rest()

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
			# Back at spot — dry off or relax
			if swimmer.water_trips_done > 0:
				return swimmer.pick_state_after_water()
			else:
				return swimmer.pick_state_after_rest()

		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "RETURNING (WAIT)"

		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			if _repath_attempts >= MAX_ATTEMPTS:
				return swimmer.pick_state_after_rest()
			_path_to_spot(swimmer)

		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "RETURNING"

	return null


func _path_to_spot(swimmer: Swimmer) -> void:
	if swimmer.spot == null or not swimmer.spot.is_valid():
		_pathed = false
		return

	swimmer.target_cell = swimmer.spot.cell
	if swimmer.request_path_to(swimmer.spot.cell):
		_pathed = true
	else:
		_pathed = false
