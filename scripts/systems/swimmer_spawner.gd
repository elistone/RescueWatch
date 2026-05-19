class_name SwimmerSpawner
extends Node

## SwimmerSpawner — Spawns swimmers over a shift with a natural bell-curve.
##
## Attach to your main scene. Call start_spawning() when shift begins.
##
## Distribution: few arrivals early, peak at mid-shift, tapering off at end.
## Randomized timing so it never feels mechanical.

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

## Total swimmers to spawn this shift.
@export var total_swimmers: int = 200

## Scene to instantiate.
@export var swimmer_scene: PackedScene = null

## Parent node to add swimmers to.
@export var spawn_parent: Node = null

## How many activities each swimmer does before leaving (min, max).
@export var min_activities: int = 2
@export var max_activities: int = 5

## Spread of the bell curve (lower = more concentrated at peak).
## 0.2 = very peaked, 0.4 = moderate spread, 0.6 = fairly even
@export var curve_spread: float = 0.35

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------

var _spawn_times: Array[float] = []  # Pre-calculated spawn times (0.0 to 1.0)
var _spawn_index: int = 0
var _active: bool = false
var _spawned_count: int = 0

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
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

	# Check if it's time to spawn the next swimmer
	var progress := ShiftManager.get_progress()

	while _spawn_index < _spawn_times.size() and progress >= _spawn_times[_spawn_index]:
		_do_spawn()
		_spawn_index += 1


# -------------------------------------------------------------------
# Control
# -------------------------------------------------------------------

func start_spawning() -> void:
	_generate_spawn_times()
	_spawn_index = 0
	_spawned_count = 0
	_active = true
	print("[Spawner] Prepared %d spawn times over shift" % _spawn_times.size())


func stop_spawning() -> void:
	_active = false


func get_spawned_count() -> int:
	return _spawned_count


func get_remaining_count() -> int:
	return total_swimmers - _spawned_count


# -------------------------------------------------------------------
# Spawn Time Generation (Bell Curve)
# -------------------------------------------------------------------

func _generate_spawn_times() -> void:
	## Pre-generates all spawn times using a bell curve distribution.
	## Times are normalized 0.0 to 1.0 (shift progress).
	_spawn_times.clear()

	for i in range(total_swimmers):
		var t := _sample_bell_curve()
		_spawn_times.append(t)

	# Sort so we can process in order
	_spawn_times.sort()

	# Add jitter so consecutive spawns don't feel mechanical
	_add_jitter()


func _sample_bell_curve() -> float:
	## Samples from a Gaussian-like distribution centered at 0.5.
	## Uses Box-Muller transform approximation.
	## Returns value clamped to 0.05 - 0.90 (nobody arrives at very start/end).

	# Box-Muller transform for normal distribution
	var u1 := randf_range(0.001, 1.0)
	var u2 := randf_range(0.001, 1.0)
	var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)

	# Center at 0.5, apply spread
	var value := 0.5 + z * curve_spread

	# Clamp — no one arrives in first 5% or last 10% of shift
	return clampf(value, 0.05, 0.90)


func _add_jitter() -> void:
	## Adds small random offsets so spawns don't cluster unnaturally.
	var min_gap := 0.002  # Minimum gap between spawns (~0.6s at 300s shift)

	for i in range(1, _spawn_times.size()):
		var gap := _spawn_times[i] - _spawn_times[i - 1]
		if gap < min_gap:
			_spawn_times[i] = _spawn_times[i - 1] + min_gap + randf_range(0.0, 0.005)

	# Re-clamp after jitter
	for i in range(_spawn_times.size()):
		_spawn_times[i] = clampf(_spawn_times[i], 0.05, 0.95)


# -------------------------------------------------------------------
# Spawning
# -------------------------------------------------------------------

func _do_spawn() -> void:
	if swimmer_scene == null:
		return

	var parent := spawn_parent if spawn_parent else get_parent()
	if parent == null:
		return

	var swimmer: Swimmer = swimmer_scene.instantiate() as Swimmer
	if swimmer == null:
		return

	# Assign random activity count
	swimmer.max_activities = randi_range(min_activities, max_activities)

	parent.add_child(swimmer)
	_spawned_count += 1


# -------------------------------------------------------------------
# Signal Handlers
# -------------------------------------------------------------------

func _on_shift_started() -> void:
	start_spawning()


func _on_shift_ended() -> void:
	stop_spawning()
