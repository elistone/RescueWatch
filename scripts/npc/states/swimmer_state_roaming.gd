class_name SwimmerStateRoaming
extends NPCState

## Roaming activity — moves between same-type cells.
## Speed and pauses driven by swimmer profile.

var _timer: float = 0.0
var _duration: float = 0.0
var _activity_name: String = ""
var _color: Color = Color.WHITE
var _cell_type: GridCell.Type = GridCell.Type.INVALID
var _roam_radius: int = 4
var _has_roam_path: bool = false
var _original_speed: float = 0.0

# Pause between roam targets
var _pausing: bool = false
var _pause_timer: float = 0.0
var _pause_duration: float = 0.0


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

	# Store original speed and apply roam speed
	_original_speed = swimmer.move_speed
	swimmer.move_speed = _original_speed * swimmer.profile.roam_speed_mult

	if swimmer.current_cell:
		_cell_type = swimmer.current_cell.type

	_pick_roam_target(swimmer)


func exit() -> void:
	# Restore original speed
	var swimmer: Swimmer = npc as Swimmer
	swimmer.move_speed = _original_speed


func process(delta: float) -> NPCState:
	_timer += delta

	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "%s %.1fs" % [_activity_name, _duration - _timer]

	if _timer >= _duration:
		swimmer.clear_path()
		swimmer.on_activity_complete()
		return swimmer.pick_next_state()

	# Handle pause between roam targets
	if _pausing:
		_pause_timer += delta
		if _pause_timer >= _pause_duration:
			_pausing = false
			_pick_roam_target(swimmer)
		return null

	# Handle movement
	if _has_roam_path:
		var result := swimmer.step_movement(delta)

		match result:
			NPCBase.MoveResult.ARRIVED:
				# Pause briefly before picking next target
				_pausing = true
				_pause_timer = 0.0
				_pause_duration = randf_range(0.3, 1.5) * (1.0 - swimmer.profile.fitness * 0.5)
				_has_roam_path = false

			NPCBase.MoveResult.BLOCKED:
				swimmer.debug_status = "%s (WAIT)" % _activity_name

			NPCBase.MoveResult.REPATH:
				_pick_roam_target(swimmer)

			NPCBase.MoveResult.MOVING:
				swimmer.set_color(_color)
	else:
		_pick_roam_target(swimmer)

	return null


func _pick_roam_target(swimmer: Swimmer) -> void:
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

	var target: GridCell = candidates[randi() % candidates.size()]
	swimmer.target_cell = target

	if swimmer.request_path_to(target):
		_has_roam_path = true
	else:
		_has_roam_path = false
