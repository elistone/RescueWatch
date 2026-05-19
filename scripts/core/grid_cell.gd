class_name GridCell
extends RefCounted

## Represents a single cell in the grid.

enum Type {
	INVALID = -1,
	ENTRANCE = 0,
	BEACH = 1,
	SHALLOW = 2,
	DEEP = 3,
	OBSTACLE = 4,
}

var grid_position: Vector2i = Vector2i.ZERO
var world_position: Vector2 = Vector2.ZERO
var type: Type = Type.INVALID
var walkable: bool = true
var occupied: bool = false
var occupant: Node = null


func _init(grid_pos: Vector2i, world_pos: Vector2, cell_type: Type) -> void:
	grid_position = grid_pos
	world_position = world_pos
	type = cell_type
	walkable = (cell_type != Type.OBSTACLE)


func claim(new_occupant: Node) -> bool:
	if occupied:
		return false
	occupied = true
	occupant = new_occupant
	return true


func release() -> void:
	occupied = false
	occupant = null


func is_available_for(requester: Node) -> bool:
	if not walkable:
		return false
	if not occupied:
		return true
	return occupant == requester
