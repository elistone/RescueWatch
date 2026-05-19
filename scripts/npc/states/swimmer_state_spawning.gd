class_name SwimmerStateSpawning
extends NPCState

## Spawns at entrance, then asks swimmer what to do.


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
	return swimmer.pick_next_state()
