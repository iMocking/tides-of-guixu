extends Control
class_name UiOverlay
## Base class for full-screen popup panels (settings, achievements, ...).
##
## Provides the shared shell: dimmed backdrop, centred window with a title bar,
## a content column, a footer row and consistent pop-in / pop-out motion.
## Subclasses only describe their own body through _build_content().

signal close_requested

var content: VBoxContainer
var header: HBoxContainer
var footer: HBoxContainer
var window: PanelContainer

var close_on_scrim_click := true
var show_footer_close := true

var _scrim: ColorRect
var _center: CenterContainer
var _closing := false
var _open_tween: Tween
var _close_tween: Tween

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    theme = ThemeBuilder.shared_theme()
    _build_shell()
    _build_content()
    _finish_shell()
    if not get_viewport().size_changed.is_connected(_on_viewport_resized):
        get_viewport().size_changed.connect(_on_viewport_resized)
    visible = false

func open() -> void:
    var was_closing := _closing
    _kill_tween(_close_tween)
    _closing = false

    var already_open := visible and not was_closing
    visible = true
    _on_open()
    if already_open:
        return

    # Opening from hidden: start from the pop-in pose. Reopening while a close
    # animation is still running: continue from its current values so there
    # is no visual jump.
    if not was_closing:
        if _scrim != null:
            _scrim.modulate.a = 0.0
        if window != null:
            window.scale = Vector2(0.96, 0.96)
            window.modulate.a = 1.0
    _play_open_animation()


func _play_open_animation() -> void:
    _kill_tween(_open_tween)
    _open_tween = create_tween()
    _open_tween.set_parallel(true)
    if _scrim != null:
        _open_tween.tween_property(_scrim, "modulate:a", 1.0, 0.15)
    if window != null:
        window.pivot_offset = _window_pivot()
        _open_tween.tween_property(window, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _open_tween.tween_property(window, "modulate:a", 1.0, 0.12)


func _kill_tween(tween: Tween) -> void:
    if tween != null and tween.is_valid():
        tween.kill()


func _window_pivot() -> Vector2:
    if window == null:
        return Vector2.ZERO
    var target := window.size
    if target.x <= 0.0:
        target.x = window.custom_minimum_size.x
    if target.y <= 0.0:
        target.y = window.custom_minimum_size.y
    return target * 0.5

func close() -> void:
    _request_close()

func is_closing() -> bool:
    return _closing

# ------------------------------------------------------------- internals ----
func _build_shell() -> void:
    _scrim = UIKit.scrim(0.6)
    _scrim.gui_input.connect(_on_scrim_gui_input)
    add_child(_scrim)

    _center = CenterContainer.new()
    _center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_center)

    var shell := UIKit.build_modal(_modal_title(), _fit_modal_size(_modal_size()), _modal_icon())
    window = shell.root
    header = shell.header
    content = shell.content
    footer = shell.footer
    _center.add_child(window)

func _finish_shell() -> void:
    header.add_child(UIKit.close_button(_request_close))
    if show_footer_close:
        var close_button := UIKit.button(LocaleData.text("close"), "GhostButton", Vector2(120, 38))
        close_button.pressed.connect(_request_close)
        footer.add_child(close_button)

## Re-fits the window whenever the (logical) viewport changes, e.g. after the
## UI-scale slider or a window resize.
func _on_viewport_resized() -> void:
    if window == null:
        return
    var fitted := _fit_modal_size(_modal_size())
    if window.custom_minimum_size != fitted:
        window.custom_minimum_size = fitted
        window.pivot_offset = fitted * 0.5


## Never let a window grow past the viewport - a large UI scale on a small
## window used to push the header/footer off screen.
func _fit_modal_size(size_hint: Vector2) -> Vector2:
    var view_size := get_viewport_rect().size
    return Vector2(
        minf(size_hint.x, maxf(view_size.x - 32.0, 320.0)),
        minf(size_hint.y, maxf(view_size.y - 32.0, 240.0))
    )


func _request_close() -> void:
    if _closing:
        return
    _closing = true
    _kill_tween(_open_tween)
    AudioManager.play_ui_click()
    _on_close()
    close_requested.emit()

    _kill_tween(_close_tween)
    if not is_inside_tree():
        _after_close()
        return
    _close_tween = create_tween()
    _close_tween.set_parallel(true)
    if _scrim != null:
        _close_tween.tween_property(_scrim, "modulate:a", 0.0, 0.12)
    if window != null:
        window.pivot_offset = _window_pivot()
        _close_tween.tween_property(window, "scale", Vector2(0.97, 0.97), 0.12)
        _close_tween.tween_property(window, "modulate:a", 0.0, 0.12)
    _close_tween.chain().tween_callback(_after_close)


func _after_close() -> void:
    _closing = false
    visible = false
    _close_tween = null
    if window != null:
        window.scale = Vector2.ONE
        window.modulate.a = 1.0
    if _scrim != null:
        _scrim.modulate.a = 1.0

func _on_scrim_gui_input(event: InputEvent) -> void:
    if not close_on_scrim_click:
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
            _request_close()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or _closing:
        return
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _request_close()

# ------------------------------------------------------- subclass hooks -----
func _modal_title() -> String:
    return ""

func _modal_size() -> Vector2:
    return Vector2(720, 560)

func _modal_icon() -> String:
    return ""

func _build_content() -> void:
    pass

func _on_open() -> void:
    pass

func _on_close() -> void:
    pass