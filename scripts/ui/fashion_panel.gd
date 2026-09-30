extends UiOverlay
class_name FashionPanel
## Wardrobe (时装) overlay: collection list on the left, the mirror in the middle
## and the detail / dye / aura column on the right.
##
## Fashion is cosmetic only, so this panel never touches combat numbers; it only
## drives GameState.fashion_* and lets the player try an outfit on in the mirror.

const ROW_HEIGHT := 46.0

var _summary: Label
var _list: VBoxContainer
var _preview: FashionPreview

var _detail_name: Label
var _detail_meta: Label
var _detail_desc: Label
var _detail_parts: Label
var _detail_cost: Label
var _palette_row: HBoxContainer
var _aura_check: CheckBox

var _wear_button: Button
var _take_off_button: Button
var _unlock_button: Button

var _selected := ""
var _rows: Dictionary = {}


func _modal_title() -> String:
    return LocaleData.text("fashion")


func _modal_size() -> Vector2:
    return Vector2(1040, 620)


func _modal_icon() -> String:
    return "robe"


func _build_content() -> void:
    _summary = UIKit.label("", "GoldValueLabel")
    header.add_child(_summary)

    var body := UIKit.hbox(14)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(body)

    body.add_child(_build_list_column())
    body.add_child(_build_preview_column())
    body.add_child(_build_detail_column())

    _take_off_button = UIKit.ghost_button(LocaleData.text("fashion_take_off"), Vector2(120, 38))
    _take_off_button.pressed.connect(_on_take_off_pressed)
    footer.add_child(_take_off_button)

    _wear_button = UIKit.primary_button(LocaleData.text("fashion_wear"), Vector2(130, 40))
    _wear_button.pressed.connect(_on_wear_pressed)
    footer.add_child(_wear_button)

    _unlock_button = UIKit.primary_button(LocaleData.text("fashion_unlock"), Vector2(120, 40))
    _unlock_button.pressed.connect(_on_unlock_pressed)
    footer.add_child(_unlock_button)


# ---------------------------------------------------------------- layout ----
func _build_list_column() -> Control:
    var card := PanelContainer.new()
    card.theme_type_variation = "CardPanel"
    card.custom_minimum_size = Vector2(296, 0)

    var margin := UIKit.margin_container(12, 12, 12, 12)
    card.add_child(margin)

    var column := UIKit.vbox(8)
    margin.add_child(column)
    column.add_child(UIKit.section(LocaleData.text("fashion_collection")))

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(scroll)

    _list = UIKit.vbox(6)
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_list)
    return card


func _build_preview_column() -> Control:
    var card := PanelContainer.new()
    card.theme_type_variation = "CardPanel"
    card.custom_minimum_size = Vector2(300, 0)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var margin := UIKit.margin_container(10, 10, 10, 10)
    card.add_child(margin)

    var column := UIKit.vbox(6)
    margin.add_child(column)

    var title_row := UIKit.hbox(6)
    var glyph := UIKit.icon("sparkle", 16.0, ThemeBuilder.JADE_DIM, 1.6)
    glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    title_row.add_child(glyph)
    title_row.add_child(UIKit.section(LocaleData.text("fashion_preview")))
    column.add_child(title_row)

    _preview = FashionPreview.new()
    _preview.custom_minimum_size = Vector2(280, 360)
    _preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(_preview)

    var hint := UIKit.wrapped_label(LocaleData.text("fashion_dye_hint"), "HintLabel")
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(hint)
    return card


func _build_detail_column() -> Control:
    var card := PanelContainer.new()
    card.theme_type_variation = "CardPanel"
    card.custom_minimum_size = Vector2(330, 0)

    var margin := UIKit.margin_container(14, 12, 14, 12)
    card.add_child(margin)

    var column := UIKit.vbox(8)
    margin.add_child(column)

    _detail_name = UIKit.label("", "TitleLabel")
    column.add_child(_detail_name)

    _detail_meta = UIKit.label("", "HintLabel")
    column.add_child(_detail_meta)

    column.add_child(UIKit.separator())

    _detail_desc = UIKit.wrapped_label("", "MutedLabel")
    column.add_child(_detail_desc)

    _detail_parts = UIKit.wrapped_label("", "HintLabel")
    column.add_child(_detail_parts)

    _detail_cost = UIKit.wrapped_label("", "HintLabel")
    column.add_child(_detail_cost)

    var palette_body := UIKit.section_header(column, LocaleData.text("fashion_palette"))
    _palette_row = UIKit.hbox(6)
    palette_body.add_child(_palette_row)

    var aura_body := UIKit.section_header(column, LocaleData.text("fashion_aura"))
    _aura_check = CheckBox.new()
    _aura_check.focus_mode = Control.FOCUS_NONE
    _aura_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _aura_check.toggled.connect(_on_aura_toggled)
    aura_body.add_child(_aura_check)

    return card


# --------------------------------------------------------------- refresh ----
func _on_open() -> void:
    _refresh_all()


func _refresh_all() -> void:
    _refresh_list()
    if _selected == "" or not FashionData.has(_selected):
        _selected = GameState.fashion_worn if GameState.fashion_worn != "" else _first_id()
    _refresh_detail()


func _first_id() -> String:
    var ids := FashionData.ids()
    if ids.is_empty():
        return ""
    return ids[0]


func _refresh_list() -> void:
    for child in _list.get_children():
        _list.remove_child(child)
        child.queue_free()
    _rows.clear()

    _summary.text = LocaleData.text("fashion_owned_count") % [GameState.fashion_owned_count(), GameState.fashion_total_count()]

    var ids := FashionData.ids()
    if ids.is_empty():
        _list.add_child(UIKit.muted(LocaleData.text("fashion_empty")))
        return
    for id in ids:
        var key := str(id)
        var row := _make_row(key)
        _rows[key] = row
        _list.add_child(row)


func _make_row(id: String) -> Button:
    var owned := GameState.has_fashion(id)
    var accent := FashionData.rarity_color(id) if owned else ThemeBuilder.BORDER_MUTED

    var button := UIKit.button(FashionData.name(id), "", Vector2(0, ROW_HEIGHT))
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.clip_text = true
    button.focus_mode = Control.FOCUS_NONE
    button.tooltip_text = str(FashionData.desc(id))
    button.pressed.connect(_on_row_pressed.bind(id))
    button.add_theme_color_override("font_color", accent if owned else ThemeBuilder.TEXT_MUTED)
    _style_row(button, id, accent)

    var stripe := ColorRect.new()
    stripe.color = Color(accent.r, accent.g, accent.b, 0.9 if owned else 0.32)
    stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stripe.anchor_top = 0.0
    stripe.anchor_bottom = 1.0
    stripe.offset_left = 0.0
    stripe.offset_right = 4.0
    stripe.offset_top = 6.0
    stripe.offset_bottom = -6.0
    button.add_child(stripe)

    var tag := UIKit.label(_state_tag(id), "HintLabel")
    tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    tag.anchor_left = 1.0
    tag.anchor_right = 1.0
    tag.anchor_top = 0.5
    tag.anchor_bottom = 0.5
    tag.offset_left = -92.0
    tag.offset_right = -10.0
    tag.offset_top = -10.0
    tag.offset_bottom = 10.0
    tag.add_theme_color_override("font_color", _state_color(id))
    button.add_child(tag)
    return button


func _style_row(button: Button, id: String, accent: Color) -> void:
    var selected := id == _selected
    var box := ThemeBuilder.flat_box(
        ThemeBuilder.BG_RAISED if selected else ThemeBuilder.BG_PANEL_SOFT,
        ThemeBuilder.GOLD if selected else accent,
        7,
        1
    )
    box.content_margin_left = 16.0
    box.content_margin_right = 94.0
    box.content_margin_top = 6.0
    box.content_margin_bottom = 6.0
    button.add_theme_stylebox_override("normal", box)

    var highlight := box.duplicate() as StyleBoxFlat
    highlight.bg_color = ThemeBuilder.BG_RAISED
    highlight.border_color = ThemeBuilder.GOLD if selected else ThemeBuilder.GOLD_DIM
    button.add_theme_stylebox_override("hover", highlight)
    button.add_theme_stylebox_override("pressed", highlight)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _state_tag(id: String) -> String:
    if GameState.is_fashion_worn(id):
        return LocaleData.text("fashion_wearing")
    if GameState.has_fashion(id):
        return LocaleData.text("fashion_owned")
    return LocaleData.text("fashion_not_owned")


func _state_color(id: String) -> Color:
    if GameState.is_fashion_worn(id):
        return ThemeBuilder.GOLD
    if GameState.has_fashion(id):
        return ThemeBuilder.JADE_DIM
    return ThemeBuilder.TEXT_MUTED


func _refresh_detail() -> void:
    if _selected == "" or not FashionData.has(_selected):
        return
    var id := _selected
    var owned := GameState.has_fashion(id)

    _detail_name.text = FashionData.name(id)
    _detail_name.add_theme_color_override("font_color", FashionData.rarity_color(id))

    var meta: Array[String] = []
    meta.append("%s %d" % [LocaleData.text("fashion_rarity"), FashionData.rarity(id)])
    var element := FashionData.element(id)
    if element != "none":
        meta.append(GameData.element_name(element))
    meta.append(LocaleData.text("fashion_owned") if owned else LocaleData.text("fashion_not_owned"))
    if not owned:
        var requirement := FashionData.requirement_text(id)
        if requirement != "":
            meta.append(requirement)
    _detail_meta.text = " · ".join(meta)

    _detail_desc.text = FashionData.desc(id)
    _detail_parts.text = "%s：%s" % [LocaleData.text("fashion_parts"), FashionData.part_list_text(id)]
    _detail_cost.text = "%s：%s" % [LocaleData.text("fashion_cost"), FashionData.cost_text(id)]
    _detail_cost.visible = not owned

    _refresh_palettes()
    _refresh_aura()

    if _preview != null:
        _preview.set_appearance(GameState.fashion_preview_appearance(id))

    var worn := GameState.is_fashion_worn(id)
    _wear_button.disabled = not owned or worn
    _wear_button.text = LocaleData.text("fashion_wearing") if worn else LocaleData.text("fashion_wear")
    _take_off_button.disabled = GameState.fashion_worn == ""
    _unlock_button.visible = not owned
    var blocker := GameState.get_fashion_blocker(id)
    _unlock_button.disabled = blocker != ""
    _unlock_button.tooltip_text = blocker


func _refresh_palettes() -> void:
    for child in _palette_row.get_children():
        _palette_row.remove_child(child)
        child.queue_free()

    var id := _selected
    var owned := GameState.has_fashion(id)
    var count := FashionData.palette_count(id)
    if count <= 1:
        _palette_row.add_child(UIKit.muted(LocaleData.text("none")))
        return

    var group := ButtonGroup.new()
    var current := GameState.get_fashion_palette(id)
    for i in range(count):
        var scheme := FashionData.palette(id, i)
        var robe: Color = scheme.get("robe", Color.WHITE)
        var chip := UIKit.chip_button(str(scheme.get("name", "")), group, Vector2(0, 28))
        chip.focus_mode = Control.FOCUS_NONE
        chip.disabled = not owned
        chip.button_pressed = i == current
        chip.add_theme_color_override("font_color", robe)
        chip.add_theme_color_override("font_hover_color", robe.lightened(0.3))
        chip.add_theme_color_override("font_pressed_color", ThemeBuilder.GOLD)
        chip.add_theme_color_override("font_disabled_color", Color(robe.r, robe.g, robe.b, 0.5))
        chip.pressed.connect(_on_palette_pressed.bind(i))
        _palette_row.add_child(chip)


func _refresh_aura() -> void:
    var id := _selected
    var kind := FashionData.aura(id)
    var has_aura := kind != "none"
    _aura_check.disabled = not GameState.has_fashion(id) or not has_aura
    _aura_check.set_pressed_no_signal(GameState.get_fashion_aura_enabled(id))
    _aura_check.text = FashionData.aura_name(kind) if has_aura else LocaleData.text("fashion_aura_none")


# ---------------------------------------------------------------- actions ---
func _on_row_pressed(id: String) -> void:
    if _selected == id:
        return
    _selected = id
    AudioManager.play_ui_click()
    _refresh_list()
    _refresh_detail()


func _on_palette_pressed(index: int) -> void:
    if not GameState.has_fashion(_selected):
        return
    AudioManager.play_ui_click()
    GameState.set_fashion_palette(_selected, index)
    _refresh_detail()


func _on_aura_toggled(pressed: bool) -> void:
    if not GameState.has_fashion(_selected):
        return
    GameState.set_fashion_aura_enabled(_selected, pressed)
    _refresh_detail()


func _on_wear_pressed() -> void:
    if _selected == "":
        return
    if GameState.wear_fashion(_selected):
        AudioManager.play_ui_confirm()
    _refresh_list()
    _refresh_detail()


func _on_take_off_pressed() -> void:
    if GameState.fashion_worn == "":
        return
    GameState.take_off_fashion()
    AudioManager.play_ui_click()
    _refresh_all()


func _on_unlock_pressed() -> void:
    if _selected == "":
        return
    if GameState.unlock_fashion(_selected):
        AudioManager.play_ui_confirm()
    _refresh_all()