class_name SwimmerStateMoving
extends NPCState

## Follows path cell-to-cell with personality-driven pauses.

var _repath_attempts: int = 0
const MAX_REPATH_ATTEMPTS := 3

# Pause between steps
var _pausing: bool = false
var _pause_timer: float = 0.0
var _pause_duration: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "MOVING"
	swimmer.set_color(Color.CYAN)
	_repath_attempts = 0
	_pausing = false


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Handle pause
	if _pausing:
		_pause_timer += delta
		swimmer.debug_status = "PAUSING"
		if _pause_timer >= _pause_duration:
			_pausing = false
		return null

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
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

			# Check for random pause after each step completes
			if not swimmer._moving and swimmer.has_path():
				if swimmer.should_pause():
					_pausing = true
					_pause_timer = 0.0
					_pause_duration = swimmer.get_pause_duration()

	return null
