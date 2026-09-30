extends Node
## Global game state: character, inventory, equipment, achievements, calendar and save data.

const SAVE_PATH := "user://tides_of_guixu_save.json"
const SETTINGS_PATH := "user://tides_of_guixu_settings.cfg"
const INVENTORY_SIZE := 40

const DEFAULT_SETTINGS := {
    "camera_mode": 0,
    "mouse_sensitivity": 0.0025,
    "invert_y": false,
    "camera_fov": 55.0,
    "camera_rotate_speed": 110.0,
    "master_volume_db": -6.0,
    "fullscreen": false,
    "resolution_index": 0,
    "show_damage_numbers": true,
    "ui_scale": 1.0,
}

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
var equipment: Dictionary = {"weapon": "", "head": "", "body": "", "accessory": "", "talisman": ""}
var achievements: Dictionary = {}
var quest_states: Dictionary = {}
var tracked_quest_id := ""
var stats: Dictionary = {}
var game_time: Dictionary = {"year": 2025, "month": 3, "day": 1, "hour": 9, "minute": 0}
var play_time := 0.0
var has_started := false
var settings: Dictionary = {}
var time_scale := 60.0
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
    var base := get_total_stats()
    health = float(base["max_health"])
    qi = float(base["max_qi"])
    equipment = {"weapon": "", "head": "", "body": "", "accessory": "", "talisman": ""}
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
    has_started = true
    EventBus.game_started.emit()
    EventBus.player_stats_changed.emit()
    EventBus.inventory_changed.emit()
    EventBus.equipment_changed.emit()
    EventBus.time_changed.emit(get_pillars())
    EventBus.toast_requested.emit(LocaleData.text("toast_start"), Color(0.7, 0.95, 0.8))
    save_game()

func _equip_starting_gear() -> void:
    for i in range(inventory.size()):
        var slot: Variant = inventory[i]
        if slot is Dictionary and str(slot.get("id", "")) == "weapon_qingfeng":
            equip_item(i)
            break
    for i in range(inventory.size()):
        var slot: Variant = inventory[i]
        if slot is Dictionary and str(slot.get("id", "")) == "armor_buyi":
            equip_item(i)
            break

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
        var item: Variant = GameData.ITEMS.get(item_id, {})
        if not (item is Dictionary):
            continue
        var item_stats: Variant = item.get("stats", {})
        if item_stats is Dictionary:
            for stat_key in item_stats.keys():
                result[stat_key] = float(result.get(stat_key, 0.0)) + float(item_stats[stat_key])
    return result

func get_realm_name() -> String:
    return GameData.realm_name(realm_index)

func get_element_name() -> String:
    return GameData.element_name(player_element)

func get_birth_text() -> String:
    if birth_pillar.is_empty():
        return LocaleData.text("none")
    return str(birth_pillar.get("name", "")) + " / " + GameData.element_name(str(birth_pillar.get("element", "earth")))

func add_cultivation_xp(amount: float) -> void:
    if amount <= 0.0:
        return
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
        "accessory":
            slot_rank = 3
        "talisman":
            slot_rank = 4
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
        return 0.0
    var current := float(stats.get(str(achievement.get("stat", "")), 0.0))
    var target := maxf(float(achievement.get("target", 1.0)), 1.0)
    return clampf(current / target, 0.0, 1.0)

func get_achievement_progress_text(achievement: Dictionary) -> String:
    if is_achievement_unlocked(str(achievement.get("id", ""))):
        return LocaleData.text("unlocked")
    if achievement.has("special") and str(achievement["special"]) == "inventory_full":
        return "%d / %d" % [_occupied_slots(), INVENTORY_SIZE]
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

func get_time_string() -> String:
    return "%04d-%02d-%02d %02d:%02d" % [int(game_time["year"]), int(game_time["month"]), int(game_time["day"]), int(game_time["hour"]), int(game_time["minute"])]

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
    AudioServer.set_bus_volume_db(0, float(settings.get("master_volume_db", -6.0)))
    if get_window() != null:
        get_window().content_scale_factor = clampf(float(settings.get("ui_scale", 1.0)), 0.8, 1.4)
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
        equipment = loaded_equipment
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
    var loaded_time: Variant = data.get("game_time", {})
    if loaded_time is Dictionary:
        game_time = loaded_time
    play_time = float(data.get("play_time", 0.0))
    has_started = true
    EventBus.game_loaded.emit()
    EventBus.player_stats_changed.emit()
    EventBus.inventory_changed.emit()
    EventBus.equipment_changed.emit()
    EventBus.time_changed.emit(get_pillars())
    return true

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _setup_input_map() -> void:
    _add_key_action("move_forward", [KEY_W, KEY_UP])
    _add_key_action("move_back", [KEY_S, KEY_DOWN])
    _add_key_action("move_left", [KEY_A, KEY_LEFT])
    _add_key_action("move_right", [KEY_D, KEY_RIGHT])
    _add_key_action("dodge", [KEY_SPACE])
    _add_key_action("interact", [KEY_F])
    _add_key_action("camera_rotate_left", [KEY_Q])
    _add_key_action("camera_rotate_right", [KEY_E])
    _add_key_action("camera_reset", [KEY_R])
    _add_key_action("toggle_inventory", [KEY_TAB, KEY_I])
    _add_key_action("toggle_character", [KEY_C])
    _add_key_action("toggle_achievements", [KEY_K])
    _add_key_action("toggle_settings", [KEY_ESCAPE])
    _add_key_action("toggle_camera", [KEY_V])
    _add_key_action("skill_1", [KEY_1])
    _add_key_action("skill_2", [KEY_2])
    _add_key_action("skill_3", [KEY_3])
    _add_key_action("skill_4", [KEY_4])
    _add_key_action("ultimate", [KEY_5])
    _add_mouse_action("attack", MOUSE_BUTTON_LEFT)

func _add_key_action(action: StringName, keycodes: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.5)
    if not InputMap.action_get_events(action).is_empty():
        return
    for code in keycodes:
        var event := InputEventKey.new()
        event.physical_keycode = code
        InputMap.action_add_event(action, event)

func _add_mouse_action(action: StringName, button_index: int) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.5)
    if not InputMap.action_get_events(action).is_empty():
        return
    var event := InputEventMouseButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action, event)
