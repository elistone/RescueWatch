class_name SwimmerStateActivity
extends NPCState

## Performs one activity. No follow-up — asks swimmer what's next when done.

var _timer: float = 0.0
var _duration: float = 0.0
var _activity_name: String = ""


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer

	# Get activity config from the swimmer
	var config := swimmer.get_activity_for_cell(swimmer.current_cell)
	_activity_name = config["name"]
	_duration = config["duration"]
	swimmer.set_color(config["color"])
	swimmer.debug_status = _activity_name

	_timer = 0.0


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "%s %.1fs" % [_activity_name, _duration - _timer]

	if _timer >= _duration:
		swimmer.on_activity_complete()
		return swimmer.pick_next_state()

	return null
