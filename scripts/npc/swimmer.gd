class_name Swimmer
extends NPCBase

## Swimmer NPC — a beach visitor driven by personality stats.
##
## Each swimmer has a unique profile (age, gender, fitness, weight)
## that determines how they behave, how fast they move, and what
## activities they prefer.

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

## Set to -1 for infinite activities (never leaves), 0+ for a limit.
@export var max_activities: int = -1

# -------------------------------------------------------------------
# Properties
# -------------------------------------------------------------------

var profile: SwimmerProfile = null
var target_cell: GridCell = null
var activities_completed: int = 0

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

	# Generate random personality
	profile = SwimmerProfile.generate_random()

	# Apply profile to movement
	move_speed = profile.move_speed

	# Visual size hint based on age/weight
	_apply_visual_profile()

	state_machine.change_state(SwimmerStateSpawning.new())


func _apply_visual_profile() -> void:
	## Adjusts visual appearance based on profile.
	if body == null:
		return

	# Size based on age group
	var size := 24.0  # Default half-size
	match profile.age_group:
		SwimmerProfile.AgeGroup.CHILD:
			size = 16.0
		SwimmerProfile.AgeGroup.TEEN:
			size = 20.0
		SwimmerProfile.AgeGroup.ADULT:
			size = 24.0 + (profile.weight * 8.0)  # 24-32 based on weight
		SwimmerProfile.AgeGroup.ELDERLY:
			size = 22.0 + (profile.weight * 6.0)

	body.offset_left = -size
	body.offset_top = -size
	body.offset_right = size
	body.offset_bottom = size

	# Skin tone variation
	var tone := randf_range(0.6, 1.0)
	body.color = Color(tone, tone * 0.85, tone * 0.67, 1.0)


# -------------------------------------------------------------------
# Decision Making
# -------------------------------------------------------------------

func pick_next_state() -> NPCState:
	if max_activities >= 0 and activities_completed >= max_activities:
		return SwimmerStateLeaving.new()

	var destination := _pick_destination()
	if destination and request_path_to(destination):
		target_cell = destination
		return SwimmerStateMoving.new()

	return SwimmerStateLeaving.new()


func on_activity_complete() -> void:
	activities_completed += 1


# -------------------------------------------------------------------
# Destination Picking (Profile-Driven)
# -------------------------------------------------------------------

func _pick_destination() -> GridCell:
	var preferred_type := profile.get_activity_preference()
	var cell := GridManager.find_random_cell_of_type(preferred_type)

	# Fallback: if preferred zone is full, try others
	if cell == null:
		cell = GridManager.find_random_cell_of_type(GridCell.Type.BEACH)
	if cell == null:
		cell = GridManager.find_random_cell_of_type(GridCell.Type.SHALLOW)

	return cell


# -------------------------------------------------------------------
# Activity Config (Profile-Driven)
# -------------------------------------------------------------------

func get_activity_for_cell(cell: GridCell) -> Dictionary:
	if cell == null:
		return {"name": "IDLE", "duration": 1.0, "color": Color.WHITE, "roaming": false}

	match cell.type:
		GridCell.Type.BEACH:
			return {
				"name": "SUNBATHING",
				"duration": profile.get_activity_duration(3.0, 6.0),
				"color": Color.ORANGE,
				"roaming": false,
			}
		GridCell.Type.SHALLOW:
			return {
				"name": "WADING",
				"duration": profile.get_activity_duration(4.0, 8.0),
				"color": Color.LIGHT_BLUE,
				"roaming": true,
			}
		GridCell.Type.DEEP:
			return {
				"name": "SWIMMING",
				"duration": profile.get_activity_duration(5.0, 10.0),
				"color": Color.DODGER_BLUE,
				"roaming": true,
			}
		_:
			return {
				"name": "IDLE",
				"duration": 1.0,
				"color": Color.WHITE,
				"roaming": false,
			}


# -------------------------------------------------------------------
# Pause Behaviour
# -------------------------------------------------------------------

func should_pause() -> bool:
	## Called by movement state between steps. Profile determines likelihood.
	return randf() < profile.pause_chance


func get_pause_duration() -> float:
	## How long to pause (jittered).
	return profile.pause_duration * randf_range(0.5, 1.5)


# -------------------------------------------------------------------
# Helpers
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

	if max_activities >= 0:
		text += "\n%d/%d" % [activities_completed, max_activities]

	debug_label.text = text
