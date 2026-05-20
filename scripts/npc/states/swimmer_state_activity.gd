class_name SwimmerStateActivity
extends NPCState

## Stationary activity — relaxing at spot, sunbathing, etc.
## Routes to SwimmerStateRoaming for water activities.

var _timer: float = 0.0
var _duration: float = 0.0
var _activity_name: String = ""


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer

	# Check if this should be a roaming activity
	var config := swimmer.get_activity_for_cell(swimmer.current_cell)
	if config["roaming"]:
		swimmer.set_meta("pending_roam_config", config)
		return

	_activity_name = config["name"]
	_duration = config["duration"]
	swimmer.set_color(config["color"])
	swimmer.debug_status = _activity_name
	_timer = 0.0


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Redirect to roaming if needed
	if swimmer.has_meta("pending_roam_config"):
		var config: Dictionary = swimmer.get_meta("pending_roam_config")
		swimmer.remove_meta("pending_roam_config")
		return SwimmerStateRoaming.new(config)

	_timer += delta
	swimmer.debug_status = "%s %.1fs" % [_activity_name, _duration - _timer]

	if _timer >= _duration:
		swimmer.on_activity_complete()
		return swimmer.pick_state_after_rest()

	return null
