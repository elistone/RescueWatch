class_name SwimmerStateLeaving
extends NPCState

## Paths to entrance and despawns.

var _repath_attempts: int = 0
const MAX_REPATH_ATTEMPTS := 3


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer
	swimmer.debug_status = "LEAVING"
	swimmer.set_color(Color.MEDIUM_PURPLE)

	# Make sure spot is released
	if swimmer.spot:
		swimmer.spot.release()
		swimmer.spot = null

	_request_exit(swimmer)


func _request_exit(swimmer: Swimmer) -> void:
	var exit_cell := GridManager.find_random_cell_of_type(GridCell.Type.ENTRANCE)
	if exit_cell == null:
		_despawn(swimmer)
		return

	swimmer.target_cell = exit_cell
	if not swimmer.request_path_to(exit_cell):
		_repath_attempts += 1
		if _repath_attempts >= MAX_REPATH_ATTEMPTS:
			_despawn(swimmer)


func process(delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

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
				_request_exit(swimmer)
		NPCBase.MoveResult.MOVING:
			swimmer.debug_status = "LEAVING"

	return null


func _despawn(swimmer: Swimmer) -> void:
	if swimmer.current_cell:
		swimmer.current_cell.release()
	swimmer.queue_free()
