class_name SwimmerFatigue
extends RefCounted

## Tracks a swimmer's fatigue, stamina, and danger state.
##
## Fatigue builds while in water. When it exceeds stamina thresholds,
## the swimmer enters progressively more dangerous states.
## Recovery happens on land.

# -------------------------------------------------------------------
# Danger States
# -------------------------------------------------------------------

enum DangerState {
	SAFE,        ## On land or resting, no danger
	TIRED,       ## Getting fatigued, moving slower (can self-rescue)
	STRUGGLING,  ## Cannot swim, waving for help (cannot self-rescue)
	DROWNING,    ## Sinking, urgent (cannot self-rescue)
	DROWNED,     ## Too late
}

# -------------------------------------------------------------------
# Stats
# -------------------------------------------------------------------

var fatigue: float = 0.0          ## 0.0 (fresh) to 1.0+ (exhausted)
var stamina: float = 1.0          ## Max fatigue before danger (profile-driven)
var danger_state: DangerState = DangerState.SAFE

## Thresholds (as fraction of stamina)
var tired_threshold: float = 0.6
var struggling_threshold: float = 0.85
var drowning_threshold: float = 1.0

## Timers for state escalation
var struggling_time: float = 0.0
var struggling_max: float = 12.0   ## Seconds before escalating to drowning
var drowning_time: float = 0.0
var drowning_max: float = 6.0      ## Seconds before drowned

## Recovery
var recovery_rate: float = 0.15    ## Fatigue recovered per second on land

## Flags
var in_water: bool = false
var had_cramp: bool = false

# -------------------------------------------------------------------
# Initialization
# -------------------------------------------------------------------

static func create_from_profile(profile: SwimmerProfile) -> SwimmerFatigue:
	var f := SwimmerFatigue.new()

	# Stamina based on fitness and age
	f.stamina = profile.fitness * 0.8 + 0.2  # 0.2 to 1.0

	# Adjust for age
	match profile.age_group:
		SwimmerProfile.AgeGroup.CHILD:
			f.stamina *= 0.6   # Kids tire fast
			f.struggling_max = 8.0
			f.drowning_max = 5.0
		SwimmerProfile.AgeGroup.TEEN:
			f.stamina *= 0.9
		SwimmerProfile.AgeGroup.ADULT:
			f.stamina *= 1.0
		SwimmerProfile.AgeGroup.ELDERLY:
			f.stamina *= 0.5   # Elderly tire very fast
			f.struggling_max = 10.0
			f.drowning_max = 5.0

	# Recovery rate based on fitness
	f.recovery_rate = lerpf(0.08, 0.25, profile.fitness)

	return f


# -------------------------------------------------------------------
# Update
# -------------------------------------------------------------------

func update(delta: float, cell_type: GridCell.Type) -> void:
	## Call every frame. Updates fatigue and danger state.

	in_water = (cell_type == GridCell.Type.SHALLOW or cell_type == GridCell.Type.DEEP)

	if in_water:
		_build_fatigue(delta, cell_type)
	else:
		_recover(delta)

	_update_danger_state()


func _build_fatigue(delta: float, cell_type: GridCell.Type) -> void:
	## Fatigue increases while in water.
	var rate := 0.05  # Base fatigue per second

	# Deep water is harder
	if cell_type == GridCell.Type.DEEP:
		rate *= 2.0

	# Cramp doubles fatigue rate
	if had_cramp:
		rate *= 2.0

	fatigue += rate * delta


func _recover(delta: float) -> void:
	## Fatigue decreases on land.
	if danger_state == DangerState.SAFE or danger_state == DangerState.TIRED:
		fatigue = max(0.0, fatigue - recovery_rate * delta)
		# Reset cramp when fully recovered
		if fatigue <= 0.0:
			had_cramp = false


func _update_danger_state() -> void:
	## Determines danger state based on fatigue thresholds.
	var fatigue_ratio := fatigue / stamina

	match danger_state:
		DangerState.SAFE:
			if fatigue_ratio >= tired_threshold and in_water:
				danger_state = DangerState.TIRED

		DangerState.TIRED:
			if not in_water or fatigue_ratio < tired_threshold:
				danger_state = DangerState.SAFE
			elif fatigue_ratio >= struggling_threshold:
				danger_state = DangerState.STRUGGLING
				struggling_time = 0.0

		DangerState.STRUGGLING:
			if fatigue_ratio >= drowning_threshold:
				danger_state = DangerState.DROWNING
				drowning_time = 0.0

		DangerState.DROWNING:
			# No escape from drowning without rescue
			pass

		DangerState.DROWNED:
			# Final state
			pass


func update_timers(delta: float) -> void:
	## Updates escalation timers for struggling/drowning.
	## Call separately so states can react to transitions.

	match danger_state:
		DangerState.STRUGGLING:
			struggling_time += delta
			if struggling_time >= struggling_max:
				danger_state = DangerState.DROWNING
				drowning_time = 0.0

		DangerState.DROWNING:
			drowning_time += delta
			if drowning_time >= drowning_max:
				danger_state = DangerState.DROWNED


# -------------------------------------------------------------------
# Events
# -------------------------------------------------------------------

func trigger_cramp() -> void:
	## Random cramp event — instant fatigue spike.
	had_cramp = true
	fatigue += stamina * 0.3  # Jump 30% toward exhaustion


func rescue() -> void:
	## Called when lifeguard rescues this swimmer.
	danger_state = DangerState.SAFE
	fatigue = stamina * 0.5  # Still tired but safe
	had_cramp = false


# -------------------------------------------------------------------
# Queries
# -------------------------------------------------------------------

func get_danger_ratio() -> float:
	## Returns 0.0 (safe) to 1.0 (drowning) for the bar display.
	if stamina <= 0:
		return 1.0
	return clampf(fatigue / stamina, 0.0, 1.0)


func can_self_rescue() -> bool:
	## TIRED swimmers can get back to shore. STRUGGLING+ cannot.
	return danger_state == DangerState.SAFE or danger_state == DangerState.TIRED


func is_in_danger() -> bool:
	return danger_state == DangerState.STRUGGLING or danger_state == DangerState.DROWNING


func get_state_name() -> String:
	match danger_state:
		DangerState.SAFE: return "SAFE"
		DangerState.TIRED: return "TIRED"
		DangerState.STRUGGLING: return "STRUGGLING"
		DangerState.DROWNING: return "DROWNING"
		DangerState.DROWNED: return "DROWNED"
		_: return "UNKNOWN"
