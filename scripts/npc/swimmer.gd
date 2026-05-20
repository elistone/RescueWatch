class_name Swimmer
extends NPCBase

## Swimmer NPC — a beach visitor with a full realistic routine.
##
## Lifecycle: Arrive → Find Spot → Set Up → [Relax ↔ Water trips] → Pack Up → Leave
## Danger: Fatigue builds in water → Tired → Struggling → Drowning

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

@export var max_activities: int = -1

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

var profile: SwimmerProfile = null
var fatigue: SwimmerFatigue = null
var group: SwimmerGroup = null
var spot: SwimmerSpot = null
var target_cell: GridCell = null

## Lifecycle tracking
var activities_completed: int = 0
var water_trips_done: int = 0
var has_set_up: bool = false
var group_leaving: bool = false

## Cramp system
var _cramp_chance_per_second: float = 0.002  # ~0.2% per second in water
var _cramp_checked: bool = false

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var body: ColorRect = $Body
@onready var debug_label: Label = $DebugLabel
@onready var danger_bar: DangerBar = $DangerBar

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------

func _on_ready() -> void:
	add_to_group("swimmers")

	if profile == null:
		profile = SwimmerProfile.generate_random()

	# Create fatigue system from profile
	fatigue = SwimmerFatigue.create_from_profile(profile)

	# Cramp chance adjusted by fitness (unfit = more cramps)
	_cramp_chance_per_second = lerpf(0.005, 0.0005, profile.fitness)

	move_speed = profile.move_speed
	_apply_visual_profile()
	state_machine.change_state(SwimmerStateSpawning.new())


func _apply_visual_profile() -> void:
	if body == null:
		return

	var size := 24.0
	match profile.age_group:
		SwimmerProfile.AgeGroup.CHILD:
			size = 16.0
		SwimmerProfile.AgeGroup.TEEN:
			size = 20.0
		SwimmerProfile.AgeGroup.ADULT:
			size = 24.0 + (profile.weight * 8.0)
		SwimmerProfile.AgeGroup.ELDERLY:
			size = 22.0 + (profile.weight * 6.0)

	body.offset_left = -size
	body.offset_top = -size
	body.offset_right = size
	body.offset_bottom = size

	# Update danger bar position based on size
	if danger_bar:
		danger_bar.offset_top = -(size + 12.0)
		danger_bar.offset_bottom = -(size + 8.0)

	var tone := randf_range(0.6, 1.0)
	body.color = Color(tone, tone * 0.85, tone * 0.67, 1.0)


# -------------------------------------------------------------------
# Process (runs every frame regardless of state)
# -------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)

	# Update fatigue system
	if fatigue and current_cell:
		fatigue.update(delta, current_cell.type)
		fatigue.update_timers(delta)

		# Check for cramp (only while in water and not already in danger)
		if fatigue.in_water and fatigue.can_self_rescue() and not fatigue.had_cramp:
			_check_cramp(delta)

		# Update danger bar
		if danger_bar:
			danger_bar.update_bar(fatigue.get_danger_ratio(), fatigue.danger_state, delta)

		# React to danger state changes
		_check_danger_transitions()


func _check_cramp(delta: float) -> void:
	## Random cramp check each frame.
	if randf() < _cramp_chance_per_second * delta:
		fatigue.trigger_cramp()
		print("[Swimmer] CRAMP! Fatigue spiked.")


func _check_danger_transitions() -> void:
	## Forces state transitions when danger escalates.
	## Only interrupts if we're in a water state.
	if fatigue == null:
		return

	match fatigue.danger_state:
		SwimmerFatigue.DangerState.TIRED:
			# Self-rescue: if tired, try to head back to shore
			if fatigue.in_water and _is_in_water_state():
				_trigger_self_rescue()

		SwimmerFatigue.DangerState.STRUGGLING:
			# Force into struggling state if not already
			if not _is_in_danger_state():
				state_machine.change_state(SwimmerStateStruggling.new())

		SwimmerFatigue.DangerState.DROWNING:
			if not (state_machine.current_state is SwimmerStateDrowning):
				state_machine.change_state(SwimmerStateDrowning.new())

		SwimmerFatigue.DangerState.DROWNED:
			_on_drowned()


func _trigger_self_rescue() -> void:
	## Tired swimmer abandons current activity and heads to shore.
	## Only triggers once — if already returning/leaving, don't interrupt.
	if state_machine.current_state is SwimmerStateReturning:
		return
	if state_machine.current_state is SwimmerStateLeaving:
		return
	if state_machine.current_state is SwimmerStateStruggling:
		return
	if state_machine.current_state is SwimmerStateDrowning:
		return

	state_machine.change_state(SwimmerStateReturning.new())


func _is_in_water_state() -> bool:
	return (state_machine.current_state is SwimmerStateRoaming
		or state_machine.current_state is SwimmerStateEnteringWater)


func _is_in_danger_state() -> bool:
	return (state_machine.current_state is SwimmerStateStruggling
		or state_machine.current_state is SwimmerStateDrowning)


func _on_drowned() -> void:
	## Called when swimmer drowns. Game penalty.
	debug_status = "DROWNED"
	set_color(Color.DARK_GRAY)

	# Notify danger manager
	if is_in_group("swimmers_in_danger"):
		remove_from_group("swimmers_in_danger")
	add_to_group("swimmers_drowned")

	# Release cell and stop
	if current_cell:
		current_cell.release()

	# Could trigger game over / penalty here via signal
	# For now just remove after a delay
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(queue_free)


# -------------------------------------------------------------------
# Decision Making
# -------------------------------------------------------------------

func pick_next_state() -> NPCState:
	if group_leaving:
		return SwimmerStatePackingUp.new()

	if not has_set_up:
		return SwimmerStateFindingSpot.new()

	if max_activities >= 0 and activities_completed >= max_activities:
		return SwimmerStatePackingUp.new()

	if _should_go_to_water():
		return SwimmerStateEnteringWater.new()
	else:
		return SwimmerStateReturning.new()


func pick_state_after_water() -> NPCState:
	water_trips_done += 1
	activities_completed += 1
	return SwimmerStateDryingOff.new()


func pick_state_after_rest() -> NPCState:
	activities_completed += 1

	if group_leaving:
		return SwimmerStatePackingUp.new()

	if max_activities >= 0 and activities_completed >= max_activities:
		return SwimmerStatePackingUp.new()

	return pick_next_state()


func on_activity_complete() -> void:
	activities_completed += 1


# -------------------------------------------------------------------
# Decision Helpers
# -------------------------------------------------------------------

func _should_go_to_water() -> bool:
	if water_trips_done == 0:
		return randf() < 0.8

	if water_trips_done >= profile.water_trips:
		return false

	if profile.prefers_water:
		return randf() < 0.7
	else:
		return randf() < 0.3


func get_water_target_type() -> GridCell.Type:
	return profile.get_water_destination()


# -------------------------------------------------------------------
# Activity Config
# -------------------------------------------------------------------

func get_spot_relax_duration() -> float:
	return profile.get_spot_activity_duration()


func get_drying_off_duration() -> float:
	return profile.get_drying_off_duration()


func get_activity_for_cell(cell: GridCell) -> Dictionary:
	if cell == null:
		return {"name": "IDLE", "duration": 1.0, "color": Color.WHITE, "roaming": false}

	match cell.type:
		GridCell.Type.SHALLOW:
			return {
				"name": "WADING",
				"duration": profile.get_activity_duration(3.0, 6.0),
				"color": Color.LIGHT_BLUE,
				"roaming": true,
			}
		GridCell.Type.DEEP:
			return {
				"name": "SWIMMING",
				"duration": profile.get_activity_duration(4.0, 8.0),
				"color": Color.DODGER_BLUE,
				"roaming": true,
			}
		_:
			return {
				"name": "RELAXING",
				"duration": profile.get_spot_activity_duration(),
				"color": Color.ORANGE,
				"roaming": false,
			}


# -------------------------------------------------------------------
# Movement Helpers
# -------------------------------------------------------------------

func should_pause() -> bool:
	return randf() < profile.pause_chance


func get_pause_duration() -> float:
	return profile.pause_duration * randf_range(0.5, 1.5)


# -------------------------------------------------------------------
# Visual Helpers
# -------------------------------------------------------------------

func set_color(color: Color) -> void:
	if body:
		body.color = color


# -------------------------------------------------------------------
# Debug
# -------------------------------------------------------------------

func _update_debug() -> void:
	if debug_label == null:
		return

	var text := debug_status

	if current_cell:
		text += "\n(%d,%d)" % [current_cell.grid_position.x, current_cell.grid_position.y]

	if profile:
		text += "\n%s" % profile.get_summary()
		text += "\nW:%d/%d" % [water_trips_done, profile.water_trips]

	if fatigue and fatigue.danger_state != SwimmerFatigue.DangerState.SAFE:
		text += "\n⚠ %s" % fatigue.get_state_name()

	debug_label.text = text
