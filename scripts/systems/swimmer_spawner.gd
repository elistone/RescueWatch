class_name SwimmerSpawner
extends Node

## Spawns swimmers in groups over the shift with a bell-curve distribution.

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

@export var total_swimmers: int = 200
@export var swimmer_scene: PackedScene = null
@export var spawn_parent: Node = null
@export var min_activities: int = 3
@export var max_activities: int = 6
@export var curve_spread: float = 0.35

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------

var _spawn_times: Array[float] = []
var _spawn_index: int = 0
var _active: bool = false
var _spawned_count: int = 0
var _groups: Array[SwimmerGroup] = []

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
	add_to_group("spawner")

	if swimmer_scene == null:
		swimmer_scene = preload("res://scenes/npc/swimmer.tscn")

	ShiftManager.shift_started.connect(_on_shift_started)
	ShiftManager.shift_ended.connect(_on_shift_ended)


func _process(_delta: float) -> void:
	if not _active:
		return

	if _spawn_index >= _spawn_times.size():
		_active = false
		return

	var progress := ShiftManager.get_progress()

	while _spawn_index < _spawn_times.size() and progress >= _spawn_times[_spawn_index]:
		_do_spawn_group()
		_spawn_index += 1


# -------------------------------------------------------------------
# Control
# -------------------------------------------------------------------

func start_spawning() -> void:
	_generate_spawn_times()
	_spawn_index = 0
	_spawned_count = 0
	_groups.clear()
	_active = true
	print("[Spawner] Prepared %d group spawns" % _spawn_times.size())


func stop_spawning() -> void:
	_active = false


func get_spawned_count() -> int:
	return _spawned_count


func get_remaining_count() -> int:
	return max(0, total_swimmers - _spawned_count)


# -------------------------------------------------------------------
# Spawn Time Generation
# -------------------------------------------------------------------

func _generate_spawn_times() -> void:
	_spawn_times.clear()

	# Generate group spawn events (not individual swimmers)
	# Estimate ~2.5 average group size
	var estimated_groups := int(ceil(total_swimmers / 2.5))
	var remaining := total_swimmers

	for i in range(estimated_groups):
		if remaining <= 0:
			break
		var t := _sample_bell_curve()
		_spawn_times.append(t)
		remaining -= 2  # Rough estimate, actual size determined at spawn time

	_spawn_times.sort()
	_add_jitter()


func _sample_bell_curve() -> float:
	var u1 := randf_range(0.001, 1.0)
	var u2 := randf_range(0.001, 1.0)
	var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	var value := 0.5 + z * curve_spread
	return clampf(value, 0.05, 0.90)


func _add_jitter() -> void:
	var min_gap := 0.005

	for i in range(1, _spawn_times.size()):
		var gap := _spawn_times[i] - _spawn_times[i - 1]
		if gap < min_gap:
			_spawn_times[i] = _spawn_times[i - 1] + min_gap + randf_range(0.0, 0.008)

	for i in range(_spawn_times.size()):
		_spawn_times[i] = clampf(_spawn_times[i], 0.05, 0.95)


# -------------------------------------------------------------------
# Group Spawning
# -------------------------------------------------------------------

func _do_spawn_group() -> void:
	if _spawned_count >= total_swimmers:
		return

	var parent := spawn_parent if spawn_parent else get_parent()
	if parent == null:
		return

	# Create a group
	var group := SwimmerGroup.create_random()
	var group_size := mini(group.get_size(), total_swimmers - _spawned_count)

	# Create swimmers for the group
	for i in range(group_size):
		var swimmer: Swimmer = swimmer_scene.instantiate() as Swimmer
		if swimmer == null:
			continue

		# Generate profile based on group type
		swimmer.profile = SwimmerProfile.generate_for_group(group.group_type, i, group_size)

		# Activities based on profile
		swimmer.max_activities = swimmer.profile.water_trips + randi_range(1, 3)

		# Register with group
		group.add_member(swimmer)
		swimmer.group = group

		parent.add_child(swimmer)
		_spawned_count += 1

	# Find group spots (adjacent beach cells)
	group.find_group_spots()

	_groups.append(group)


# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------

func _on_shift_started() -> void:
	start_spawning()


func _on_shift_ended() -> void:
	stop_spawning()
	# Signal all remaining groups to leave
	for group in _groups:
		group.signal_group_leave()
