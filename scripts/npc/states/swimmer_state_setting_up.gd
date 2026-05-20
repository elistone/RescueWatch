class_name SwimmerStateSettingUp
extends NPCState

## Setting up at the spot — placing towel, umbrella, etc.
## A short idle period before the swimmer starts their beach day.

var _timer: float = 0.0
var _duration: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "SETTING UP"
	swimmer.set_color(Color.SANDY_BROWN)

	_duration = swimmer.profile.setup_time
	_timer = 0.0

	swimmer.has_set_up = true


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "SETTING UP %.1fs" % [_duration - _timer]

	if _timer >= _duration:
		# Done setting up — decide what to do
		return swimmer.pick_next_state()

	return null
