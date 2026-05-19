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

var fitness: float = 0.5    ## Affects speed and activity duration
var weight: float = 0.5     ## Affects speed (heavier = slower)
var confidence: float = 0.5 ## Affects how likely to go to deep water
var patience: float = 0.5   ## Affects how long they wait before repathing

# -------------------------------------------------------------------
# Derived Stats
# -------------------------------------------------------------------

var move_speed: float = 100.0
var activity_speed_mult: float = 1.0   ## Multiplier on activity durations
var roam_speed_mult: float = 1.0       ## Multiplier on roaming speed
var pause_chance: float = 0.0          ## Chance to pause between steps
var pause_duration: float = 0.0        ## How long pauses last

# -------------------------------------------------------------------
# Generation
# -------------------------------------------------------------------

static func generate_random() -> SwimmerProfile:
	var profile := SwimmerProfile.new()

	# Random gender
	profile.gender = Gender.MALE if randf() < 0.5 else Gender.FEMALE

	# Random age group (weighted: more adults)
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

	# Stats influenced by age
	match profile.age_group:
		AgeGroup.CHILD:
			profile.fitness = randf_range(0.6, 0.9)
			profile.weight = randf_range(0.1, 0.3)
			profile.confidence = randf_range(0.3, 0.7)
			profile.patience = randf_range(0.1, 0.3)  # Kids are impatient!
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
			profile.patience = randf_range(0.7, 1.0)  # Elderly are patient

	# Calculate derived stats
	profile._calculate_derived()

	return profile


func _calculate_derived() -> void:
	## Converts raw stats into gameplay values.

	# Base speed: 60-140 pixels/sec
	# High fitness = faster, high weight = slower
	var speed_factor := (fitness * 0.7) + ((1.0 - weight) * 0.3)
	move_speed = lerpf(60.0, 140.0, speed_factor)

	# Children are fast but erratic, elderly are slow
	match age_group:
		AgeGroup.CHILD:
			move_speed *= randf_range(1.0, 1.3)
		AgeGroup.ELDERLY:
			move_speed *= randf_range(0.5, 0.7)

	# Activity duration multiplier (fit people do activities longer)
	activity_speed_mult = lerpf(0.7, 1.5, fitness)

	# Roam speed (how fast they move while swimming/wading)
	roam_speed_mult = lerpf(0.6, 1.2, fitness)

	# Pause behaviour (less fit = more pauses)
	pause_chance = lerpf(0.3, 0.0, fitness)  # 0-30% chance per step
	pause_duration = lerpf(0.3, 1.2, 1.0 - fitness)

	# Add some randomness on top
	move_speed *= randf_range(0.9, 1.1)


# -------------------------------------------------------------------
# Preference Queries
# -------------------------------------------------------------------

func get_activity_preference() -> GridCell.Type:
	## Returns preferred activity zone based on personality.
	var roll := randf()

	# Confident/fit swimmers go deeper
	var deep_threshold := confidence * 0.4   # 0-40% chance for deep
	var shallow_threshold := deep_threshold + 0.3

	if roll < deep_threshold:
		return GridCell.Type.DEEP
	elif roll < shallow_threshold:
		return GridCell.Type.SHALLOW
	else:
		return GridCell.Type.BEACH


func get_activity_duration(base_min: float, base_max: float) -> float:
	## Returns a duration scaled by personality.
	var base := randf_range(base_min, base_max)
	return base * activity_speed_mult


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
	return "%s %s %d | Fit:%.0f%% Wt:%.0f%% Spd:%.0f" % [
		get_gender_name(),
		get_age_group_name(),
		age,
		fitness * 100,
		weight * 100,
		move_speed
	]
