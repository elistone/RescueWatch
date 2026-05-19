class_name SwimmerStateSpawning
extends NPCState

## Spawns the swimmer at a random entrance cell, then transitions to moving.


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer

	var entrance := GridManager.find_random_cell_of_type(GridCell.Type.ENTRANCE)
	if entrance == null:
		push_error("[Swimmer] No entrance cells available!")
		return

	swimmer.place_at_cell(entrance)
	swimmer.debug_status = "SPAWNING"


func process(_delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Pick a destination and transition to moving
	var destination := swimmer.pick_activity_destination()
	if destination == null:
		return SwimmerStateLeaving.new()

	if swimmer.request_path_to(destination):
		swimmer.target_cell = destination
		return SwimmerStateMoving.new()
	else:
		return SwimmerStateLeaving.new()
