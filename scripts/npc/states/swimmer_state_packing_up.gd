class_name SwimmerStatePackingUp
extends NPCState

## Packing up at the spot before leaving.
## Returns to spot first if not there, then packs up, then leaves.

var _timer: float = 0.0
var _duration: float = 0.0
var _at_spot: bool = false
var _pathing_to_spot: bool = false
var _repath_attempts: int = 0
const MAX_ATTEMPTS := 3


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "PACKING UP"
	swimmer.set_color(Color.ROSY_BROWN)

	_duration = swimmer.profile.packing_time

	# Check if we're at our spot
	if swimmer.spot and swimmer.spot.is_valid():
		if swimmer.current_cell == swimmer.spot.cell:
			_at_spot = true
		else:
			# Need to go back to spot first
			_path_to_spot(swimmer)
	else:
		# No spot — just leave
		_at_spot = true
		_duration = 0.5


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Walking back to spot
	if _pathing_to_spot:
		var result := swimmer.step_movement(delta)
		match result:
			NPCBase.MoveResult.ARRIVED:
				_at_spot = true
				_pathing_to_spot = false
			NPCBase.MoveResult.BLOCKED:
				swimmer.debug_status = "GOING TO PACK (WAIT)"
			NPCBase.MoveResult.REPATH:
				_repath_attempts += 1
				if _repath_attempts >= MAX_ATTEMPTS:
					_at_spot = true  # Give up, pack wherever we are
					_pathing_to_spot = false
				else:
					_path_to_spot(swimmer)
			NPCBase.MoveResult.MOVING:
				swimmer.debug_status = "GOING TO PACK"
		return null

	# At spot — packing up
	if _at_spot:
		_timer += delta
		swimmer.debug_status = "PACKING UP %.1fs" % [_duration - _timer]

		if _timer >= _duration:
			# Release spot
			if swimmer.spot:
				swimmer.spot.release()
				swimmer.spot = null
			return SwimmerStateLeaving.new()

	return null


func _path_to_spot(swimmer: Swimmer) -> void:
	if swimmer.spot == null or not swimmer.spot.is_valid():
		_at_spot = true
		return

	swimmer.target_cell = swimmer.spot.cell
	if swimmer.request_path_to(swimmer.spot.cell):
		_pathing_to_spot = true
	else:
		_at_spot = true  # Can't path, just pack here
