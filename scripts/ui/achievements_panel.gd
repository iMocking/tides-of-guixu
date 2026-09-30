extends UiOverlay
class_name AchievementsPanel
## Achievements overlay: summary bar plus one card per achievement.

var _list: VBoxContainer
var _summary: Label
var _progress: ProgressBar

func _modal_title() -> String:
    return LocaleData.text("achievements")

func _modal_size() -> Vector2:
    return Vector2(780, 620)

func _modal_icon() -> String:
    return "trophy"

func _build_content() -> void:
    _summary = UIKit.label("", "GoldValueLabel")
    header.add_child(_summary)

    _progress = ProgressBar.new()
    _progress.theme_type_variation = "CultivationBar"
    _progress.show_percentage = false
    _progress.custom_minimum_size = Vector2(0, 8)
    _progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_child(_progress)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(scroll)

    _list = UIKit.vbox(8)
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_list)

func _on_open() -> void:
    _refresh()

func _refresh() -> void:
    for child in _list.get_children():
        _list.remove_child(child)
        child.queue_free()

    var unlocked := 0
    var entries := GameData.achievement_list()
    for ach in entries:
        var is_unlocked := GameState.is_achievement_unlocked(str(ach.get("id", "")))
        if is_unlocked:
            unlocked += 1
        _list.add_child(_make_row(ach, is_unlocked))

    _summary.text = LocaleData.text("achievement_summary") % [unlocked, entries.size()]
    _progress.max_value = maxf(float(entries.size()), 1.0)
    _progress.value = float(unlocked)

func _make_row(ach: Dictionary, unlocked: bool) -> PanelContainer:
    var accent := ThemeBuilder.GOLD_DIM if unlocked else ThemeBuilder.BORDER_MUTED
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel", UIKit.card_box(accent))
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var line := UIKit.hbox(12)
    row.add_child(line)

    var state_color := ThemeBuilder.GOLD if unlocked else ThemeBuilder.TEXT_MUTED
    var badge := UIKit.pill(LocaleData.text("unlocked") if unlocked else LocaleData.text("locked"), state_color)
    badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    line.add_child(badge)

    var text_box := UIKit.vbox(4)
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.add_child(text_box)

    var name_label := UIKit.label(str(ach.get("name", ach.get("id", ""))), "ValueLabel")
    if unlocked:
        name_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
    text_box.add_child(name_label)
    text_box.add_child(UIKit.wrapped_label(str(ach.get("desc", "")), "MutedLabel"))

    var progress_label := UIKit.label(GameState.get_achievement_progress_text(ach), "HintLabel")
    progress_label.custom_minimum_size = Vector2(96, 0)
    progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    progress_label.add_theme_color_override("font_color", state_color)
    line.add_child(progress_label)

    return row