class_name Swimmer
extends NPCBase

## Swimmer NPC — a beach visitor with a full realistic routine.
##
## Lifecycle: Arrive → Find Spot → Set Up → [Relax ↔ Water trips] → Pack Up → Leave

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

@export var max_activities: int = -1  # Overridden by spawner

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

var profile: SwimmerProfile = null
var group: SwimmerGroup = null
var spot: SwimmerSpot = null
var target_cell: GridCell = null

## Lifecycle tracking
var activities_completed: int = 0
var water_trips_done: int = 0
var has_set_up: bool = false
var group_leaving: bool = false

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

@onready var body: ColorRect = $Body
@onready var debug_label: Label = $DebugLabel

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------

func _on_ready() -> void:
	add_to_group("swimmers")

	# Profile may already be set by spawner (for group generation)
	if profile == null:
		profile = SwimmerProfile.generate_random()

	# Apply profile stats
	move_speed = profile.move_speed

	# Visual appearance
	_apply_visual_profile()

	# Start lifecycle
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

	var tone := randf_range(0.6, 1.0)
	body.color = Color(tone, tone * 0.85, tone * 0.67, 1.0)


# -------------------------------------------------------------------
# Decision Making
# -------------------------------------------------------------------

func pick_next_state() -> NPCState:
	## Central decision point — what should I do next?

	# Group is leaving — pack up
	if group_leaving:
		return SwimmerStatePackingUp.new()

	# Haven't found a spot yet
	if not has_set_up:
		return SwimmerStateFindingSpot.new()

	# Check if done for the day
	if max_activities >= 0 and activities_completed >= max_activities:
		return SwimmerStatePackingUp.new()

	# Decide between relaxing at spot or going to water
	if _should_go_to_water():
		return SwimmerStateEnteringWater.new()
	else:
		# Relax at spot
		return SwimmerStateReturning.new()


func pick_state_after_water() -> NPCState:
	## Called after coming back from water.
	water_trips_done += 1
	activities_completed += 1
	return SwimmerStateDryingOff.new()


func pick_state_after_rest() -> NPCState:
	## Called after resting at spot.
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
	## Decides if swimmer should go to water or stay at spot.

	# Haven't done any water trips yet — likely to go
	if water_trips_done == 0:
		return randf() < 0.8

	# Done all planned water trips?
	if water_trips_done >= profile.water_trips:
		return false

	# Profile-based preference
	if profile.prefers_water:
		return randf() < 0.7
	else:
		return randf() < 0.3


func get_water_target_type() -> GridCell.Type:
	## Returns which water zone to head to.
	return profile.get_water_destination()


# -------------------------------------------------------------------
# Activity Config
# -------------------------------------------------------------------

func get_spot_relax_duration() -> float:
	return profile.get_spot_activity_duration()


func get_drying_off_duration() -> float:
	return profile.get_drying_off_duration()


func get_activity_for_cell(cell: GridCell) -> Dictionary:
	## Used by roaming state for water activities.
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

	debug_label.text = text
