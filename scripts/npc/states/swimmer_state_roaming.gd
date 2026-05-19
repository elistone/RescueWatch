class_name SwimmerStateRoaming
extends NPCState

## Roaming activity — moves between cells of the same type.
## Used for wading and swimming. Looks like they're moving around in the water.

var _timer: float = 0.0
var _duration: float = 0.0
var _activity_name: String = ""
var _color: Color = Color.WHITE
var _cell_type: GridCell.Type = GridCell.Type.INVALID
var _roam_radius: int = 4
var _has_roam_path: bool = false


func _init(config: Dictionary = {}) -> void:
	if config.is_empty():
		return
	_activity_name = config.get("name", "ROAMING")
	_duration = config.get("duration", 5.0)
	_color = config.get("color", Color.WHITE)


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.set_color(_color)
	swimmer.debug_status = _activity_name

	_timer = 0.0

	if swimmer.current_cell:
		_cell_type = swimmer.current_cell.type

	# Start first roam
	_pick_roam_target(swimmer)


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "%s %.1fs" % [_activity_name, _duration - _timer]

	# Check if activity time is up
	if _timer >= _duration:
		swimmer.clear_path()
		swimmer.on_activity_complete()
		return swimmer.pick_next_state()

	# Handle movement
	if _has_roam_path:
		var result := swimmer.step_movement(delta)

		match result:
			NPCBase.MoveResult.ARRIVED:
				# Reached roam point, pick another
				_pick_roam_target(swimmer)

			NPCBase.MoveResult.BLOCKED:
				swimmer.debug_status = "%s (WAIT)" % _activity_name

			NPCBase.MoveResult.REPATH:
				# Can't get there, pick a different spot
				_pick_roam_target(swimmer)

			NPCBase.MoveResult.MOVING:
				swimmer.set_color(_color)
	else:
		# No path — try picking a new target
		_pick_roam_target(swimmer)

	return null


func _pick_roam_target(swimmer: Swimmer) -> void:
	## Picks a random nearby cell of the same type to roam to.
	if swimmer.current_cell == null:
		_has_roam_path = false
		return

	var candidates := GridManager.find_nearby_cells_of_type(
		swimmer.current_cell.grid_position,
		_cell_type,
		_roam_radius
	)

	if candidates.is_empty():
		_has_roam_path = false
		return

	# Pick a random candidate
	var target: GridCell = candidates[randi() % candidates.size()]
	swimmer.target_cell = target

	if swimmer.request_path_to(target):
		_has_roam_path = true
	else:
		_has_roam_path = false
