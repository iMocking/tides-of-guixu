extends UiOverlay
class_name GameMenu
## In-game pause menu opened with Esc. Settings remain a separate panel.

signal resume_requested
signal main_menu_requested
signal settings_requested
signal quit_requested

func _modal_title() -> String:
    return LocaleData.text("game_menu")

func _modal_size() -> Vector2:
    return Vector2(440, 390)

func _build_content() -> void:
    close_on_scrim_click = false
    show_footer_close = false

    var buttons := UIKit.vbox(10)
    buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(buttons)

    _menu_button(buttons, "ResumeButton", LocaleData.text("return_to_game"), "MenuPlaquePrimary", _on_resume_pressed)
    _menu_button(buttons, "MainMenuButton", LocaleData.text("return_to_main_menu"), "MenuPlaqueButton", _on_main_menu_pressed)
    _menu_button(buttons, "GameSettingsButton", LocaleData.text("game_settings"), "MenuPlaqueButton", _on_settings_pressed)
    _menu_button(buttons, "QuitButton", LocaleData.text("quit"), "MenuPlaqueButton", _on_quit_pressed)

func _menu_button(parent: VBoxContainer, node_name: String, text: String, variation: String, callable: Callable) -> Button:
    var button := UIKit.button(text, variation, Vector2(300, 48))
    button.name = node_name
    button.pressed.connect(callable)
    parent.add_child(button)
    return button

func _unhandled_input(_event: InputEvent) -> void:
    # ESC is handled centrally by GameUI. Returning without consuming the
    # event keeps repeated ESC presses toggling the menu even while the close
    # animation is still running.
    pass

func _on_resume_pressed() -> void:
    AudioManager.play_ui_confirm()
    resume_requested.emit()

func _on_main_menu_pressed() -> void:
    AudioManager.play_ui_click()
    main_menu_requested.emit()

func _on_settings_pressed() -> void:
    AudioManager.play_ui_click()
    settings_requested.emit()

func _on_quit_pressed() -> void:
    AudioManager.play_ui_click()
    quit_requested.emit()
