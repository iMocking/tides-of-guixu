extends Control
class_name CooldownSweep
## League-style cooldown: a dark wedge that unwinds clockwise from the top of
## the icon while the remaining seconds are printed in the middle.
##
## Only the wedge is drawn here - the countdown number stays a normal Label so
## it keeps the shared theme font and shadow.

var sweep_color := Color(0.016, 0.024, 0.039, 0.68)

var _ratio := 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## `remaining` / `total` seconds; 0 clears the wedge.
func set_cooldown(remaining: float, total: float) -> void:
    var ratio := clampf(remaining / maxf(total, 0.001), 0.0, 1.0)
    if is_equal_approx(ratio, _ratio):
        return
    _ratio = ratio
    queue_redraw()


func ratio() -> float:
    return _ratio


func _draw() -> void:
    if _ratio <= 0.001 or size.x <= 2.0 or size.y <= 2.0:
        return
    var center := size * 0.5
    # The radius has to reach the far corner for the wedge to cover the whole
    # square, so the arc itself runs past this control - GameUI mounts the
    # sweep inside a clipping frame (see _make_skill_button) that keeps it
    # inside the slot.
    var radius := size.length()
    var steps := maxi(int(ceil(64.0 * _ratio)), 2)
    var points := PackedVector2Array()
    points.append(center)
    for i in range(steps + 1):
        var angle := -PI * 0.5 + TAU * _ratio * float(i) / float(steps)
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    draw_colored_polygon(points, sweep_color)