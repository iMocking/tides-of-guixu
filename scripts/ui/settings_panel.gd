extends UiOverlay
class_name SettingsPanel
## Tabbed settings window: 画面 / 操作 / 音频.
##
## Every control is bound to a key in GameState.settings, so adding a new option
## only means registering it in _sliders / _options / _checks and giving it a row.

const TABS: Array[String] = ["display", "controls", "audio"]

var _pages: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _active_tab := "display"

var _sliders: Dictionary = {}      # setting key -> HSlider
var _options: Dictionary = {}      # setting key -> OptionButton
var _checks: Dictionary = {}       # setting key -> CheckButton
var _value_labels: Dictionary = {} # setting key -> Label

var _gamepad_status: Label
var _bind_buttons: Dictionary = {}
var _listening_action := ""

# ------------------------------------------------------------------ shell ---
func _modal_title() -> String:
    return LocaleData.text("settings")

func _modal_icon() -> String:
    return "gear"

func _modal_size() -> Vector2:
    return Vector2(820, 660)

func _build_content() -> void:
    close_on_scrim_click = false

    var tabs := UIKit.hbox(6)
    content.add_child(tabs)

    var group := ButtonGroup.new()
    for tab_id in TABS:
        var chip := UIKit.chip_button(_tab_text(tab_id), group, Vector2(108, 34))
        chip.name = "Tab_" + tab_id
        chip.pressed.connect(_set_tab.bind(tab_id))
        tabs.add_child(chip)
        _tab_buttons[tab_id] = chip
    tabs.add_child(UIKit.spacer(true, false))
    tabs.add_child(UIKit.hint(LocaleData.text("settings_tab_hint")))

    var page_host := Control.new()
    page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(page_host)

    for tab_id in TABS:
        var scroll := ScrollContainer.new()
        scroll.name = "Page_" + tab_id
        scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroll.visible = false
        page_host.add_child(scroll)

        var page := UIKit.vbox(12)
        page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(page)
        _pages[tab_id] = scroll
        match tab_id:
            "display":
                _build_display_page(page)
            "controls":
                _build_controls_page(page)
            "audio":
                _build_audio_page(page)

    var reset := UIKit.button(LocaleData.text("reset_settings"), "GhostButton", Vector2(150, 38))
    reset.pressed.connect(_on_reset_pressed)
    footer.add_child(reset)

    _set_tab(_active_tab, false)

func _tab_text(tab_id: String) -> String:
    match tab_id:
        "display":
            return LocaleData.text("graphics")
        "controls":
            return LocaleData.text("controls")
    return LocaleData.text("audio")

func _set_tab(tab_id: String, play_sound := true) -> void:
    _active_tab = tab_id
    for id in _pages.keys():
        (_pages[id] as Control).visible = (str(id) == tab_id)
    if play_sound:
        AudioManager.play_ui_click()

# ------------------------------------------------------------------ 画面 ----
func _build_display_page(page: VBoxContainer) -> void:
    var window_grid := _section(page, "section_window")
    _options["resolution"] = _add_option_row(window_grid, "resolution", _resolution_labels())
    _checks["fullscreen"] = _add_check_row(window_grid, "fullscreen")
    _sliders["ui_scale"] = _add_slider_row(window_grid, "ui_scale", 0.8, 1.4, 0.05)
    _options["vsync"] = _add_option_row(window_grid, "vsync",
        [LocaleData.text("vsync_off"), LocaleData.text("vsync_on"), LocaleData.text("vsync_adaptive")])
    _options["fps_limit"] = _add_option_row(window_grid, "fps_limit", _fps_labels())
    _options["msaa"] = _add_option_row(window_grid, "msaa", _msaa_labels())

    var picture_grid := _section(page, "section_picture")
    _sliders["brightness"] = _add_slider_row(picture_grid, "brightness", 0.8, 1.6, 0.02)
    _options["screen_filter"] = _add_option_row(picture_grid, "screen_filter",
        [LocaleData.text("filter_none"), LocaleData.text("filter_ink"), LocaleData.text("filter_warm"), LocaleData.text("filter_night")])
    _sliders["camera_fov"] = _add_slider_row(picture_grid, "camera_fov", 40.0, 80.0, 1.0)
    _checks["shadows"] = _add_check_row(picture_grid, "shadows")
    _checks["fog"] = _add_check_row(picture_grid, "fog")

    var world_grid := _section(page, "section_world")
    _sliders["time_scale"] = _add_slider_row(world_grid, "time_flow", 0.1, 2.0, 0.05)
    _sliders["time_of_day"] = _add_slider_row(world_grid, "time_of_day", 0.0, 23.0, 1.0)

    var combat_grid := _section(page, "section_combat")
    _options["combat_fx"] = _add_option_row(combat_grid, "combat_fx",
        [LocaleData.text("combat_fx_off"), LocaleData.text("combat_fx_low"), LocaleData.text("combat_fx_full")])
    _checks["show_damage_numbers"] = _add_check_row(combat_grid, "show_damage")
    _checks["enemy_health_bars"] = _add_check_row(combat_grid, "enemy_health_bars")
    _checks["quest_tracker"] = _add_check_row(combat_grid, "quest_tracker_toggle")

func _resolution_labels() -> Array:
    var labels := []
    for i in range(GameState.RESOLUTION_SIZES.size()):
        var option_size := GameState.get_resolution_size(i)
        labels.append("%d x %d (16:9)" % [option_size.x, option_size.y])
    return labels

func _fps_labels() -> Array:
    var labels := []
    for value in GameState.FPS_OPTIONS:
        labels.append(LocaleData.text("fps_unlimited") if int(value) == 0 else "%d" % int(value))
    return labels

func _msaa_labels() -> Array:
    var labels := [LocaleData.text("msaa_off")]
    for level in [1, 2, 3]:
        labels.append("%d×" % (1 << level))
    return labels

# ------------------------------------------------------------------ 操作 ----
func _build_controls_page(page: VBoxContainer) -> void:
    var camera_grid := _section(page, "section_camera")
    _options["camera_mode"] = _add_option_row(camera_grid, "camera_mode",
        [LocaleData.text("camera_top_down"), LocaleData.text("camera_third_person")])
    _sliders["mouse_sensitivity"] = _add_slider_row(camera_grid, "mouse_sensitivity", 0.0005, 0.01, 0.0005)
    _sliders["camera_rotate_speed"] = _add_slider_row(camera_grid, "camera_rotate_speed", 40.0, 260.0, 10.0)
    _checks["invert_y"] = _add_check_row(camera_grid, "invert_y")

    var pad_grid := _section(page, "section_gamepad")
    pad_grid.add_child(UIKit.label(LocaleData.text("gamepad_status"), "StatLabel"))
    _gamepad_status = UIKit.value("")
    _gamepad_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    pad_grid.add_child(_gamepad_status)
    _checks["gamepad_rumble"] = _add_check_row(pad_grid, "gamepad_rumble")

    var bind_body := UIKit.section_header(page, LocaleData.text("section_keybinds"))
    var hint := UIKit.muted(LocaleData.text("keybinds_hint"))
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bind_body.add_child(hint)

    var bind_grid := UIKit.grid(3, 14, 8)
    bind_body.add_child(bind_grid)
    for action in GameState.BINDABLE_ACTIONS:
        bind_grid.add_child(UIKit.label(_action_text(action), "StatLabel"))
        bind_grid.add_child(UIKit.spacer(true, false))
        var rebind := UIKit.button("", "ChipButton", Vector2(140, 30))
        rebind.name = "Bind_" + action
        rebind.pressed.connect(_start_listen.bind(action))
        bind_grid.add_child(rebind)
        _bind_buttons[action] = rebind

    var reset_binds := UIKit.button(LocaleData.text("keybind_reset"), "GhostButton", Vector2(170, 34))
    reset_binds.pressed.connect(_on_reset_bindings)
    bind_body.add_child(reset_binds)

func _action_text(action: String) -> String:
    match action:
        "move_forward", "move_back", "move_left", "move_right", "jump", "dodge", "interact", "toggle_camera", \
        "camera_rotate_left", "camera_rotate_right", "camera_reset":
            return LocaleData.text("action_" + action)
        "attack":
            return LocaleData.text("basic_attack")
        "toggle_inventory":
            return LocaleData.text("inventory")
        "toggle_character":
            return LocaleData.text("character")
        "toggle_achievements":
            return LocaleData.text("achievements")
        "toggle_game_menu", "toggle_settings":
            return LocaleData.text("game_menu")
    return LocaleData.text(action)

# ------------------------------------------------------------------ 音频 ----
func _build_audio_page(page: VBoxContainer) -> void:
    var volume_grid := _section(page, "section_volume")
    _sliders["master_volume_db"] = _add_slider_row(volume_grid, "master_volume", -30.0, 0.0, 1.0)
    _sliders["sfx_volume_db"] = _add_slider_row(volume_grid, "sfx_volume", -30.0, 0.0, 1.0)
    _sliders["music_volume_db"] = _add_slider_row(volume_grid, "music_volume", -30.0, 0.0, 1.0)

# ------------------------------------------------------------- row builders -
func _section(page: VBoxContainer, title_key: String) -> GridContainer:
    var body := UIKit.section_header(page, LocaleData.text(title_key))
    var grid := UIKit.grid(2, 20, 12)
    body.add_child(grid)
    return grid

func _setting_key(ui_key: String) -> String:
    return "resolution_index" if ui_key == "resolution" else ui_key

func _add_slider_row(grid: GridContainer, label_key: String, min_value: float, max_value: float, step: float) -> HSlider:
    grid.add_child(UIKit.label(LocaleData.text(label_key), "StatLabel"))
    var row := UIKit.hbox(8)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(row)

    var slider := HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    slider.custom_minimum_size = Vector2(180, 22)
    slider.value_changed.connect(_on_slider_changed.bind(label_key))
    row.add_child(slider)

    var value_label := UIKit.value("")
    value_label.custom_minimum_size = Vector2(80, 0)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(value_label)
    _value_labels[label_key] = value_label
    return slider

func _add_option_row(grid: GridContainer, label_key: String, labels: Array) -> OptionButton:
    grid.add_child(UIKit.label(LocaleData.text(label_key), "StatLabel"))
    var option := OptionButton.new()
    option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    for entry in labels:
        option.add_item(str(entry))
    option.item_selected.connect(_on_option_selected.bind(label_key))
    grid.add_child(option)
    return option

func _add_check_row(grid: GridContainer, label_key: String) -> CheckButton:
    grid.add_child(UIKit.label(LocaleData.text(label_key), "StatLabel"))
    var check := CheckButton.new()
    check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    check.toggled.connect(_on_check_toggled.bind(label_key))
    grid.add_child(check)
    return check

# ----------------------------------------------------------------- changes --
func _on_slider_changed(value: float, ui_key: String) -> void:
    if ui_key == "time_of_day":
        GameState.set_time_of_day(int(round(value)))
    else:
        GameState.set_setting(_setting_key(ui_key), value)
    _refresh_values()

func _on_option_selected(index: int, ui_key: String) -> void:
    GameState.set_setting(_setting_key(ui_key), index)
    AudioManager.play_ui_click()
    _sync_dependent()

func _on_check_toggled(pressed: bool, ui_key: String) -> void:
    GameState.set_setting(_setting_key(ui_key), pressed)
    _sync_dependent()

func _on_reset_bindings() -> void:
    GameState.reset_bindings()
    _listening_action = ""
    AudioManager.play_ui_confirm()
    _refresh_bindings()

func _start_listen(action: String) -> void:
    _listening_action = action
    AudioManager.play_ui_click()
    _refresh_bindings()

func _cancel_listen() -> void:
    _listening_action = ""
    _refresh_bindings()

func _unhandled_input(event: InputEvent) -> void:
    if _listening_action != "":
        if event is InputEventKey and event.pressed and not event.echo:
            var key := event as InputEventKey
            if key.physical_keycode == KEY_ESCAPE:
                _cancel_listen()
            else:
                GameState.set_binding(_listening_action, key.physical_keycode)
                _listening_action = ""
                _refresh_bindings()
                AudioManager.play_ui_confirm()
            get_viewport().set_input_as_handled()
            return
        if event is InputEventMouseButton and event.pressed:
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _on_reset_pressed() -> void:
    GameState.settings = GameState.DEFAULT_SETTINGS.duplicate(true)
    GameState.save_settings()
    GameState.apply_settings()
    GameState.apply_window_resolution()
    EventBus.settings_changed.emit()
    _sync()
    AudioManager.play_ui_confirm()

# -------------------------------------------------------------------- sync --
func _on_open() -> void:
    _listening_action = ""
    _sync()

func _sync() -> void:
    for ui_key in _options.keys():
        var option: OptionButton = _options[ui_key]
        var index := clampi(int(GameState.settings.get(_setting_key(str(ui_key)), 0)), 0, maxi(option.item_count - 1, 0))
        option.select(index)
    for ui_key in _sliders.keys():
        var slider: HSlider = _sliders[ui_key]
        if str(ui_key) == "time_of_day":
            slider.set_value_no_signal(float(GameState.get_time_of_day()))
        else:
            slider.set_value_no_signal(float(GameState.settings.get(_setting_key(str(ui_key)), slider.value)))
    for ui_key in _checks.keys():
        var check: CheckButton = _checks[ui_key]
        check.set_pressed_no_signal(bool(GameState.settings.get(_setting_key(str(ui_key)), false)))
    _refresh_values()
    _refresh_bindings()
    _refresh_gamepad()
    _sync_dependent()

func _sync_dependent() -> void:
    if _checks.has("fullscreen") and _options.has("resolution"):
        (_options["resolution"] as OptionButton).disabled = (_checks["fullscreen"] as CheckButton).button_pressed

func _refresh_values() -> void:
    for ui_key in _value_labels.keys():
        var label: Label = _value_labels[ui_key]
        var key := str(ui_key)
        if key == "time_of_day":
            label.text = _format_value(key, float(GameState.get_time_of_day()))
        else:
            label.text = _format_value(key, float(GameState.settings.get(_setting_key(key), 0.0)))

func _format_value(key: String, value: float) -> String:
    match key:
        "ui_scale":
            return "%d%%" % int(round(value * 100.0))
        "camera_fov":
            return "%d\u00b0" % int(value)
        "camera_rotate_speed":
            return "%d\u00b0/s" % int(value)
        "mouse_sensitivity":
            return "%.4f" % value
        "master_volume_db", "sfx_volume_db", "music_volume_db":
            return "%d dB" % int(value)
        "brightness":
            return "%.2f" % value
        "time_scale":
            return "%.1f \u5c0f\u65f6/\u65e5" % (0.4 / maxf(value, 0.01))
        "time_of_day":
            return "%02d:00" % int(value)
    return "%.2f" % value

func _refresh_bindings() -> void:
    for action in _bind_buttons.keys():
        var button: Button = _bind_buttons[action]
        if action == _listening_action:
            button.text = LocaleData.text("keybind_listening")
        else:
            button.text = GameState.get_binding_label(str(action))

func _refresh_gamepad() -> void:
    if _gamepad_status == null:
        return
    var pads := Input.get_connected_joypads()
    if pads.is_empty():
        _gamepad_status.text = LocaleData.text("gamepad_none")
        _gamepad_status.add_theme_color_override("font_color", ThemeBuilder.TEXT_MUTED)
        return
    var names: Array[String] = []
    for pad in pads:
        names.append(Input.get_joy_name(pad))
    _gamepad_status.text = LocaleData.text("gamepad_ready") % ", ".join(names)
    _gamepad_status.add_theme_color_override("font_color", ThemeBuilder.JADE)