extends Node
## Global game state: character, inventory, equipment, achievements, calendar and save data.

const SAVE_PATH := "user://tides_of_guixu_save.json"
## Hold this action to show the cursor without leaving the mouse lock.
const PEEK_ACTION := "peek_cursor"
## Default name used before 陈梦飞 was introduced; saves still carrying it
## are upgraded on load (see load_game).
const LEGACY_DEFAULT_PLAYER_NAME := "无名散修"
const SETTINGS_PATH := "user://tides_of_guixu_settings.cfg"
const INVENTORY_SIZE := 40

const DEFAULT_EQUIPMENT := {
    "weapon": "", "head": "", "body": "", "legs": "", "boots": "",
    "bracers": "", "accessory": "", "talisman": "",
}

const DEFAULT_SETTINGS := {
    # --- camera / controls ---
    "camera_mode": 0,
    "mouse_sensitivity": 0.0025,
    "invert_y": false,
    "camera_fov": 55.0,
    "camera_rotate_speed": 110.0,
    "gamepad_rumble": true,
    # --- display ---
    "fullscreen": false,
    "resolution_index": 0,
    "ui_scale": 1.0,
    "vsync": 1,                  # 0 off / 1 on / 2 adaptive
    "fps_limit": 1,              # index into FPS_OPTIONS
    "msaa": 0,                   # index into MSAA_OPTIONS
    "shadows": true,
    "brightness": 1.2,
    "screen_filter": 0,          # index into FILTER_OPTIONS
    "fog": true,
    "time_scale": 0.4,           # game minutes per real second (1440 / 0.4 = 3600s = 1h/day)
    "combat_fx": 2,              # index into COMBAT_FX_OPTIONS
    "show_damage_numbers": true,
    "enemy_health_bars": true,
    "quest_tracker": true,
    # --- audio ---
    "master_volume_db": -6.0,
    "sfx_volume_db": -4.0,
    "music_volume_db": -14.0,
}

## Keyboard defaults; the settings panel can rebind any entry in BINDABLE_ACTIONS.
const DEFAULT_KEYS := {
    "move_forward": [KEY_W, KEY_UP],
    "move_back": [KEY_S, KEY_DOWN],
    "move_left": [KEY_A, KEY_LEFT],
    "move_right": [KEY_D, KEY_RIGHT],
    "jump": [KEY_SPACE],
    "dodge": [KEY_SHIFT],
    "interact": [KEY_F],
    "toggle_inventory": [KEY_TAB, KEY_I],
    "toggle_character": [KEY_C],
    "toggle_achievements": [KEY_K],
    "toggle_fashion": [KEY_U],
    "peek_cursor": [KEY_ALT],
    "toggle_game_menu": [KEY_ESCAPE],
    "toggle_camera": [KEY_V],
    "skill_1": [KEY_1],
    "skill_2": [KEY_2],
    "skill_3": [KEY_3],
    "skill_4": [KEY_4],
    "ultimate": [KEY_5],
    "camera_rotate_left": [KEY_Q],
    "camera_rotate_right": [KEY_E],
    "camera_reset": [KEY_R],
}
const DEFAULT_MOUSE := {"attack": MOUSE_BUTTON_LEFT}

const BINDABLE_ACTIONS: Array[String] = [
    "move_forward", "move_back", "move_left", "move_right",
    "jump", "dodge", "interact", "attack",
    "skill_1", "skill_2", "skill_3", "skill_4", "ultimate",
    "camera_rotate_left", "camera_rotate_right", "camera_reset", "toggle_camera",
    "toggle_inventory", "toggle_character", "toggle_achievements", "toggle_game_menu",
    "toggle_fashion", "peek_cursor",
]

const FPS_OPTIONS := [30, 60, 90, 120, 144, 0]
const MSAA_OPTIONS := [0, 1, 2, 3]
const COMBAT_FX_OPTIONS := [0, 1, 2]
const FILTER_OPTIONS: Array[String] = ["none", "ink", "warm", "night"]

## Screen filter tuning: [saturation, contrast, brightness, tint colour].
const FILTER_PRESETS := {
    "none": [1.08, 1.02, 1.20, Color(0, 0, 0, 0)],
    "ink": [0.38, 1.16, 1.16, Color(0.86, 0.89, 0.86, 0.07)],
    "warm": [1.18, 1.04, 1.24, Color(1.0, 0.84, 0.58, 0.09)],
    "night": [0.86, 1.10, 0.94, Color(0.34, 0.48, 0.86, 0.13)],
}

const KEYS_PATH := "user://tides_of_guixu_keys.cfg"

var _bindings: Dictionary = {}

## Display presets offered in the settings. Every entry is a strict 16:9 pair
## (the height is re-derived by get_resolution_size() so the list can never
## drift off-ratio even if a value is edited by hand).
const RESOLUTION_SIZES := [
    {"width": 1280, "height": 720},
    {"width": 1600, "height": 900},
    {"width": 1920, "height": 1080},
    {"width": 2560, "height": 1440},
    {"width": 3840, "height": 2160},
]

const ASPECT_RATIO := 16.0 / 9.0

const DEFAULT_STATS := {
    "enemies_defeated": 0.0,
    "items_collected": 0.0,
    "stones_earned": 0.0,
    "damage_dealt": 0.0,
    "damage_taken": 0.0,
    "skills_cast": 0.0,
    "days_survived": 0.0,
    "realm_index": 0.0,
    "play_time": 0.0,
    "fashion_owned": 0.0,
    "elements_cast": {"metal": 0.0, "wood": 0.0, "water": 0.0, "fire": 0.0, "earth": 0.0},
}

var player_name := "Player"
var player_element := "wood"
var birth_pillar: Dictionary = {}
var cultivation_xp := 0.0
var realm_index := 0
var health := 100.0
var qi := 50.0
var inventory: Array = []
var equipment: Dictionary = {"weapon": "", "head": "", "body": "", "legs": "", "boots": "", "bracers": "", "accessory": "", "talisman": ""}
## Fashion (时装) is a cosmetic overlay: owned outfit ids, the worn outfit
## ("" = keep the equipment look) and per-outfit styling.
var fashion_owned: Dictionary = {}
var fashion_worn := ""
var fashion_style: Dictionary = {}
var achievements: Dictionary = {}
var quest_states: Dictionary = {}
var tracked_quest_id := ""
var stats: Dictionary = {}
var game_time: Dictionary = {"year": 2025, "month": 3, "day": 1, "hour": 9, "minute": 0}
var play_time := 0.0
var has_started := false
var settings: Dictionary = {}
var time_scale := 0.4
var _minute_accumulator := 0.0
var _autosave_accumulator := 0.0

func _ready() -> void:
    _setup_input_map()
    _ensure_inventory()
    stats = _default_stats()
    load_settings()

func _process(delta: float) -> void:
    if not has_started:
        return
    if get_tree().paused:
        return
    play_time += delta
    stats["play_time"] = play_time
    _autosave_accumulator += delta
    if _autosave_accumulator >= 45.0:
        _autosave_accumulator = 0.0
        save_game()
    _minute_accumulator += delta * time_scale
    var changed := false
    while _minute_accumulator >= 1.0:
        _minute_accumulator -= 1.0
        _advance_one_minute()
        changed = true
    if changed:
        EventBus.time_changed.emit(get_pillars())

## True while the player holds the peek key (Alt) inside the world.
func is_cursor_peeked() -> bool:
    return InputMap.has_action(PEEK_ACTION) and Input.is_action_pressed(PEEK_ACTION)


## The mouse mode the world should be in right now.
##
## Panels pause the game and always want a cursor; so does the player while
## holding the peek key in third-person play, which lets them reach the HUD
## without leaving the mouse lock.  The key is read live, so releasing it
## while a panel is open can never strand the cursor.
func desired_mouse_mode(panel_open: bool = false) -> int:
    if panel_open or is_cursor_peeked():
        return Input.MOUSE_MODE_VISIBLE
    if int(settings.get("camera_mode", 0)) == 1:
        return Input.MOUSE_MODE_CAPTURED
    return Input.MOUSE_MODE_VISIBLE


## Last mode apply_mouse_mode() asked for.  A headless display server ignores
## mouse_set_mode, so this is also what the tests assert against.
var last_applied_mouse_mode := Input.MOUSE_MODE_VISIBLE


## Applies desired_mouse_mode() and remembers the request.
func apply_mouse_mode(panel_open: bool = false) -> int:
    var mode := desired_mouse_mode(panel_open)
    if Input.mouse_mode != mode:
        Input.mouse_mode = mode
    last_applied_mouse_mode = mode
    return mode


func _default_stats() -> Dictionary:
    var result: Dictionary = DEFAULT_STATS.duplicate(true)
    result["elements_cast"] = DEFAULT_STATS["elements_cast"].duplicate(true)
    return result

func _ensure_inventory() -> void:
    if inventory.size() != INVENTORY_SIZE:
        inventory.resize(INVENTORY_SIZE)

func start_new_game() -> void:
    player_name = LocaleData.text("default_player_name")
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    player_element = GameData.ELEMENT_IDS[rng.randi_range(0, GameData.ELEMENT_IDS.size() - 1)]
    birth_pillar = GameData.year_pillar(rng.randi_range(1980, 2020))
    cultivation_xp = 0.0
    realm_index = 0
    equipment = DEFAULT_EQUIPMENT.duplicate(true)
    var base := get_total_stats()
    health = float(base["max_health"])
    qi = float(base["max_qi"])
    achievements.clear()
    quest_states.clear()
    tracked_quest_id = ""
    stats = _default_stats()
    game_time = {"year": 2025, "month": 3, "day": 1, "hour": 9, "minute": 0}
    play_time = 0.0
    _minute_accumulator = 0.0
    _autosave_accumulator = 0.0
    inventory.clear()
    inventory.resize(INVENTORY_SIZE)
    for entry in GameData.starting_items():
        add_item(str(entry["id"]), int(entry["count"]))
    _equip_starting_gear()
    _reset_fashion()
    has_started = true
    EventBus.fashion_changed.emit()
    EventBus.game_started.emit()
    EventBus.player_stats_changed.emit()
    EventBus.inventory_changed.emit()
    EventBus.equipment_changed.emit()
    EventBus.time_changed.emit(get_pillars())
    EventBus.toast_requested.emit(LocaleData.text("toast_start"), Color(0.7, 0.95, 0.8))
    save_game()

func _equip_starting_gear() -> void:
    for piece_id in GameData.set_piece_ids("shaoxia"):
        var target_id := str(piece_id)
        for i in range(inventory.size()):
            var slot: Variant = inventory[i]
            if slot is Dictionary and str(slot.get("id", "")) == target_id:
                equip_item(i)
                break

# ---------------------------------------------------------------- fashion ---
## Fashion (时装) is a purely cosmetic overlay: an outfit never feeds
## get_total_stats().  Ownership is permanent, wearing / dyeing / the aura can be
## switched freely.  Player and the wardrobe preview both read
## fashion_appearance() so the look can never drift apart.

func _reset_fashion() -> void:
    fashion_owned = {}
    fashion_style = {}
    fashion_worn = ""
    for id in FashionData.STARTER_OWNED:
        var key := str(id)
        if FashionData.has(key):
            fashion_owned[key] = true
    stats["fashion_owned"] = float(fashion_owned.size())


## Sanitises fashion data coming from a save file: unknown ids are dropped and
## the worn outfit / its styling are guaranteed to exist.
func _ensure_fashion() -> void:
    var owned := {}
    for id in fashion_owned.keys():
        var key := str(id)
        if FashionData.has(key):
            owned[key] = true
    fashion_owned = owned

    var styles := {}
    for id in fashion_style.keys():
        var key := str(id)
        if not fashion_owned.has(key):
            continue
        var raw: Variant = fashion_style[key]
        if raw is Dictionary:
            var data: Dictionary = raw
            styles[key] = {
                "palette": clampi(int(data.get("palette", 0)), 0, FashionData.palette_count(key) - 1),
                "aura": bool(data.get("aura", true)),
            }
        else:
            styles[key] = {"palette": 0, "aura": true}
    fashion_style = styles

    if fashion_worn != "" and not fashion_owned.has(fashion_worn):
        fashion_worn = ""
    if fashion_worn != "" and not fashion_style.has(fashion_worn):
        fashion_style[fashion_worn] = {"palette": 0, "aura": true}
    stats["fashion_owned"] = float(fashion_owned.size())


func has_fashion(id: String) -> bool:
    return fashion_owned.has(id)


func fashion_owned_count() -> int:
    return fashion_owned.size()


func fashion_total_count() -> int:
    return FashionData.count()


func is_fashion_worn(id: String) -> bool:
    return id != "" and fashion_worn == id


func _fashion_style_of(id: String) -> Dictionary:
    var raw: Variant = fashion_style.get(id, null)
    if raw is Dictionary:
        return raw
    return {"palette": 0, "aura": true}


func get_fashion_palette(id: String) -> int:
    return clampi(int(_fashion_style_of(id).get("palette", 0)), 0, FashionData.palette_count(id) - 1)


func get_fashion_aura_enabled(id: String) -> bool:
    return bool(_fashion_style_of(id).get("aura", true))


## Appearance of the worn outfit ({} when nothing is worn).
func fashion_appearance() -> Dictionary:
    if fashion_worn == "" or not fashion_owned.has(fashion_worn):
        return {}
    return FashionData.appearance(fashion_worn, get_fashion_palette(fashion_worn), get_fashion_aura_enabled(fashion_worn))


## Appearance used by the wardrobe preview, for an outfit that may not be owned.
func fashion_preview_appearance(id: String) -> Dictionary:
    if not FashionData.has(id):
        return {}
    return FashionData.appearance(id, get_fashion_palette(id), get_fashion_aura_enabled(id))


func wear_fashion(id: String) -> bool:
    if id != "" and not fashion_owned.has(id):
        return false
    if fashion_worn == id:
        return true
    fashion_worn = id
    if id != "" and not fashion_style.has(id):
        fashion_style[id] = {"palette": 0, "aura": true}
    EventBus.fashion_changed.emit()
    if id != "":
        EventBus.toast_requested.emit(LocaleData.text("fashion_worn_toast") % FashionData.name(id), Color(0.85, 1.0, 0.9))
    else:
        EventBus.toast_requested.emit(LocaleData.text("fashion_taken_off_toast"), Color(0.82, 0.92, 0.88))
    save_game()
    return true


func take_off_fashion() -> void:
    wear_fashion("")


func set_fashion_palette(id: String, index: int) -> void:
    if not fashion_owned.has(id):
        return
    var style := _fashion_style_of(id).duplicate()
    var clamped := clampi(index, 0, FashionData.palette_count(id) - 1)
    if int(style.get("palette", 0)) == clamped:
        return
    style["palette"] = clamped
    fashion_style[id] = style
    EventBus.fashion_changed.emit()
    save_game()


func set_fashion_aura_enabled(id: String, enabled: bool) -> void:
    if not fashion_owned.has(id):
        return
    var style := _fashion_style_of(id).duplicate()
    if bool(style.get("aura", true)) == enabled:
        return
    style["aura"] = enabled
    fashion_style[id] = style
    EventBus.fashion_changed.emit()
    save_game()


## "" when the outfit can be unlocked right now, otherwise the blocking reason.
func get_fashion_blocker(id: String) -> String:
    if not FashionData.has(id):
        return LocaleData.text("fashion_not_owned")
    if fashion_owned.has(id):
        return LocaleData.text("fashion_owned")
    var requirement := FashionData.realm_requirement(id)
    if realm_index < requirement:
        return LocaleData.text("fashion_block_realm") % GameData.realm_name(requirement)
    var missing: Array[String] = []
    var entries := FashionData.cost(id)
    for item_id in entries.keys():
        var need := int(entries[item_id])
        var have := count_item(str(item_id))
        if have < need:
            missing.append("%s ×%d" % [GameData.item_name(str(item_id)), need - have])
    if not missing.is_empty():
        return LocaleData.text("fashion_block_items") % " · ".join(missing)
    return ""


func can_unlock_fashion(id: String) -> bool:
    return FashionData.has(id) and not fashion_owned.has(id) and get_fashion_blocker(id) == ""


func unlock_fashion(id: String) -> bool:
    if not can_unlock_fashion(id):
        var reason := get_fashion_blocker(id)
        if reason != "" and reason != LocaleData.text("fashion_owned"):
            EventBus.toast_requested.emit(reason, Color(0.95, 0.72, 0.5))
        return false
    var entries := FashionData.cost(id)
    for item_id in entries.keys():
        remove_item(str(item_id), int(entries[item_id]))
    fashion_owned[id] = true
    if not fashion_style.has(id):
        fashion_style[id] = {"palette": 0, "aura": true}
    stats["fashion_owned"] = float(fashion_owned.size())
    EventBus.toast_requested.emit(LocaleData.text("fashion_unlocked") % FashionData.name(id), Color(1.0, 0.86, 0.42))
    EventBus.inventory_changed.emit()
    EventBus.fashion_changed.emit()
    check_achievements()
    save_game()
    return true


func get_total_stats() -> Dictionary:
    var realm := GameData.realm_stats(realm_index)
    var result := {
        "max_health": float(realm["hp"]),
        "max_qi": float(realm["qi"]),
        "attack": float(realm["atk"]),
        "defense": float(realm["def"]),
        "move_speed": 6.0,
        "crit_chance": 0.05,
        "crit_damage": 1.5,
    }
    for slot_id in equipment.keys():
        var item_id := str(equipment[slot_id])
        if item_id == "":
            continue
        var item := GameData.item_row(item_id)
        var item_stats: Variant = item.get("stats", {})
        if item_stats is Dictionary:
            for stat_key in item_stats.keys():
                result[stat_key] = float(result.get(stat_key, 0.0)) + float(item_stats[stat_key])
    _apply_set_bonuses(result)
    return result


func _apply_set_bonuses(result: Dictionary) -> void:
    var set_counts: Dictionary = {}
    for slot_id in equipment.keys():
        var item_id := str(equipment[slot_id])
        if item_id == "":
            continue
        var set_id := GameData.item_set_id(item_id)
        if set_id == "":
            continue
        set_counts[set_id] = int(set_counts.get(set_id, 0)) + 1
    for set_id in set_counts.keys():
        var bonus_stats := GameData.set_bonus_stats(str(set_id), int(set_counts[set_id]))
        for stat_key in bonus_stats.keys():
            result[stat_key] = float(result.get(stat_key, 0.0)) + float(bonus_stats[stat_key])


func get_equipped_set_count(set_id: String) -> int:
    var count := 0
    for slot_id in equipment.keys():
        var item_id := str(equipment[slot_id])
        if item_id != "" and GameData.item_set_id(item_id) == set_id:
            count += 1
    return count

func get_realm_name() -> String:
    return GameData.realm_name(realm_index)

func get_element_name() -> String:
    return GameData.element_name(player_element)

func get_birth_text() -> String:
    if birth_pillar.is_empty():
        return LocaleData.text("none")
    return str(birth_pillar.get("name", "")) + " / " + GameData.element_name(str(birth_pillar.get("element", "earth")))

## Grants cultivation xp and returns how much was actually applied, so the
## kill notification can print the real number.
func add_cultivation_xp(amount: float) -> float:
    if amount <= 0.0:
        return 0.0
    cultivation_xp += amount
    var new_realm := GameData.realm_for_xp(cultivation_xp)
    if new_realm > realm_index:
        realm_index = new_realm
        stats["realm_index"] = float(realm_index)
        var total := get_total_stats()
        health = float(total["max_health"])
        qi = float(total["max_qi"])
        EventBus.realm_changed.emit(realm_index)
        EventBus.toast_requested.emit(LocaleData.text("realm_up") % get_realm_name(), Color(1.0, 0.86, 0.35))
        EventBus.player_stats_changed.emit()
    check_achievements()
    return amount

func get_quest_state(quest_id: String) -> Dictionary:
    var state: Variant = quest_states.get(quest_id, {})
    if not (state is Dictionary):
        state = {}
    if not state.has("status"):
        state["status"] = "inactive"
    if not state.has("progress"):
        state["progress"] = 0
    return state

func start_quest(quest_id: String) -> void:
    var quest := GameData.quest(quest_id)
    if quest.is_empty():
        return
    var state := get_quest_state(quest_id)
    if str(state.get("status", "inactive")) != "inactive":
        return
    state["status"] = "active"
    state["progress"] = 0
    quest_states[quest_id] = state
    if tracked_quest_id == "":
        tracked_quest_id = quest_id
    EventBus.quest_updated.emit(quest_id)
    EventBus.toast_requested.emit(LocaleData.text("quest_started") % str(quest.get("name", quest_id)), Color(1.0, 0.86, 0.42))

func record_quest_kill(enemy_id: String) -> void:
    for quest_id in quest_states.keys():
        var state := get_quest_state(str(quest_id))
        if str(state.get("status", "inactive")) != "active":
            continue
        var quest := GameData.quest(str(quest_id))
        if quest.is_empty():
            continue
        var objective: Variant = quest.get("objective", {})
        if not (objective is Dictionary):
            continue
        if str(objective.get("type", "")) != "kill" or str(objective.get("enemy_id", "")) != enemy_id:
            continue
        state["progress"] = int(state.get("progress", 0)) + 1
        var target := int(objective.get("target", 1))
        if int(state["progress"]) >= target:
            state["status"] = "ready"
        quest_states[str(quest_id)] = state
        EventBus.quest_updated.emit(str(quest_id))
        if str(state["status"]) == "ready":
            EventBus.toast_requested.emit(LocaleData.text("quest_ready") + ": " + str(quest.get("name", quest_id)), Color(0.72, 0.95, 1.0))

func complete_quest(quest_id: String) -> bool:
    var state := get_quest_state(quest_id)
    if str(state.get("status", "inactive")) != "ready":
        return false
    var quest := GameData.quest(quest_id)
    if quest.is_empty():
        return false
    state["status"] = "completed"
    quest_states[quest_id] = state
    if tracked_quest_id == quest_id:
        tracked_quest_id = ""
    add_cultivation_xp(float(quest.get("reward_xp", 0.0)))
    var rewards: Variant = quest.get("reward_items", [])
    if rewards is Array:
        for reward in rewards:
            if reward is Dictionary:
                add_item(str(reward.get("id", "")), int(reward.get("count", 1)))
    EventBus.quest_completed.emit(quest_id)
    EventBus.toast_requested.emit(LocaleData.text("quest_finished") % str(quest.get("name", quest_id)), Color(1.0, 0.86, 0.42))
    check_achievements()
    return true

func get_tracked_quest() -> Dictionary:
    if tracked_quest_id == "":
        return {}
    var quest := GameData.quest(tracked_quest_id)
    if quest.is_empty():
        return {}
    var state := get_quest_state(tracked_quest_id)
    var objective: Variant = quest.get("objective", {})
    var target := 1
    if objective is Dictionary:
        target = int(objective.get("target", 1))
    return {
        "id": tracked_quest_id,
        "name": str(quest.get("name", tracked_quest_id)),
        "desc": str(quest.get("desc", "")),
        "status": str(state.get("status", "inactive")),
        "progress": int(state.get("progress", 0)),
        "target": maxi(target, 1),
    }

func get_quest_state_text(quest_id: String) -> String:
    var state := get_quest_state(quest_id)
    var status := str(state.get("status", "inactive"))
    if status == "completed":
        return LocaleData.text("quest_completed")
    if status == "ready":
        return LocaleData.text("quest_ready")
    if status == "active":
        return LocaleData.text("quest_in_progress")
    return ""

func record_stat(stat_name: String, amount: float = 1.0) -> void:
    stats[stat_name] = float(stats.get(stat_name, 0.0)) + amount
    check_achievements()

func record_element_cast(element: String) -> void:
    var casts: Dictionary = stats.get("elements_cast", {})
    casts[element] = float(casts.get(element, 0.0)) + 1.0
    stats["elements_cast"] = casts
    record_stat("skills_cast", 1.0)

func add_item(item_id: String, count: int = 1) -> int:
    if count <= 0:
        return 0
    var item: Dictionary = GameData.item(item_id)
    if item.is_empty():
        return count
    _ensure_inventory()
    var remaining := count
    var stackable := bool(item.get("stackable", false))
    # Non-stackable gear (weapons, armour ...) must never share one slot.
    var max_stack := 1 if not stackable else int(item.get("max_stack", 99))
    if stackable:
        for i in range(inventory.size()):
            var slot: Variant = inventory[i]
            if slot is Dictionary and str(slot.get("id", "")) == item_id:
                var current := int(slot.get("count", 0))
                var space := max_stack - current
                if space > 0:
                    var moved: int = mini(space, remaining)
                    slot["count"] = current + moved
                    remaining -= moved
                    if remaining <= 0:
                        break
    while remaining > 0:
        var empty_index := _find_empty_slot()
        if empty_index < 0:
            break
        var moved: int = mini(max_stack, remaining)
        inventory[empty_index] = {"id": item_id, "count": moved}
        remaining -= moved
    var added := count - remaining
    if added > 0:
        stats["items_collected"] = float(stats.get("items_collected", 0.0)) + added
        if item_id == "material_jingshi":
            stats["stones_earned"] = float(stats.get("stones_earned", 0.0)) + added
        EventBus.inventory_changed.emit()
        EventBus.toast_requested.emit(LocaleData.text("item_added") % [str(item["name"]), added], Color(0.75, 0.95, 0.8))
        check_achievements()
    return remaining

func remove_item(item_id: String, count: int = 1) -> bool:
    if count <= 0:
        return true
    var remaining := count
    for i in range(inventory.size()):
        var slot: Variant = inventory[i]
        if slot is Dictionary and str(slot.get("id", "")) == item_id:
            var current := int(slot.get("count", 0))
            var removed: int = mini(current, remaining)
            slot["count"] = current - removed
            remaining -= removed
            if int(slot["count"]) <= 0:
                inventory[i] = null
            if remaining <= 0:
                break
    if remaining > 0:
        return false
    EventBus.inventory_changed.emit()
    return true

func count_item(item_id: String) -> int:
    var total := 0
    for slot in inventory:
        if slot is Dictionary and str(slot.get("id", "")) == item_id:
            total += int(slot.get("count", 0))
    return total

## Merges identical stacks and reorders the bag: equipment (by slot), then
## consumables, then materials - each sorted by rarity and finally by id.
## Empty slots are pushed to the end.

func sort_inventory() -> void:
    _ensure_inventory()
    var merged: Dictionary = {}
    var singles: Array = []
    for slot in inventory:
        if not (slot is Dictionary) or (slot as Dictionary).is_empty():
            continue
        var data := slot as Dictionary
        var item_id := str(data.get("id", ""))
        if item_id == "":
            continue
        var row: Dictionary = GameData.item_row(item_id)
        var count := int(data.get("count", 1))
        if bool(row.get("stackable", false)):
            merged[item_id] = int(merged.get(item_id, 0)) + count
        else:
            singles.append({"id": item_id, "count": count})

    var entries: Array = singles.duplicate(true)
    for item_id in merged.keys():
        var remaining := int(merged[item_id])
        var max_stack := maxi(int(GameData.item_row(str(item_id)).get("max_stack", 99)), 1)
        while remaining > 0:
            var pile: int = mini(remaining, max_stack)
            entries.append({"id": str(item_id), "count": pile})
            remaining -= pile

    entries.sort_custom(_sort_inventory_entry)
    for i in range(inventory.size()):
        inventory[i] = entries[i] if i < entries.size() else null

    EventBus.inventory_changed.emit()
    EventBus.toast_requested.emit(LocaleData.text("inventory_sorted"), Color(0.62, 0.95, 0.78))

func _sort_inventory_entry(a: Variant, b: Variant) -> bool:
    return _inventory_sort_key(a) < _inventory_sort_key(b)


## Sort key: category -> equipment slot -> rarity (higher first) -> item id.

func _inventory_sort_key(entry: Variant) -> String:
    var item_id := str((entry as Dictionary).get("id", ""))
    var row: Dictionary = GameData.item_row(item_id)
    var type_rank := 8
    match str(row.get("type", "")):
        "equipment":
            type_rank = 0
        "consumable":
            type_rank = 1
        "material":
            type_rank = 2
    var slot_rank := 0
    match str(row.get("slot", "")):
        "weapon":
            slot_rank = 0
        "head":
            slot_rank = 1
        "body":
            slot_rank = 2
        "legs":
            slot_rank = 3
        "boots":
            slot_rank = 4
        "bracers":
            slot_rank = 5
        "accessory":
            slot_rank = 6
        "talisman":
            slot_rank = 7
    var rarity := clampi(int(row.get("rarity", 1)), 0, 9)
    return "%d%d%d_%s" % [type_rank, slot_rank, 9 - rarity, item_id]

func use_item(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= inventory.size():
        return false
    var slot: Variant = inventory[slot_index]
    if not (slot is Dictionary):
        return false
    var item_id := str(slot.get("id", ""))
    var item: Dictionary = GameData.item(item_id)
    if item.is_empty():
        return false
    if str(item.get("type", "")) == "equipment":
        return equip_item(slot_index)
    if bool(item.get("revive_only", false)):
        EventBus.toast_requested.emit(LocaleData.text("cannot_use"), Color(0.85, 0.75, 0.65))
        return false
    if str(item.get("type", "")) == "consumable":
        _apply_use_effect(item.get("use_effect", {}), item)
        remove_item(item_id, 1)
        EventBus.toast_requested.emit(LocaleData.text("use_success") % str(item["name"]), Color(0.8, 0.9, 0.75))
        return true
    EventBus.toast_requested.emit(LocaleData.text("cannot_use"), Color(0.85, 0.75, 0.65))
    return false

func equip_item(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= inventory.size():
        return false
    var slot: Variant = inventory[slot_index]
    if not (slot is Dictionary):
        return false
    var item_id := str(slot.get("id", ""))
    var item: Dictionary = GameData.item(item_id)
    if str(item.get("type", "")) != "equipment":
        return false
    var target_slot := str(item.get("slot", "weapon"))
    var old_item := str(equipment.get(target_slot, ""))
    remove_item(item_id, 1)
    equipment[target_slot] = item_id
    if old_item != "":
        add_item(old_item, 1)
    EventBus.equipment_changed.emit()
    EventBus.player_stats_changed.emit()
    EventBus.toast_requested.emit(LocaleData.text("equip_success") % str(item["name"]), Color(0.75, 0.92, 1.0))
    return true

func unequip_slot(slot_id: String) -> bool:
    var item_id := str(equipment.get(slot_id, ""))
    if item_id == "":
        return false
    var remaining := add_item(item_id, 1)
    if remaining > 0:
        return false
    equipment[slot_id] = ""
    EventBus.equipment_changed.emit()
    EventBus.player_stats_changed.emit()
    return true

func _find_empty_slot() -> int:
    for i in range(inventory.size()):
        var slot: Variant = inventory[i]
        if slot == null or not (slot is Dictionary) or slot.is_empty():
            return i
    return -1

func _apply_use_effect(effect: Variant, item: Dictionary) -> void:
    if not (effect is Dictionary):
        return
    if effect.has("heal_ratio"):
        var total := get_total_stats()
        heal(float(total["max_health"]) * float(effect["heal_ratio"]))
    if effect.has("restore_qi"):
        restore_qi(float(effect["restore_qi"]))
    if effect.has("cultivation_xp"):
        add_cultivation_xp(float(effect["cultivation_xp"]))
    if effect.has("aoe_damage"):
        var player := get_tree().get_first_node_in_group("player")
        if player != null and player.has_method("cast_talisman_aoe"):
            player.cast_talisman_aoe(float(effect.get("aoe_damage", 0.0)), float(effect.get("radius", 4.0)), str(item.get("element", "fire")))

## Short gamepad rumble, used for hits and heavy skills.
func rumble(strength: float = 0.5, duration: float = 0.18) -> void:
    if not bool(settings.get("gamepad_rumble", true)):
        return
    if Input.get_connected_joypads().is_empty():
        return
    Input.start_joy_vibration(0, clampf(strength * 0.6, 0.0, 1.0), clampf(strength, 0.0, 1.0), duration)


func take_damage(amount: float) -> void:
    health = maxf(0.0, health - maxf(amount, 0.0))
    stats["damage_taken"] = float(stats.get("damage_taken", 0.0)) + amount
    EventBus.player_stats_changed.emit()
    if health <= 0.0:
        EventBus.player_died.emit()

func heal(amount: float) -> void:
    var total := get_total_stats()
    health = minf(float(total["max_health"]), health + maxf(amount, 0.0))
    EventBus.player_stats_changed.emit()

func restore_qi(amount: float) -> void:
    var total := get_total_stats()
    qi = minf(float(total["max_qi"]), qi + maxf(amount, 0.0))
    EventBus.player_stats_changed.emit()

func spend_qi(amount: float) -> bool:
    if qi < amount:
        return false
    qi -= amount
    EventBus.player_stats_changed.emit()
    return true

func is_achievement_unlocked(id: String) -> bool:
    if not achievements.has(id):
        return false
    var data: Variant = achievements[id]
    return data is Dictionary and bool(data.get("unlocked", false))

func get_achievement_progress(achievement: Dictionary) -> float:
    if is_achievement_unlocked(str(achievement.get("id", ""))):
        return 1.0
    if achievement.has("special"):
        var special := str(achievement["special"])
        if special == "all_elements":
            var casts: Dictionary = stats.get("elements_cast", {})
            var minimum := 1.0
            for element in GameData.ELEMENT_IDS:
                minimum = minf(minimum, float(casts.get(element, 0.0)))
            return clampf(minimum / maxf(float(achievement.get("target", 1.0)), 1.0), 0.0, 1.0)
        if special == "inventory_full":
            return 1.0 if _occupied_slots() >= INVENTORY_SIZE else 0.0
        if special == "fashion_complete":
            return 1.0 if fashion_owned_count() >= FashionData.count() else 0.0
        return 0.0
    var current := float(stats.get(str(achievement.get("stat", "")), 0.0))
    var target := maxf(float(achievement.get("target", 1.0)), 1.0)
    return clampf(current / target, 0.0, 1.0)

func get_achievement_progress_text(achievement: Dictionary) -> String:
    if is_achievement_unlocked(str(achievement.get("id", ""))):
        return LocaleData.text("unlocked")
    if achievement.has("special") and str(achievement["special"]) == "inventory_full":
        return "%d / %d" % [_occupied_slots(), INVENTORY_SIZE]
    if achievement.has("special") and str(achievement["special"]) == "fashion_complete":
        return "%d / %d" % [fashion_owned_count(), FashionData.count()]
    var current := int(stats.get(str(achievement.get("stat", "")), 0.0))
    return "%d / %d" % [current, int(achievement.get("target", 1.0))]

func check_achievements() -> void:
    for ach in GameData.achievement_list():
        var id := str(ach.get("id", ""))
        if is_achievement_unlocked(id):
            continue
        if get_achievement_progress(ach) >= 1.0:
            unlock_achievement(id)

func unlock_achievement(id: String) -> void:
    if is_achievement_unlocked(id):
        return
    var ach: Dictionary = {}
    for entry in GameData.achievement_list():
        if str(entry.get("id", "")) == id:
            ach = entry
            break
    if ach.is_empty():
        return
    achievements[id] = {"unlocked": true, "time": Time.get_datetime_string_from_system()}
    EventBus.achievement_unlocked.emit(ach)
    EventBus.toast_requested.emit(LocaleData.text("achievement_unlocked") % str(ach.get("name", id)), Color(1.0, 0.86, 0.35))

func get_achievement_summary() -> String:
    var unlocked := 0
    for ach in GameData.achievement_list():
        if is_achievement_unlocked(str(ach.get("id", ""))):
            unlocked += 1
    return "%d / %d" % [unlocked, GameData.achievement_list().size()]

func _occupied_slots() -> int:
    var count := 0
    for slot in inventory:
        if slot is Dictionary and not slot.is_empty():
            count += 1
    return count

## Public helper so the inventory UI can show used/total without touching internals.

func get_inventory_used() -> int:
    return _occupied_slots()

func _advance_one_minute() -> void:
    game_time["minute"] = int(game_time["minute"]) + 1
    if int(game_time["minute"]) < 60:
        return
    game_time["minute"] = 0
    game_time["hour"] = int(game_time["hour"]) + 1
    if int(game_time["hour"]) < 24:
        return
    game_time["hour"] = 0
    game_time["day"] = int(game_time["day"]) + 1
    stats["days_survived"] = float(stats.get("days_survived", 0.0)) + 1.0
    check_achievements()
    if int(game_time["day"]) > _days_in_month(int(game_time["year"]), int(game_time["month"])):
        game_time["day"] = 1
        game_time["month"] = int(game_time["month"]) + 1
        if int(game_time["month"]) > 12:
            game_time["month"] = 1
            game_time["year"] = int(game_time["year"]) + 1

func _days_in_month(year: int, month: int) -> int:
    var days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 and ((year % 4 == 0 and year % 100 != 0) or year % 400 == 0):
        return 29
    return int(days[clampi(month - 1, 0, 11)])

func get_pillars() -> Dictionary:
    return GameData.get_pillars(int(game_time["year"]), int(game_time["month"]), int(game_time["day"]), int(game_time["hour"]))

## In-world calendar line, e.g. "归墟七十七年腊月十五 辰时三刻".
func get_calendar_text() -> String:
    return GameData.calendar_text(game_time)


## Raw clock the game keeps internally ("2025-03-01 09:00"), kept for
## debugging and save inspection - the UI shows get_calendar_text().
func get_time_string() -> String:
    return "%04d-%02d-%02d %02d:%02d" % [int(game_time["year"]), int(game_time["month"]), int(game_time["day"]), int(game_time["hour"]), int(game_time["minute"])]


func get_time_of_day() -> int:
    return int(game_time.get("hour", 0))


## Manually jump to an in-world hour/minute (used by the settings time node).
func set_time_of_day(hour: int, minute: int = 0) -> void:
    game_time["hour"] = posmod(hour, 24)
    game_time["minute"] = clampi(minute, 0, 59)
    _minute_accumulator = 0.0
    EventBus.time_changed.emit(get_pillars())

func get_cultivation_text() -> String:
    var next_xp := GameData.realm_next_xp(realm_index)
    if next_xp < 0.0:
        return "%d" % int(cultivation_xp)
    return "%d / %d" % [int(cultivation_xp), int(next_xp)]

func get_element_relation_text() -> String:
    var current: String = str(GameData.BRANCH_ELEMENTS[GameData.hour_branch_index(int(game_time["hour"]))])
    var relation: String = GameData.element_relationship(player_element, current)
    var relation_names := {"same": LocaleData.text("relation_same"), "generates": LocaleData.text("relation_generates"), "overcomes": LocaleData.text("relation_overcomes"), "generated_by": LocaleData.text("relation_generated_by"), "overcome_by": LocaleData.text("relation_overcome_by"), "neutral": LocaleData.text("relation_neutral")}
    return "%s | %s | %s" % [GameData.element_name(player_element), GameData.element_name(current), str(relation_names.get(relation, ""))]

func load_settings() -> void:
    settings = DEFAULT_SETTINGS.duplicate(true)
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        for key in DEFAULT_SETTINGS.keys():
            settings[key] = config.get_value("settings", key, DEFAULT_SETTINGS[key])
        # Old builds stored game minutes per real second (default 60, i.e. a
        # ~24 second day). Migrate that legacy range to the new one-hour day.
        var legacy_time_scale := float(settings.get("time_scale", 0.4))
        if legacy_time_scale <= 0.0 or legacy_time_scale > 3.0:
            settings["time_scale"] = 0.4
    apply_settings()
    apply_window_resolution()

func save_settings() -> void:
    var config := ConfigFile.new()
    for key in settings.keys():
        config.set_value("settings", key, settings[key])
    config.save(SETTINGS_PATH)

func set_setting(key: String, value: Variant) -> void:
    settings[key] = value
    apply_settings()
    if key == "resolution_index" or key == "fullscreen":
        apply_window_resolution()
    save_settings()
    EventBus.settings_changed.emit()

func apply_settings() -> void:
    time_scale = clampf(float(settings.get("time_scale", 0.4)), 0.1, 4.0)
    apply_audio_settings()
    if get_window() != null:
        get_window().content_scale_factor = clampf(float(settings.get("ui_scale", 1.0)), 0.8, 1.4)
    apply_render_settings()
    var want_fullscreen := bool(settings.get("fullscreen", false))
    var mode := DisplayServer.window_get_mode()
    if want_fullscreen and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    if not want_fullscreen and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

## Resolution preset at index, always normalised to a strict 16:9 frame.

func get_resolution_size(index: int) -> Vector2i:
    var safe_index := clampi(index, 0, RESOLUTION_SIZES.size() - 1)
    var size_data: Dictionary = RESOLUTION_SIZES[safe_index]
    var width := int(size_data.get("width", 1280))
    return Vector2i(width, int(round(float(width) / ASPECT_RATIO)))

## Bus volumes: Master / SFX (combat + UI) / Music.
func apply_audio_settings() -> void:
    AudioServer.set_bus_volume_db(0, float(settings.get("master_volume_db", -6.0)))
    var sfx_index := AudioServer.get_bus_index("SFX")
    if sfx_index >= 0:
        AudioServer.set_bus_volume_db(sfx_index, float(settings.get("sfx_volume_db", -4.0)))
    var music_index := AudioServer.get_bus_index("Music")
    if music_index >= 0:
        AudioServer.set_bus_volume_db(music_index, float(settings.get("music_volume_db", -14.0)))


## VSync / frame cap / anti-aliasing.
func apply_render_settings() -> void:
    DisplayServer.window_set_vsync_mode(clampi(int(settings.get("vsync", 1)), 0, 2))
    var fps_index := clampi(int(settings.get("fps_limit", 1)), 0, FPS_OPTIONS.size() - 1)
    Engine.max_fps = int(FPS_OPTIONS[fps_index])
    var viewport := get_viewport()
    if viewport != null:
        var msaa_index := clampi(int(settings.get("msaa", 0)), 0, MSAA_OPTIONS.size() - 1)
        viewport.msaa_3d = int(MSAA_OPTIONS[msaa_index])


## Screen-filter preset: [saturation, contrast, brightness, tint].
func get_filter_preset() -> Array:
    var filter_id := str(FILTER_OPTIONS[clampi(int(settings.get("screen_filter", 0)), 0, FILTER_OPTIONS.size() - 1)])
    return FILTER_PRESETS.get(filter_id, FILTER_PRESETS["none"])


## 0 = off, 1 = reduced, 2 = full.
func combat_fx_level() -> int:
    var index := clampi(int(settings.get("combat_fx", 2)), 0, COMBAT_FX_OPTIONS.size() - 1)
    return int(COMBAT_FX_OPTIONS[index])


func apply_window_resolution() -> void:
    if bool(settings.get("fullscreen", false)):
        return
    var index := clampi(int(settings.get("resolution_index", 0)), 0, RESOLUTION_SIZES.size() - 1)
    var target := get_resolution_size(index)
    if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(target)
    var screen := DisplayServer.window_get_current_screen()
    var screen_size := DisplayServer.screen_get_size(screen)
    var position := Vector2i(
        maxi((screen_size.x - target.x) / 2, 0),
        maxi((screen_size.y - target.y) / 2, 0)
    )
    DisplayServer.window_set_position(position)

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
    if not has_started:
        return
    var data := {
        "player_name": player_name,
        "player_element": player_element,
        "birth_pillar": birth_pillar,
        "cultivation_xp": cultivation_xp,
        "realm_index": realm_index,
        "health": health,
        "qi": qi,
        "inventory": inventory.duplicate(true),
        "equipment": equipment.duplicate(true),
        "fashion_owned": fashion_owned.duplicate(true),
        "fashion_worn": fashion_worn,
        "fashion_style": fashion_style.duplicate(true),
        "achievements": achievements.duplicate(true),
        "quest_states": quest_states.duplicate(true),
        "tracked_quest_id": tracked_quest_id,
        "stats": stats.duplicate(true),
        "game_time": game_time.duplicate(true),
        "play_time": play_time,
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(data))
    file.close()
    EventBus.game_saved.emit()

func load_game() -> bool:
    if not has_save():
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var text := file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return false
    var data: Dictionary = parsed
    player_name = str(data.get("player_name", player_name))
    # Nothing ever let the player rename the character, so a save still on the
    # old placeholder name is upgraded to the new default.
    if player_name == LEGACY_DEFAULT_PLAYER_NAME:
        player_name = LocaleData.text("default_player_name")
    player_element = str(data.get("player_element", player_element))
    var loaded_birth: Variant = data.get("birth_pillar", {})
    if loaded_birth is Dictionary:
        birth_pillar = loaded_birth
    cultivation_xp = float(data.get("cultivation_xp", 0.0))
    realm_index = int(data.get("realm_index", 0))
    health = float(data.get("health", 100.0))
    qi = float(data.get("qi", 50.0))
    var loaded_inventory: Variant = data.get("inventory", [])
    if loaded_inventory is Array:
        inventory = loaded_inventory
    inventory.resize(INVENTORY_SIZE)
    var loaded_equipment: Variant = data.get("equipment", {})
    if loaded_equipment is Dictionary:
        equipment = _normalize_equipment(loaded_equipment)
    # Saves written before the fashion system get the starter outfits.
    var loaded_fashion: Variant = data.get("fashion_owned", {})
    fashion_owned = {}
    if data.has("fashion_owned"):
        if loaded_fashion is Dictionary:
            fashion_owned = loaded_fashion
    else:
        for starter_id in FashionData.STARTER_OWNED:
            fashion_owned[str(starter_id)] = true
    fashion_worn = str(data.get("fashion_worn", ""))
    var loaded_styles: Variant = data.get("fashion_style", {})
    if loaded_styles is Dictionary:
        fashion_style = loaded_styles
    var loaded_achievements: Variant = data.get("achievements", {})
    if loaded_achievements is Dictionary:
        achievements = loaded_achievements
    var loaded_quests: Variant = data.get("quest_states", {})
    if loaded_quests is Dictionary:
        quest_states = loaded_quests
    tracked_quest_id = str(data.get("tracked_quest_id", ""))
    var loaded_stats: Variant = data.get("stats", {})
    if loaded_stats is Dictionary:
        stats = loaded_stats
    # Merged over the defaults: a save missing a calendar key must not crash
    # get_pillars(), which indexes year / month / day / hour directly.
    game_time = {"year": 2025, "month": 3, "day": 1, "hour": 9, "minute": 0}
    var loaded_time: Variant = data.get("game_time", {})
    if loaded_time is Dictionary:
        var time_data: Dictionary = loaded_time
        for key in game_time.keys():
            if time_data.has(key):
                game_time[key] = int(time_data[key])
    play_time = float(data.get("play_time", 0.0))
    _ensure_fashion()
    has_started = true
    EventBus.game_loaded.emit()
    EventBus.player_stats_changed.emit()
    EventBus.inventory_changed.emit()
    EventBus.equipment_changed.emit()
    EventBus.fashion_changed.emit()
    EventBus.time_changed.emit(get_pillars())
    return true

func _normalize_equipment(loaded: Dictionary) -> Dictionary:
    var result := DEFAULT_EQUIPMENT.duplicate(true)
    for slot_id in result.keys():
        result[slot_id] = str(loaded.get(slot_id, ""))
    return result


func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

## Rebuilds the whole input map: defaults, then saved key bindings, then gamepad.
func _setup_input_map() -> void:
    for action in DEFAULT_KEYS.keys():
        _ensure_action(str(action))
        InputMap.action_erase_events(str(action))
        for code in DEFAULT_KEYS[action]:
            _add_key_event(str(action), int(code))
    for action in DEFAULT_MOUSE.keys():
        _ensure_action(str(action))
        InputMap.action_erase_events(str(action))
        _add_mouse_event(str(action), int(DEFAULT_MOUSE[action]))

    # ESC now opens the independent in-game menu; migrate/remove the old
    # settings toggle action so it cannot remain as a second hidden binding.
    if InputMap.has_action("toggle_settings"):
        InputMap.erase_action("toggle_settings")

    _load_bindings()
    for action in _bindings.keys():
        apply_binding(str(action), int(_bindings[action]))

    _setup_gamepad()


func _ensure_action(action: String) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.5)


func _add_key_event(action: String, keycode: int) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)


func _add_mouse_event(action: String, button_index: int) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action, event)


func _add_joy_button(action: String, button_index: int) -> void:
    _ensure_action(action)
    var event := InputEventJoypadButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action, event)


func _add_joy_axis(action: String, axis: int, value: float) -> void:
    _ensure_action(action)
    var event := InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = value
    InputMap.action_add_event(action, event)


## Standard gamepad layout: left stick moves, right stick turns the camera,
## face buttons for attack / dodge / interact, shoulders + dpad for skills.
func _setup_gamepad() -> void:
    _add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
    _add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
    _add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
    _add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
    _add_joy_axis("camera_rotate_left", JOY_AXIS_RIGHT_X, -1.0)
    _add_joy_axis("camera_rotate_right", JOY_AXIS_RIGHT_X, 1.0)
    _add_joy_button("attack", JOY_BUTTON_X)
    _add_joy_button("jump", JOY_BUTTON_DPAD_DOWN)
    _add_joy_button("dodge", JOY_BUTTON_A)
    _add_joy_button("interact", JOY_BUTTON_B)
    _add_joy_button("skill_1", JOY_BUTTON_LEFT_SHOULDER)
    _add_joy_button("skill_2", JOY_BUTTON_RIGHT_SHOULDER)
    _add_joy_button("skill_3", JOY_BUTTON_DPAD_LEFT)
    _add_joy_button("skill_4", JOY_BUTTON_DPAD_UP)
    _add_joy_button("ultimate", JOY_BUTTON_Y)
    _add_joy_button("toggle_inventory", JOY_BUTTON_BACK)
    _add_joy_button("toggle_game_menu", JOY_BUTTON_START)


## Rebinds one action (replaces its keyboard events, keeps mouse/gamepad ones).
func apply_binding(action: String, keycode: int) -> void:
    if keycode <= 0:
        return
    _ensure_action(action)
    for event in InputMap.action_get_events(action):
        if event is InputEventKey:
            InputMap.action_erase_event(action, event)
    _add_key_event(action, keycode)


func set_binding(action: String, keycode: int) -> void:
    _bindings[action] = keycode
    apply_binding(action, keycode)
    _save_bindings()
    EventBus.settings_changed.emit()


func reset_bindings() -> void:
    _bindings.clear()
    if FileAccess.file_exists(KEYS_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(KEYS_PATH))
    _setup_input_map()
    EventBus.settings_changed.emit()


## Human readable current binding, e.g. "W", "Space" or "鼠标左键".
func get_binding_label(action: String) -> String:
    var keys: Array[String] = []
    var mouse := ""
    for event in InputMap.action_get_events(action):
        if event is InputEventKey:
            keys.append(OS.get_keycode_string((event as InputEventKey).physical_keycode))
        elif event is InputEventMouseButton:
            mouse = _mouse_button_label((event as InputEventMouseButton).button_index)
    if not keys.is_empty():
        return keys[0] if mouse == "" else "%s / %s" % [keys[0], mouse]
    if mouse != "":
        return mouse
    return "-"


func _mouse_button_label(button_index: int) -> String:
    match button_index:
        MOUSE_BUTTON_LEFT:
            return "鼠标左键"
        MOUSE_BUTTON_RIGHT:
            return "鼠标右键"
        MOUSE_BUTTON_MIDDLE:
            return "鼠标中键"
    return "鼠标%d" % button_index


func _load_bindings() -> void:
    _bindings.clear()
    var config := ConfigFile.new()
    if config.load(KEYS_PATH) != OK:
        return
    var legacy_toggle_settings := 0
    var has_legacy_toggle_settings := false
    for action in config.get_section_keys("input"):
        var action_name := str(action)
        var keycode := int(config.get_value("input", action, 0))
        if action_name == "toggle_settings":
            legacy_toggle_settings = keycode
            has_legacy_toggle_settings = true
            continue
        _bindings[action_name] = keycode
    if has_legacy_toggle_settings and not _bindings.has("toggle_game_menu"):
        _bindings["toggle_game_menu"] = legacy_toggle_settings
    # Old builds bound dodge to Space. Split that default into Space = jump and
    # Shift = dodge so both actions remain usable after the control update.
    if int(_bindings.get("dodge", 0)) == KEY_SPACE:
        _bindings["jump"] = KEY_SPACE
        _bindings["dodge"] = KEY_SHIFT


func _save_bindings() -> void:
    var config := ConfigFile.new()
    for action in _bindings.keys():
        config.set_value("input", str(action), int(_bindings[action]))
    config.save(KEYS_PATH)
