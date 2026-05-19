extends Node

## ShiftManager — Controls the day/night cycle.
##
## A "shift" runs from a start hour to an end hour in game-world time,
## compressed into a real-time duration (e.g. 8am-7pm in 300 seconds).
##
## Singleton: ShiftManager.get_progress(), ShiftManager.get_current_hour()

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

## Real-world time the shift lasts (seconds)
@export var shift_duration: float = 300.0

## In-game start/end hours (24h format)
@export var start_hour: float = 8.0   # 8:00 AM
@export var end_hour: float = 19.0    # 7:00 PM

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------

var _elapsed: float = 0.0
var _active: bool = false
var _paused: bool = false

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------

signal shift_started
signal shift_ended
signal hour_changed(hour: int)

var _last_hour: int = -1

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not _active or _paused:
		return

	_elapsed += delta

	# Check for hour changes
	var current_hour := int(get_current_hour())
	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_changed.emit(current_hour)

	# Check if shift ended
	if _elapsed >= shift_duration:
		_elapsed = shift_duration
		_active = false
		shift_ended.emit()


# -------------------------------------------------------------------
# Control
# -------------------------------------------------------------------

func start_shift() -> void:
	_elapsed = 0.0
	_active = true
	_paused = false
	_last_hour = int(start_hour)
	shift_started.emit()
	print("[ShiftManager] Shift started: %d:00 - %d:00 (%ds real time)" % [
		int(start_hour), int(end_hour), int(shift_duration)
	])


func pause_shift() -> void:
	_paused = true


func resume_shift() -> void:
	_paused = false


func is_active() -> bool:
	return _active


func is_paused() -> bool:
	return _paused


# -------------------------------------------------------------------
# Time Queries
# -------------------------------------------------------------------

func get_progress() -> float:
	## Returns 0.0 (start of shift) to 1.0 (end of shift).
	if shift_duration <= 0:
		return 0.0
	return clampf(_elapsed / shift_duration, 0.0, 1.0)


func get_elapsed() -> float:
	return _elapsed


func get_remaining() -> float:
	return max(0.0, shift_duration - _elapsed)


func get_current_hour() -> float:
	## Returns the current in-game hour (e.g. 8.0 to 19.0).
	var hour_range := end_hour - start_hour
	return start_hour + (get_progress() * hour_range)


func get_time_string() -> String:
	## Returns formatted time like "2:35 PM".
	var hour := get_current_hour()
	var h := int(hour)
	var m := int((hour - h) * 60.0)
	var period := "AM" if h < 12 else "PM"
	var display_h := h % 12
	if display_h == 0:
		display_h = 12
	return "%d:%02d %s" % [display_h, m, period]
