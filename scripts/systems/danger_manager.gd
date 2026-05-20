class_name DangerManager
extends Node

## Tracks all swimmers currently in danger.
## Emits signals for UI alerts and lifeguard dispatch.

signal swimmer_struggling(swimmer: Swimmer)
signal swimmer_drowning(swimmer: Swimmer)
signal swimmer_drowned(swimmer: Swimmer)
signal swimmer_rescued(swimmer: Swimmer)

var _tracked_struggling: Array[Swimmer] = []
var _tracked_drowning: Array[Swimmer] = []
var _total_drowned: int = 0
var _total_rescued: int = 0


func _process(_delta: float) -> void:
	_scan_danger_groups()


func _scan_danger_groups() -> void:
	## Scans groups to detect new entries and emit signals.
	var in_danger := get_tree().get_nodes_in_group("swimmers_in_danger")

	for node in in_danger:
		var swimmer := node as Swimmer
		if swimmer == null:
			continue

		match swimmer.fatigue.danger_state:
			SwimmerFatigue.DangerState.STRUGGLING:
				if swimmer not in _tracked_struggling:
					_tracked_struggling.append(swimmer)
					swimmer_struggling.emit(swimmer)

			SwimmerFatigue.DangerState.DROWNING:
				if swimmer not in _tracked_drowning:
					_tracked_drowning.append(swimmer)
					_tracked_struggling.erase(swimmer)
					swimmer_drowning.emit(swimmer)

	# Check for drowned
	var drowned := get_tree().get_nodes_in_group("swimmers_drowned")
	for node in drowned:
		var swimmer := node as Swimmer
		if swimmer and swimmer in _tracked_drowning:
			_tracked_drowning.erase(swimmer)
			_total_drowned += 1
			swimmer_drowned.emit(swimmer)

	# Clean up freed references
	_tracked_struggling = _tracked_struggling.filter(func(s): return is_instance_valid(s))
	_tracked_drowning = _tracked_drowning.filter(func(s): return is_instance_valid(s))


# -------------------------------------------------------------------
# Queries
# -------------------------------------------------------------------

func get_struggling_count() -> int:
	return _tracked_struggling.size()


func get_drowning_count() -> int:
	return _tracked_drowning.size()


func get_total_drowned() -> int:
	return _total_drowned


func get_total_rescued() -> int:
	return _total_rescued


func get_all_in_danger() -> Array:
	var result: Array = []
	result.append_array(_tracked_struggling)
	result.append_array(_tracked_drowning)
	return result


func register_rescue(swimmer: Swimmer) -> void:
	## Call when a lifeguard rescues someone.
	_tracked_struggling.erase(swimmer)
	_tracked_drowning.erase(swimmer)
	_total_rescued += 1
	swimmer_rescued.emit(swimmer)
