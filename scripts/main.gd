extends Node
## Application root: switches between the main menu and the playable world.

func _ready() -> void:
    _configure_window()
    _show_main_menu()
    if OS.get_cmdline_user_args().has("--auto-start"):
        call_deferred("_start_new_game")
    if OS.get_cmdline_user_args().has("--auto-continue"):
        call_deferred("_continue_game")

func _clear_screen() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    for child in get_children():
        child.queue_free()

func _show_main_menu() -> void:
    _clear_screen()
    var menu := MainMenu.new()
    menu.name = "MainMenu"
    menu.new_game_requested.connect(_start_new_game)
    menu.continue_requested.connect(_continue_game)
    menu.quit_requested.connect(_quit_game)
    add_child(menu)

func _start_new_game() -> void:
    GameState.start_new_game()
    _start_world()

func _continue_game() -> void:
    if not GameState.load_game():
        _show_main_menu()
        return
    _start_world()

func _start_world() -> void:
    _clear_screen()
    var world := GameWorld.new()
    world.name = "GameWorld"
    add_child(world)
    var ui := GameUI.new()
    ui.name = "GameUI"
    add_child(ui)
    await get_tree().process_frame
    ui.set_player(world.get_player())

func _quit_game() -> void:
    get_tree().quit()

## Renders straight into the OS window: the viewport always matches the window
## size, so the content keeps filling the frame while the player resizes / maximises
## the window (no letterbox bars, no fixed render resolution).
func _configure_window() -> void:
    var window := get_window()
    if window == null:
        return
    window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    window.content_scale_size = Vector2i.ZERO
    # Keep a sane lower bound for the fixed-size HUD; never collapse to zero.
    var min_size := Vector2i(960, 540)
    if window.min_size != min_size:
        window.min_size = min_size
