class_name SwimmerStateDryingOff
extends NPCState

## Drying off at the spot after being in the water.
## Short rest before deciding what to do next.

var _timer: float = 0.0
var _duration: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "DRYING OFF"
	swimmer.set_color(Color.WHEAT)

	_duration = swimmer.get_drying_off_duration()
	_timer = 0.0


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "DRYING OFF %.1fs" % [_duration - _timer]

	if _timer >= _duration:
		return swimmer.pick_next_state()

	return null
