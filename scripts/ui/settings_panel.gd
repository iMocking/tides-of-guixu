extends UiOverlay
class_name SettingsPanel
## Settings overlay shared by the main menu and the in-game HUD.

var _camera_mode: OptionButton
var _sensitivity: HSlider
var _sensitivity_value: Label
var _rotate_speed: HSlider
var _rotate_speed_value: Label
var _invert_y: CheckButton
var _fov: HSlider
var _fov_value: Label
var _volume: HSlider
var _volume_value: Label
var _fullscreen: CheckButton
var _resolution: OptionButton
var _damage_numbers: CheckButton
var _ui_scale: HSlider
var _ui_scale_value: Label

func _modal_title() -> String:
    return LocaleData.text("settings")

func _modal_size() -> Vector2:
    return Vector2(700, 600)

func _modal_icon() -> String:
    return "gear"

func _build_content() -> void:
    close_on_scrim_click = false

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(scroll)

    var body := UIKit.vbox(10)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(body)

    # ------------------------------------------------------------- display --
    var display_grid := UIKit.grid(2, 20, 12)
    UIKit.section_header(body, LocaleData.text("section_display")).add_child(display_grid)

    var fov_row := _add_slider_row(display_grid, LocaleData.text("camera_fov"))
    _fov = fov_row["slider"]
    _fov_value = fov_row["value"]
    _fov.min_value = 40.0
    _fov.max_value = 80.0
    _fov.step = 1.0
    _fov.value_changed.connect(_on_fov_changed)

    _add_label(display_grid, LocaleData.text("fullscreen"))
    _fullscreen = CheckButton.new()
    _fullscreen.toggled.connect(_on_fullscreen_toggled)
    display_grid.add_child(_fullscreen)

    _add_label(display_grid, LocaleData.text("resolution"))
    _resolution = OptionButton.new()
    _resolution.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for i in range(GameState.RESOLUTION_SIZES.size()):
        var option_size := GameState.get_resolution_size(i)
        _resolution.add_item("%d x %d (16:9)" % [option_size.x, option_size.y])
    _resolution.item_selected.connect(_on_resolution_changed)
    display_grid.add_child(_resolution)

    _add_label(display_grid, LocaleData.text("show_damage"))
    _damage_numbers = CheckButton.new()
    _damage_numbers.toggled.connect(_on_damage_numbers_toggled)
    display_grid.add_child(_damage_numbers)

    var scale_row := _add_slider_row(display_grid, LocaleData.text("ui_scale"))
    _ui_scale = scale_row["slider"]
    _ui_scale_value = scale_row["value"]
    _ui_scale.min_value = 0.8
    _ui_scale.max_value = 1.4
    _ui_scale.step = 0.05
    _ui_scale.value_changed.connect(_on_ui_scale_changed)

    # ------------------------------------------------------------ controls --
    var control_section := UIKit.section_header(body, LocaleData.text("section_controls"))
    var control_grid := UIKit.grid(2, 20, 12)
    control_section.add_child(control_grid)

    _add_label(control_grid, LocaleData.text("camera_mode"))
    _camera_mode = OptionButton.new()
    _camera_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _camera_mode.add_item(LocaleData.text("camera_top_down"))
    _camera_mode.add_item(LocaleData.text("camera_third_person"))
    _camera_mode.item_selected.connect(_on_camera_mode_changed)
    control_grid.add_child(_camera_mode)

    var sensitivity_row := _add_slider_row(control_grid, LocaleData.text("mouse_sensitivity"))
    _sensitivity = sensitivity_row["slider"]
    _sensitivity_value = sensitivity_row["value"]
    _sensitivity.min_value = 0.0005
    _sensitivity.max_value = 0.01
    _sensitivity.step = 0.0005
    _sensitivity.value_changed.connect(_on_sensitivity_changed)

    var rotate_row := _add_slider_row(control_grid, LocaleData.text("camera_rotate_speed"))
    _rotate_speed = rotate_row["slider"]
    _rotate_speed_value = rotate_row["value"]
    _rotate_speed.min_value = 40.0
    _rotate_speed.max_value = 260.0
    _rotate_speed.step = 10.0
    _rotate_speed.value_changed.connect(_on_rotate_speed_changed)

    _add_label(control_grid, LocaleData.text("invert_y"))
    _invert_y = CheckButton.new()
    _invert_y.toggled.connect(_on_invert_y_toggled)
    control_grid.add_child(_invert_y)

    var camera_hint := UIKit.muted(LocaleData.text("camera_hint"))
    camera_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    control_section.add_child(camera_hint)

    # --------------------------------------------------------------- audio --
    var audio_grid := UIKit.grid(2, 20, 12)
    UIKit.section_header(body, LocaleData.text("section_audio")).add_child(audio_grid)

    var volume_row := _add_slider_row(audio_grid, LocaleData.text("master_volume"))
    _volume = volume_row["slider"]
    _volume_value = volume_row["value"]
    _volume.min_value = -30.0
    _volume.max_value = 0.0
    _volume.step = 1.0
    _volume.value_changed.connect(_on_volume_changed)

    body.add_child(UIKit.spacer(false, false, Vector2(0, 4)))
    var tip := UIKit.muted(LocaleData.text("settings_tip") + "   " + LocaleData.text("close_hint_esc"))
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    body.add_child(tip)

    # Dropdowns and check boxes read as buttons too, so give them the hand cursor.
    for control in [_camera_mode, _resolution, _fullscreen, _damage_numbers, _invert_y]:
        if control is Control:
            (control as Control).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

    var reset := UIKit.button(LocaleData.text("reset_settings"), "GhostButton", Vector2(150, 38))
    reset.pressed.connect(_on_reset_pressed)
    footer.add_child(reset)

func _add_label(parent: GridContainer, text: String) -> void:
    parent.add_child(UIKit.label(text, "StatLabel"))

func _add_slider_row(parent: GridContainer, label_text: String) -> Dictionary:
    parent.add_child(UIKit.label(label_text, "StatLabel"))
    var row := UIKit.hbox(8)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(row)

    var slider := HSlider.new()
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    slider.custom_minimum_size = Vector2(180, 22)
    row.add_child(slider)

    var value_label := UIKit.label("", "ValueLabel")
    value_label.custom_minimum_size = Vector2(72, 0)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(value_label)
    return {"slider": slider, "value": value_label}

# ------------------------------------------------------------------ sync ----
func _on_open() -> void:
    _sync()

func _sync() -> void:
    _camera_mode.select(int(GameState.settings.get("camera_mode", 0)))
    _sensitivity.set_value_no_signal(float(GameState.settings.get("mouse_sensitivity", 0.0025)))
    _rotate_speed.set_value_no_signal(float(GameState.settings.get("camera_rotate_speed", 110.0)))
    _invert_y.set_pressed_no_signal(bool(GameState.settings.get("invert_y", false)))
    _fov.set_value_no_signal(float(GameState.settings.get("camera_fov", 55.0)))
    _volume.set_value_no_signal(float(GameState.settings.get("master_volume_db", -6.0)))
    _fullscreen.set_pressed_no_signal(bool(GameState.settings.get("fullscreen", false)))
    _resolution.select(clampi(int(GameState.settings.get("resolution_index", 0)), 0, GameState.RESOLUTION_SIZES.size() - 1))
    _resolution.disabled = _fullscreen.button_pressed
    _damage_numbers.set_pressed_no_signal(bool(GameState.settings.get("show_damage_numbers", true)))
    _ui_scale.set_value_no_signal(float(GameState.settings.get("ui_scale", 1.0)))
    _refresh_values()

func _refresh_values() -> void:
    _sensitivity_value.text = "%.4f" % _sensitivity.value
    _rotate_speed_value.text = "%d\u00b0/s" % int(_rotate_speed.value)
    _fov_value.text = "%d\u00b0" % int(_fov.value)
    _volume_value.text = "%d dB" % int(_volume.value)
    _ui_scale_value.text = "%d%%" % int(round(_ui_scale.value * 100.0))

# --------------------------------------------------------------- signals ----
func _on_camera_mode_changed(index: int) -> void:
    GameState.set_setting("camera_mode", index)
    AudioManager.play_ui_click()

func _on_sensitivity_changed(value: float) -> void:
    GameState.set_setting("mouse_sensitivity", value)
    _sensitivity_value.text = "%.4f" % value

func _on_rotate_speed_changed(value: float) -> void:
    GameState.set_setting("camera_rotate_speed", value)
    _rotate_speed_value.text = "%d\u00b0/s" % int(value)

func _on_invert_y_toggled(value: bool) -> void:
    GameState.set_setting("invert_y", value)

func _on_fov_changed(value: float) -> void:
    GameState.set_setting("camera_fov", value)
    _fov_value.text = "%d\u00b0" % int(value)

func _on_volume_changed(value: float) -> void:
    GameState.set_setting("master_volume_db", value)
    _volume_value.text = "%d dB" % int(value)

func _on_fullscreen_toggled(value: bool) -> void:
    _resolution.disabled = value
    GameState.set_setting("fullscreen", value)

func _on_resolution_changed(index: int) -> void:
    GameState.set_setting("resolution_index", index)
    AudioManager.play_ui_click()

func _on_damage_numbers_toggled(value: bool) -> void:
    GameState.set_setting("show_damage_numbers", value)

func _on_ui_scale_changed(value: float) -> void:
    GameState.set_setting("ui_scale", value)
    _ui_scale_value.text = "%d%%" % int(round(value * 100.0))

func _on_reset_pressed() -> void:
    GameState.settings = GameState.DEFAULT_SETTINGS.duplicate(true)
    GameState.save_settings()
    GameState.apply_settings()
    GameState.apply_window_resolution()
    EventBus.settings_changed.emit()
    _sync()
    AudioManager.play_ui_confirm()