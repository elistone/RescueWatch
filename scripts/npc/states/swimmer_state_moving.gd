class_name SwimmerStateMoving
extends NPCState

## Follows path cell-to-cell. On arrival, asks swimmer what's next.

var _repath_attempts: int = 0
const MAX_REPATH_ATTEMPTS := 3


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "MOVING"
	swimmer.set_color(Color.CYAN)
	_repath_attempts = 0


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
			# Arrived — start activity at this cell
			return SwimmerStateActivity.new()

		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "WAITING"
			swimmer.set_color(Color.GRAY)

		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			if _repath_attempts >= MAX_REPATH_ATTEMPTS:
				return swimmer.pick_next_state()

			if swimmer.target_cell and swimmer.request_path_to(swimmer.target_cell):
				swimmer.set_color(Color.CYAN)
				swimmer.debug_status = "MOVING"
			else:
				return swimmer.pick_next_state()

		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "MOVING"
			swimmer.set_color(Color.CYAN)

	return null
