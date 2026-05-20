class_name SwimmerStateDrowning
extends NPCState

## Swimmer is drowning — sinking, urgent, seconds to act.
## If not rescued in time, swimmer drowns (game penalty).

var _flash_timer: float = 0.0
var _sink_progress: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "DROWNING!"
	swimmer.clear_path()

	if not swimmer.is_in_group("swimmers_in_danger"):
		swimmer.add_to_group("swimmers_in_danger")

	print("[Swimmer] DROWNING at (%d,%d)! Urgent rescue needed!" % [
		swimmer.current_cell.grid_position.x if swimmer.current_cell else -1,
		swimmer.current_cell.grid_position.y if swimmer.current_cell else -1,
	])


func exit() -> void:
	var swimmer: Swimmer = npc as Swimmer
	if swimmer.is_in_group("swimmers_in_danger"):
		swimmer.remove_from_group("swimmers_in_danger")

	# Reset visual
	swimmer.body.scale = Vector2.ONE


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Urgent flashing
	_flash_timer += delta
	var flash: float = abs(sin(_flash_timer * 8.0))
	swimmer.set_color(Color.RED.lerp(Color.DARK_RED, flash))

	# Sinking visual (shrink slightly)
	_sink_progress = clampf(swimmer.fatigue.drowning_time / swimmer.fatigue.drowning_max, 0.0, 1.0)
	var sink_scale := lerpf(1.0, 0.6, _sink_progress)
	swimmer.body.scale = Vector2(sink_scale, sink_scale)

	# Check if rescued
	if swimmer.fatigue.danger_state == SwimmerFatigue.DangerState.SAFE:
		swimmer.body.scale = Vector2.ONE
		return SwimmerStateReturning.new()

	# Drowned is handled by swimmer._on_drowned()

	swimmer.debug_status = "DROWNING! %.1fs" % (swimmer.fatigue.drowning_max - swimmer.fatigue.drowning_time)

	return null
