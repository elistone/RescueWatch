class_name DangerBar
extends Control

## Floating danger/fatigue bar above a swimmer.
##
## - Hidden when safe
## - Shows as thin bar that grows/shrinks with fatigue
## - Colour transitions: green → yellow → orange → red
## - Flashes when drowning

@onready var bar_fill: ColorRect = $Fill
@onready var bar_bg: ColorRect = $Background

const BAR_WIDTH: float = 32.0
const BAR_HEIGHT: float = 4.0

var _flash_timer: float = 0.0
var _visible_amount: float = 0.0


func _ready() -> void:
	visible = false

	bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_bg.color = Color(0, 0, 0, 0.5)

	bar_fill.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar_fill.size = Vector2(0, BAR_HEIGHT)


func update_bar(fatigue_ratio: float, danger_state: SwimmerFatigue.DangerState, delta: float) -> void:
	if danger_state == SwimmerFatigue.DangerState.SAFE and fatigue_ratio < 0.3:
		visible = false
		return

	visible = true

	_visible_amount = lerp(_visible_amount, fatigue_ratio, delta * 5.0)

	var fill_width: float = _visible_amount * BAR_WIDTH
	bar_fill.size.x = fill_width
	bar_fill.custom_minimum_size.x = fill_width

	var bar_color: Color = _get_color(danger_state, _visible_amount)

	if danger_state == SwimmerFatigue.DangerState.DROWNING:
		_flash_timer += delta * 6.0
		var flash: float = abs(sin(_flash_timer))
		bar_color = bar_color.lerp(Color.WHITE, flash * 0.5)
	elif danger_state == SwimmerFatigue.DangerState.STRUGGLING:
		_flash_timer += delta * 3.0
		var flash: float = abs(sin(_flash_timer))
		bar_color = bar_color.lerp(Color.WHITE, flash * 0.2)
	else:
		_flash_timer = 0.0

	bar_fill.color = bar_color


func _get_color(danger_state: SwimmerFatigue.DangerState, ratio: float) -> Color:
	match danger_state:
		SwimmerFatigue.DangerState.SAFE:
			return Color.GREEN.lerp(Color.YELLOW, ratio / 0.6)
		SwimmerFatigue.DangerState.TIRED:
			return Color.YELLOW
		SwimmerFatigue.DangerState.STRUGGLING:
			return Color.ORANGE_RED
		SwimmerFatigue.DangerState.DROWNING:
			return Color.RED
		SwimmerFatigue.DangerState.DROWNED:
			return Color.DARK_RED
		_:
			return Color.GREEN
