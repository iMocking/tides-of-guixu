extends UiOverlay
class_name DeathPanel
## Death settlement window: revive in place with an item, or return to spawn.

signal revive_in_place_requested
signal revive_at_spawn_requested

const REVIVE_ITEM_ID := "consumable_huanhun"

var _revive_button: Button
var _item_label: Label


func _modal_title() -> String:
    return LocaleData.text("death_title")


func _modal_icon() -> String:
    return "heart"


func _modal_size() -> Vector2:
    return Vector2(540, 390)


func _build_content() -> void:
    close_on_scrim_click = false
    show_footer_close = false

    var message := UIKit.wrapped_label(LocaleData.text("death_desc"), "MutedLabel")
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.custom_minimum_size = Vector2(420, 70)
    content.add_child(message)

    _item_label = UIKit.value("")
    _item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(_item_label)

    content.add_child(UIKit.spacer(false, false, Vector2(0, 8)))

    _revive_button = UIKit.button("", "PrimaryButton", Vector2(340, 50))
    _revive_button.pressed.connect(_on_revive_in_place_pressed)
    content.add_child(_revive_button)

    var spawn_button := UIKit.button(LocaleData.text("revive_at_spawn"), "", Vector2(340, 50))
    spawn_button.pressed.connect(_on_revive_at_spawn_pressed)
    content.add_child(spawn_button)

    refresh()


func refresh() -> void:
    var count := GameState.count_item(REVIVE_ITEM_ID)
    var item_name := GameData.item_name(REVIVE_ITEM_ID)
    if _item_label != null:
        _item_label.text = "%s  x%d" % [item_name, count]
    if _revive_button != null:
        _revive_button.disabled = count <= 0
        if count > 0:
            _revive_button.text = "%s  (%s x1)" % [LocaleData.text("revive_in_place"), item_name]
        else:
            _revive_button.text = "%s  (%s)" % [LocaleData.text("revive_in_place"), LocaleData.text("revive_no_item")]


func _on_open() -> void:
    refresh()


func _on_revive_in_place_pressed() -> void:
    if GameState.count_item(REVIVE_ITEM_ID) <= 0:
        refresh()
        return
    revive_in_place_requested.emit()


func _on_revive_at_spawn_pressed() -> void:
    revive_at_spawn_requested.emit()


func _finish_shell() -> void:
    # Death must be resolved through one of the two options; do not add the
    # usual header close button.
    pass


func _unhandled_input(_event: InputEvent) -> void:
    # Death panel cannot be dismissed with ESC.
    pass
