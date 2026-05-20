class_name SwimmerStateStruggling
extends NPCState

## Swimmer is struggling — cannot move, waving for help.
## Will escalate to drowning if not rescued in time.
## Self-rescue is NOT possible from this state.

var _wave_timer: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "STRUGGLING!"
	swimmer.clear_path()

	# Add to danger group so systems can track
	if not swimmer.is_in_group("swimmers_in_danger"):
		swimmer.add_to_group("swimmers_in_danger")

	print("[Swimmer] STRUGGLING at (%d,%d)!" % [
		swimmer.current_cell.grid_position.x if swimmer.current_cell else -1,
		swimmer.current_cell.grid_position.y if swimmer.current_cell else -1,
	])


func exit() -> void:
	var swimmer: Swimmer = npc as Swimmer
	if swimmer.is_in_group("swimmers_in_danger"):
		swimmer.remove_from_group("swimmers_in_danger")


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Waving animation (toggle colour for visual feedback)
	_wave_timer += delta
	var wave: float = abs(sin(_wave_timer * 4.0))
	swimmer.set_color(Color.ORANGE_RED.lerp(Color.YELLOW, wave * 0.3))
	
	# Check if rescued (fatigue system would set state to SAFE)
	if swimmer.fatigue.danger_state == SwimmerFatigue.DangerState.SAFE:
		# Rescued! Head back to shore
		return SwimmerStateReturning.new()

	# Drowning transition is handled by swimmer._check_danger_transitions()
	# (it will force-change our state to drowning)

	swimmer.debug_status = "STRUGGLING! %.1fs" % swimmer.fatigue.struggling_time

	return null
