class_name NPCState
extends RefCounted

## Base class for all NPC states.
## Override enter(), exit(), and process() in subclasses.

var npc: Node = null  # Set by state machine


func enter() -> void:
	pass


func exit() -> void:
	pass


func process(delta: float) -> NPCState:
	## Return a new state to transition, or null to stay in this state.
	return null
