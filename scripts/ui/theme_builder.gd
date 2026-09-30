class_name ThemeBuilder
## Central UI design system.
##
## Every screen (main menu, HUD, inventory, settings, achievements ...) pulls its
## colors, style boxes and type variations from here so the whole game shares one
## dark-xianxia look. Everything is generated at runtime, so the project keeps
## working without external UI assets.

# --------------------------------------------------------------- palette ----
## Surfaces are deliberately translucent so the world stays visible behind the
## interface; the HUD panels are the most see-through, windows stay readable.
const BG_DEEP := Color(0.031, 0.043, 0.067)
const BG_PANEL := Color(0.055, 0.073, 0.108, 0.86)
const BG_PANEL_SOFT := Color(0.078, 0.102, 0.141, 0.72)
const BG_SLOT := Color(0.086, 0.112, 0.153, 0.68)
const BG_HUD := Color(0.043, 0.059, 0.090, 0.55)
const BG_HUD_STRONG := Color(0.047, 0.063, 0.094, 0.66)
const BG_RAISED := Color(0.105, 0.137, 0.180, 0.84)
const BG_TRACK := Color(0.027, 0.039, 0.055, 0.72)
## Plate-free HUD surface: a whisper of ink so text keeps its grouping without a
## black card behind it.
const BG_GLASS := Color(0.020, 0.030, 0.045, 0.16)

const BORDER := Color(0.318, 0.510, 0.478, 0.85)
const BORDER_SOFT := Color(0.216, 0.318, 0.353, 0.72)
const BORDER_GOLD := Color(0.784, 0.639, 0.318, 0.85)
const BORDER_MUTED := Color(0.196, 0.231, 0.243, 0.7)

const GOLD := Color(1.0, 0.847, 0.443)
const GOLD_DIM := Color(0.749, 0.612, 0.310)
const JADE := Color(0.541, 0.929, 0.706)
const JADE_DIM := Color(0.451, 0.694, 0.616)
const TEXT := Color(0.898, 0.929, 0.918)
const TEXT_DIM := Color(0.702, 0.769, 0.741)
const TEXT_MUTED := Color(0.463, 0.537, 0.522)
const DANGER := Color(0.878, 0.451, 0.420)

const HEALTH_COLOR := Color(0.847, 0.376, 0.396)
const QI_COLOR := Color(0.376, 0.706, 0.941)
const CULTIVATION_COLOR := Color(0.898, 0.729, 0.341)

const RADIUS := 8
const RADIUS_SMALL := 5

static var _shared: Theme = null

# ------------------------------------------------------------- factories ----
static func shared_theme() -> Theme:
    if _shared == null:
        _shared = make_theme()
    return _shared

static func make_theme() -> Theme:
    var theme := Theme.new()
    var font := body_font()
    if font != null:
        theme.default_font = font
    theme.default_font_size = 16
    _setup_panels(theme)
    _setup_labels(theme)
    _setup_buttons(theme)
    _setup_bars(theme)
    _setup_inputs(theme)
    _setup_scroll(theme)
    _setup_misc(theme)
    return theme

static func body_font() -> Font:
    var resource := load("res://assets/fonts/HarmonyOS_Sans_SC.ttf")
    if resource is Font:
        return resource
    return ThemeDB.fallback_font

static func gold_color() -> Color:
    return GOLD

static func jade_color() -> Color:
    return JADE

## Generic flat box helper shared by the theme and by per-widget overrides.
static func flat_box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = RADIUS, border_width: int = 1, pad_h: float = 0.0, pad_v: float = 0.0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(border_width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = pad_h
    box.content_margin_right = pad_h
    box.content_margin_top = pad_v
    box.content_margin_bottom = pad_v
    return box

static func panel_box(bg: Color, border: Color = BORDER_SOFT, radius: int = RADIUS, border_width: int = 1) -> StyleBoxFlat:
    return flat_box(bg, border, radius, border_width, 0.0, 0.0)

## Shared look for floating 3D labels (names, damage numbers ...) so the world
## text matches the 2D UI.
static func style_world_label(label: Label3D, size: int, color: Color, outline: int = 6) -> void:
    label.font = body_font()
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = size
    label.modulate = color
    label.outline_size = outline
    label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
    label.render_priority = 1

## Soft drop shadow so a translucent surface keeps its edges over bright terrain.
static func with_shadow(box: StyleBoxFlat, size: int = 6, alpha: float = 0.38) -> StyleBoxFlat:
    box.shadow_color = Color(0.0, 0.0, 0.0, alpha)
    box.shadow_size = size
    box.shadow_offset = Vector2(0.0, 2.0)
    return box


static func line_box(color: Color, thickness: int = 1) -> StyleBoxLine:
    var line := StyleBoxLine.new()
    line.color = color
    line.thickness = thickness
    line.grow_begin = 0.0
    line.grow_end = 0.0
    return line

# ------------------------------------------------------------ panels ---------
static func _setup_panels(theme: Theme) -> void:
    var modal := panel_box(BG_PANEL, BORDER, 10, 1)
    theme.set_stylebox("panel", "PanelContainer", panel_box(BG_PANEL, BORDER_SOFT, RADIUS, 1))
    theme.set_stylebox("panel", "Panel", panel_box(BG_PANEL, BORDER_SOFT, RADIUS, 1))
    theme.set_stylebox("panel", "PopupPanel", modal)
    theme.set_stylebox("panel", "TooltipPanel", with_shadow(flat_box(Color(0.031, 0.047, 0.067, 0.9), BORDER_SOFT, 6, 1, 10.0, 6.0), 5, 0.4))

    theme.set_type_variation("ModalPanel", "PanelContainer")
    theme.set_stylebox("panel", "ModalPanel", with_shadow(modal, 10, 0.45))

    theme.set_type_variation("HUDPanel", "PanelContainer")
    theme.set_stylebox("panel", "HUDPanel", with_shadow(panel_box(BG_HUD, BORDER_SOFT, 7, 1)))

    # Plate-free HUD surfaces: just a faint ink tint, no border, no shadow.
    theme.set_type_variation("GlassPanel", "PanelContainer")
    theme.set_stylebox("panel", "GlassPanel", flat_box(BG_GLASS, Color(0, 0, 0, 0), 4, 0, 10.0, 8.0))

    # Combat log: the same tint plus a jade accent rule on the left.
    theme.set_type_variation("LogPanel", "PanelContainer")
    var log_box := flat_box(BG_GLASS, Color(0, 0, 0, 0), 4, 0, 10.0, 8.0)
    log_box.border_width_left = 3
    log_box.border_color = Color(JADE_DIM.r, JADE_DIM.g, JADE_DIM.b, 0.42)
    theme.set_stylebox("panel", "LogPanel", log_box)

    theme.set_type_variation("CardPanel", "PanelContainer")
    theme.set_stylebox("panel", "CardPanel", panel_box(BG_PANEL_SOFT, BORDER_SOFT, 7, 1))

    theme.set_type_variation("CardPanelAccent", "PanelContainer")
    theme.set_stylebox("panel", "CardPanelAccent", panel_box(BG_PANEL_SOFT, BORDER_GOLD, 7, 1))

    theme.set_type_variation("ToastPanel", "PanelContainer")
    theme.set_stylebox("panel", "ToastPanel", with_shadow(flat_box(BG_HUD_STRONG, BORDER_GOLD, 16, 1, 20.0, 9.0)))

    var quest := with_shadow(panel_box(Color(0.043, 0.059, 0.090, 0.58), BORDER_GOLD, 7, 1))
    quest.border_width_left = 3
    quest.content_margin_left = 12.0
    quest.content_margin_right = 10.0
    quest.content_margin_top = 8.0
    quest.content_margin_bottom = 8.0
    theme.set_type_variation("QuestPanel", "PanelContainer")
    theme.set_stylebox("panel", "QuestPanel", quest)

    theme.set_stylebox("panel", "PopupMenu", panel_box(BG_PANEL, BORDER, 8, 1))
    theme.set_stylebox("hover", "PopupMenu", panel_box(BG_RAISED, Color(0, 0, 0, 0), 4, 0))
    theme.set_stylebox("separator", "PopupMenu", line_box(BORDER_MUTED, 1))
    theme.set_stylebox("labeled_separator_left", "PopupMenu", line_box(BORDER_MUTED, 1))
    theme.set_stylebox("labeled_separator_right", "PopupMenu", line_box(BORDER_MUTED, 1))
    theme.set_font_size("font_size", "PopupMenu", 15)
    theme.set_color("font_color", "PopupMenu", TEXT_DIM)
    theme.set_color("font_hover_color", "PopupMenu", GOLD)
    theme.set_color("font_disabled_color", "PopupMenu", Color(0.40, 0.44, 0.44))
    theme.set_color("font_separator_color", "PopupMenu", TEXT_MUTED)

    var portrait := panel_box(Color(0.086, 0.157, 0.153, 0.95), BORDER, 40, 2)
    theme.set_type_variation("PortraitPanel", "PanelContainer")
    theme.set_stylebox("panel", "PortraitPanel", portrait)

# ------------------------------------------------------------ labels ---------
static func _setup_labels(theme: Theme) -> void:
    theme.set_color("font_color", "Label", TEXT)
    theme.set_color("font_color", "RichTextLabel", TEXT)
    theme.set_color("default_color", "RichTextLabel", TEXT_DIM)
    theme.set_color("font_color", "TooltipLabel", TEXT)
    theme.set_font_size("font_size", "TooltipLabel", 14)
    theme.set_color("font_color", "LinkButton", JADE)
    theme.set_color("font_hover_color", "LinkButton", GOLD)

    _label_variation(theme, "MenuTitleLabel", 76, GOLD)
    _label_variation(theme, "HeroLabel", 56, GOLD)
    _label_variation(theme, "TitleLabel", 26, GOLD)
    _label_variation(theme, "HeadingLabel", 20, JADE)
    _label_variation(theme, "SectionLabel", 15, JADE_DIM)
    _label_variation(theme, "StatLabel", 16, TEXT_DIM)
    _label_variation(theme, "ValueLabel", 16, TEXT)
    _label_variation(theme, "GoldValueLabel", 17, GOLD)
    _label_variation(theme, "MutedLabel", 14, TEXT_MUTED)
    _label_variation(theme, "HintLabel", 13, TEXT_MUTED)
    _label_variation(theme, "DangerLabel", 16, DANGER)

static func _label_variation(theme: Theme, variation: String, size: int, color: Color) -> void:
    theme.set_type_variation(variation, "Label")
    theme.set_font_size("font_size", variation, size)
    theme.set_color("font_color", variation, color)

# ----------------------------------------------------------- buttons ---------
static func _setup_buttons(theme: Theme) -> void:
    var normal := flat_box(BG_RAISED, BORDER_SOFT, 6, 1, 16.0, 8.0)
    var hover := flat_box(BG_RAISED.lightened(0.12), JADE_DIM, 6, 1, 16.0, 8.0)
    var pressed := flat_box(Color(0.078, 0.184, 0.176, 0.98), JADE, 6, 1, 16.0, 8.0)
    var disabled := flat_box(Color(0.086, 0.098, 0.114, 0.72), BORDER_MUTED, 6, 1, 16.0, 8.0)
    var focus := flat_box(Color(0, 0, 0, 0), JADE, 6, 1, 16.0, 8.0)

    theme.set_stylebox("normal", "Button", normal)
    theme.set_stylebox("hover", "Button", hover)
    theme.set_stylebox("pressed", "Button", pressed)
    theme.set_stylebox("disabled", "Button", disabled)
    theme.set_stylebox("focus", "Button", focus)
    theme.set_font_size("font_size", "Button", 16)
    theme.set_color("font_color", "Button", TEXT)
    theme.set_color("font_hover_color", "Button", Color(0.96, 1.0, 0.96))
    theme.set_color("font_pressed_color", "Button", JADE)
    theme.set_color("font_disabled_color", "Button", Color(0.42, 0.46, 0.46))
    theme.set_color("font_focus_color", "Button", TEXT)

    _button_variation(theme, "PrimaryButton", Color(0.216, 0.169, 0.082), BORDER_GOLD, GOLD, GOLD, 17.0, 9.0)
    _button_variation(theme, "DangerButton", Color(0.208, 0.098, 0.106), DANGER, DANGER, DANGER, 16.0, 8.0)
    _button_variation(theme, "HUDButton", BG_HUD, BORDER_SOFT, JADE, JADE, 15.0, 6.0)
    _button_variation(theme, "SkillButton", BG_PANEL, BORDER, JADE, GOLD, 15.0, 8.0)

    # Transparent button used for quiet actions (close buttons, footer links ...).
    theme.set_type_variation("GhostButton", "Button")
    theme.set_stylebox("normal", "GhostButton", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 6, 0, 14.0, 7.0))
    theme.set_stylebox("hover", "GhostButton", flat_box(BG_PANEL_SOFT, BORDER_SOFT, 6, 1, 14.0, 7.0))
    theme.set_stylebox("pressed", "GhostButton", flat_box(BG_RAISED, BORDER, 6, 1, 14.0, 7.0))
    theme.set_stylebox("disabled", "GhostButton", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 6, 0, 14.0, 7.0))
    theme.set_stylebox("focus", "GhostButton", flat_box(Color(0, 0, 0, 0), JADE, 6, 1, 14.0, 7.0))
    theme.set_font_size("font_size", "GhostButton", 15)
    theme.set_color("font_color", "GhostButton", TEXT_DIM)
    theme.set_color("font_hover_color", "GhostButton", JADE)
    theme.set_color("font_pressed_color", "GhostButton", JADE)
    theme.set_color("font_disabled_color", "GhostButton", Color(0.36, 0.40, 0.40))

    # Small square button for the window "x".
    theme.set_type_variation("IconButton", "Button")
    theme.set_stylebox("normal", "IconButton", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 5, 0, 4.0, 0.0))
    theme.set_stylebox("hover", "IconButton", flat_box(Color(0.45, 0.16, 0.16, 0.85), DANGER, 5, 1, 4.0, 0.0))
    theme.set_stylebox("pressed", "IconButton", flat_box(Color(0.34, 0.11, 0.11, 0.95), DANGER, 5, 1, 4.0, 0.0))
    theme.set_stylebox("focus", "IconButton", flat_box(Color(0, 0, 0, 0), DANGER, 5, 1, 4.0, 0.0))
    theme.set_font_size("font_size", "IconButton", 20)
    theme.set_color("font_color", "IconButton", TEXT_MUTED)
    theme.set_color("font_hover_color", "IconButton", Color(1.0, 0.88, 0.88))
    theme.set_color("font_pressed_color", "IconButton", DANGER)

    # Pill shaped toggle chip used by the inventory filter row.
    theme.set_type_variation("ChipButton", "Button")
    theme.set_stylebox("normal", "ChipButton", flat_box(Color(0, 0, 0, 0), BORDER_SOFT, 13, 1, 12.0, 4.0))
    theme.set_stylebox("hover", "ChipButton", flat_box(BG_PANEL_SOFT, JADE_DIM, 13, 1, 12.0, 4.0))
    theme.set_stylebox("pressed", "ChipButton", flat_box(Color(JADE.r, JADE.g, JADE.b, 0.18), JADE, 13, 1, 12.0, 4.0))
    theme.set_stylebox("disabled", "ChipButton", flat_box(Color(0, 0, 0, 0), BORDER_MUTED, 13, 1, 12.0, 4.0))
    theme.set_stylebox("focus", "ChipButton", flat_box(Color(0, 0, 0, 0), JADE, 13, 1, 12.0, 4.0))
    theme.set_font_size("font_size", "ChipButton", 14)
    theme.set_color("font_color", "ChipButton", TEXT_DIM)
    theme.set_color("font_hover_color", "ChipButton", TEXT)
    theme.set_color("font_pressed_color", "ChipButton", JADE)
    theme.set_color("font_disabled_color", "ChipButton", Color(0.38, 0.42, 0.42))

    # Title-screen plaque: dark ink tablet with a bronze hairline, square-ish.
    theme.set_type_variation("MenuPlaqueButton", "Button")
    theme.set_stylebox("normal", "MenuPlaqueButton", flat_box(Color(0.055, 0.058, 0.072, 0.74), Color(0.60, 0.52, 0.30, 0.70), 3, 1, 22.0, 11.0))
    theme.set_stylebox("hover", "MenuPlaqueButton", flat_box(Color(0.100, 0.096, 0.100, 0.88), Color(0.92, 0.79, 0.47, 0.95), 3, 1, 22.0, 11.0))
    theme.set_stylebox("pressed", "MenuPlaqueButton", flat_box(Color(0.036, 0.042, 0.050, 0.94), Color(0.60, 0.85, 0.72, 0.95), 3, 1, 22.0, 11.0))
    theme.set_stylebox("disabled", "MenuPlaqueButton", flat_box(Color(0.040, 0.044, 0.052, 0.50), Color(0.32, 0.32, 0.32, 0.55), 3, 1, 22.0, 11.0))
    theme.set_stylebox("focus", "MenuPlaqueButton", flat_box(Color(0, 0, 0, 0), Color(0.92, 0.79, 0.47, 0.75), 3, 1, 22.0, 11.0))
    theme.set_font_size("font_size", "MenuPlaqueButton", 20)
    theme.set_color("font_color", "MenuPlaqueButton", Color(0.906, 0.886, 0.827))
    theme.set_color("font_hover_color", "MenuPlaqueButton", GOLD)
    theme.set_color("font_pressed_color", "MenuPlaqueButton", JADE)
    theme.set_color("font_disabled_color", "MenuPlaqueButton", Color(0.42, 0.42, 0.42))

    theme.set_type_variation("MenuPlaquePrimary", "Button")
    theme.set_stylebox("normal", "MenuPlaquePrimary", flat_box(Color(0.115, 0.098, 0.062, 0.80), Color(0.80, 0.67, 0.38, 0.90), 3, 1, 22.0, 11.0))
    theme.set_stylebox("hover", "MenuPlaquePrimary", flat_box(Color(0.170, 0.140, 0.078, 0.90), GOLD, 3, 1, 22.0, 11.0))
    theme.set_stylebox("pressed", "MenuPlaquePrimary", flat_box(Color(0.090, 0.076, 0.046, 0.95), Color(0.60, 0.85, 0.72, 0.95), 3, 1, 22.0, 11.0))
    theme.set_stylebox("disabled", "MenuPlaquePrimary", flat_box(Color(0.055, 0.052, 0.044, 0.50), Color(0.34, 0.32, 0.24, 0.55), 3, 1, 22.0, 11.0))
    theme.set_stylebox("focus", "MenuPlaquePrimary", flat_box(Color(0, 0, 0, 0), GOLD, 3, 1, 22.0, 11.0))
    theme.set_font_size("font_size", "MenuPlaquePrimary", 20)
    theme.set_color("font_color", "MenuPlaquePrimary", GOLD)
    theme.set_color("font_hover_color", "MenuPlaquePrimary", Color(1.0, 0.94, 0.78))
    theme.set_color("font_pressed_color", "MenuPlaquePrimary", JADE)
    theme.set_color("font_disabled_color", "MenuPlaquePrimary", Color(0.46, 0.42, 0.34))

    # Ability slot: a League-style square icon frame - dark plate, crisp 1px
    # border (radius 0) that lights up on hover / press.
    theme.set_type_variation("SkillSlotButton", "Button")
    theme.set_stylebox("normal", "SkillSlotButton", flat_box(BG_SLOT, BORDER_SOFT, 0, 1, 3.0, 3.0))
    theme.set_stylebox("hover", "SkillSlotButton", flat_box(BG_RAISED, JADE, 0, 1, 3.0, 3.0))
    theme.set_stylebox("pressed", "SkillSlotButton", flat_box(Color(JADE.r, JADE.g, JADE.b, 0.24), JADE, 0, 1, 3.0, 3.0))
    theme.set_stylebox("disabled", "SkillSlotButton", flat_box(Color(0.063, 0.078, 0.098, 0.62), BORDER_MUTED, 0, 1, 3.0, 3.0))
    theme.set_stylebox("focus", "SkillSlotButton", flat_box(Color(0, 0, 0, 0), JADE, 0, 1, 3.0, 3.0))

    # Borderless icon button: no plate behind the glyph, only a soft hover hint.
    theme.set_type_variation("FlatIconButton", "Button")
    theme.set_stylebox("normal", "FlatIconButton", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS, 0, 6.0, 6.0))
    theme.set_stylebox("hover", "FlatIconButton", flat_box(Color(JADE.r, JADE.g, JADE.b, 0.13), Color(JADE.r, JADE.g, JADE.b, 0.45), RADIUS, 1, 6.0, 6.0))
    theme.set_stylebox("pressed", "FlatIconButton", flat_box(Color(JADE.r, JADE.g, JADE.b, 0.22), Color(JADE.r, JADE.g, JADE.b, 0.85), RADIUS, 1, 6.0, 6.0))
    theme.set_stylebox("disabled", "FlatIconButton", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS, 0, 6.0, 6.0))
    theme.set_stylebox("focus", "FlatIconButton", flat_box(Color(0, 0, 0, 0), Color(JADE.r, JADE.g, JADE.b, 0.6), RADIUS, 1, 6.0, 6.0))

    # Inventory slot: keeps the rarity color on the frame.
    theme.set_type_variation("ItemSlot", "Button")
    theme.set_stylebox("normal", "ItemSlot", flat_box(BG_SLOT, BORDER_SOFT, 6, 1, 4.0, 4.0))
    theme.set_stylebox("hover", "ItemSlot", flat_box(BG_RAISED, JADE, 6, 1, 4.0, 4.0))
    theme.set_stylebox("pressed", "ItemSlot", flat_box(Color(0.086, 0.176, 0.180, 0.98), JADE, 6, 1, 4.0, 4.0))
    theme.set_stylebox("focus", "ItemSlot", flat_box(Color(0, 0, 0, 0), GOLD, 6, 1, 4.0, 4.0))
    theme.set_font_size("font_size", "ItemSlot", 13)
    theme.set_color("font_color", "ItemSlot", TEXT)

static func _button_variation(theme: Theme, variation: String, bg: Color, border: Color, font: Color, hover_font: Color, size: float, pad_v: float) -> void:
    theme.set_type_variation(variation, "Button")
    theme.set_stylebox("normal", variation, flat_box(bg, border, 6, 1, 16.0, pad_v))
    theme.set_stylebox("hover", variation, flat_box(bg.lightened(0.16), hover_font, 6, 1, 16.0, pad_v))
    theme.set_stylebox("pressed", variation, flat_box(bg.darkened(0.18), font, 6, 1, 16.0, pad_v))
    theme.set_stylebox("disabled", variation, flat_box(Color(0.086, 0.098, 0.114, 0.72), BORDER_MUTED, 6, 1, 16.0, pad_v))
    theme.set_stylebox("focus", variation, flat_box(Color(0, 0, 0, 0), hover_font, 6, 1, 16.0, pad_v))
    theme.set_font_size("font_size", variation, int(size))
    theme.set_color("font_color", variation, font)
    theme.set_color("font_hover_color", variation, hover_font.lightened(0.25))
    theme.set_color("font_pressed_color", variation, font)
    theme.set_color("font_disabled_color", variation, Color(0.42, 0.44, 0.44))

# ------------------------------------------------------------- bars ---------
static func _setup_bars(theme: Theme) -> void:
    var bg := panel_box(BG_TRACK, Color(0.129, 0.176, 0.204, 0.85), 5, 1)
    theme.set_stylebox("background", "ProgressBar", bg)
    theme.set_stylebox("fill", "ProgressBar", panel_box(JADE, Color(0, 0, 0, 0), 4, 0))
    theme.set_font_size("font_size", "ProgressBar", 13)
    theme.set_color("font_color", "ProgressBar", Color(0.94, 0.95, 0.92))
    theme.set_color("font_outline_color", "ProgressBar", Color(0, 0, 0, 0.65))

    _bar_variation(theme, "HealthBar", HEALTH_COLOR)
    _bar_variation(theme, "QiBar", QI_COLOR)
    _bar_variation(theme, "CultivationBar", CULTIVATION_COLOR)

static func _bar_variation(theme: Theme, variation: String, color: Color) -> void:
    theme.set_type_variation(variation, "ProgressBar")
    var fill := panel_box(color, color.lightened(0.35), 4, 1)
    fill.border_width_top = 2
    theme.set_stylebox("fill", variation, fill)
    theme.set_stylebox("background", variation, panel_box(BG_TRACK, Color(0.129, 0.176, 0.204, 0.85), 5, 1))

# ------------------------------------------------------------ inputs --------
static func _setup_inputs(theme: Theme) -> void:
    var drop_normal := flat_box(BG_SLOT, BORDER_SOFT, 6, 1, 12.0, 6.0)
    var drop_hover := flat_box(BG_RAISED, JADE_DIM, 6, 1, 12.0, 6.0)
    var drop_pressed := flat_box(Color(0.078, 0.184, 0.176, 0.98), JADE, 6, 1, 12.0, 6.0)
    theme.set_stylebox("normal", "OptionButton", drop_normal)
    theme.set_stylebox("hover", "OptionButton", drop_hover)
    theme.set_stylebox("pressed", "OptionButton", drop_pressed)
    theme.set_stylebox("disabled", "OptionButton", flat_box(Color(0.086, 0.098, 0.114, 0.72), BORDER_MUTED, 6, 1, 12.0, 6.0))
    theme.set_stylebox("focus", "OptionButton", flat_box(Color(0, 0, 0, 0), JADE, 6, 1, 12.0, 6.0))
    theme.set_font_size("font_size", "OptionButton", 15)
    theme.set_color("font_color", "OptionButton", TEXT)
    theme.set_color("font_hover_color", "OptionButton", JADE)
    theme.set_color("font_pressed_color", "OptionButton", JADE)
    theme.set_color("font_disabled_color", "OptionButton", Color(0.42, 0.46, 0.46))
    theme.set_constant("arrow_margin", "OptionButton", 8)

    for checkbox in ["CheckBox", "CheckButton"]:
        theme.set_stylebox("normal", checkbox, flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS_SMALL, 0, 6.0, 5.0))
        theme.set_stylebox("hover", checkbox, flat_box(BG_PANEL_SOFT, BORDER_SOFT, RADIUS_SMALL, 1, 6.0, 5.0))
        theme.set_stylebox("pressed", checkbox, flat_box(BG_RAISED, BORDER, RADIUS_SMALL, 1, 6.0, 5.0))
        theme.set_stylebox("disabled", checkbox, flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS_SMALL, 0, 6.0, 5.0))
        theme.set_stylebox("focus", checkbox, flat_box(Color(0, 0, 0, 0), JADE, RADIUS_SMALL, 1, 6.0, 5.0))
        theme.set_color("font_color", checkbox, TEXT_DIM)
        theme.set_color("font_hover_color", checkbox, TEXT)
        theme.set_color("font_pressed_color", checkbox, JADE)
        theme.set_color("font_disabled_color", checkbox, Color(0.38, 0.42, 0.42))
        theme.set_color("font_focus_color", checkbox, TEXT)

    var track := flat_box(BG_TRACK, Color(0.16, 0.21, 0.24, 0.9), 4, 1, 0.0, 4.0)
    var filled := flat_box(JADE.darkened(0.15), Color(0, 0, 0, 0), 4, 0, 0.0, 4.0)
    var filled_hi := flat_box(JADE, Color(0, 0, 0, 0), 4, 0, 0.0, 4.0)
    for slider in ["HSlider", "VSlider"]:
        theme.set_stylebox("slider", slider, track)
        theme.set_stylebox("grabber_area", slider, filled)
        theme.set_stylebox("grabber_area_highlight", slider, filled_hi)

    var field := flat_box(BG_TRACK, BORDER_SOFT, 6, 1, 10.0, 6.0)
    theme.set_stylebox("normal", "LineEdit", field)
    theme.set_stylebox("focus", "LineEdit", flat_box(BG_TRACK, JADE, 6, 1, 10.0, 6.0))
    theme.set_color("font_color", "LineEdit", TEXT)
    theme.set_color("caret_color", "LineEdit", JADE)
    theme.set_color("selection_color", "LineEdit", Color(0.30, 0.55, 0.50, 0.6))

# ----------------------------------------------------------- scrolling ------
static func _setup_scroll(theme: Theme) -> void:
    for scrollbar in ["VScrollBar", "HScrollBar"]:
        theme.set_stylebox("scroll", scrollbar, panel_box(BG_TRACK, Color(0, 0, 0, 0), 4, 0))
        theme.set_stylebox("grabber", scrollbar, panel_box(BORDER_SOFT, Color(0, 0, 0, 0), 4, 0))
        theme.set_stylebox("grabber_highlight", scrollbar, panel_box(JADE_DIM, Color(0, 0, 0, 0), 4, 0))
        theme.set_stylebox("grabber_pressed", scrollbar, panel_box(JADE, Color(0, 0, 0, 0), 4, 0))
    theme.set_stylebox("panel", "ScrollContainer", flat_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))

# --------------------------------------------------------------- misc -------
static func _setup_misc(theme: Theme) -> void:
    theme.set_stylebox("separator", "HSeparator", line_box(BORDER_MUTED, 1))
    theme.set_stylebox("separator", "VSeparator", line_box(BORDER_MUTED, 1))
    theme.set_constant("separation", "HSeparator", 0)
    theme.set_constant("separation", "VSeparator", 0)