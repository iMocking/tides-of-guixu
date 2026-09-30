extends Control
class_name ViewCompass
## Horizontal compass strip for the HUD.
##
## Draws the cardinal directions the camera is facing plus tick marks every 15
## degrees, so the player can tell where the rotatable camera points.

const VISIBLE_DEGREES := 190.0
const TICK_MINOR := 15

var heading_deg := 0.0

var _font: Font

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true
    _font = ThemeBuilder.body_font()

## Camera heading in degrees: 0 = north (-Z), 90 = east (+X).
func set_heading(degrees: float) -> void:
    var wrapped := wrapf(degrees, 0.0, 360.0)
    if absf(wrapped - heading_deg) < 0.05:
        return
    heading_deg = wrapped
    queue_redraw()

func _draw() -> void:
    var width := size.x
    var height := size.y
    if width <= 1.0 or height <= 1.0:
        return
    var font := _font if _font != null else ThemeBuilder.body_font()
    var center_x := width * 0.5
    var pixels_per_degree := width / VISIBLE_DEGREES

    for degrees in range(0, 360, TICK_MINOR):
        var delta := wrapf(float(degrees) - heading_deg, -180.0, 180.0)
        var x := center_x + delta * pixels_per_degree
        if x < -20.0 or x > width + 20.0:
            continue
        var major := degrees % 90 == 0
        var fade := clampf(1.0 - absf(delta) / (VISIBLE_DEGREES * 0.6), 0.12, 1.0)
        var tick_height := 13.0 if major else 7.0
        var tick_color := ThemeBuilder.JADE_DIM if major else ThemeBuilder.TEXT_MUTED
        tick_color.a *= fade
        draw_line(Vector2(x, height - 1.0), Vector2(x, height - 1.0 - tick_height), tick_color, 1.0)
        if major:
            var label := _cardinal(degrees)
            if label == "":
                continue
            var label_color := ThemeBuilder.GOLD if absf(delta) < 12.0 else ThemeBuilder.TEXT_DIM
            label_color.a *= fade
            var label_pos := Vector2(x - 26.0, height - 17.0)
            # Plate-free HUD, so give the text a soft shadow for legibility.
            draw_string(font, label_pos + Vector2(1.0, 1.0), label, HORIZONTAL_ALIGNMENT_CENTER, 52.0, 14, Color(0.0, 0.0, 0.0, 0.75 * fade))
            draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, 52.0, 14, label_color)

    var marker_color := ThemeBuilder.GOLD
    draw_line(Vector2(center_x, 0.0), Vector2(center_x, 6.0), marker_color, 2.0)
    draw_rect(Rect2(center_x - 18.0, height - 2.0, 36.0, 1.0), Color(marker_color.r, marker_color.g, marker_color.b, 0.5), true)

func _cardinal(degrees: int) -> String:
    match degrees:
        0:
            return LocaleData.text("dir_north")
        90:
            return LocaleData.text("dir_east")
        180:
            return LocaleData.text("dir_south")
        270:
            return LocaleData.text("dir_west")
    return ""