extends Control
class_name MainMenu
## Title screen: procedural ink-wash backdrop, seal-stamped game title and a
## bronze-edged plaque menu.

signal new_game_requested
signal continue_requested
signal quit_requested

var _continue_button: Button
var _settings_panel: SettingsPanel
var _achievements_panel: AchievementsPanel

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    theme = ThemeBuilder.shared_theme()
    _build()
    _refresh_continue_button()
    EventBus.settings_changed.connect(_refresh_continue_button)
    _play_intro()

# ------------------------------------------------------------------ build ---
func _build() -> void:
    var backdrop := InkBackdrop.new()
    backdrop.name = "InkBackdrop"
    add_child(backdrop)

    var version := UIKit.label(_version_text(), "HintLabel")
    version.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    version.offset_left = 22
    version.offset_top = 14
    version.offset_right = 520
    version.offset_bottom = 34
    version.add_theme_color_override("font_color", Color(0.64, 0.63, 0.56, 0.78))
    add_child(version)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(center)

    var column := UIKit.vbox(8)
    column.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_child(column)

    column.add_child(_build_title())
    column.add_child(_build_rule())

    column.add_child(UIKit.label(LocaleData.text("game_subtitle"), "HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER))

    var lore := UIKit.wrapped_label(LocaleData.text("lore"), "MutedLabel")
    lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lore.custom_minimum_size = Vector2(440, 0)
    column.add_child(lore)

    column.add_child(UIKit.spacer(false, false, Vector2(0, 20)))
    column.add_child(_build_plaque_table())

    var footer := UIKit.label(_footer_text(), "HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
    footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_top = -40
    footer.offset_bottom = -16
    add_child(footer)

    _settings_panel = SettingsPanel.new()
    _settings_panel.name = "settings"
    _settings_panel.close_requested.connect(_on_overlay_closed)
    add_child(_settings_panel)

    _achievements_panel = AchievementsPanel.new()
    _achievements_panel.name = "achievements"
    _achievements_panel.close_requested.connect(_on_overlay_closed)
    add_child(_achievements_panel)

## Title + vermilion seal, arranged like a scroll header.
func _build_title() -> Control:
    var row := UIKit.hbox(20)
    row.alignment = BoxContainer.ALIGNMENT_CENTER

    var title := UIKit.label(LocaleData.text("game_title"), "MenuTitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
    title.add_theme_color_override("font_outline_color", Color(0.05, 0.045, 0.035, 0.92))
    title.add_theme_constant_override("outline_size", 5)
    title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 3)
    row.add_child(title)
    row.add_child(_build_seal())
    return row

## Vermilion seal stamp next to the title.
func _build_seal() -> Control:
    var seal := PanelContainer.new()
    seal.name = "Seal"
    seal.add_theme_stylebox_override("panel", ThemeBuilder.flat_box(Color(0.612, 0.157, 0.129, 0.92), Color(0.815, 0.290, 0.220, 0.95), 4, 2, 4.0, 4.0))
    seal.custom_minimum_size = Vector2(56, 56)
    seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    seal.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var glyph := UIKit.label(LocaleData.text("game_seal"), "", HORIZONTAL_ALIGNMENT_CENTER)
    glyph.add_theme_font_size_override("font_size", 19)
    glyph.add_theme_color_override("font_color", Color(0.98, 0.945, 0.890))
    glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    glyph.add_theme_constant_override("line_spacing", 0)
    seal.add_child(glyph)
    return seal

## Bronze hairline with a small diamond, under the title.
func _build_rule() -> Control:
    var row := UIKit.hbox(10)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_child(_hairline(150))
    var diamond := UIKit.label("\u25c6", "", HORIZONTAL_ALIGNMENT_CENTER)
    diamond.add_theme_font_size_override("font_size", 11)
    diamond.add_theme_color_override("font_color", Color(0.78, 0.66, 0.36, 0.85))
    row.add_child(diamond)
    row.add_child(_hairline(150))
    return row

func _hairline(width: float) -> HSeparator:
    var line := HSeparator.new()
    line.add_theme_stylebox_override("separator", ThemeBuilder.line_box(Color(0.62, 0.54, 0.32, 0.55), 1))
    line.custom_minimum_size = Vector2(width, 0)
    line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return line

## The menu itself: a dark tablet holding the bronze plaques.
func _build_plaque_table() -> Control:
    var table := PanelContainer.new()
    table.name = "MenuTable"
    table.theme_type_variation = "ModalPanel"
    table.custom_minimum_size = Vector2(440, 0)

    var margin := UIKit.margin_container(20, 18, 20, 18)
    table.add_child(margin)

    var buttons := UIKit.vbox(8)
    margin.add_child(buttons)

    _continue_button = _menu_button(buttons, "ContinueButton", LocaleData.text("continue_game"), "MenuPlaquePrimary", _on_continue_pressed)
    _menu_button(buttons, "NewGameButton", LocaleData.text("new_game"), "MenuPlaqueButton", _on_new_game_pressed)
    buttons.add_child(_hairline(0))
    _menu_button(buttons, "SettingsButton", LocaleData.text("settings"), "MenuPlaqueButton", _on_settings_pressed)
    _menu_button(buttons, "AchievementsButton", LocaleData.text("achievements"), "MenuPlaqueButton", _on_achievements_pressed)
    _menu_button(buttons, "QuitButton", LocaleData.text("quit"), "MenuPlaqueButton", _on_quit_pressed)
    return table

func _menu_button(parent: VBoxContainer, node_name: String, text: String, variation: String, callable: Callable) -> Button:
    var button := UIKit.button(_spaced(text), variation, Vector2(280, 46))
    button.name = node_name
    button.pressed.connect(callable)
    parent.add_child(button)
    return button

## "继续修行" -> "继 续 修 行" for the classic tablet look.
func _spaced(text: String) -> String:
    var out := ""
    for i in range(text.length()):
        if i > 0:
            out += " "
        out += text[i]
    return out

func _version_text() -> String:
    return "《%s》  ·  Godot 4.7 prototype" % LocaleData.text("game_title")

func _footer_text() -> String:
    return "WASD 移动   ·   左键普攻   ·   Q / E 或右键拖拽转视角   ·   R 重置视角   ·   滚轮缩放   ·   V 切换视角   ·   Tab 行囊   ·   C 角色   ·   K 成就   ·   Esc 设置"

func _play_intro() -> void:
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- actions ---
func _refresh_continue_button() -> void:
    if _continue_button == null:
        return
    _continue_button.disabled = not GameState.has_save()

func _on_new_game_pressed() -> void:
    AudioManager.play_ui_confirm()
    new_game_requested.emit()

func _on_continue_pressed() -> void:
    AudioManager.play_ui_confirm()
    continue_requested.emit()

func _on_settings_pressed() -> void:
    AudioManager.play_ui_click()
    _settings_panel.open()

func _on_achievements_pressed() -> void:
    AudioManager.play_ui_click()
    _achievements_panel.open()

func _on_overlay_closed() -> void:
    pass

func _on_quit_pressed() -> void:
    AudioManager.play_ui_click()
    quit_requested.emit()