class_name SwimmerStateActivity
extends NPCState

## Performs a stationary activity (e.g. sunbathing).
## For water activities, transitions to SwimmerStateRoaming instead.

var _timer: float = 0.0
var _duration: float = 0.0
var _activity_name: String = ""


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	var config := swimmer.get_activity_for_cell(swimmer.current_cell)

	# If this is a roaming activity, switch to roaming state
	if config["roaming"]:
		# We'll handle this in process() on first frame
		# Store config so roaming state can read it
		swimmer.set_meta("pending_roam_config", config)
		return

	_activity_name = config["name"]
	_duration = config["duration"]
	swimmer.set_color(config["color"])
	swimmer.debug_status = _activity_name
	_timer = 0.0


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Check if we need to redirect to roaming
	if swimmer.has_meta("pending_roam_config"):
		var config: Dictionary = swimmer.get_meta("pending_roam_config")
		swimmer.remove_meta("pending_roam_config")
		return SwimmerStateRoaming.new(config)

	_timer += delta
	swimmer.debug_status = "%s %.1fs" % [_activity_name, _duration - _timer]

	if _timer >= _duration:
		swimmer.on_activity_complete()
		return swimmer.pick_next_state()

	return null
