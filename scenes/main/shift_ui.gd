extends Control

## Shift HUD — shows current time, progress, and swimmer count.

@onready var time_label: Label = $TimeLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var count_label: Label = $CountLabel

var _spawner: SwimmerSpawner = null
var _waiting_to_start: bool = true


func _ready() -> void:
	_spawner = get_tree().get_first_node_in_group("spawner") as SwimmerSpawner
	_update_idle_state()


func _process(_delta: float) -> void:
	if not ShiftManager.is_active():
		return

	time_label.text = ShiftManager.get_time_string()
	progress_bar.value = ShiftManager.get_progress() * 100.0

	if _spawner:
		var active_count := get_tree().get_nodes_in_group("swimmers").size()
		count_label.text = "Swimmers: %d | Spawned: %d/%d" % [
			active_count,
			_spawner.get_spawned_count(),
			_spawner.total_swimmers
		]


func _input(event: InputEvent) -> void:
	if _waiting_to_start and event.is_action_pressed("ui_accept"):  # Space bar
		_waiting_to_start = false
		ShiftManager.start_shift()
		get_viewport().set_input_as_handled()


func _update_idle_state() -> void:
	time_label.text = "Ready"
	progress_bar.value = 0
	count_label.text = "Press SPACE to start shift"
