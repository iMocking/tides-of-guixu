extends Control
class_name UiIcon
## Procedurally drawn vector icons - no external art assets.
##
## Every glyph is authored on a virtual 24x24 grid and scaled to fit the
## control, so a single definition stays crisp from 16px HUD buttons up to
## 48px panel headers.

var glyph := "bag"
var tint := Color.WHITE
var stroke := 1.8
## Draw size cap in pixels (0 = fill the control).
var glyph_size := 0.0
## Optional soft drop shadow so icons stay readable without a button plate.
var shadow_color := Color(0.0, 0.0, 0.0, 0.0)
var shadow_offset := Vector2(0.0, 1.5)

var _o := Vector2.ZERO
var _u := 1.0
var _paint := Color.WHITE

func _init(glyph_id := "bag", color := Color.WHITE, width := 1.8) -> void:
    glyph = glyph_id
    tint = color
    stroke = width
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    focus_mode = Control.FOCUS_NONE

## Change glyph / tint / stroke and repaint.
func setup(glyph_id: String, color: Color, width := 1.8) -> void:
    glyph = glyph_id
    tint = color
    stroke = width
    queue_redraw()

func set_tint(color: Color) -> void:
    if tint == color:
        return
    tint = color
    queue_redraw()

# --------------------------------------------------------------- painting ---
func _pt(x: float, y: float) -> Vector2:
    return _o + Vector2(x, y) * _u

func _line(a: Vector2, b: Vector2, weight := 1.0) -> void:
    draw_line(_pt(a.x, a.y), _pt(b.x, b.y), _paint, stroke * weight, true)

func _path(points: PackedVector2Array, closed := true, weight := 1.0) -> void:
    if points.size() < 2:
        return
    var scaled := PackedVector2Array()
    for point in points:
        scaled.append(_pt(point.x, point.y))
    if closed:
        scaled.append(scaled[0])
    draw_polyline(scaled, _paint, stroke * weight, true)

func _arc(center: Vector2, radius: float, from: float, to: float, weight := 1.0) -> void:
    draw_arc(_pt(center.x, center.y), radius * _u, from, to, 48, _paint, stroke * weight, true)

func _ring(center: Vector2, radius: float, weight := 1.0) -> void:
    _arc(center, radius, 0.0, TAU, weight)

func _dot(center: Vector2, radius: float) -> void:
    draw_circle(_pt(center.x, center.y), radius * _u, _paint)

func _draw() -> void:
    var span := minf(size.x, size.y)
    if glyph_size > 0.0:
        span = minf(span, glyph_size)
    if span <= 2.0:
        return
    _u = span / 24.0
    var base := (size - Vector2(span, span)) * 0.5
    if shadow_color.a > 0.0:
        _paint = shadow_color
        _o = base + shadow_offset
        _run_glyph()
    _paint = tint
    _o = base
    _run_glyph()

func _run_glyph() -> void:
    match glyph:
        "bag":
            _glyph_bag()
        "person":
            _glyph_person()
        "trophy":
            _glyph_trophy()
        "gear":
            _glyph_gear()
        "sword":
            _glyph_sword()
        "head":
            _glyph_head()
        "body":
            _glyph_body()
        "accessory":
            _glyph_accessory()
        "talisman":
            _glyph_talisman()
        "slot_weapon":
            _glyph_slot_weapon()
        "slot_head":
            _glyph_slot_head()
        "slot_body":
            _glyph_slot_body()
        "slot_legs":
            _glyph_slot_legs()
        "slot_boots":
            _glyph_slot_boots()
        "slot_bracers":
            _glyph_slot_bracers()
        "slot_accessory":
            _glyph_slot_accessory()
        "slot_talisman":
            _glyph_slot_talisman()
        "heart":
            _glyph_heart()
        "drop":
            _glyph_drop()
        "shield":
            _glyph_shield()
        "speed":
            _glyph_speed()
        "star":
            _glyph_star()
        "potion":
            _glyph_potion()
        "orb":
            _glyph_orb()
        "chevron_left":
            _glyph_chevron_left()
        "chevron_right":
            _glyph_chevron_right()
        "slash":
            _glyph_slash()
        "wood":
            _glyph_wood()
        "fire":
            _glyph_fire()
        "water":
            _glyph_water()
        "metal":
            _glyph_metal()
        "earth":
            _glyph_earth()
        "robe":
            _glyph_robe()
        "palette":
            _glyph_palette()
        "sparkle":
            _glyph_sparkle()
        _:
            _ring(Vector2(12.0, 12.0), 8.0)

# ---------------------------------------------------------------- glyphs ----
func _glyph_bag() -> void:
    _path(PackedVector2Array([
        Vector2(5.0, 9.0), Vector2(19.0, 9.0), Vector2(20.6, 11.6), Vector2(20.6, 18.4),
        Vector2(18.4, 21.0), Vector2(5.6, 21.0), Vector2(3.4, 18.4), Vector2(3.4, 11.6),
    ]))
    _arc(Vector2(12.0, 9.2), 3.7, PI, TAU)
    _line(Vector2(4.4, 14.2), Vector2(19.6, 14.2), 0.85)

func _glyph_person() -> void:
    _ring(Vector2(12.0, 8.2), 3.7)
    _arc(Vector2(12.0, 21.6), 7.7, PI, TAU)

func _glyph_trophy() -> void:
    _path(PackedVector2Array([
        Vector2(7.4, 3.6), Vector2(16.6, 3.6), Vector2(15.2, 11.8), Vector2(8.8, 11.8),
    ]))
    _arc(Vector2(7.6, 7.0), 2.9, PI * 0.5, PI * 1.5)
    _arc(Vector2(16.4, 7.0), 2.9, -PI * 0.5, PI * 0.5)
    _line(Vector2(12.0, 11.8), Vector2(12.0, 17.2))
    _line(Vector2(9.4, 17.2), Vector2(14.6, 17.2), 0.9)
    _line(Vector2(7.6, 20.2), Vector2(16.4, 20.2))

func _glyph_gear() -> void:
    _ring(Vector2(12.0, 12.0), 5.2)
    for i in range(8):
        var angle := TAU * float(i) / 8.0
        var dir := Vector2(cos(angle), sin(angle))
        _line(Vector2(12.0, 12.0) + dir * 5.2, Vector2(12.0, 12.0) + dir * 8.2, 1.7)
    _ring(Vector2(12.0, 12.0), 2.0, 0.85)

func _glyph_sword() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 2.4), Vector2(13.7, 5.2), Vector2(12.8, 14.6),
        Vector2(11.2, 14.6), Vector2(10.3, 5.2),
    ]))
    _line(Vector2(7.6, 15.6), Vector2(16.4, 15.6))
    _line(Vector2(12.0, 15.6), Vector2(12.0, 19.8))
    _dot(Vector2(12.0, 20.9), 1.3)

func _glyph_head() -> void:
    _arc(Vector2(12.0, 14.6), 6.7, PI, TAU)
    _line(Vector2(4.2, 14.6), Vector2(19.8, 14.6))
    _line(Vector2(12.0, 14.6), Vector2(12.0, 18.2), 0.9)
    _line(Vector2(12.0, 5.4), Vector2(12.0, 8.0), 0.8)

func _glyph_body() -> void:
    _path(PackedVector2Array([
        Vector2(8.6, 4.4), Vector2(12.0, 6.2), Vector2(15.4, 4.4), Vector2(17.6, 7.6),
        Vector2(16.0, 9.6), Vector2(15.0, 20.2), Vector2(9.0, 20.2), Vector2(8.0, 9.6),
        Vector2(6.4, 7.6),
    ]))
    _line(Vector2(12.0, 8.4), Vector2(12.0, 18.6), 0.8)

func _glyph_accessory() -> void:
    _ring(Vector2(12.0, 9.4), 4.7)
    _ring(Vector2(12.0, 9.4), 2.0, 0.85)
    _line(Vector2(12.0, 14.1), Vector2(12.0, 19.4))
    _dot(Vector2(12.0, 20.8), 1.4)

func _glyph_talisman() -> void:
    _path(PackedVector2Array([
        Vector2(7.8, 3.4), Vector2(16.2, 3.4), Vector2(16.2, 20.6), Vector2(7.8, 20.6),
    ]))
    _path(PackedVector2Array([
        Vector2(12.0, 6.2), Vector2(10.0, 9.2), Vector2(14.2, 12.6),
        Vector2(10.4, 15.6), Vector2(12.0, 18.4),
    ]), false, 0.85)

func _glyph_slot_weapon() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 2.2), Vector2(14.0, 6.0), Vector2(12.9, 15.0),
        Vector2(11.1, 15.0), Vector2(10.0, 6.0),
    ]))
    _line(Vector2(7.4, 16.0), Vector2(16.6, 16.0), 1.0)
    _line(Vector2(12.0, 16.0), Vector2(12.0, 19.8))
    _dot(Vector2(12.0, 21.0), 1.25)
    _arc(Vector2(7.1, 16.0), 1.9, -PI * 0.5, PI * 0.5, 0.65)
    _arc(Vector2(16.9, 16.0), 1.9, PI * 0.5, PI * 1.5, 0.65)
    _line(Vector2(9.2, 12.8), Vector2(14.8, 12.8), 0.6)


func _glyph_slot_head() -> void:
    _path(PackedVector2Array([
        Vector2(5.2, 15.4), Vector2(6.2, 7.6), Vector2(9.2, 4.2),
        Vector2(14.8, 4.2), Vector2(17.8, 7.6), Vector2(18.8, 15.4),
        Vector2(16.0, 19.4), Vector2(8.0, 19.4),
    ]))
    _line(Vector2(5.2, 15.4), Vector2(18.8, 15.4), 0.8)
    _dot(Vector2(12.0, 9.8), 1.35)
    _arc(Vector2(8.8, 13.1), 2.4, PI * 1.12, PI * 1.88, 0.65)
    _arc(Vector2(15.2, 13.1), 2.4, PI * 1.12, PI * 1.88, 0.65)


func _glyph_slot_body() -> void:
    _path(PackedVector2Array([
        Vector2(8.2, 3.8), Vector2(12.0, 6.0), Vector2(15.8, 3.8),
        Vector2(18.6, 7.0), Vector2(16.2, 10.2), Vector2(16.2, 20.6),
        Vector2(7.8, 20.6), Vector2(7.8, 10.2), Vector2(5.4, 7.0),
    ]))
    _line(Vector2(12.0, 8.0), Vector2(12.0, 20.0), 0.7)
    _line(Vector2(9.6, 13.0), Vector2(14.4, 13.0), 0.6)


func _glyph_slot_legs() -> void:
    _path(PackedVector2Array([
        Vector2(8.0, 3.6), Vector2(16.0, 3.6), Vector2(16.8, 20.6),
        Vector2(13.2, 20.6), Vector2(12.0, 11.8), Vector2(10.8, 20.6),
        Vector2(7.2, 20.6),
    ]))
    _line(Vector2(12.0, 4.2), Vector2(12.0, 10.8), 0.7)
    _line(Vector2(8.8, 8.0), Vector2(15.2, 8.0), 0.6)


func _glyph_slot_boots() -> void:
    _path(PackedVector2Array([
        Vector2(5.6, 5.0), Vector2(11.0, 5.0), Vector2(11.0, 12.4),
        Vector2(17.4, 12.4), Vector2(19.0, 16.0), Vector2(19.0, 19.6), Vector2(5.6, 19.6),
    ]))
    _line(Vector2(5.6, 16.8), Vector2(11.0, 16.8), 0.7)
    _line(Vector2(11.0, 5.0), Vector2(11.0, 12.4), 0.7)


func _glyph_slot_bracers() -> void:
    _path(PackedVector2Array([
        Vector2(7.8, 3.8), Vector2(16.2, 3.8), Vector2(17.8, 8.0),
        Vector2(16.0, 12.0), Vector2(17.0, 20.4), Vector2(7.0, 20.4),
        Vector2(8.0, 12.0), Vector2(6.2, 8.0),
    ]))
    _line(Vector2(8.0, 8.0), Vector2(16.0, 8.0), 0.7)
    _line(Vector2(8.0, 16.0), Vector2(16.0, 16.0), 0.7)


func _glyph_slot_accessory() -> void:
    _ring(Vector2(12.0, 8.8), 5.2)
    _ring(Vector2(12.0, 8.8), 2.3, 0.8)
    _line(Vector2(12.0, 14.1), Vector2(12.0, 18.6))
    _path(PackedVector2Array([
        Vector2(9.8, 16.2), Vector2(12.0, 20.6), Vector2(14.2, 16.2),
    ]), true, 0.9)


func _glyph_slot_talisman() -> void:
    _path(PackedVector2Array([
        Vector2(7.6, 3.2), Vector2(16.4, 3.2), Vector2(16.4, 20.8), Vector2(7.6, 20.8),
    ]))
    _line(Vector2(12.0, 6.0), Vector2(12.0, 18.0), 0.55)
    _path(PackedVector2Array([
        Vector2(12.0, 6.2), Vector2(10.0, 9.2), Vector2(14.2, 12.6),
        Vector2(10.4, 15.6), Vector2(12.0, 18.0),
    ]), false, 0.85)
    _dot(Vector2(12.0, 20.1), 1.05)


func _glyph_heart() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 20.2), Vector2(3.8, 12.0), Vector2(3.8, 8.6),
        Vector2(6.4, 6.2), Vector2(9.6, 7.0), Vector2(12.0, 10.0),
        Vector2(14.4, 7.0), Vector2(17.6, 6.2), Vector2(20.2, 8.6),
        Vector2(20.2, 12.0),
    ]))

func _glyph_drop() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 3.4), Vector2(16.6, 10.4), Vector2(17.6, 13.8),
        Vector2(15.6, 18.4), Vector2(12.0, 20.6), Vector2(8.4, 18.4),
        Vector2(6.4, 13.8), Vector2(7.4, 10.4),
    ]))

func _glyph_shield() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 2.8), Vector2(19.6, 6.0), Vector2(18.6, 13.6),
        Vector2(12.0, 20.8), Vector2(5.4, 13.6), Vector2(4.4, 6.0),
    ]))
    _line(Vector2(12.0, 7.0), Vector2(12.0, 16.8), 0.8)

func _glyph_speed() -> void:
    _path(PackedVector2Array([Vector2(4.6, 6.8), Vector2(10.0, 12.0), Vector2(4.6, 17.2)]), false)
    _path(PackedVector2Array([Vector2(12.4, 6.8), Vector2(17.8, 12.0), Vector2(12.4, 17.2)]), false)

func _glyph_star() -> void:
    var points := PackedVector2Array()
    for i in range(10):
        var angle := -PI * 0.5 + TAU * float(i) / 10.0
        var radius := 8.4 if i % 2 == 0 else 3.7
        points.append(Vector2(12.0 + cos(angle) * radius, 12.4 + sin(angle) * radius))
    _path(points, true)

# ------------------------------------------------------ skill glyphs -------
## Consumable: medicine bottle.
func _glyph_potion() -> void:
    _line(Vector2(9.9, 3.2), Vector2(14.1, 3.2), 0.85)
    _line(Vector2(10.4, 3.6), Vector2(10.4, 8.2), 0.8)
    _line(Vector2(13.6, 3.6), Vector2(13.6, 8.2), 0.8)
    _path(PackedVector2Array([
        Vector2(10.4, 8.2), Vector2(7.8, 12.2), Vector2(7.4, 16.6),
        Vector2(9.6, 20.4), Vector2(14.4, 20.4), Vector2(16.6, 16.6),
        Vector2(16.2, 12.2), Vector2(13.6, 8.2),
    ]), false)
    _line(Vector2(7.9, 14.4), Vector2(16.1, 14.4), 0.75)


## Material: monster core / bead.
func _glyph_orb() -> void:
    _ring(Vector2(12.0, 12.0), 7.6)
    _arc(Vector2(12.0, 12.0), 4.8, PI * 1.02, PI * 1.62, 0.85)
    _dot(Vector2(9.2, 9.0), 1.05)


func _glyph_chevron_left() -> void:
    _path(PackedVector2Array([
        Vector2(15.0, 4.6), Vector2(8.6, 12.0), Vector2(15.0, 19.4),
    ]), false, 1.3)


func _glyph_chevron_right() -> void:
    _path(PackedVector2Array([
        Vector2(9.0, 4.6), Vector2(15.4, 12.0), Vector2(9.0, 19.4),
    ]), false, 1.3)


## Basic attack: three parallel claw strokes.
func _glyph_slash() -> void:
    _arc(Vector2(15.6, 8.4), 6.6, PI * 0.55, PI * 1.06, 1.5)
    _arc(Vector2(13.0, 11.0), 6.6, PI * 0.55, PI * 1.06, 1.1)
    _arc(Vector2(10.4, 13.6), 6.6, PI * 0.55, PI * 1.06, 0.75)

## Wood: leaf with a midrib.
func _glyph_wood() -> void:
    _path(PackedVector2Array([
        Vector2(4.4, 19.6), Vector2(6.4, 11.0), Vector2(12.0, 4.8),
        Vector2(19.6, 4.4), Vector2(19.2, 12.0), Vector2(13.0, 17.6),
    ]))
    _line(Vector2(4.4, 19.6), Vector2(16.6, 7.4), 0.8)

## Fire: flame outline with an inner wick.
func _glyph_fire() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 2.6), Vector2(15.2, 8.4), Vector2(13.0, 10.4),
        Vector2(16.6, 9.4), Vector2(18.8, 13.0), Vector2(17.2, 18.6),
        Vector2(12.0, 21.4), Vector2(6.8, 18.6), Vector2(5.2, 13.0),
        Vector2(8.4, 13.6), Vector2(9.4, 10.0),
    ]))
    _line(Vector2(12.0, 20.2), Vector2(12.0, 13.6), 0.8)

## Water: six point snowflake.
func _glyph_water() -> void:
    for i in range(3):
        var angle := PI * float(i) / 3.0
        var dir := Vector2(cos(angle), sin(angle))
        var perp := Vector2(-dir.y, dir.x)
        _line(Vector2(12.0, 12.0) - dir * 8.6, Vector2(12.0, 12.0) + dir * 8.6, 1.0)
        for factor in [-1.0, 1.0]:
            var step := float(factor)
            var tip := Vector2(12.0, 12.0) + dir * 8.6 * step
            var base := Vector2(12.0, 12.0) + dir * 5.4 * step
            _line(tip, base + perp * 2.4, 0.7)
            _line(tip, base - perp * 2.4, 0.7)

## Metal: faceted gem.
func _glyph_metal() -> void:
    _path(PackedVector2Array([
        Vector2(7.0, 3.8), Vector2(17.0, 3.8), Vector2(21.2, 10.0),
        Vector2(12.0, 20.8), Vector2(2.8, 10.0),
    ]))
    _line(Vector2(2.8, 10.0), Vector2(21.2, 10.0), 0.85)
    _line(Vector2(7.0, 3.8), Vector2(9.2, 10.0), 0.65)
    _line(Vector2(17.0, 3.8), Vector2(14.8, 10.0), 0.65)
    _line(Vector2(9.2, 10.0), Vector2(12.0, 20.8), 0.65)
    _line(Vector2(14.8, 10.0), Vector2(12.0, 20.8), 0.65)

## Earth: sprout breaking through the soil.
func _glyph_earth() -> void:
    _arc(Vector2(12.0, 20.6), 8.2, PI * 1.12, PI * 1.88, 1.0)
    _line(Vector2(12.0, 20.4), Vector2(12.0, 10.6), 1.0)
    _path(PackedVector2Array([
        Vector2(12.0, 14.6), Vector2(8.2, 12.6), Vector2(5.4, 8.0),
        Vector2(10.6, 8.6), Vector2(12.0, 14.6),
    ]))
    _path(PackedVector2Array([
        Vector2(12.0, 12.6), Vector2(15.8, 10.2), Vector2(18.6, 5.4),
        Vector2(13.4, 6.4), Vector2(12.0, 12.6),
    ]))
## Fashion: a hanging robe with a waist sash.
func _glyph_robe() -> void:
    _path(PackedVector2Array([
        Vector2(9.2, 3.6), Vector2(14.8, 3.6), Vector2(20.4, 8.4), Vector2(17.6, 12.2),
        Vector2(16.6, 9.6), Vector2(17.2, 20.4), Vector2(6.8, 20.4), Vector2(7.4, 9.6),
        Vector2(6.4, 12.2), Vector2(3.6, 8.4),
    ]))
    _line(Vector2(9.2, 3.6), Vector2(12.0, 6.4), 0.8)
    _line(Vector2(14.8, 3.6), Vector2(12.0, 6.4), 0.8)
    _line(Vector2(7.6, 12.8), Vector2(16.4, 12.8), 0.7)


## Dye: a painter's palette with a few colour wells.
func _glyph_palette() -> void:
    _ring(Vector2(12.0, 12.0), 8.2)
    _dot(Vector2(9.9, 8.4), 1.7)
    _dot(Vector2(15.3, 9.4), 1.7)
    _dot(Vector2(15.0, 15.0), 1.7)
    _dot(Vector2(9.3, 14.3), 1.7)


## Aura: a four-point sparkle with two satellites.
func _glyph_sparkle() -> void:
    _path(PackedVector2Array([
        Vector2(12.0, 2.8), Vector2(13.6, 10.4), Vector2(21.2, 12.0), Vector2(13.6, 13.6),
        Vector2(12.0, 21.2), Vector2(10.4, 13.6), Vector2(2.8, 12.0), Vector2(10.4, 10.4),
    ]))
    _dot(Vector2(18.8, 5.2), 1.5)
    _dot(Vector2(5.4, 18.6), 1.2)
