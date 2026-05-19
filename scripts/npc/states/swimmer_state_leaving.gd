class_name SwimmerStateLeaving
extends NPCState

## Paths to an entrance cell and exits.

var _repath_attempts: int = 0
const MAX_REPATH_ATTEMPTS := 3
var _path_requested: bool = false


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "LEAVING"
	swimmer.set_color(Color.MEDIUM_PURPLE)

	_request_exit_path(swimmer)


func _request_exit_path(swimmer: Swimmer) -> void:
	var exit_cell := GridManager.find_random_cell_of_type(GridCell.Type.ENTRANCE)
	if exit_cell == null:
		# No exit available, just despawn
		_despawn(swimmer)
		return

	swimmer.target_cell = exit_cell
	if not swimmer.request_path_to(exit_cell):
		_repath_attempts += 1
		if _repath_attempts >= MAX_REPATH_ATTEMPTS:
			_despawn(swimmer)
	_path_requested = true


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	if not _path_requested:
		return null

	var result := swimmer.step_movement(delta)

	match result:
		NPCBase.MoveResult.ARRIVED:
			_despawn(swimmer)
		NPCBase.MoveResult.BLOCKED:
			swimmer.debug_status = "LEAVING (WAIT)"
		NPCBase.MoveResult.REPATH:
			_repath_attempts += 1
			if _repath_attempts >= MAX_REPATH_ATTEMPTS:
				_despawn(swimmer)
			else:
				_request_exit_path(swimmer)
		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "LEAVING"

	return null


func _despawn(swimmer: Swimmer) -> void:
	if swimmer.current_cell:
		swimmer.current_cell.release()
	swimmer.queue_free()
