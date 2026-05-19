class_name SwimmerStateMoving
extends NPCState

## Follows the current path cell-to-cell.

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
			return SwimmerStateActivity.new()

		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "WAITING"
			swimmer.set_color(Color.GRAY)

		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			swimmer.debug_status = "REPATH %d" % _repath_attempts

			if _repath_attempts >= MAX_REPATH_ATTEMPTS:
				# Give up, leave the beach
				return SwimmerStateLeaving.new()

			# Try to recalculate path
			if swimmer.target_cell and swimmer.request_path_to(swimmer.target_cell):
				swimmer.set_color(Color.CYAN)
				swimmer.debug_status = "MOVING"
			else:
				return SwimmerStateLeaving.new()

		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "MOVING"
			swimmer.set_color(Color.CYAN)

	return null
