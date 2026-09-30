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

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    theme = ThemeBuilder.shared_theme()
    _build_shell()
    _build_content()
    _finish_shell()
    visible = false

func open() -> void:
    if visible and not _closing:
        _on_open()
        return
    _closing = false
    _on_open()
    visible = true
    if _scrim != null:
        _scrim.modulate.a = 0.0
        var tween := create_tween()
        tween.tween_property(_scrim, "modulate:a", 1.0, 0.15)
    UIKit.pop_in(window)

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

    var shell := UIKit.build_modal(_modal_title(), _modal_size(), _modal_icon())
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

func _request_close() -> void:
    if _closing:
        return
    _closing = true
    AudioManager.play_ui_click()
    _on_close()
    close_requested.emit()
    if _scrim != null and _scrim.is_inside_tree():
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(_scrim, "modulate:a", 0.0, 0.12)
        tween.chain().tween_callback(_after_close)
    else:
        _after_close()
    UIKit.pop_out(window)

func _after_close() -> void:
    _closing = false
    visible = false

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