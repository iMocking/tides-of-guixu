extends Control
class_name VitalBar
## League-style tracker bar: a dark plate, a coloured fill, segment ticks, a
## trailing "damage ghost" and the value printed straight on the bar.
##
## Drawn procedurally to stay in step with the rest of the HUD (UiIcon,
## ViewCompass ...) and to keep the bar readable on any background.

const PLATE := Color(0.031, 0.043, 0.067, 0.82)
const BORDER := Color(0.0, 0.0, 0.0, 0.75)
const GHOST := Color(0.94, 0.90, 0.72, 0.72)
const HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.16)
const TICK := Color(0.0, 0.0, 0.0, 0.42)
const TEXT := Color(0.96, 0.97, 0.95)
const TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.8)
## How fast the damage ghost catches up, as a fraction of the bar per second.
const GHOST_RATE := 0.85
const GHOST_MIN_RATE := 10.0

var value := 100.0
var max_value := 100.0
var bar_color := Color(0.847, 0.376, 0.396)
var caption := ""
## Value per tick mark; 0 draws no ticks.
var tick_step := 0.0
## Pick a tick step so the bar shows roughly eight segments.
var auto_ticks := true
var font_size := 13
var show_caption := true

var _ghost := 100.0
var _font: Font


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _font = get_theme_font("font", "Label")
    if _font == null:
        _font = ThemeDB.fallback_font


func set_values(current: float, maximum: float) -> void:
    var new_max := maxf(maximum, 1.0)
    var new_value := clampf(current, 0.0, new_max)
    var new_caption := "%d / %d" % [int(round(new_value)), int(round(new_max))]
    var changed := not is_equal_approx(new_max, max_value) \
        or not is_equal_approx(new_value, value) \
        or new_caption != caption
    max_value = new_max
    value = new_value
    caption = new_caption
    _ghost = clampf(maxf(_ghost, value), 0.0, max_value)
    if auto_ticks:
        var step := nice_tick_step(max_value)
        if not is_equal_approx(step, tick_step):
            tick_step = step
            changed = true
    if changed:
        queue_redraw()


## Roughly eight ticks across the bar, snapped to a readable round number.
static func nice_tick_step(maximum: float) -> float:
    var target := maximum / 8.0
    var candidates := [1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0, 200.0, 250.0,
        500.0, 1000.0, 2000.0, 2500.0, 5000.0, 10000.0]
    var best := 0.0
    for candidate in candidates:
        if float(candidate) <= target:
            best = float(candidate)
        else:
            break
    return best


func _process(delta: float) -> void:
    if _ghost <= value:
        if not is_equal_approx(_ghost, value):
            _ghost = value
            queue_redraw()
        return
    _ghost = maxf(value, _ghost - (max_value * GHOST_RATE + GHOST_MIN_RATE) * delta)
    queue_redraw()


func _draw() -> void:
    var width := size.x
    var height := size.y
    if width <= 2.0 or height <= 2.0:
        return
    var reference := maxf(max_value, 1.0)
    var ratio := clampf(value / reference, 0.0, 1.0)
    var ghost_ratio := clampf(_ghost / reference, 0.0, 1.0)
    var inner_width := width - 2.0
    var inner_height := height - 2.0

    draw_rect(Rect2(0.0, 0.0, width, height), PLATE)
    if ghost_ratio > ratio:
        draw_rect(Rect2(1.0, 1.0, inner_width * ghost_ratio, inner_height), GHOST)
    if ratio > 0.0:
        draw_rect(Rect2(1.0, 1.0, inner_width * ratio, inner_height), bar_color)
        draw_rect(Rect2(1.0, 1.0, inner_width * ratio, maxf(inner_height * 0.3, 1.0)), HIGHLIGHT)

    if tick_step > 0.0:
        var step_px := inner_width * (tick_step / reference)
        if step_px >= 3.0:
            var x := 1.0 + step_px
            while x < width - 1.0:
                draw_rect(Rect2(floorf(x), 1.0, 1.0, inner_height), TICK)
                x += step_px

    draw_rect(Rect2(0.0, 0.0, width, height), BORDER, false, 1.0)

    if show_caption and caption != "" and _font != null:
        var text_width := _font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var baseline := (height + _font.get_ascent(font_size) - _font.get_descent(font_size)) * 0.5
        var origin := Vector2((width - text_width) * 0.5, baseline)
        draw_string(_font, origin + Vector2(1.0, 1.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_SHADOW)
        draw_string(_font, origin, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT)