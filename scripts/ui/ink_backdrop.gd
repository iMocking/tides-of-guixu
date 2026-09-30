extends Control
class_name InkBackdrop
## Procedural ink-wash (水墨) title backdrop: layered mountain silhouettes,
## drifting mist, a pale moon and slow cloud banks. No external art assets.

const LAYER_COUNT := 4
const SKY_STEPS := 64

var _time := 0.0
var _seeds: Array[float] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _rng.seed = 20250930
    for _i in range(LAYER_COUNT):
        _seeds.append(_rng.randf() * 128.0)

func _process(delta: float) -> void:
    _time += delta
    queue_redraw()

# ------------------------------------------------------------------ paint ---
func _draw() -> void:
    var w := size.x
    var h := size.y
    if w < 16.0 or h < 16.0:
        return
    _draw_sky(w, h)
    _draw_moon(w, h)
    _draw_mountains(w, h)
    _draw_mist(w, h)
    _draw_clouds(w, h)

func _draw_sky(w: float, h: float) -> void:
    var top := Color(0.031, 0.039, 0.055)
    var mid := Color(0.070, 0.082, 0.098)
    var bottom := Color(0.118, 0.113, 0.100)
    var band := h / float(SKY_STEPS)
    for i in range(SKY_STEPS):
        var t := float(i) / float(SKY_STEPS - 1)
        var color := top.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(bottom, (t - 0.5) * 2.0)
        draw_rect(Rect2(0.0, band * float(i), w, band + 1.0), color)

func _draw_moon(w: float, h: float) -> void:
    var center := Vector2(w * 0.735, h * 0.215)
    var radius := minf(w, h) * 0.045
    for i in range(5, 0, -1):
        var t := float(i) / 5.0
        draw_circle(center, radius * (1.0 + t * 2.6), Color(0.88, 0.91, 0.85, 0.022 * (1.0 - t) + 0.008))
    draw_circle(center, radius, Color(0.90, 0.91, 0.83, 0.90))
    for i in range(3):
        var angle := 1.1 + float(i) * 2.1
        var spot := center + Vector2(cos(angle), sin(angle)) * radius * 0.45
        draw_circle(spot, radius * 0.16, Color(0.78, 0.80, 0.74, 0.22))

func _draw_mountains(w: float, h: float) -> void:
    for layer in range(LAYER_COUNT):
        var ridge := _ridge_points(w, h, layer)
        var depth := float(layer) / float(LAYER_COUNT - 1)
        # Hazy lit ridge fading into a dark ink base.
        var peak := Color(0.170, 0.192, 0.198, 0.16 + 0.34 * depth)
        var base := Color(0.014, 0.019, 0.027, 0.58 + 0.40 * depth)
        var bottom := h + 4.0
        for i in range(ridge.size() - 1):
            var a := ridge[i]
            var b := ridge[i + 1]
            var quad := PackedVector2Array([
                a, b, Vector2(b.x, bottom), Vector2(a.x, bottom),
            ])
            draw_polygon(quad, PackedColorArray([peak, peak, base, base]))
        if layer == LAYER_COUNT - 1:
            draw_polyline(ridge, Color(0.66, 0.72, 0.68, 0.12), 1.0, true)


func _ridge_points(w: float, h: float, layer: int) -> PackedVector2Array:
    var points := PackedVector2Array()
    var base_y := h * (0.50 + 0.115 * float(layer))
    var amplitude := h * (0.115 - 0.020 * float(layer))
    var steps := 22 + layer * 8
    for i in range(steps + 1):
        var t := float(i) / float(steps)
        var wave := _wave(t * (2.6 + float(layer) * 1.1), _seeds[layer])
        points.append(Vector2(w * t, base_y - amplitude * wave))
    return points

func _wave(x: float, seed: float) -> float:
    var value := sin(x * 1.7 + seed) * 0.5 + sin(x * 0.9 + seed * 1.7) * 0.32 + sin(x * 3.1 + seed * 2.3) * 0.18
    return clampf(value * 0.5 + 0.5, 0.0, 1.0)

func _draw_mist(w: float, h: float) -> void:
    for i in range(3):
        var y := h * (0.50 + 0.055 * float(i))
        var band := h * 0.085
        var drift := sin(_time * 0.05 + float(i) * 1.7) * w * 0.025
        var mist := Color(0.64, 0.70, 0.67, 0.075)
        var clear := Color(0.64, 0.70, 0.67, 0.0)
        var poly := PackedVector2Array([
            Vector2(-30.0 + drift, y),
            Vector2(w + 30.0 + drift, y - band * 0.3),
            Vector2(w + 30.0 + drift, y + band),
            Vector2(-30.0 + drift, y + band * 1.25),
        ])
        draw_polygon(poly, PackedColorArray([clear, clear, mist, mist]))

func _draw_clouds(w: float, h: float) -> void:
    for i in range(5):
        var speed := 5.0 + float(i) * 2.4
        var x := fmod(_time * speed + float(i) * 431.0, w + 700.0) - 350.0
        var y := h * (0.14 + 0.055 * float(i % 3))
        var scale := 0.75 + 0.22 * float(i % 3)
        for j in range(5):
            var offset := Vector2(float(j - 2) * 48.0 * scale, sin(float(j) * 1.3 + float(i)) * 9.0 * scale)
            draw_circle(Vector2(x, y) + offset, 42.0 * scale, Color(0.74, 0.78, 0.75, 0.018))