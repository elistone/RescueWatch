class_name SwimmerProfile
extends RefCounted

## A swimmer's identity — age, gender, fitness, weight.
## These stats drive movement speed, activity preferences, and timing.

# -------------------------------------------------------------------
# Identity
# -------------------------------------------------------------------

enum Gender { MALE, FEMALE }
enum AgeGroup { CHILD, TEEN, ADULT, ELDERLY }

var gender: Gender = Gender.MALE
var age_group: AgeGroup = AgeGroup.ADULT
var age: int = 30

# -------------------------------------------------------------------
# Physical Stats (0.0 to 1.0)
# -------------------------------------------------------------------

var fitness: float = 0.5
var weight: float = 0.5
var confidence: float = 0.5
var patience: float = 0.5

# -------------------------------------------------------------------
# Behaviour Preferences
# -------------------------------------------------------------------

var max_water_depth: GridCell.Type = GridCell.Type.DEEP  ## Deepest they'll go
var prefers_water: bool = false   ## More water trips vs sunbathing
var setup_time: float = 2.0      ## How long to "set up" at their spot
var packing_time: float = 2.0    ## How long to "pack up" before leaving

# -------------------------------------------------------------------
# Derived Stats
# -------------------------------------------------------------------

var move_speed: float = 100.0
var walk_in_speed: float = 50.0       ## Slower when arriving (carrying things)
var activity_speed_mult: float = 1.0
var roam_speed_mult: float = 1.0
var pause_chance: float = 0.0
var pause_duration: float = 0.0
var water_trips: int = 2              ## How many times they'll go to the water

# -------------------------------------------------------------------
# Generation
# -------------------------------------------------------------------

static func generate_random() -> SwimmerProfile:
	var profile := SwimmerProfile.new()

	profile.gender = Gender.MALE if randf() < 0.5 else Gender.FEMALE

	var age_roll := randf()
	if age_roll < 0.15:
		profile.age_group = AgeGroup.CHILD
		profile.age = randi_range(5, 12)
	elif age_roll < 0.30:
		profile.age_group = AgeGroup.TEEN
		profile.age = randi_range(13, 17)
	elif age_roll < 0.80:
		profile.age_group = AgeGroup.ADULT
		profile.age = randi_range(18, 55)
	else:
		profile.age_group = AgeGroup.ELDERLY
		profile.age = randi_range(56, 80)

	match profile.age_group:
		AgeGroup.CHILD:
			profile.fitness = randf_range(0.6, 0.9)
			profile.weight = randf_range(0.1, 0.3)
			profile.confidence = randf_range(0.3, 0.7)
			profile.patience = randf_range(0.1, 0.3)
		AgeGroup.TEEN:
			profile.fitness = randf_range(0.5, 0.9)
			profile.weight = randf_range(0.3, 0.6)
			profile.confidence = randf_range(0.5, 0.9)
			profile.patience = randf_range(0.2, 0.5)
		AgeGroup.ADULT:
			profile.fitness = randf_range(0.2, 0.8)
			profile.weight = randf_range(0.3, 0.9)
			profile.confidence = randf_range(0.4, 0.9)
			profile.patience = randf_range(0.4, 0.8)
		AgeGroup.ELDERLY:
			profile.fitness = randf_range(0.1, 0.4)
			profile.weight = randf_range(0.4, 0.8)
			profile.confidence = randf_range(0.3, 0.6)
			profile.patience = randf_range(0.7, 1.0)

	profile._calculate_derived()
	return profile


static func generate_for_group(group_type: SwimmerGroup.GroupType, index: int, total: int) -> SwimmerProfile:
	## Generates a profile appropriate for the group type and position within it.
	var profile := SwimmerProfile.new()

	match group_type:
		SwimmerGroup.GroupType.SOLO:
			profile = generate_random()

		SwimmerGroup.GroupType.COUPLE:
			profile.age_group = AgeGroup.ADULT
			profile.age = randi_range(20, 50)
			profile.gender = Gender.MALE if index == 0 else Gender.FEMALE
			profile.fitness = randf_range(0.3, 0.8)
			profile.weight = randf_range(0.3, 0.7)
			profile.confidence = randf_range(0.5, 0.9)
			profile.patience = randf_range(0.5, 0.8)

		SwimmerGroup.GroupType.FRIENDS:
			profile.age_group = AgeGroup.TEEN if randf() < 0.5 else AgeGroup.ADULT
			profile.age = randi_range(16, 30)
			profile.gender = Gender.MALE if randf() < 0.5 else Gender.FEMALE
			profile.fitness = randf_range(0.5, 0.9)
			profile.weight = randf_range(0.2, 0.6)
			profile.confidence = randf_range(0.6, 1.0)
			profile.patience = randf_range(0.2, 0.5)

		SwimmerGroup.GroupType.FAMILY:
			# First 2 are parents, rest are children
			if index < 2:
				profile.age_group = AgeGroup.ADULT
				profile.age = randi_range(28, 50)
				profile.gender = Gender.MALE if index == 0 else Gender.FEMALE
				profile.fitness = randf_range(0.3, 0.7)
				profile.weight = randf_range(0.4, 0.8)
				profile.confidence = randf_range(0.5, 0.8)
				profile.patience = randf_range(0.6, 0.9)
			else:
				profile.age_group = AgeGroup.CHILD
				profile.age = randi_range(4, 12)
				profile.gender = Gender.MALE if randf() < 0.5 else Gender.FEMALE
				profile.fitness = randf_range(0.7, 1.0)
				profile.weight = randf_range(0.1, 0.3)
				profile.confidence = randf_range(0.3, 0.7)
				profile.patience = randf_range(0.1, 0.3)

	profile._calculate_derived()
	return profile


func _calculate_derived() -> void:
	# Movement speed
	var speed_factor := (fitness * 0.7) + ((1.0 - weight) * 0.3)
	move_speed = lerpf(60.0, 140.0, speed_factor)

	match age_group:
		AgeGroup.CHILD:
			move_speed *= randf_range(1.0, 1.3)
		AgeGroup.ELDERLY:
			move_speed *= randf_range(0.5, 0.7)

	# Walk-in speed (carrying stuff, slower)
	walk_in_speed = move_speed * randf_range(0.4, 0.6)

	# Activity multiplier
	activity_speed_mult = lerpf(0.7, 1.5, fitness)

	# Roam speed
	roam_speed_mult = lerpf(0.6, 1.2, fitness)

	# Pauses
	pause_chance = lerpf(0.3, 0.0, fitness)
	pause_duration = lerpf(0.3, 1.2, 1.0 - fitness)

	# Water depth preference
	if confidence < 0.3 or age_group == AgeGroup.CHILD:
		max_water_depth = GridCell.Type.SHALLOW
	elif confidence < 0.6:
		max_water_depth = GridCell.Type.SHALLOW if randf() < 0.5 else GridCell.Type.DEEP
	else:
		max_water_depth = GridCell.Type.DEEP

	# Water preference
	prefers_water = fitness > 0.5 and confidence > 0.4

	# How many water trips (fit/young = more)
	match age_group:
		AgeGroup.CHILD:
			water_trips = randi_range(3, 6)
		AgeGroup.TEEN:
			water_trips = randi_range(2, 5)
		AgeGroup.ADULT:
			water_trips = randi_range(1, 3)
		AgeGroup.ELDERLY:
			water_trips = randi_range(0, 2)

	# Setup/packing times
	setup_time = randf_range(1.5, 4.0)
	packing_time = randf_range(1.5, 3.0)

	# Elderly and families take longer to set up
	if age_group == AgeGroup.ELDERLY:
		setup_time *= 1.5
		packing_time *= 1.5

	# Randomise on top
	move_speed *= randf_range(0.9, 1.1)


# -------------------------------------------------------------------
# Queries
# -------------------------------------------------------------------

func get_water_destination() -> GridCell.Type:
	## Returns which water zone this swimmer will go to.
	if max_water_depth == GridCell.Type.DEEP:
		return GridCell.Type.DEEP if randf() < confidence else GridCell.Type.SHALLOW
	return GridCell.Type.SHALLOW


func get_spot_activity_duration() -> float:
	## How long to relax at their spot between trips.
	var base := randf_range(3.0, 8.0)
	if age_group == AgeGroup.ELDERLY:
		base *= 1.5
	if age_group == AgeGroup.CHILD:
		base *= 0.4  # Kids don't sit still long
	return base * activity_speed_mult


func get_drying_off_duration() -> float:
	## How long to dry off after returning from water.
	return randf_range(1.5, 4.0)


# -------------------------------------------------------------------
# Display
# -------------------------------------------------------------------

func get_age_group_name() -> String:
	match age_group:
		AgeGroup.CHILD: return "Child"
		AgeGroup.TEEN: return "Teen"
		AgeGroup.ADULT: return "Adult"
		AgeGroup.ELDERLY: return "Elderly"
		_: return "Unknown"


func get_gender_name() -> String:
	match gender:
		Gender.MALE: return "M"
		Gender.FEMALE: return "F"
		_: return "?"


func get_summary() -> String:
	return "%s %s %d | Fit:%.0f%% Spd:%.0f" % [
		get_gender_name(),
		get_age_group_name(),
		age,
		fitness * 100,
		move_speed
	]

func get_activity_duration(base_min: float, base_max: float) -> float:
	## Returns a duration scaled by personality.
	var base := randf_range(base_min, base_max)
	return base * activity_speed_mult
