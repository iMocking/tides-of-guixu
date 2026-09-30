extends CanvasLayer
class_name GameUI
const GAME_MENU_SCRIPT := preload("res://scripts/ui/game_menu.gd")
const DEATH_PANEL_SCRIPT := preload("res://scripts/ui/death_panel.gd")
## In-game HUD plus every popup panel (inventory, character, dialogue ...).

## Inventory cells are square (72x72): 7 per row, up to 6 rows - 42 cells - per
## page. The grid fills the panel down to the pager, so a full page is taller than
## the viewport and scrolls.
const INVENTORY_COLUMNS := 7
const INVENTORY_ROWS := 6
const INVENTORY_PAGE_SIZE := INVENTORY_COLUMNS * INVENTORY_ROWS
const INVENTORY_MAX_PAGE_CELLS := 42
const INVENTORY_CELL := 72.0
const INVENTORY_GAP := 8.0
const INVENTORY_FILTERS: Array[String] = ["all", "equipment", "consumable", "material"]
const CHARACTER_LEFT_SLOTS: Array[String] = ["weapon", "head", "body", "bracers"]
const CHARACTER_RIGHT_SLOTS: Array[String] = ["legs", "boots", "accessory", "talisman"]

var player: Player

# ------------------------------------------------------------------- HUD ----
var _health_bar: ProgressBar
var _qi_bar: ProgressBar
var _cultivation_bar: ProgressBar
var _realm_label: Label
var _element_label: Label
var _time_label: Label
var _pip_label: Label
var _bar_values: Dictionary = {}
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer := 0.0
var _log_label: Label
var _log_lines: Array[String] = []
var _skill_buttons: Dictionary = {}
var _skill_icons: Dictionary = {}
var _skill_cooldown_labels: Dictionary = {}
var _compass: ViewCompass
var _quest_panel: PanelContainer
var _quest_label: Label
var _interact_panel: PanelContainer
var _interact_label: Label

# -------------------------------------------------------------- inventory ---
var _panel_scrim: ColorRect
var _filter_tint: ColorRect
var _inventory_panel: PanelContainer
var _inventory_grid: GridContainer
var _inventory_name: Label
var _inventory_desc: Label
var _inventory_stats: Label
var _inventory_capacity: Label
var _use_button: Button
var _equip_button: Button
var _drop_button: Button
var _selected_slot := -1
var _slot_buttons: Array[Button] = []
var _slot_colors: Array[Color] = []
## Absolute inventory index for every rendered cell (-1 for padding cells).
var _slot_indices: Array[int] = []
var _inventory_filter := "all"
var _inventory_page := 0
var _inventory_page_label: Label
var _inventory_prev: Button
var _inventory_next: Button
var _inventory_total_label: Label
var _inventory_filter_buttons: Dictionary = {}

# -------------------------------------------------------------- character ---
var _character_panel: PanelContainer
var _character_header: Label
var _char_values: Dictionary = {}
var _char_equip_rows: Dictionary = {}
var _char_equip_icons: Dictionary = {}
var _character_preview: FashionPreview

# --------------------------------------------------------------- overlays ---
var _settings_panel: SettingsPanel
var _achievements_panel: AchievementsPanel
var _fashion_panel: FashionPanel
var _game_menu: Control
var _death_panel
var _all_panels: Array[Control] = []

# --------------------------------------------------------------- dialogue ---
var _dialogue_panel: PanelContainer
var _dialogue_portrait: Label
var _dialogue_name: Label
var _dialogue_text: Label
var _dialogue_next: Button
var _dialogue_accept: Button
var _dialogue_decline: Button
var _dialogue_npc_id := ""
var _dialogue_lines: Array[String] = []
var _dialogue_index := 0

func _ready() -> void:
    add_to_group("game_ui")
    process_mode = Node.PROCESS_MODE_ALWAYS

    var root := Control.new()
    root.name = "UIRoot"
    root.theme = ThemeBuilder.shared_theme()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _filter_tint = ColorRect.new()
    _filter_tint.name = "FilterTint"
    _filter_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _filter_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _filter_tint.color = Color(0.0, 0.0, 0.0, 0.0)
    root.add_child(_filter_tint)

    _build_hud(root)

    _panel_scrim = UIKit.scrim(0.6)
    _panel_scrim.name = "PanelScrim"
    _panel_scrim.gui_input.connect(_on_panel_scrim_input)
    _panel_scrim.hide()
    root.add_child(_panel_scrim)

    _build_inventory_panel(root)
    _build_character_panel(root)
    _build_dialogue_panel(root)

    _settings_panel = SettingsPanel.new()
    _settings_panel.name = "settings"
    _settings_panel.close_requested.connect(_on_overlay_closed.bind("settings"))
    root.add_child(_settings_panel)

    _achievements_panel = AchievementsPanel.new()
    _achievements_panel.name = "achievements"
    _achievements_panel.close_requested.connect(_on_overlay_closed.bind("achievements"))
    root.add_child(_achievements_panel)

    _fashion_panel = FashionPanel.new()
    _fashion_panel.name = "fashion"
    _fashion_panel.close_requested.connect(_on_overlay_closed.bind("fashion"))
    root.add_child(_fashion_panel)

    _game_menu = GAME_MENU_SCRIPT.new()
    _game_menu.name = "game_menu"
    _game_menu.connect("close_requested", _on_overlay_closed.bind("game_menu"))
    _game_menu.connect("resume_requested", _on_game_menu_resume_requested)
    _game_menu.connect("main_menu_requested", _on_game_menu_main_menu_requested)
    _game_menu.connect("settings_requested", _on_game_menu_settings_requested)
    _game_menu.connect("quit_requested", _on_game_menu_quit_requested)
    root.add_child(_game_menu)

    _death_panel = DEATH_PANEL_SCRIPT.new()
    _death_panel.name = "death"
    _death_panel.connect("close_requested", _on_overlay_closed.bind("death"))
    _death_panel.connect("revive_in_place_requested", _on_revive_in_place_requested)
    _death_panel.connect("revive_at_spawn_requested", _on_revive_at_spawn_requested)
    root.add_child(_death_panel)

    _all_panels = [_inventory_panel, _character_panel, _fashion_panel, _settings_panel, _achievements_panel, _dialogue_panel, _game_menu, _death_panel]

    EventBus.player_stats_changed.connect(_refresh_hud)
    EventBus.inventory_changed.connect(_refresh_inventory)
    EventBus.equipment_changed.connect(_refresh_inventory)
    EventBus.time_changed.connect(_on_time_changed)
    EventBus.toast_requested.connect(_on_toast_requested)
    EventBus.combat_log.connect(_on_combat_log)
    EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
    EventBus.fashion_changed.connect(_on_fashion_changed)
    EventBus.settings_changed.connect(_on_settings_changed)
    EventBus.dialogue_requested.connect(_on_dialogue_requested)
    EventBus.quest_updated.connect(_on_quest_updated)
    EventBus.quest_completed.connect(_on_quest_completed)
    EventBus.player_died.connect(_on_player_died)

    _apply_screen_filter()
    _refresh_hud()
    _refresh_inventory()
    _close_panels()

func set_player(new_player: Player) -> void:
    player = new_player
    _refresh_hud()

# ================================================================== HUD ======

func _build_hud(root: Control) -> void:
    var status := PanelContainer.new()
    status.name = "StatusPanel"
    status.theme_type_variation = "GlassPanel"
    status.position = Vector2(18, 18)
    status.custom_minimum_size = Vector2(348, 0)
    status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(status)

    var status_margin := UIKit.margin_container(14, 12, 14, 12)
    status.add_child(status_margin)

    var status_column := UIKit.vbox(6)
    status_margin.add_child(status_column)

    var status_header := UIKit.hbox(8)
    status_column.add_child(status_header)
    _realm_label = _shadowed(UIKit.heading(""))
    status_header.add_child(_realm_label)
    status_header.add_child(UIKit.spacer(true, false))
    _element_label = _shadowed(UIKit.label("", "SectionLabel"))
    status_header.add_child(_element_label)

    _health_bar = _make_status_bar(status_column, "health", "HealthBar", ThemeBuilder.HEALTH_COLOR)
    _qi_bar = _make_status_bar(status_column, "qi", "QiBar", ThemeBuilder.QI_COLOR)
    _cultivation_bar = _make_status_bar(status_column, "cultivation_progress", "CultivationBar", ThemeBuilder.CULTIVATION_COLOR)

    var status_footer := UIKit.hbox(8)
    status_column.add_child(status_footer)
    _time_label = _shadowed(UIKit.hint(""))
    status_footer.add_child(_time_label)
    status_footer.add_child(UIKit.spacer(true, false))
    _pip_label = _shadowed(UIKit.hint(""))
    _pip_label.add_theme_color_override("font_color", ThemeBuilder.JADE_DIM)
    status_footer.add_child(_pip_label)

    var top_right := UIKit.hbox(8)
    top_right.name = "HudButtons"
    top_right.anchor_left = 1.0
    top_right.anchor_right = 1.0
    top_right.offset_left = -312
    top_right.offset_right = -18
    top_right.offset_top = 18
    top_right.offset_bottom = 58
    top_right.alignment = BoxContainer.ALIGNMENT_END
    root.add_child(top_right)

    _hud_icon_button(top_right, "bag", LocaleData.text("inventory"), func() -> void: _toggle_panel(_inventory_panel, "inventory"))
    _hud_icon_button(top_right, "person", LocaleData.text("character"), func() -> void: _toggle_panel(_character_panel, "character"))
    _hud_icon_button(top_right, "robe", LocaleData.text("fashion"), func() -> void: _toggle_panel(_fashion_panel, "fashion"))
    _hud_icon_button(top_right, "trophy", LocaleData.text("achievements"), func() -> void: _open_panel(_achievements_panel, "achievements"))
    _hud_icon_button(top_right, "gear", LocaleData.text("settings"), func() -> void: _open_panel(_settings_panel, "settings"))

    var compass_panel := PanelContainer.new()
    compass_panel.name = "CompassPanel"
    compass_panel.theme_type_variation = "GlassPanel"
    compass_panel.anchor_left = 0.5
    compass_panel.anchor_right = 0.5
    compass_panel.offset_left = -100
    compass_panel.offset_right = 100
    compass_panel.offset_top = 12
    compass_panel.offset_bottom = 52
    compass_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(compass_panel)

    var compass_margin := UIKit.margin_container(8, 4, 8, 4)
    compass_panel.add_child(compass_margin)

    _compass = ViewCompass.new()
    _compass.custom_minimum_size = Vector2(184, 32)
    compass_margin.add_child(_compass)

    var skill_bar := UIKit.hbox(8)
    skill_bar.name = "SkillBar"
    skill_bar.anchor_left = 0.5
    skill_bar.anchor_right = 0.5
    skill_bar.anchor_top = 1.0
    skill_bar.anchor_bottom = 1.0
    skill_bar.offset_left = -280
    skill_bar.offset_right = 280
    skill_bar.offset_top = -100
    skill_bar.offset_bottom = -16
    skill_bar.alignment = BoxContainer.ALIGNMENT_CENTER
    root.add_child(skill_bar)

    var index := 1
    for skill_id in GameData.ACTION_SKILLS:
        var button := _make_skill_button(skill_id, index)
        skill_bar.add_child(button)
        _skill_buttons[skill_id] = button
        index += 1

    _toast_panel = PanelContainer.new()
    _toast_panel.name = "ToastPanel"
    _toast_panel.theme_type_variation = "ToastPanel"
    _toast_panel.anchor_left = 0.5
    _toast_panel.anchor_right = 0.5
    _toast_panel.offset_left = -300
    _toast_panel.offset_right = 300
    _toast_panel.offset_top = 58
    _toast_panel.offset_bottom = 104
    _toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _toast_panel.modulate.a = 0.0
    root.add_child(_toast_panel)
    _toast_label = UIKit.label("", "", HORIZONTAL_ALIGNMENT_CENTER)
    _toast_label.add_theme_font_size_override("font_size", 20)
    _toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _toast_panel.add_child(_toast_label)

    var log_panel := PanelContainer.new()
    log_panel.name = "LogPanel"
    log_panel.theme_type_variation = "LogPanel"
    log_panel.anchor_top = 1.0
    log_panel.anchor_bottom = 1.0
    log_panel.offset_left = 18
    log_panel.offset_right = 410
    log_panel.offset_top = -300
    log_panel.offset_bottom = -120
    log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(log_panel)

    var log_margin := UIKit.margin_container(12, 10, 12, 10)
    log_panel.add_child(log_margin)
    var log_column := UIKit.vbox(4)
    log_margin.add_child(log_column)
    var log_title := UIKit.section(LocaleData.text("combat_log"))
    log_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
    log_title.add_theme_constant_override("shadow_offset_x", 1)
    log_title.add_theme_constant_override("shadow_offset_y", 1)
    log_column.add_child(log_title)

    _log_label = UIKit.label("")
    _log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    _log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _log_label.add_theme_font_size_override("font_size", 14)
    _log_label.add_theme_color_override("font_color", ThemeBuilder.TEXT_DIM)
    # No plate behind it any more, so keep the text legible with a soft shadow.
    _log_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
    _log_label.add_theme_constant_override("shadow_offset_x", 1)
    _log_label.add_theme_constant_override("shadow_offset_y", 1)
    log_column.add_child(_log_label)

    _quest_panel = PanelContainer.new()
    _quest_panel.name = "QuestPanel"
    _quest_panel.theme_type_variation = "QuestPanel"
    _quest_panel.anchor_left = 1.0
    _quest_panel.anchor_right = 1.0
    _quest_panel.offset_left = -340
    _quest_panel.offset_right = -18
    _quest_panel.offset_top = 70
    _quest_panel.offset_bottom = 190
    _quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(_quest_panel)
    _quest_label = UIKit.label("")
    _quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _quest_label.add_theme_font_size_override("font_size", 14)
    _quest_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.82))
    _quest_panel.add_child(_quest_label)
    _quest_panel.hide()

    _interact_panel = PanelContainer.new()
    _interact_panel.name = "InteractPanel"
    _interact_panel.theme_type_variation = "ToastPanel"
    _interact_panel.anchor_left = 0.5
    _interact_panel.anchor_right = 0.5
    _interact_panel.anchor_top = 1.0
    _interact_panel.anchor_bottom = 1.0
    _interact_panel.offset_left = -230
    _interact_panel.offset_right = 230
    _interact_panel.offset_top = -160
    _interact_panel.offset_bottom = -122
    _interact_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(_interact_panel)
    _interact_label = UIKit.label("", "GoldValueLabel", HORIZONTAL_ALIGNMENT_CENTER)
    _interact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _interact_panel.add_child(_interact_label)
    _interact_panel.hide()

## Soft dark shadow so a label stays readable on the plate-free HUD panels.
func _shadowed(node: Label) -> Label:
    node.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
    node.add_theme_constant_override("shadow_offset_x", 1)
    node.add_theme_constant_override("shadow_offset_y", 1)
    return node

func _make_status_bar(parent: VBoxContainer, title_key: String, variation: String, color: Color) -> ProgressBar:
    var row := UIKit.hbox(8)
    parent.add_child(row)
    row.add_child(_shadowed(UIKit.hint(LocaleData.text(title_key))))
    row.add_child(UIKit.spacer(true, false))
    var value_label := _shadowed(UIKit.value(""))
    value_label.add_theme_font_size_override("font_size", 13)
    value_label.add_theme_color_override("font_color", color)
    row.add_child(value_label)
    _bar_values[title_key] = value_label

    var bar := ProgressBar.new()
    bar.theme_type_variation = variation
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 12)
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(bar)
    return bar

## One transparent skill icon: element glyph, key hint in the corner and a
## countdown label that appears while the skill is cooling down.

func _make_skill_button(skill_id: String, index: int) -> Button:
    var name_text := LocaleData.text(skill_id)
    var tooltip_text := "%s  [%d]\n%s%s" % [
        name_text,
        index,
        LocaleData.text("skill_desc_" + skill_id),
        "" if str(GameData.skill(skill_id).get("element", "none")) == "none" else "  |  " + GameData.element_name(str(GameData.skill(skill_id).get("element", "none"))),
    ]
    var button := UIKit.glyph_button(_skill_glyph(skill_id), tooltip_text, _on_skill_button_pressed.bind(skill_id), 38.0, Vector2(72, 72), _skill_tint(), "SkillSlotButton")
    button.name = "Skill_" + skill_id
    # Keep the frame a true square: the bar is taller than the button.
    button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

    # Small key badge tucked into the glyph's top-right corner.
    var key_label := UIKit.label(str(index), "HintLabel")
    key_label.name = "KeyBadge"
    key_label.add_theme_font_size_override("font_size", 12)
    key_label.add_theme_color_override("font_color", ThemeBuilder.JADE)
    key_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
    key_label.add_theme_constant_override("shadow_offset_x", 1)
    key_label.add_theme_constant_override("shadow_offset_y", 1)
    key_label.anchor_left = 1.0
    key_label.anchor_right = 1.0
    key_label.anchor_top = 0.0
    key_label.anchor_bottom = 0.0
    key_label.offset_left = -22.0
    key_label.offset_right = -5.0
    key_label.offset_top = 2.0
    key_label.offset_bottom = 17.0
    key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    button.add_child(key_label)

    var cooldown_label := UIKit.label("", "HintLabel")
    cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    cooldown_label.add_theme_font_size_override("font_size", 22)
    cooldown_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
    cooldown_label.hide()
    button.add_child(cooldown_label)

    _skill_icons[skill_id] = button.get_node_or_null("Glyph")
    _skill_cooldown_labels[skill_id] = cooldown_label
    return button

func _skill_glyph(skill_id: String) -> String:
    match skill_id:
        "basic_attack":
            return "slash"
        "skill_1":
            return "wood"
        "skill_2":
            return "fire"
        "skill_3":
            return "water"
        "skill_4":
            return "metal"
        "ultimate":
            return "earth"
    return "star"

## Every skill icon takes the colour of the character's spiritual root (灵根):
## 金=亮金 木=青绿 水=淡蓝 火=岩浆 土=土灰 雷=深紫 冰=水银.
func _skill_tint() -> Color:
    return GameData.element_icon_color(GameState.player_element)

func _hud_icon_button(parent: HBoxContainer, glyph: String, tooltip_text: String, callable: Callable) -> void:
    var button := UIKit.glyph_button(glyph, tooltip_text, callable, 22.0, Vector2(44, 38))
    parent.add_child(button)

func _build_inventory_panel(root: Control) -> void:
    _inventory_panel = PanelContainer.new()
    _inventory_panel.name = "inventory"
    _inventory_panel.theme_type_variation = "ModalPanel"
    _inventory_panel.custom_minimum_size = Vector2(940, 550)
    _inventory_panel.anchor_left = 0.5
    _inventory_panel.anchor_top = 0.5
    _inventory_panel.anchor_right = 0.5
    _inventory_panel.anchor_bottom = 0.5
    _inventory_panel.offset_left = -470
    _inventory_panel.offset_right = 470
    _inventory_panel.offset_top = -275
    _inventory_panel.offset_bottom = 275
    root.add_child(_inventory_panel)

    var margin := UIKit.margin_container(24, 18, 24, 18)
    _inventory_panel.add_child(margin)

    var column := UIKit.vbox(8)
    margin.add_child(column)

    # ------------------------------------------------------------- header ---
    var header := UIKit.hbox(10)
    column.add_child(header)
    header.add_child(UIKit.title_with_icon("bag", LocaleData.text("inventory")))
    header.add_child(UIKit.spacer(true, false))
    _inventory_capacity = UIKit.muted("")
    header.add_child(_inventory_capacity)
    header.add_child(UIKit.close_button(_close_panels))

    column.add_child(UIKit.separator())

    # ------------------------------------------------- filter / organise ----
    var toolbar := UIKit.hbox(6)
    column.add_child(toolbar)
    toolbar.add_child(UIKit.hint(LocaleData.text("filter_label")))

    var chip_group := ButtonGroup.new()
    for filter_id in INVENTORY_FILTERS:
        var chip := UIKit.chip_button(_inventory_filter_text(filter_id), chip_group)
        chip.pressed.connect(_set_inventory_filter.bind(filter_id))
        toolbar.add_child(chip)
        _inventory_filter_buttons[filter_id] = chip
    if _inventory_filter_buttons.has(_inventory_filter):
        (_inventory_filter_buttons[_inventory_filter] as Button).button_pressed = true

    toolbar.add_child(UIKit.spacer(true, false))
    var sort_button := UIKit.button(LocaleData.text("sort_inventory"), "ChipButton", Vector2(0, 30))
    sort_button.pressed.connect(_on_sort_inventory_pressed)
    toolbar.add_child(sort_button)

    # --------------------------------------------------------------- body ---
    var body := UIKit.hbox(18)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(body)

    var scroll := ScrollContainer.new()
    scroll.name = "ItemScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(scroll)

    _inventory_grid = GridContainer.new()
    _inventory_grid.columns = INVENTORY_COLUMNS
    _inventory_grid.add_theme_constant_override("h_separation", int(INVENTORY_GAP))
    _inventory_grid.add_theme_constant_override("v_separation", int(INVENTORY_GAP))
    _inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_inventory_grid)

    var detail_card := PanelContainer.new()
    detail_card.theme_type_variation = "CardPanel"
    detail_card.custom_minimum_size = Vector2(320, 0)
    body.add_child(detail_card)

    var detail_margin := UIKit.margin_container(16, 14, 16, 14)
    detail_card.add_child(detail_margin)

    var detail := UIKit.vbox(8)
    detail_margin.add_child(detail)

    _inventory_name = UIKit.value(LocaleData.text("no_item"))
    _inventory_name.add_theme_font_size_override("font_size", 20)
    _inventory_name.add_theme_color_override("font_color", ThemeBuilder.GOLD)
    detail.add_child(_inventory_name)

    _inventory_desc = UIKit.wrapped_label("", "MutedLabel")
    _inventory_desc.custom_minimum_size = Vector2(288, 72)
    detail.add_child(_inventory_desc)

    _inventory_stats = UIKit.wrapped_label("", "")
    _inventory_stats.add_theme_color_override("font_color", ThemeBuilder.JADE)
    _inventory_stats.custom_minimum_size = Vector2(288, 104)
    detail.add_child(_inventory_stats)

    detail.add_child(UIKit.spacer(false, true))

    _use_button = UIKit.button(LocaleData.text("use"), "PrimaryButton", Vector2(0, 36))
    _use_button.pressed.connect(_on_use_pressed)
    detail.add_child(_use_button)

    _equip_button = UIKit.button(LocaleData.text("equip"), "", Vector2(0, 36))
    _equip_button.pressed.connect(_on_equip_pressed)
    detail.add_child(_equip_button)

    _drop_button = UIKit.button(LocaleData.text("drop"), "GhostButton", Vector2(0, 36))
    _drop_button.pressed.connect(_on_drop_pressed)
    detail.add_child(_drop_button)

    # -------------------------------------------------------------- pager ---
    var pager := UIKit.hbox(6)
    column.add_child(pager)
    _inventory_prev = UIKit.glyph_button("chevron_left", LocaleData.text("prev_page"), _on_inventory_prev_page, 16.0, Vector2(36, 30), ThemeBuilder.TEXT_DIM)
    pager.add_child(_inventory_prev)
    _inventory_page_label = UIKit.value("")
    _inventory_page_label.custom_minimum_size = Vector2(120, 0)
    _inventory_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pager.add_child(_inventory_page_label)
    _inventory_next = UIKit.glyph_button("chevron_right", LocaleData.text("next_page"), _on_inventory_next_page, 16.0, Vector2(36, 30), ThemeBuilder.TEXT_DIM)
    pager.add_child(_inventory_next)
    pager.add_child(UIKit.spacer(true, false))
    _inventory_total_label = UIKit.muted("")
    pager.add_child(_inventory_total_label)

# ============================================================ character ======

func _build_character_panel(root: Control) -> void:
    _character_panel = PanelContainer.new()
    _character_panel.name = "character"
    _character_panel.theme_type_variation = "ModalPanel"
    _character_panel.custom_minimum_size = Vector2(900, 620)
    _character_panel.anchor_left = 0.5
    _character_panel.anchor_top = 0.5
    _character_panel.anchor_right = 0.5
    _character_panel.anchor_bottom = 0.5
    _character_panel.offset_left = -450
    _character_panel.offset_right = 450
    _character_panel.offset_top = -310
    _character_panel.offset_bottom = 310
    root.add_child(_character_panel)

    var margin := UIKit.margin_container(24, 18, 24, 18)
    _character_panel.add_child(margin)

    var column := UIKit.vbox(8)
    margin.add_child(column)

    var header := UIKit.hbox(10)
    column.add_child(header)
    header.add_child(UIKit.title_with_icon("person", LocaleData.text("character")))
    header.add_child(UIKit.spacer(true, false))
    header.add_child(UIKit.close_button(_close_panels))

    _character_header = UIKit.label("", "SectionLabel")
    column.add_child(_character_header)

    column.add_child(UIKit.separator())

    var body := UIKit.hbox(16)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(body)

    # --------------------------------------------------- left: equipment ----
    var gear_card := PanelContainer.new()
    gear_card.theme_type_variation = "CardPanel"
    gear_card.custom_minimum_size = Vector2(470, 0)
    body.add_child(gear_card)

    var gear_margin := UIKit.margin_container(14, 12, 14, 12)
    gear_card.add_child(gear_margin)

    var gear_column := UIKit.vbox(10)
    gear_margin.add_child(gear_column)
    gear_column.add_child(UIKit.section(LocaleData.text("section_equipment")))

    var equipment_row := UIKit.hbox(10)
    equipment_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    gear_column.add_child(equipment_row)

    var left_slots := UIKit.vbox(10)
    left_slots.alignment = BoxContainer.ALIGNMENT_CENTER
    left_slots.size_flags_vertical = Control.SIZE_EXPAND_FILL
    equipment_row.add_child(left_slots)

    var preview := _build_character_preview()
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    equipment_row.add_child(preview)

    var right_slots := UIKit.vbox(10)
    right_slots.alignment = BoxContainer.ALIGNMENT_CENTER
    right_slots.size_flags_vertical = Control.SIZE_EXPAND_FILL
    equipment_row.add_child(right_slots)

    for slot_id in CHARACTER_LEFT_SLOTS:
        left_slots.add_child(_make_equipment_row(slot_id))
    for slot_id in CHARACTER_RIGHT_SLOTS:
        right_slots.add_child(_make_equipment_row(slot_id))

    # ------------------------------------------------- right: attributes ----
    var stats_scroll := ScrollContainer.new()
    stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    stats_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(stats_scroll)

    var stats := UIKit.vbox(12)
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_scroll.add_child(stats)

    var attribute_grid := UIKit.grid(2, 28, 10)
    UIKit.section_header(stats, LocaleData.text("section_attributes")).add_child(attribute_grid)
    _char_values["health"] = UIKit.stat_row(attribute_grid, LocaleData.text("health"), "", "heart")
    _char_values["qi"] = UIKit.stat_row(attribute_grid, LocaleData.text("qi"), "", "drop")
    _char_values["attack"] = UIKit.stat_row(attribute_grid, LocaleData.text("attack"), "", "sword")
    _char_values["defense"] = UIKit.stat_row(attribute_grid, LocaleData.text("defense"), "", "shield")
    _char_values["move_speed"] = UIKit.stat_row(attribute_grid, LocaleData.text("move_speed"), "", "speed")
    _char_values["crit_chance"] = UIKit.stat_row(attribute_grid, LocaleData.text("crit_chance"), "", "star")

    var destiny_grid := UIKit.grid(2, 28, 10)
    UIKit.section_header(stats, LocaleData.text("section_destiny")).add_child(destiny_grid)
    _char_values["realm"] = UIKit.stat_row(destiny_grid, LocaleData.text("realm"))
    _char_values["element"] = UIKit.stat_row(destiny_grid, LocaleData.text("element"))
    _char_values["cultivation"] = UIKit.stat_row(destiny_grid, LocaleData.text("cultivation"))
    _char_values["birth_pillar"] = UIKit.stat_row(destiny_grid, LocaleData.text("birth_pillar"))
    _char_values["current_pillar"] = UIKit.stat_row(destiny_grid, LocaleData.text("current_pillar"))
    _char_values["time"] = UIKit.stat_row(destiny_grid, LocaleData.text("time"))
    _char_values["fashion"] = UIKit.stat_row(destiny_grid, LocaleData.text("fashion"))

## One equipment slot: a square framed glyph.  The slot / item name is shown
## as a tooltip so the Destiny-style equipment panel can stay text-free.
func _make_equipment_row(slot_id: String) -> Control:
    var frame := PanelContainer.new()
    frame.name = "Slot_" + slot_id
    frame.custom_minimum_size = Vector2(64, 64)
    frame.mouse_filter = Control.MOUSE_FILTER_STOP
    frame.add_theme_stylebox_override("panel", ThemeBuilder.flat_box(ThemeBuilder.BG_SLOT, ThemeBuilder.BORDER_MUTED, 8, 1))
    frame.tooltip_text = GameData.slot_name(slot_id) + "\n" + LocaleData.text("equipment_empty")

    var slot_icon := UiIcon.new(_slot_glyph(slot_id), ThemeBuilder.JADE_DIM, 1.8)
    slot_icon.glyph_size = 38.0
    frame.add_child(slot_icon)

    _char_equip_rows[slot_id] = frame
    _char_equip_icons[slot_id] = slot_icon
    return frame


func _slot_glyph(slot_id: String) -> String:
    match slot_id:
        "weapon":
            return "slot_weapon"
        "head":
            return "slot_head"
        "body":
            return "slot_body"
        "legs":
            return "slot_legs"
        "boots":
            return "slot_boots"
        "bracers":
            return "slot_bracers"
        "accessory":
            return "slot_accessory"
        "talisman":
            return "slot_talisman"
    return "slot_body"


## The equipment panel reuses the wardrobe mirror, so the preview always shows
## the same body, outfit and weapon as the world does.
func _build_character_preview() -> Control:
    _character_preview = FashionPreview.new()
    _character_preview.custom_minimum_size = Vector2(190, 330)
    _character_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _character_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    return _character_preview


func _build_dialogue_panel(root: Control) -> void:
    _dialogue_panel = PanelContainer.new()
    _dialogue_panel.name = "dialogue"
    _dialogue_panel.theme_type_variation = "ModalPanel"
    _dialogue_panel.custom_minimum_size = Vector2(880, 0)
    _dialogue_panel.anchor_left = 0.5
    _dialogue_panel.anchor_right = 0.5
    _dialogue_panel.anchor_top = 1.0
    _dialogue_panel.anchor_bottom = 1.0
    _dialogue_panel.offset_left = -440
    _dialogue_panel.offset_right = 440
    _dialogue_panel.offset_top = -300
    _dialogue_panel.offset_bottom = -46
    root.add_child(_dialogue_panel)

    var margin := UIKit.margin_container(22, 18, 22, 18)
    _dialogue_panel.add_child(margin)

    var column := UIKit.vbox(10)
    margin.add_child(column)

    var row := UIKit.hbox(14)
    column.add_child(row)

    var portrait := PanelContainer.new()
    portrait.theme_type_variation = "PortraitPanel"
    portrait.custom_minimum_size = Vector2(56, 56)
    portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_child(portrait)
    _dialogue_portrait = UIKit.heading("")
    _dialogue_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _dialogue_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    portrait.add_child(_dialogue_portrait)

    var text_column := UIKit.vbox(6)
    text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text_column)

    _dialogue_name = UIKit.heading("")
    text_column.add_child(_dialogue_name)

    _dialogue_text = UIKit.wrapped_label("")
    _dialogue_text.add_theme_color_override("font_color", ThemeBuilder.TEXT_DIM)
    _dialogue_text.custom_minimum_size = Vector2(0, 96)
    _dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    text_column.add_child(_dialogue_text)

    var buttons := UIKit.hbox(10)
    buttons.alignment = BoxContainer.ALIGNMENT_END
    column.add_child(buttons)

    _dialogue_decline = UIKit.button(LocaleData.text("quest_decline"), "GhostButton", Vector2(120, 38))
    _dialogue_decline.pressed.connect(_on_dialogue_decline)
    buttons.add_child(_dialogue_decline)

    _dialogue_accept = UIKit.button(LocaleData.text("quest_accept"), "PrimaryButton", Vector2(120, 38))
    _dialogue_accept.pressed.connect(_on_dialogue_accept)
    buttons.add_child(_dialogue_accept)

    _dialogue_next = UIKit.button(LocaleData.text("dialogue_next"), "", Vector2(120, 38))
    _dialogue_next.pressed.connect(_advance_dialogue)
    buttons.add_child(_dialogue_next)

    _dialogue_panel.hide()

# ================================================================ refresh ====

func _refresh_hud() -> void:
    if _health_bar == null:
        return
    var total := GameState.get_total_stats()
    var max_health := maxf(float(total["max_health"]), 1.0)
    var max_qi := maxf(float(total["max_qi"]), 1.0)
    _health_bar.max_value = max_health
    _health_bar.value = clampf(GameState.health, 0.0, max_health)
    _qi_bar.max_value = max_qi
    _qi_bar.value = clampf(GameState.qi, 0.0, max_qi)
    _health_bar.tooltip_text = LocaleData.text("health")
    _qi_bar.tooltip_text = LocaleData.text("qi")

    var health_label: Label = _bar_values.get("health")
    if health_label != null:
        health_label.text = "%d / %d" % [int(round(GameState.health)), int(round(max_health))]
    var qi_label: Label = _bar_values.get("qi")
    if qi_label != null:
        qi_label.text = "%d / %d" % [int(round(GameState.qi)), int(round(max_qi))]

    _realm_label.text = GameState.get_realm_name()
    _element_label.text = GameState.get_element_name()
    _element_label.add_theme_color_override("font_color", GameData.element_color(GameState.player_element))

    var cultivation_label: Label = _bar_values.get("cultivation_progress")
    var next_xp := GameData.realm_next_xp(GameState.realm_index)
    if next_xp < 0.0:
        _cultivation_bar.max_value = maxf(GameState.cultivation_xp, 1.0)
        _cultivation_bar.value = GameState.cultivation_xp
        if cultivation_label != null:
            cultivation_label.text = LocaleData.text("value_dash")
    else:
        var current_threshold := float(GameData.realm_stats(GameState.realm_index)["xp"])
        _cultivation_bar.max_value = maxf(next_xp - current_threshold, 1.0)
        _cultivation_bar.value = clampf(GameState.cultivation_xp - current_threshold, 0.0, _cultivation_bar.max_value)
        if cultivation_label != null:
            cultivation_label.text = "%d / %d" % [int(_cultivation_bar.value), int(_cultivation_bar.max_value)]

    _time_label.text = GameState.get_time_string()
    _pip_label.text = GameState.get_element_relation_text()
    if _character_panel != null and _character_panel.visible:
        _refresh_character_panel()
    _refresh_quest_label()

func _refresh_character_panel() -> void:
    if _char_values.is_empty():
        return
    var total := GameState.get_total_stats()
    _character_header.text = "%s   %s   %s" % [GameState.player_name, GameState.get_realm_name(), GameState.get_element_name()]
    _char_values["health"].text = "%d / %d" % [int(GameState.health), int(total["max_health"])]
    _char_values["qi"].text = "%d / %d" % [int(GameState.qi), int(total["max_qi"])]
    _char_values["attack"].text = "%d" % int(total["attack"])
    _char_values["defense"].text = "%d" % int(total["defense"])
    _char_values["move_speed"].text = "%.1f" % float(total["move_speed"])
    _char_values["crit_chance"].text = "%.1f%%" % (float(total["crit_chance"]) * 100.0)
    _char_values["realm"].text = GameState.get_realm_name()
    _char_values["element"].text = GameState.get_element_name()
    _char_values["cultivation"].text = GameState.get_cultivation_text()
    _char_values["birth_pillar"].text = GameState.get_birth_text()
    _char_values["current_pillar"].text = str(GameState.get_pillars().get("text", ""))
    _char_values["time"].text = GameState.get_time_string()
    _char_values["fashion"].text = _fashion_text()
    for slot_id in _char_equip_icons.keys():
        var item_id := str(GameState.equipment.get(slot_id, ""))
        var slot_icon: UiIcon = _char_equip_icons.get(slot_id)
        var frame: Control = _char_equip_rows.get(slot_id)
        if item_id == "":
            if slot_icon != null:
                slot_icon.setup(_slot_glyph(str(slot_id)), ThemeBuilder.JADE_DIM, 1.8)
            if frame != null:
                frame.tooltip_text = GameData.slot_name(str(slot_id)) + "\n" + LocaleData.text("equipment_empty")
        else:
            var item_color := GameData.item_color(item_id)
            if slot_icon != null:
                slot_icon.setup(GameData.item_icon(item_id), item_color, 2.0)
            if frame != null:
                frame.tooltip_text = GameData.slot_name(str(slot_id)) + "\n" + GameData.item_name(item_id)
        if frame is PanelContainer:
            var border := ThemeBuilder.BORDER_MUTED if item_id == "" else GameData.item_color(item_id)
            (frame as PanelContainer).add_theme_stylebox_override("panel", ThemeBuilder.flat_box(ThemeBuilder.BG_SLOT, border, 8, 1))
    if _character_preview != null:
        _character_preview.set_appearance(GameState.fashion_appearance())
        _character_preview.set_weapon(str(GameState.equipment.get("weapon", "")))

## The wardrobe row on the character sheet only needs a refresh while it is
## actually on screen - the rest of the HUD is unaffected by cosmetics.
func _on_fashion_changed() -> void:
    if _character_panel != null and _character_panel.visible:
        _refresh_character_panel()


func _fashion_text() -> String:
    if GameState.fashion_worn == "":
        return LocaleData.text("fashion_none")
    return FashionData.name(GameState.fashion_worn)


func _refresh_inventory() -> void:
    if _inventory_grid == null:
        return
    for child in _inventory_grid.get_children():
        _inventory_grid.remove_child(child)
        child.queue_free()
    _slot_buttons.clear()
    _slot_colors.clear()
    _slot_indices.clear()

    if _inventory_capacity != null:
        _inventory_capacity.text = LocaleData.text("inventory_capacity") % [GameState.get_inventory_used(), GameState.INVENTORY_SIZE]

    var entries := _inventory_entries()
    var page_cells: int = mini(INVENTORY_PAGE_SIZE, INVENTORY_MAX_PAGE_CELLS)
    var page_count := maxi(1, int(ceil(float(entries.size()) / float(page_cells))))
    _inventory_page = clampi(_inventory_page, 0, page_count - 1)
    var page_start := _inventory_page * page_cells
    var page_entries := entries.slice(page_start, mini(page_start + page_cells, entries.size()))

    var visible := {}
    for entry in page_entries:
        visible[int((entry as Dictionary).get("index", -1))] = true
    if _selected_slot >= 0 and not visible.has(_selected_slot):
        _selected_slot = -1

    for entry in page_entries:
        var data := entry as Dictionary
        var item_id := str(data.get("id", ""))
        var color := GameData.rarity_color(int(GameData.item_row(item_id).get("rarity", 1)))
        var button := _make_item_slot(data)
        _inventory_grid.add_child(button)
        _slot_buttons.append(button)
        _slot_colors.append(color)
        _slot_indices.append(int(data.get("index", -1)))

    # Pad the page so the grid keeps its shape.
    for _i in range(page_cells - page_entries.size()):
        var filler := _make_empty_slot()
        _inventory_grid.add_child(filler)
        _slot_buttons.append(filler)
        _slot_colors.append(ThemeBuilder.BORDER_MUTED)
        _slot_indices.append(-1)

    _update_slot_selection()
    _refresh_inventory_detail()

    if _inventory_page_label != null:
        _inventory_page_label.text = LocaleData.text("page_format") % [_inventory_page + 1, page_count]
    if _inventory_prev != null:
        _inventory_prev.disabled = _inventory_page <= 0
    if _inventory_next != null:
        _inventory_next.disabled = _inventory_page >= page_count - 1
    if _inventory_total_label != null:
        _inventory_total_label.text = LocaleData.text("inventory_total") % entries.size()

## One square item cell: item glyph tinted by the item colour, stack count in
## the bottom-right corner. Name/description live in the tooltip and detail card.

func _make_item_slot(entry: Dictionary) -> Button:
    var absolute_index := int(entry.get("index", -1))
    var item_id := str(entry.get("id", ""))
    var count := int(entry.get("count", 1))

    var button := UIKit.button("", "ItemSlot", Vector2(INVENTORY_CELL, INVENTORY_CELL))
    button.tooltip_text = "%s\n%s" % [GameData.item_name(item_id), str(GameData.item(item_id).get("desc", ""))]
    button.pressed.connect(_on_inventory_slot_pressed.bind(absolute_index))

    var glyph := UiIcon.new(GameData.item_icon(item_id), GameData.item_color(item_id), 2.0)
    glyph.glyph_size = 38.0
    glyph.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
    glyph.shadow_offset = Vector2(0.0, 1.0)
    UIKit.attach_glyph(button, glyph, 38.0)

    if count > 1:
        var count_label := UIKit.label("x%d" % count, "HintLabel")
        count_label.add_theme_font_size_override("font_size", 13)
        count_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
        count_label.anchor_left = 1.0
        count_label.anchor_right = 1.0
        count_label.anchor_top = 1.0
        count_label.anchor_bottom = 1.0
        count_label.offset_left = -40.0
        count_label.offset_right = -6.0
        count_label.offset_top = -22.0
        count_label.offset_bottom = -4.0
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
        button.add_child(count_label)

    return button

func _make_empty_slot() -> Button:
    var filler := UIKit.button("", "ItemSlot", Vector2(INVENTORY_CELL, INVENTORY_CELL))
    filler.disabled = true
    return filler


## Items matching the active filter, in bag order.

func _inventory_entries() -> Array:
    var entries: Array = []
    for i in range(GameState.inventory.size()):
        var slot: Variant = GameState.inventory[i]
        if not (slot is Dictionary) or (slot as Dictionary).is_empty():
            continue
        var data := slot as Dictionary
        var item_id := str(data.get("id", ""))
        if item_id == "":
            continue
        if _inventory_filter != "all" and GameData.item_category(item_id) != _inventory_filter:
            continue
        entries.append({"index": i, "id": item_id, "count": int(data.get("count", 1))})
    return entries

func _inventory_filter_text(filter_id: String) -> String:
    match filter_id:
        "equipment":
            return LocaleData.text("equipment")
        "consumable":
            return LocaleData.text("consumable")
        "material":
            return LocaleData.text("material")
    return LocaleData.text("filter_all")

func _set_inventory_filter(filter_id: String) -> void:
    if _inventory_filter == filter_id:
        return
    _inventory_filter = filter_id
    _inventory_page = 0
    _selected_slot = -1
    AudioManager.play_ui_click()
    _refresh_inventory()

func _on_inventory_prev_page() -> void:
    if _inventory_page <= 0:
        return
    _inventory_page -= 1
    AudioManager.play_ui_click()
    _refresh_inventory()

func _on_inventory_next_page() -> void:
    _inventory_page += 1
    AudioManager.play_ui_click()
    _refresh_inventory()

func _on_sort_inventory_pressed() -> void:
    AudioManager.play_ui_confirm()
    _inventory_page = 0
    _selected_slot = -1
    GameState.sort_inventory()
    _refresh_inventory()

func _update_slot_selection() -> void:
    for i in range(_slot_buttons.size()):
        var button: Button = _slot_buttons[i]
        var color := ThemeBuilder.BORDER_MUTED
        if i < _slot_colors.size():
            color = _slot_colors[i]
        var absolute := -1
        if i < _slot_indices.size():
            absolute = _slot_indices[i]
        var selected := absolute >= 0 and absolute == _selected_slot
        button.add_theme_stylebox_override("normal", UIKit.slot_box(color, selected, false))
        button.add_theme_stylebox_override("hover", UIKit.slot_box(color, selected, true))
        button.add_theme_stylebox_override("pressed", UIKit.slot_box(color, true, true))

func _refresh_inventory_detail() -> void:
    if _inventory_name == null:
        return
    var data := _selected_slot_data()
    if data.is_empty():
        _inventory_name.text = LocaleData.text("no_item")
        _inventory_name.add_theme_color_override("font_color", ThemeBuilder.TEXT_MUTED)
        _inventory_desc.text = ""
        _inventory_stats.text = ""
        _use_button.disabled = true
        _equip_button.disabled = true
        _drop_button.disabled = true
        return
    var item_id := str(data.get("id", ""))
    var item := GameData.item(item_id)
    var type_id := str(item.get("type", ""))
    _inventory_name.text = str(item.get("name", item_id))
    _inventory_name.add_theme_color_override("font_color", GameData.item_color(item_id))
    _inventory_desc.text = str(item.get("desc", ""))
    var lines: Array[String] = []
    lines.append(GameData.item_type_name(type_id))
    if type_id == "equipment":
        lines.append(GameData.slot_name(str(item.get("slot", ""))))
    var count := int(data.get("count", 1))
    if count > 1:
        lines.append(LocaleData.text("amount") + ": x%d" % count)
    if str(item.get("element", "none")) != "none":
        lines.append(LocaleData.text("element") + ": " + GameData.element_name(str(item.get("element", "none"))))
    var item_stats: Variant = item.get("stats", {})
    if item_stats is Dictionary:
        for key in item_stats.keys():
            lines.append("%s %s" % [LocaleData.text(str(key)), _format_stat_value(item_stats[key], str(key))])
    var set_id := str(item.get("set", ""))
    if set_id != "":
        var equipped_pieces := GameState.get_equipped_set_count(set_id)
        var total_pieces := GameData.set_total_pieces(set_id)
        lines.append("%s (%d/%d)" % [GameData.equipment_set_name(set_id), equipped_pieces, total_pieces])
        for bonus_line in GameData.set_bonus_lines(set_id, equipped_pieces):
            lines.append(bonus_line)
    _inventory_stats.text = "\n".join(lines)
    _use_button.disabled = type_id != "consumable"
    _equip_button.disabled = type_id != "equipment"
    _drop_button.disabled = false

## Signed stat read-out so penalties show as "-0.4" instead of "+-0.4".

func _format_stat_value(value: Variant, stat_key := "") -> String:
    match stat_key:
        "crit_chance", "crit_damage":
            return "%+.1f%%" % (float(value) * 100.0)
        "move_speed":
            return "%+.2f" % float(value)
    if value is int:
        return "%+d" % int(value)
    if value is float:
        if is_equal_approx(float(value), roundf(float(value))):
            return "%+d" % int(round(float(value)))
        return "%+.2f" % float(value)
    return str(value)

func _selected_slot_data() -> Dictionary:
    if _selected_slot < 0 or _selected_slot >= GameState.inventory.size():
        return {}
    var slot: Variant = GameState.inventory[_selected_slot]
    if slot is Dictionary and not (slot as Dictionary).is_empty():
        return slot as Dictionary
    return {}

func _on_inventory_slot_pressed(index: int) -> void:
    _selected_slot = index
    AudioManager.play_ui_click()
    _update_slot_selection()
    _refresh_inventory_detail()

func _on_use_pressed() -> void:
    if GameState.use_item(_selected_slot):
        _selected_slot = -1
        _refresh_inventory()
    AudioManager.play_ui_confirm()

func _on_equip_pressed() -> void:
    if GameState.equip_item(_selected_slot):
        _selected_slot = -1
        _refresh_inventory()
    AudioManager.play_ui_confirm()

func _on_drop_pressed() -> void:
    if _selected_slot < 0 or _selected_slot >= GameState.inventory.size():
        return
    var slot: Variant = GameState.inventory[_selected_slot]
    if slot is Dictionary:
        GameState.remove_item(str((slot as Dictionary).get("id", "")), 1)
    _selected_slot = -1
    _refresh_inventory()

# ================================================================ update =====

func _update_compass() -> void:
    if _compass == null:
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var forward := -camera.global_transform.basis.z
    forward.y = 0.0
    if forward.length() < 0.001:
        return
    _compass.set_heading(rad_to_deg(atan2(forward.x, -forward.z)))

func _on_skill_button_pressed(skill_id: String) -> void:
    _cast_from_ui(skill_id)

func _cast_from_ui(skill_id: String) -> void:
    if player == null:
        return
    player._cast_skill(skill_id)

func _process(delta: float) -> void:
    # The equipment mirror spins itself whenever it is visible (FashionPreview).
    if _toast_timer > 0.0:
        _toast_timer = maxf(0.0, _toast_timer - delta)
        if _toast_panel != null:
            _toast_panel.modulate.a = clampf(_toast_timer * 2.0, 0.0, 1.0)
    if player != null:
        for skill_id in _skill_buttons.keys():
            var cooldown := float(player.skill_cooldowns.get(skill_id, 0.0))
            var icon: UiIcon = _skill_icons.get(skill_id)
            var cooldown_label: Label = _skill_cooldown_labels.get(skill_id)
            if icon != null:
                icon.set_tint(_skill_tint())
            if cooldown > 0.05:
                if cooldown_label != null:
                    cooldown_label.text = "%.1f" % cooldown
                    cooldown_label.show()
                if icon != null:
                    icon.modulate = Color(1.0, 1.0, 1.0, 0.3)
            else:
                if cooldown_label != null:
                    cooldown_label.hide()
                if icon != null:
                    icon.modulate = Color.WHITE
    _update_compass()
    _refresh_hud()
    _update_interact_hint()

func _unhandled_input(event: InputEvent) -> void:
    if _death_panel != null and _death_panel.visible:
        return
    if _dialogue_panel != null and _dialogue_panel.visible:
        var awaiting_choice := _dialogue_accept.visible or _dialogue_decline.visible
        if not awaiting_choice and event.is_action_pressed("ui_accept"):
            _advance_dialogue()
            get_viewport().set_input_as_handled()
            return
    if event.is_action_pressed("toggle_inventory"):
        _toggle_panel(_inventory_panel, "inventory")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("toggle_character"):
        _toggle_panel(_character_panel, "character")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("toggle_fashion"):
        _toggle_panel(_fashion_panel, "fashion")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("toggle_achievements"):
        if _achievements_panel.visible:
            _close_panels()
        else:
            _open_panel(_achievements_panel, "achievements")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("toggle_game_menu"):
        if _game_menu.visible and _game_menu.is_closing():
            # A second quick press cancels the close animation and reopens the
            # menu instead of being swallowed by the closing state.
            _open_panel(_game_menu, "game_menu")
        elif _game_menu.visible:
            _close_panels()
        elif _any_panel_visible():
            _close_panels()
        else:
            _open_panel(_game_menu, "game_menu")
        get_viewport().set_input_as_handled()

# ================================================================ panels =====

func _toggle_panel(panel: Control, panel_name: String) -> void:
    if panel.visible:
        _close_panels()
    else:
        _open_panel(panel, panel_name)

func _open_panel(panel: Control, panel_name: String) -> void:
    for other in _all_panels:
        if other == panel or not other.visible:
            continue
        if other.has_method("close"):
            other.call("close")
        else:
            other.hide()
        EventBus.ui_panel_toggled.emit(str(other.name), false)

    var is_overlay := panel.has_method("open")
    if _panel_scrim != null:
        _panel_scrim.visible = not is_overlay
    panel.show()
    if is_overlay:
        panel.call("open")
    else:
        UIKit.pop_in(panel)
    EventBus.ui_panel_toggled.emit(panel_name, true)
    AudioManager.play_ui_click()
    _sync_pause()

func _close_panels() -> void:
    for panel in _all_panels:
        if not panel.visible:
            continue
        if panel.has_method("close"):
            panel.call("close")
        else:
            panel.hide()
        EventBus.ui_panel_toggled.emit(str(panel.name), false)
    if _panel_scrim != null:
        _panel_scrim.visible = false
    _sync_pause()

func _any_panel_visible() -> bool:
    for panel in _all_panels:
        if panel.visible:
            return true
    return false

func _any_panel_active() -> bool:
    for panel in _all_panels:
        if not panel.visible:
            continue
        if panel.has_method("is_closing") and bool(panel.call("is_closing")):
            continue
        return true
    return false

func _sync_pause() -> void:
    var open := _any_panel_active()
    get_tree().paused = open
    if open:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif int(GameState.settings.get("camera_mode", 0)) == 1:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_panel_scrim_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
            _close_panels()

func _on_overlay_closed(panel_name: String) -> void:
    EventBus.ui_panel_toggled.emit(panel_name, false)
    _sync_pause()

func _on_game_menu_resume_requested() -> void:
    _close_panels()

func _on_game_menu_main_menu_requested() -> void:
    GameState.save_game()
    EventBus.return_to_main_menu_requested.emit()

func _on_game_menu_settings_requested() -> void:
    _open_panel(_settings_panel, "settings")

func _on_game_menu_quit_requested() -> void:
    GameState.save_game()
    EventBus.quit_game_requested.emit()


func _on_player_died() -> void:
    _open_panel(_death_panel, "death")


func _on_revive_in_place_requested() -> void:
    if GameState.count_item("consumable_huanhun") <= 0:
        _death_panel.call("refresh")
        return
    if not GameState.remove_item("consumable_huanhun", 1):
        _death_panel.call("refresh")
        return
    if player != null:
        player.revive_in_place()
    _close_panels()
    EventBus.toast_requested.emit(LocaleData.text("revive_success"), Color(0.72, 0.95, 0.78))


func _on_revive_at_spawn_requested() -> void:
    if player != null:
        player.revive_at_spawn(GameWorld.RESPAWN_POSITION)
    _close_panels()
    EventBus.toast_requested.emit(LocaleData.text("revive_at_spawn_success"), Color(0.72, 0.90, 1.0))

# ============================================================== quests =======

func _on_time_changed(_pillars: Dictionary) -> void:
    _refresh_hud()

func _on_settings_changed() -> void:
    _apply_screen_filter()
    _refresh_hud()


## Colour-grading overlay that matches the chosen screen filter preset.
func _apply_screen_filter() -> void:
    if _filter_tint == null:
        return
    var preset := GameState.get_filter_preset()
    _filter_tint.color = preset[3]

func _refresh_quest_label() -> void:
    if _quest_label == null:
        return
    if not bool(GameState.settings.get("quest_tracker", true)):
        _quest_label.text = ""
        _quest_panel.hide()
        return
    var quest := GameState.get_tracked_quest()
    if quest.is_empty():
        _quest_label.text = ""
        _quest_panel.hide()
        return
    var status_text := GameState.get_quest_state_text(str(quest.get("id", "")))
    _quest_label.text = "%s\n%s\n%s  %d/%d" % [
        LocaleData.text("quest_tracker_title"),
        str(quest.get("name", "")),
        status_text,
        int(quest.get("progress", 0)),
        int(quest.get("target", 1)),
    ]
    _quest_panel.show()

func _on_quest_updated(_quest_id: String) -> void:
    _refresh_quest_label()

func _on_quest_completed(_quest_id: String) -> void:
    _refresh_quest_label()

# ============================================================= flavour =======

func _update_interact_hint() -> void:
    if _interact_panel == null:
        return
    if _any_panel_visible():
        _interact_panel.hide()
        return
    var hint := ""
    if player != null:
        for npc_node in get_tree().get_nodes_in_group("npcs"):
            if npc_node is Node3D:
                if player.global_position.distance_to((npc_node as Node3D).global_position) < 3.8:
                    hint = LocaleData.text("interact_hint")
                    break
        if hint == "":
            for loot_node in get_tree().get_nodes_in_group("loot"):
                if loot_node is Node3D:
                    if player.global_position.distance_to((loot_node as Node3D).global_position) < 5.0:
                        hint = LocaleData.text("interact_hint")
                        break
    _interact_label.text = hint
    _interact_panel.visible = hint != ""

func _on_toast_requested(text: String, color: Color) -> void:
    if _toast_label == null:
        return
    _toast_label.text = text
    _toast_label.add_theme_color_override("font_color", color)
    _toast_timer = 2.4
    _toast_panel.modulate.a = 1.0

func _on_combat_log(text: String) -> void:
    _log_lines.append(text)
    if _log_lines.size() > 6:
        _log_lines.pop_front()
    _log_label.text = "\n".join(_log_lines)

func _on_achievement_unlocked(_achievement: Dictionary) -> void:
    pass

# ============================================================= dialogue ======

func _on_dialogue_requested(npc_id: String) -> void:
    _dialogue_npc_id = npc_id
    var npc := GameData.npc(npc_id)
    var quest_id := str(npc.get("quest_id", ""))
    _dialogue_lines.clear()
    if quest_id == "":
        _dialogue_lines.append(LocaleData.text("npc_elder_done"))
    else:
        var state := GameState.get_quest_state(quest_id)
        var status := str(state.get("status", "inactive"))
        var quest := GameData.quest(quest_id)
        if status == "inactive":
            _dialogue_lines.append(LocaleData.text("npc_elder_greeting"))
            _dialogue_lines.append(str(quest.get("desc", "")))
        elif status == "active":
            _dialogue_lines.append(LocaleData.text("npc_elder_progress"))
        elif status == "ready":
            _dialogue_lines.append(LocaleData.text("npc_elder_complete"))
        else:
            _dialogue_lines.append(LocaleData.text("npc_elder_done"))
    _dialogue_index = 0
    _refresh_dialogue_content()
    _open_panel(_dialogue_panel, "dialogue")

func _refresh_dialogue_content() -> void:
    if _dialogue_name == null or _dialogue_text == null:
        return
    var npc := GameData.npc(_dialogue_npc_id)
    var npc_name := str(npc.get("name", ""))
    var title := str(npc.get("title", ""))
    _dialogue_name.text = npc_name + ("  " + title if title != "" else "")
    _dialogue_portrait.text = npc_name.substr(0, 1)
    if _dialogue_lines.is_empty():
        _dialogue_text.text = ""
    else:
        _dialogue_index = clampi(_dialogue_index, 0, _dialogue_lines.size() - 1)
        _dialogue_text.text = _dialogue_lines[_dialogue_index]
    var quest_id := str(npc.get("quest_id", ""))
    var status := "inactive"
    if quest_id != "":
        var state := GameState.get_quest_state(quest_id)
        status = str(state.get("status", "inactive"))
    var is_last := _dialogue_index >= _dialogue_lines.size() - 1
    var show_accept := false
    var show_decline := false
    var show_next := true
    if quest_id != "" and status == "inactive" and is_last:
        show_accept = true
        show_decline = true
        show_next = false
    elif quest_id != "" and status == "ready" and is_last:
        show_accept = true
        show_next = false
    _dialogue_accept.visible = show_accept
    _dialogue_decline.visible = show_decline
    _dialogue_next.visible = show_next
    _dialogue_accept.text = LocaleData.text("quest_turn_in") if status == "ready" else LocaleData.text("quest_accept")
    _dialogue_next.text = LocaleData.text("dialogue_close") if is_last else LocaleData.text("dialogue_next")

func _advance_dialogue() -> void:
    if _dialogue_index < _dialogue_lines.size() - 1:
        _dialogue_index += 1
        _refresh_dialogue_content()
    else:
        _close_dialogue()

func _on_dialogue_accept() -> void:
    var npc := GameData.npc(_dialogue_npc_id)
    var quest_id := str(npc.get("quest_id", ""))
    if quest_id == "":
        _close_dialogue()
        return
    var state := GameState.get_quest_state(quest_id)
    var status := str(state.get("status", "inactive"))
    if status == "inactive":
        GameState.start_quest(quest_id)
        _dialogue_lines.clear()
        _dialogue_lines.append(LocaleData.text("npc_elder_progress"))
        _dialogue_index = 0
        _refresh_dialogue_content()
    elif status == "ready":
        GameState.complete_quest(quest_id)
        _close_dialogue()
    else:
        _close_dialogue()

func _on_dialogue_decline() -> void:
    _close_dialogue()

func _close_dialogue() -> void:
    _close_panels()