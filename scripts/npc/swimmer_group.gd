class_name SwimmerGroup
extends RefCounted

## A group of swimmers that arrived together (family, friends, couple).
##
## Groups:
## - Arrive at the same time
## - Claim adjacent spots
## - Leave together (last activity triggers group departure)
## - Share a "base" area on the beach

enum GroupType { SOLO, COUPLE, FRIENDS, FAMILY }

var group_type: GroupType = GroupType.SOLO
var members: Array[Swimmer] = []
var spots: Array[SwimmerSpot] = []
var base_cell: GridCell = null  # Center of group's claimed area

# Group lifecycle
var all_arrived: bool = false
var leaving: bool = false


static func create_random() -> SwimmerGroup:
	var group := SwimmerGroup.new()

	var roll := randf()
	if roll < 0.3:
		group.group_type = GroupType.SOLO
	elif roll < 0.55:
		group.group_type = GroupType.COUPLE
	elif roll < 0.75:
		group.group_type = GroupType.FRIENDS
	else:
		group.group_type = GroupType.FAMILY

	return group


func get_size() -> int:
	match group_type:
		GroupType.SOLO:
			return 1
		GroupType.COUPLE:
			return 2
		GroupType.FRIENDS:
			return randi_range(2, 4)
		GroupType.FAMILY:
			return randi_range(3, 5)
		_:
			return 1


func add_member(swimmer: Swimmer) -> void:
	members.append(swimmer)


func find_group_spots() -> bool:
	## Finds adjacent beach cells for all group members.
	## Returns true if enough spots were found.
	var needed := members.size()

	# Find a starting cell on the beach
	base_cell = GridManager.find_random_cell_of_type(GridCell.Type.BEACH)
	if base_cell == null:
		return false

	# Find adjacent cells for the rest of the group
	var found_cells: Array[GridCell] = [base_cell]
	var search_radius := 2

	if needed > 1:
		var nearby := GridManager.find_nearby_cells_of_type(
			base_cell.grid_position,
			GridCell.Type.BEACH,
			search_radius
		)

		for cell in nearby:
			if found_cells.size() >= needed:
				break
			# Check cell isn't reserved by another group
			if cell.has_meta("reserved_by"):
				continue
			found_cells.append(cell)

	# Did we find enough?
	if found_cells.size() < needed:
		# Try with larger radius
		var nearby := GridManager.find_nearby_cells_of_type(
			base_cell.grid_position,
			GridCell.Type.BEACH,
			search_radius + 2
		)
		for cell in nearby:
			if found_cells.size() >= needed:
				break
			if cell.has_meta("reserved_by"):
				continue
			if cell not in found_cells:
				found_cells.append(cell)

	if found_cells.size() < needed:
		return false

	# Assign spots to members
	for i in range(members.size()):
		var spot := SwimmerSpot.new()
		spot.claim(found_cells[i], members[i])
		spots.append(spot)
		members[i].spot = spot

	return true


func signal_group_leave() -> void:
	## Called when the group should start leaving.
	leaving = true
	for member in members:
		if is_instance_valid(member):
			member.group_leaving = true


func release_all_spots() -> void:
	for spot in spots:
		spot.release()
	spots.clear()
