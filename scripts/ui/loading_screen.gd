extends Control
class_name LoadingScreen
## Full-screen ink-wash loading screen.
##
## The progress bar is deliberately anchored to the bottom edge, while the
## centre stays as clean title art so the transition into the world feels like
## a scroll opening rather than an opaque system dialog.

var _progress: ProgressBar
var _status: Label
var _percent: Label


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    theme = ThemeBuilder.shared_theme()
    _build()
    set_progress(0.0, LocaleData.text("loading_data"))


func set_progress(value: float, status: String) -> void:
    var clamped := clampf(value, 0.0, 1.0)
    if _progress != null:
        _progress.value = clamped
    if _status != null:
        _status.text = status
    if _percent != null:
        _percent.text = "%d%%" % int(round(clamped * 100.0))


func _build() -> void:
    var backdrop := InkBackdrop.new()
    backdrop.name = "InkBackdrop"
    add_child(backdrop)

    var shade := ColorRect.new()
    shade.name = "Shade"
    shade.color = Color(0.006, 0.010, 0.018, 0.42)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(center)

    var title_column := UIKit.vbox(10)
    title_column.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_child(title_column)

    var title_row := UIKit.hbox(18)
    title_row.alignment = BoxContainer.ALIGNMENT_CENTER
    title_column.add_child(title_row)

    var title := UIKit.label(LocaleData.text("loading_title"), "", HORIZONTAL_ALIGNMENT_CENTER)
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", ThemeBuilder.GOLD)
    title.add_theme_color_override("font_outline_color", Color(0.04, 0.035, 0.025, 0.9))
    title.add_theme_constant_override("outline_size", 6)
    title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 4)
    title_row.add_child(title)

    title_row.add_child(_build_seal())

    var rule_row := UIKit.hbox(12)
    rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
    title_column.add_child(rule_row)

    var left_rule := HSeparator.new()
    left_rule.add_theme_stylebox_override("separator", ThemeBuilder.line_box(Color(0.78, 0.66, 0.36, 0.65), 1))
    left_rule.custom_minimum_size = Vector2(150, 0)
    rule_row.add_child(left_rule)

    var diamond := UIKit.label("\u25c6", "", HORIZONTAL_ALIGNMENT_CENTER)
    diamond.add_theme_font_size_override("font_size", 12)
    diamond.add_theme_color_override("font_color", Color(0.82, 0.70, 0.42, 0.9))
    rule_row.add_child(diamond)

    var right_rule := HSeparator.new()
    right_rule.add_theme_stylebox_override("separator", ThemeBuilder.line_box(Color(0.78, 0.66, 0.36, 0.65), 1))
    right_rule.custom_minimum_size = Vector2(150, 0)
    rule_row.add_child(right_rule)

    var subtitle := UIKit.muted(LocaleData.text("loading_subtitle"))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.custom_minimum_size = Vector2(520, 0)
    title_column.add_child(subtitle)

    var bottom := VBoxContainer.new()
    bottom.name = "BottomProgress"
    bottom.anchor_left = 0.055
    bottom.anchor_right = 0.945
    bottom.anchor_top = 0.835
    bottom.anchor_bottom = 0.94
    bottom.offset_left = 0.0
    bottom.offset_right = 0.0
    bottom.offset_top = 0.0
    bottom.offset_bottom = 0.0
    bottom.add_theme_constant_override("separation", 8)
    add_child(bottom)

    var top_line := HSeparator.new()
    top_line.add_theme_stylebox_override("separator", ThemeBuilder.line_box(Color(0.78, 0.66, 0.36, 0.42), 1))
    bottom.add_child(top_line)

    var info_row := UIKit.hbox(8)
    bottom.add_child(info_row)

    _status = UIKit.hint(LocaleData.text("loading_data"))
    _status.add_theme_color_override("font_color", ThemeBuilder.TEXT_DIM)
    info_row.add_child(_status)
    info_row.add_child(UIKit.spacer(true, false))

    _percent = UIKit.value("0%")
    _percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _percent.add_theme_color_override("font_color", ThemeBuilder.GOLD_DIM)
    info_row.add_child(_percent)

    _progress = ProgressBar.new()
    _progress.name = "Progress"
    _progress.min_value = 0.0
    _progress.max_value = 1.0
    _progress.value = 0.0
    _progress.show_percentage = false
    _progress.custom_minimum_size = Vector2(0, 16)
    _progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _progress.add_theme_stylebox_override("background", ThemeBuilder.flat_box(ThemeBuilder.BG_TRACK, ThemeBuilder.BORDER_MUTED, 4, 1))
    _progress.add_theme_stylebox_override("fill", ThemeBuilder.flat_box(Color(0.29, 0.56, 0.47, 0.95), ThemeBuilder.JADE, 4, 1))
    bottom.add_child(_progress)


func _build_seal() -> Control:
    var seal := PanelContainer.new()
    seal.name = "Seal"
    seal.add_theme_stylebox_override("panel", ThemeBuilder.flat_box(Color(0.612, 0.157, 0.129, 0.92), Color(0.815, 0.290, 0.220, 0.95), 5, 2, 4.0, 4.0))
    seal.custom_minimum_size = Vector2(58, 58)
    seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    seal.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var glyph := UIKit.label(LocaleData.text("game_seal"), "", HORIZONTAL_ALIGNMENT_CENTER)
    glyph.add_theme_font_size_override("font_size", 19)
    glyph.add_theme_color_override("font_color", Color(0.98, 0.945, 0.890))
    glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    glyph.add_theme_constant_override("line_spacing", 0)
    seal.add_child(glyph)
    return seal
