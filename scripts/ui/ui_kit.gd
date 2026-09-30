class_name UIKit
## Widget factory for the game UI.
##
## Keeps every screen using the same spacing, label hierarchy, panel shell and
## open/close motion. Widgets are plain Godot Controls so they stay easy to
## restyle and to test.

const PAD := 20
const PAD_WIDE := 24
const GAP := 12
const GAP_SMALL := 8

static var _slot_box_cache: Dictionary = {}
static var _card_box_cache: Dictionary = {}
static var _pill_box_cache: Dictionary = {}

## Bundle returned by build_modal(): the panel itself plus the rows inside it.
class ModalShell:
    var root: PanelContainer
    var body: VBoxContainer
    var header: HBoxContainer
    var content: VBoxContainer
    var footer: HBoxContainer
    var title: Label

# ------------------------------------------------------------- labels -------
static func label(text_value: String, variation: String = "", align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var node := Label.new()
    node.text = text_value
    node.horizontal_alignment = align
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if variation != "":
        node.theme_type_variation = variation
    return node

static func wrapped_label(text_value: String, variation: String = "") -> Label:
    var node := label(text_value, variation)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return node

static func title(text_value: String) -> Label:
    return label(text_value, "TitleLabel")

static func heading(text_value: String) -> Label:
    return label(text_value, "HeadingLabel")

static func section(text_value: String) -> Label:
    return label(text_value, "SectionLabel")

static func muted(text_value: String) -> Label:
    return label(text_value, "MutedLabel")

static func hint(text_value: String) -> Label:
    return label(text_value, "HintLabel")

static func value(text_value: String = "") -> Label:
    return label(text_value, "ValueLabel")

# ------------------------------------------------------------ layout --------
static func spacer(expand_h: bool = false, expand_v: bool = false, min_size: Vector2 = Vector2.ZERO) -> Control:
    var node := Control.new()
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if min_size != Vector2.ZERO:
        node.custom_minimum_size = min_size
    if expand_h:
        node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if expand_v:
        node.size_flags_vertical = Control.SIZE_EXPAND_FILL
    return node

static func margin_container(left: int, top: int, right: int, bottom: int) -> MarginContainer:
    var node := MarginContainer.new()
    node.add_theme_constant_override("margin_left", left)
    node.add_theme_constant_override("margin_top", top)
    node.add_theme_constant_override("margin_right", right)
    node.add_theme_constant_override("margin_bottom", bottom)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func vbox(separation: int = GAP) -> VBoxContainer:
    var node := VBoxContainer.new()
    node.add_theme_constant_override("separation", separation)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func hbox(separation: int = GAP_SMALL) -> HBoxContainer:
    var node := HBoxContainer.new()
    node.add_theme_constant_override("separation", separation)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func grid(columns: int = 2, h_separation: int = 18, v_separation: int = 8) -> GridContainer:
    var node := GridContainer.new()
    node.columns = columns
    node.add_theme_constant_override("h_separation", h_separation)
    node.add_theme_constant_override("v_separation", v_separation)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func separator() -> HSeparator:
    var node := HSeparator.new()
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func scrim(alpha: float = 0.6) -> ColorRect:
    var node := ColorRect.new()
    node.color = Color(0.008, 0.012, 0.020, alpha)
    node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    node.mouse_filter = Control.MOUSE_FILTER_STOP
    return node

# ----------------------------------------------------------- buttons --------
static func button(text_value: String, variation: String = "", min_size: Vector2 = Vector2(120, 40)) -> Button:
    var node := Button.new()
    node.text = text_value
    if variation != "":
        node.theme_type_variation = variation
    if min_size != Vector2.ZERO:
        node.custom_minimum_size = min_size
    node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    return node

## Toggle chip for filter rows; only one chip of a group stays pressed.
static func chip_button(text_value: String, group: ButtonGroup = null, min_size: Vector2 = Vector2(0, 30)) -> Button:
    var node := button(text_value, "ChipButton", min_size)
    node.toggle_mode = true
    if group != null:
        node.button_group = group
    return node


static func primary_button(text_value: String, min_size: Vector2 = Vector2(140, 42)) -> Button:
    return button(text_value, "PrimaryButton", min_size)

static func ghost_button(text_value: String, min_size: Vector2 = Vector2(120, 38)) -> Button:
    return button(text_value, "GhostButton", min_size)

static func icon_button(glyph: String, on_pressed: Callable, tooltip_text: String = "", min_size: Vector2 = Vector2(32, 30)) -> Button:
    var node := button(glyph, "IconButton", min_size)
    node.tooltip_text = tooltip_text
    node.focus_mode = Control.FOCUS_NONE
    node.pressed.connect(on_pressed)
    return node

static func close_button(on_pressed: Callable) -> Button:
    return icon_button("\u00d7", on_pressed, "Esc")


# -------------------------------------------------------------- icons ------
static func icon(glyph_id: String, icon_size: float = 22.0, tint: Color = ThemeBuilder.JADE, width: float = 1.8, shadow: bool = false) -> UiIcon:
    var node := UiIcon.new(glyph_id, tint, width)
    node.custom_minimum_size = Vector2(icon_size, icon_size)
    node.glyph_size = icon_size
    if shadow:
        node.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
        node.shadow_offset = Vector2(0.0, 1.5)
    return node

## Square button with a procedurally drawn glyph and a hover tooltip.
static func glyph_button(glyph_id: String, tooltip_text: String, on_pressed: Callable, icon_size: float = 22.0, button_size: Vector2 = Vector2(44, 40), tint: Color = ThemeBuilder.JADE, variation: String = "FlatIconButton", shadow: bool = true) -> Button:
    var node := button("", variation, button_size)
    node.tooltip_text = tooltip_text
    node.focus_mode = Control.FOCUS_ALL
    node.pressed.connect(on_pressed)
    attach_glyph(node, icon(glyph_id, icon_size, tint, 1.8, shadow), icon_size)
    return node


## Centres a glyph inside any Control (button, panel, slot ...).
static func attach_glyph(parent: Control, glyph: UiIcon, icon_size: float) -> UiIcon:
    glyph.anchor_left = 0.5
    glyph.anchor_top = 0.5
    glyph.anchor_right = 0.5
    glyph.anchor_bottom = 0.5
    glyph.offset_left = -icon_size * 0.5
    glyph.offset_top = -icon_size * 0.5
    glyph.offset_right = icon_size * 0.5
    glyph.offset_bottom = icon_size * 0.5
    glyph.name = "Glyph"
    parent.add_child(glyph)
    return glyph

## Title row: small glyph + the shared TitleLabel look.
static func title_with_icon(glyph_id: String, text_value: String, icon_size: float = 22.0, tint: Color = ThemeBuilder.GOLD) -> HBoxContainer:
    var row := hbox(GAP_SMALL)
    var glyph := icon(glyph_id, icon_size, tint)
    glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(glyph)
    row.add_child(title(text_value))
    return row

# ------------------------------------------------------------- blocks -------
## Adds a "bullet + title + rule" section header and returns the body column.
static func section_header(parent: VBoxContainer, title_text: String) -> VBoxContainer:
    var header := hbox(GAP_SMALL)
    parent.add_child(header)

    var bullet := ColorRect.new()
    bullet.color = ThemeBuilder.JADE_DIM
    bullet.custom_minimum_size = Vector2(6, 6)
    bullet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    bullet.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(bullet)

    header.add_child(section(title_text))

    var rule := separator()
    rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    header.add_child(rule)

    var body := vbox(6)
    parent.add_child(body)
    return body

static func stat_row(grid_node: GridContainer, label_text: String, value_text: String = "", glyph_id: String = "") -> Label:
    if glyph_id == "":
        grid_node.add_child(label(label_text, "StatLabel"))
    else:
        var name_row := hbox(8)
        var glyph := icon(glyph_id, 18.0, ThemeBuilder.JADE_DIM, 1.7)
        glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        name_row.add_child(glyph)
        name_row.add_child(label(label_text, "StatLabel"))
        grid_node.add_child(name_row)
    var value_label := label(value_text, "ValueLabel")
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid_node.add_child(value_label)
    return value_label

static func key_value_row(parent: HBoxContainer, label_text: String, value_text: String = "") -> Label:
    parent.add_child(label(label_text, "StatLabel"))
    parent.add_child(spacer(true, false))
    var value_label := label(value_text, "ValueLabel")
    parent.add_child(value_label)
    return value_label

static func build_modal(title_text: String, min_size: Vector2, icon_glyph: String = "") -> ModalShell:
    var shell := ModalShell.new()

    var panel := PanelContainer.new()
    panel.theme_type_variation = "ModalPanel"
    panel.custom_minimum_size = min_size
    panel.pivot_offset = min_size * 0.5
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    shell.root = panel

    var margin := margin_container(PAD_WIDE, PAD + 2, PAD_WIDE, PAD + 2)
    panel.add_child(margin)

    var column := vbox(10)
    margin.add_child(column)
    shell.body = column

    var header := hbox(10)
    column.add_child(header)
    shell.header = header

    if icon_glyph != "":
        var glyph := icon(icon_glyph, 24.0, ThemeBuilder.GOLD, 2.0)
        glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        header.add_child(glyph)
    shell.title = title(title_text)
    header.add_child(shell.title)
    header.add_child(spacer(true, false))

    var content := vbox(GAP)
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(content)
    shell.content = content

    var footer := hbox(10)
    footer.alignment = BoxContainer.ALIGNMENT_END
    column.add_child(footer)
    shell.footer = footer

    return shell

# ------------------------------------------------------------ effects -------
## Gentle pop-in used whenever a panel becomes visible.
static func pop_in(control: Control) -> void:
    if not control.is_inside_tree():
        return
    control.pivot_offset = _pivot(control)
    control.scale = Vector2(0.96, 0.96)
    var tween := control.create_tween()
    tween.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Fades/scales a panel out, then runs on_finished and hides it.
static func pop_out(control: Control, on_finished: Callable = Callable()) -> void:
    if not control.is_inside_tree() or not control.visible:
        _finish_pop_out(control, on_finished)
        return
    control.pivot_offset = _pivot(control)
    var tween := control.create_tween()
    tween.set_parallel(true)
    tween.tween_property(control, "scale", Vector2(0.97, 0.97), 0.12)
    tween.tween_property(control, "modulate:a", 0.0, 0.12)
    tween.chain().tween_callback(func() -> void: _finish_pop_out(control, on_finished))

static func _finish_pop_out(control: Control, on_finished: Callable) -> void:
    if control != null:
        control.visible = false
        control.scale = Vector2.ONE
        control.modulate.a = 1.0
    if on_finished.is_valid():
        on_finished.call()

static func _pivot(control: Control) -> Vector2:
    var target := control.size
    if target.x <= 0.0:
        target.x = control.custom_minimum_size.x
    if target.y <= 0.0:
        target.y = control.custom_minimum_size.y
    return target * 0.5

# -------------------------------------------------------- style overlays ----
## Frame used by inventory slots; the border carries the item rarity.
static func slot_box(color: Color, selected: bool = false, hover: bool = false) -> StyleBoxFlat:
    var key := "%s|%s|%s" % [color.to_html(), selected, hover]
    if _slot_box_cache.has(key):
        return _slot_box_cache[key]
    var bg := ThemeBuilder.BG_SLOT
    var border := color
    if selected:
        bg = ThemeBuilder.BG_RAISED
        border = ThemeBuilder.GOLD
    elif hover:
        bg = ThemeBuilder.BG_RAISED
    var box := ThemeBuilder.flat_box(bg, border, 6, 1, 4.0, 4.0)
    _slot_box_cache[key] = box
    return box

## Frame used by list entries (achievements, quests ...).
static func card_box(accent: Color) -> StyleBoxFlat:
    var key := accent.to_html()
    if _card_box_cache.has(key):
        return _card_box_cache[key]
    var box := ThemeBuilder.flat_box(ThemeBuilder.BG_PANEL_SOFT, accent, 7, 1)
    box.content_margin_left = 14.0
    box.content_margin_right = 14.0
    box.content_margin_top = 10.0
    box.content_margin_bottom = 10.0
    _card_box_cache[key] = box
    return box

## Small rounded tag (used for achievement state, rarity label ...).
static func pill(text_value: String, color: Color) -> PanelContainer:
    var key := color.to_html()
    if not _pill_box_cache.has(key):
        var box := ThemeBuilder.flat_box(Color(color.r, color.g, color.b, 0.16), color, 10, 1, 10.0, 3.0)
        _pill_box_cache[key] = box
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _pill_box_cache[key])
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var text_label := label(text_value, "HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
    text_label.add_theme_color_override("font_color", color)
    panel.add_child(text_label)
    return panel