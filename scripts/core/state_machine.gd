class_name StateMachine
extends RefCounted

## Lightweight state machine. No nodes, no overhead.
## Perfect for 200-400 NPCs.

var current_state: NPCState = null
var _owner: Node = null


func _init(owner: Node) -> void:
	_owner = owner


func change_state(new_state: NPCState) -> void:
	if current_state:
		current_state.exit()

	current_state = new_state

	if current_state:
		current_state.npc = _owner
		current_state.enter()


func process(delta: float) -> void:
	if current_state == null:
		return

	var next_state := current_state.process(delta)
	if next_state != null:
		change_state(next_state)


func get_state_name() -> String:
	if current_state == null:
		return "NONE"
	# Use class name or override
	return current_state.get_script().get_global_name() if current_state.get_script() else "UNKNOWN"
