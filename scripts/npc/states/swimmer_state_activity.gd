class_name SwimmerStateActivity
extends NPCState

## Performs an activity (sunbathe, wade, swim) then transitions to leaving.

var _timer: float = 0.0
var _duration: float = 0.0


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "ACTIVITY"

	# Determine activity based on cell type
	if swimmer.current_cell == null:
		_duration = 1.0
		return

	match swimmer.current_cell.type:
		GridCell.Type.BEACH:
			_duration = randf_range(3.0, 6.0)
			swimmer.set_color(Color.ORANGE)
			swimmer.debug_status = "SUNBATHING"
		GridCell.Type.SHALLOW:
			_duration = randf_range(2.0, 4.0)
			swimmer.set_color(Color.LIGHT_BLUE)
			swimmer.debug_status = "WADING"
		GridCell.Type.DEEP:
			_duration = randf_range(4.0, 8.0)
			swimmer.set_color(Color.DODGER_BLUE)
			swimmer.debug_status = "SWIMMING"
		_:
			_duration = 1.0

	_timer = 0.0


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "%s %.1fs" % [swimmer.debug_status.split(" ")[0], _duration - _timer]

	if _timer >= _duration:
		return SwimmerStateLeaving.new()

	return null
