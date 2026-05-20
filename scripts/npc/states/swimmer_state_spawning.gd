class_name SwimmerStateSpawning
extends NPCState

## Spawns at entrance. Moves slowly (carrying bags/towels).


func enter() -> void:
	var swimmer: Swimmer = npc as Swimmer

	var entrance := GridManager.find_random_cell_of_type(GridCell.Type.ENTRANCE)
	if entrance == null:
		push_error("[Swimmer] No entrance cells available!")
		return

	swimmer.place_at_cell(entrance)
	swimmer.debug_status = "ARRIVING"

	# Slow walk-in speed
	swimmer.move_speed = swimmer.profile.walk_in_speed
	swimmer.set_color(Color(0.9, 0.85, 0.7))  # Sandy/neutral arriving colour


func process(_delta: float) -> NPCState:
	var swimmer: Swimmer = npc as Swimmer

	# Restore normal speed for next states
	swimmer.move_speed = swimmer.profile.move_speed

	# Next: find a spot
	return SwimmerStateFindingSpot.new()
