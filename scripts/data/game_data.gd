class_name GameData
## Core game data: five elements, sexagenary cycle, realms, items, skills, enemies and achievements.

const ELEMENT_IDS: Array[String] = ["metal", "wood", "water", "fire", "earth"]

const ELEMENT_GENERATES := {
    "wood": "fire",
    "fire": "earth",
    "earth": "metal",
    "metal": "water",
    "water": "wood",
}

const ELEMENT_OVERCOMES := {
    "wood": "earth",
    "earth": "water",
    "water": "fire",
    "fire": "metal",
    "metal": "wood",
}

const STEMS: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
const BRANCHES: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
const STEM_ELEMENTS := ["wood", "wood", "fire", "fire", "earth", "earth", "metal", "metal", "water", "water"]
const BRANCH_ELEMENTS := ["water", "earth", "wood", "wood", "earth", "fire", "fire", "earth", "metal", "metal", "earth", "water"]

const REALMS := [
    {"key": "realm_0", "xp": 0.0, "hp": 100.0, "qi": 50.0, "atk": 10.0, "def": 5.0},
    {"key": "realm_1", "xp": 120.0, "hp": 160.0, "qi": 90.0, "atk": 18.0, "def": 10.0},
    {"key": "realm_2", "xp": 420.0, "hp": 260.0, "qi": 160.0, "atk": 30.0, "def": 18.0},
    {"key": "realm_3", "xp": 1100.0, "hp": 430.0, "qi": 280.0, "atk": 52.0, "def": 31.0},
    {"key": "realm_4", "xp": 2500.0, "hp": 700.0, "qi": 480.0, "atk": 86.0, "def": 52.0},
    {"key": "realm_5", "xp": 5200.0, "hp": 1100.0, "qi": 800.0, "atk": 140.0, "def": 84.0},
    {"key": "realm_6", "xp": 10400.0, "hp": 1750.0, "qi": 1300.0, "atk": 230.0, "def": 135.0},
    {"key": "realm_7", "xp": 20000.0, "hp": 2700.0, "qi": 2100.0, "atk": 370.0, "def": 215.0},
    {"key": "realm_8", "xp": 38000.0, "hp": 4200.0, "qi": 3400.0, "atk": 590.0, "def": 340.0},
    {"key": "realm_9", "xp": 70000.0, "hp": 6500.0, "qi": 5400.0, "atk": 930.0, "def": 540.0},
    {"key": "realm_10", "xp": 120000.0, "hp": 10000.0, "qi": 8800.0, "atk": 1500.0, "def": 860.0},
]

const ITEMS := {
    "weapon_qingfeng": {
        "type": "equipment", "slot": "weapon", "rarity": 2, "stackable": false, "color": "#65c96f",
        "element": "wood", "value": 80, "stats": {"attack": 8.0, "crit_chance": 0.02},
    },
    "weapon_xuantie": {
        "type": "equipment", "slot": "weapon", "rarity": 3, "stackable": false, "color": "#d9ddc7",
        "element": "metal", "value": 260, "stats": {"attack": 19.0, "defense": 4.0, "move_speed": -0.4},
    },
    "armor_buyi": {
        "type": "equipment", "slot": "body", "rarity": 1, "stackable": false, "color": "#b89b6a",
        "element": "earth", "value": 30, "stats": {"defense": 3.0, "max_health": 20.0},
    },
    "armor_lingjia": {
        "type": "equipment", "slot": "body", "rarity": 3, "stackable": false, "color": "#7bd18a",
        "element": "wood", "value": 420, "stats": {"defense": 14.0, "max_health": 90.0},
    },
    "accessory_yupei": {
        "type": "equipment", "slot": "accessory", "rarity": 2, "stackable": false, "color": "#6fb7f2",
        "element": "water", "value": 150, "stats": {"max_health": 45.0, "max_qi": 20.0},
    },
    "accessory_fu": {
        "type": "equipment", "slot": "accessory", "rarity": 3, "stackable": false, "color": "#f0e68c",
        "element": "metal", "value": 380, "stats": {"attack": 6.0, "crit_chance": 0.05},
    },
    "consumable_jinchuang": {
        "type": "consumable", "rarity": 1, "stackable": true, "max_stack": 99, "color": "#d98d5d",
        "element": "earth", "value": 12, "use_effect": {"heal_ratio": 0.35},
    },
    "consumable_huiqi": {
        "type": "consumable", "rarity": 1, "stackable": true, "max_stack": 99, "color": "#61a8e8",
        "element": "water", "value": 18, "use_effect": {"restore_qi": 45.0},
    },
    "consumable_juling": {
        "type": "consumable", "rarity": 2, "stackable": true, "max_stack": 99, "color": "#82dc8d",
        "element": "wood", "value": 55, "use_effect": {"cultivation_xp": 80.0},
    },
    "consumable_xiaohun": {
        "type": "consumable", "rarity": 2, "stackable": true, "max_stack": 99, "color": "#9adbe8",
        "element": "water", "value": 30, "use_effect": {"cleanse": true, "heal_ratio": 0.12},
    },
    "material_lingcao": {
        "type": "material", "rarity": 1, "stackable": true, "max_stack": 999, "color": "#78c97b",
        "element": "wood", "value": 5,
    },
    "material_yaodan": {
        "type": "material", "rarity": 2, "stackable": true, "max_stack": 999, "color": "#d96b4f",
        "element": "fire", "value": 22,
    },
    "material_jingshi": {
        "type": "material", "rarity": 1, "stackable": true, "max_stack": 9999, "color": "#a7d8e6",
        "element": "metal", "value": 1,
    },
    "talisman_fire": {
        "type": "consumable", "rarity": 2, "stackable": true, "max_stack": 20, "color": "#f06b45",
        "element": "fire", "value": 35, "use_effect": {"aoe_damage": 55.0, "radius": 4.0},
    },
}

const SKILLS := {
    "basic_attack": {"element": "none", "type": "melee", "qi": 0.0, "cooldown": 0.65, "damage": 1.0, "range": 3.0},
    "skill_1": {"element": "wood", "type": "projectile", "qi": 8.0, "cooldown": 2.4, "damage": 1.35, "range": 15.0, "speed": 19.0},
    "skill_2": {"element": "fire", "type": "aoe", "qi": 18.0, "cooldown": 6.0, "damage": 1.85, "radius": 5.5},
    "skill_3": {"element": "water", "type": "buff", "qi": 15.0, "cooldown": 10.0, "duration": 7.0, "damage_reduction": 0.35},
    "skill_4": {"element": "metal", "type": "dash", "qi": 20.0, "cooldown": 8.0, "damage": 2.25, "dash_distance": 8.0, "range": 3.2},
    "ultimate": {"element": "earth", "type": "heal", "qi": 28.0, "cooldown": 14.0, "heal_ratio": 0.38, "duration": 6.0},
}

const ACTION_SKILLS: Array[String] = ["basic_attack", "skill_1", "skill_2", "skill_3", "skill_4"]

const ENEMIES := {
    "demon_wolf": {"element": "wood", "level": 1, "hp": 70.0, "atk": 12.0, "def": 3.0, "speed": 4.2, "aggro": 11.0, "range": 2.2, "cooldown": 1.45, "xp": 35.0, "color": "#5e8f5b", "scale": 1.0},
    "fire_imp": {"element": "fire", "level": 2, "hp": 95.0, "atk": 18.0, "def": 4.0, "speed": 3.6, "aggro": 13.0, "range": 9.0, "keep_distance": 6.5, "ranged": true, "cooldown": 1.25, "xp": 55.0, "color": "#d95b3f", "scale": 0.9},
    "stone_sentry": {"element": "earth", "level": 3, "hp": 190.0, "atk": 22.0, "def": 12.0, "speed": 2.2, "aggro": 10.0, "range": 3.0, "cooldown": 1.9, "xp": 85.0, "color": "#9b8a62", "scale": 1.25},
    "water_wraith": {"element": "water", "level": 3, "hp": 145.0, "atk": 26.0, "def": 6.0, "speed": 4.0, "aggro": 14.0, "range": 10.0, "keep_distance": 6.0, "ranged": true, "cooldown": 1.4, "xp": 80.0, "color": "#4b8fc7", "scale": 1.0},
    "metal_puppet": {"element": "metal", "level": 4, "hp": 260.0, "atk": 32.0, "def": 18.0, "speed": 3.0, "aggro": 12.0, "range": 3.0, "cooldown": 1.7, "xp": 125.0, "color": "#c9ceb8", "scale": 1.15},
}

const ENEMY_SPAWN_TABLE: Array[String] = ["demon_wolf", "fire_imp", "water_wraith", "stone_sentry", "metal_puppet"]

const NPCS := {
    "elder_shushan": {
        "name_key": "npc_elder",
        "title_key": "npc_elder_title",
        "quest_id": "wolf_cull",
        "position": {"x": 6.0, "y": 0.0, "z": -7.0},
    },
}

const QUESTS := {
    "wolf_cull": {
        "name_key": "quest_wolf_cull",
        "desc_key": "quest_wolf_cull_desc",
        "objective": {"type": "kill", "enemy_id": "demon_wolf", "target": 5},
        "reward_xp": 150.0,
        "reward_items": [
            {"id": "consumable_juling", "count": 2},
            {"id": "material_jingshi", "count": 80},
        ],
    },
}
const ACHIEVEMENTS := [
    {"id": "first_blood", "stat": "enemies_defeated", "target": 1.0},
    {"id": "hunter_10", "stat": "enemies_defeated", "target": 10.0},
    {"id": "hunter_100", "stat": "enemies_defeated", "target": 100.0},
    {"id": "elements_5", "special": "all_elements", "target": 1.0},
    {"id": "rich_1000", "stat": "stones_earned", "target": 1000.0},
    {"id": "realm_zhuji", "stat": "realm_index", "target": 2.0},
    {"id": "realm_jindan", "stat": "realm_index", "target": 3.0},
    {"id": "inventory_full", "special": "inventory_full", "target": 1.0},
    {"id": "day_survive", "stat": "days_survived", "target": 1.0},
    {"id": "damage_10000", "stat": "damage_dealt", "target": 10000.0},
    {"id": "collector_20", "stat": "items_collected", "target": 20.0},
    {"id": "skill_cast_50", "stat": "skills_cast", "target": 50.0},
]

static func element_name(element: String) -> String:
    return LocaleData.text("element_" + element)

static func element_color(element: String) -> Color:
    var colors := {"metal": "#d9ddc7", "wood": "#65c96f", "water": "#6fb7f2", "fire": "#f06b45", "earth": "#c59a54"}
    return Color(str(colors.get(element, "#777777")))


## Icon tint per spiritual root (灵根) - used by the skill bar so the whole bar
## takes the colour of the character's element.
const ELEMENT_ICON_COLORS := {
    "metal": "#ffd75a",    # 亮金色
    "wood": "#3ed492",     # 青绿色
    "water": "#86c8ff",    # 淡蓝色
    "fire": "#ff6a2b",     # 岩浆色
    "earth": "#a79277",    # 土灰色
    "thunder": "#7b4bd8",  # 深紫色
    "ice": "#c8d6de",      # 水银色
}


static func element_icon_color(element: String) -> Color:
    return Color(str(ELEMENT_ICON_COLORS.get(element, "#9fb0aa")))

static func element_damage_multiplier(attacker: String, defender: String) -> float:
    if attacker == defender:
        return 0.92
    if str(ELEMENT_GENERATES.get(attacker, "")) == defender:
        return 1.25
    if str(ELEMENT_OVERCOMES.get(attacker, "")) == defender:
        return 1.5
    if str(ELEMENT_GENERATES.get(defender, "")) == attacker:
        return 0.82
    if str(ELEMENT_OVERCOMES.get(defender, "")) == attacker:
        return 0.72
    return 1.0

static func element_relationship(attacker: String, defender: String) -> String:
    if attacker == defender:
        return "same"
    if str(ELEMENT_GENERATES.get(attacker, "")) == defender:
        return "generates"
    if str(ELEMENT_OVERCOMES.get(attacker, "")) == defender:
        return "overcomes"
    if str(ELEMENT_GENERATES.get(defender, "")) == attacker:
        return "generated_by"
    if str(ELEMENT_OVERCOMES.get(defender, "")) == attacker:
        return "overcome_by"
    return "neutral"

static func hour_branch_index(hour: int) -> int:
    return posmod(int(floor((hour + 1) / 2.0)), 12)

static func hour_name(hour: int) -> String:
    return branch_name(hour_branch_index(hour)) + LocaleData.text("time")

static func stem_name(index: int) -> String:
    return LocaleData.text("stem_%d" % posmod(index, 10))

static func branch_name(index: int) -> String:
    return LocaleData.text("branch_%d" % posmod(index, 12))

static func year_pillar(year: int) -> Dictionary:
    var stem := posmod(year - 4, 10)
    var branch := posmod(year - 4, 12)
    return {"stem": stem, "branch": branch, "name": stem_name(stem) + branch_name(branch), "element": STEM_ELEMENTS[stem]}

static func month_pillar(year_stem: int, month: int) -> Dictionary:
    var branch := posmod(month, 12)
    var stem := posmod((year_stem % 5) * 2 + 2 + posmod(branch - 2, 12), 10)
    return {"stem": stem, "branch": branch, "name": stem_name(stem) + branch_name(branch), "element": BRANCH_ELEMENTS[branch]}

static func day_pillar(year: int, month: int, day: int) -> Dictionary:
    var jdn := _gregorian_to_jdn(year, month, day)
    var sexagenary := posmod(jdn + 49, 60)
    var stem := sexagenary % 10
    var branch := sexagenary % 12
    return {"stem": stem, "branch": branch, "name": stem_name(stem) + branch_name(branch), "element": STEM_ELEMENTS[stem]}

static func hour_pillar(day_stem: int, hour: int) -> Dictionary:
    var branch := hour_branch_index(hour)
    var stem := posmod(day_stem * 2 + branch, 10)
    return {"stem": stem, "branch": branch, "name": stem_name(stem) + branch_name(branch), "element": BRANCH_ELEMENTS[branch]}

static func get_pillars(year: int, month: int, day: int, hour: int) -> Dictionary:
    var year_p := year_pillar(year)
    var month_p := month_pillar(int(year_p["stem"]), month)
    var day_p := day_pillar(year, month, day)
    var hour_p := hour_pillar(int(day_p["stem"]), hour)
    return {
        "year": year_p,
        "month": month_p,
        "day": day_p,
        "hour": hour_p,
        "text": "%s %s %s %s" % [year_p["name"], month_p["name"], day_p["name"], hour_p["name"]],
    }

static func realm_name(index: int) -> String:
    var i := clampi(index, 0, REALMS.size() - 1)
    return LocaleData.text(str(REALMS[i]["key"]))

static func realm_for_xp(xp: float) -> int:
    var index := 0
    for i in range(REALMS.size()):
        if xp >= float(REALMS[i]["xp"]):
            index = i
    return index

static func realm_stats(index: int) -> Dictionary:
    var i := clampi(index, 0, REALMS.size() - 1)
    return REALMS[i].duplicate(true)

static func realm_next_xp(index: int) -> float:
    if index + 1 >= REALMS.size():
        return -1.0
    return float(REALMS[index + 1]["xp"])

static func item(id: String) -> Dictionary:
    var data: Dictionary = ITEMS.get(id, {}).duplicate(true)
    if not data.is_empty():
        data["name"] = LocaleData.text("item_" + id)
        data["desc"] = LocaleData.text("item_desc_" + id)
    return data

static func item_name(id: String) -> String:
    return LocaleData.text("item_" + id)

static func item_color(id: String) -> Color:
    var data: Dictionary = ITEMS.get(id, {})
    return Color(str(data.get("color", "#777777")))

static func rarity_color(rarity: int) -> Color:
    if rarity <= 0:
        return Color(0.75, 0.75, 0.75)
    if rarity == 1:
        return Color(0.92, 0.92, 0.92)
    if rarity == 2:
        return Color(0.45, 0.86, 0.48)
    if rarity == 3:
        return Color(0.38, 0.68, 1.0)
    if rarity == 4:
        return Color(0.80, 0.48, 1.0)
    return Color(1.0, 0.72, 0.25)

## Icon glyph used by the inventory / equipment cells for every item id.
const ITEM_ICONS := {
    "weapon_qingfeng": "sword",
    "weapon_xuantie": "sword",
    "armor_buyi": "body",
    "armor_lingjia": "body",
    "accessory_yupei": "accessory",
    "accessory_fu": "talisman",
    "consumable_jinchuang": "potion",
    "consumable_huiqi": "potion",
    "consumable_juling": "potion",
    "consumable_xiaohun": "potion",
    "material_lingcao": "wood",
    "material_yaodan": "orb",
    "material_jingshi": "metal",
    "talisman_fire": "talisman",
}


static func item_type_name(type_id: String) -> String:
    return LocaleData.text(type_id)


## UiIcon glyph for an item, falling back to its equipment slot / category.
static func item_icon(id: String) -> String:
    if ITEM_ICONS.has(id):
        return str(ITEM_ICONS[id])
    var row := item_row(id)
    match str(row.get("slot", "")):
        "weapon":
            return "sword"
        "head":
            return "head"
        "body":
            return "body"
        "accessory":
            return "accessory"
        "talisman":
            return "talisman"
    match str(row.get("type", "")):
        "consumable":
            return "potion"
        "material":
            return "orb"
    return "bag"

## Raw item table row (no localization) - used by inventory sorting/filtering.
static func item_row(id: String) -> Dictionary:
    var row: Variant = ITEMS.get(id, {})
    if row is Dictionary:
        return row
    return {}


## Inventory filter category: equipment / consumable / material.
static func item_category(id: String) -> String:
    return str(item_row(id).get("type", "material"))

static func slot_name(slot_id: String) -> String:
    return LocaleData.text(slot_id)

static func skill(id: String) -> Dictionary:
    var data: Dictionary = SKILLS.get(id, {}).duplicate(true)
    if not data.is_empty():
        data["name"] = LocaleData.text(id)
        data["desc"] = LocaleData.text("skill_desc_" + id)
    return data

static func enemy(id: String) -> Dictionary:
    var data: Dictionary = ENEMIES.get(id, {}).duplicate(true)
    if not data.is_empty():
        data["name"] = LocaleData.text("enemy_" + id)
    return data

static func npc(id: String) -> Dictionary:
    var data: Dictionary = NPCS.get(id, {}).duplicate(true)
    if not data.is_empty():
        data["name"] = LocaleData.text(str(data.get("name_key", "npc_" + id)))
        data["title"] = LocaleData.text(str(data.get("title_key", "")))
    return data

static func quest(id: String) -> Dictionary:
    var data: Dictionary = QUESTS.get(id, {}).duplicate(true)
    if not data.is_empty():
        data["name"] = LocaleData.text(str(data.get("name_key", "quest_" + id)))
        data["desc"] = LocaleData.text(str(data.get("desc_key", "quest_desc_" + id)))
    return data
static func achievement_list() -> Array:
    var result := []
    for ach in ACHIEVEMENTS:
        var item: Dictionary = ach.duplicate(true)
        item["name"] = LocaleData.text("ach_" + str(item["id"]))
        item["desc"] = LocaleData.text("ach_desc_" + str(item["id"]))
        result.append(item)
    return result

static func random_enemy_id(player_realm: int, rng: RandomNumberGenerator) -> String:
    var max_tier := clampi(player_realm + 2, 1, ENEMY_SPAWN_TABLE.size())
    return ENEMY_SPAWN_TABLE[rng.randi_range(0, max_tier - 1)]

static func starting_items() -> Array:
    return [
        {"id": "weapon_qingfeng", "count": 1},
        {"id": "armor_buyi", "count": 1},
        {"id": "consumable_jinchuang", "count": 5},
        {"id": "consumable_huiqi", "count": 3},
        {"id": "material_lingcao", "count": 3},
        {"id": "material_jingshi", "count": 50},
    ]

static func roll_loot(level: int, rng: RandomNumberGenerator) -> Array:
    var drops := []
    var count := rng.randi_range(0, 2)
    for i in range(count):
        var pick := rng.randf()
        if pick < 0.50:
            drops.append({"id": "material_jingshi", "count": rng.randi_range(2, 8) + level})
        elif pick < 0.72:
            drops.append({"id": "material_lingcao", "count": rng.randi_range(1, 2)})
        elif pick < 0.86:
            drops.append({"id": "material_yaodan", "count": 1})
        elif pick < 0.94:
            drops.append({"id": "consumable_jinchuang", "count": 1})
        else:
            drops.append({"id": "consumable_huiqi", "count": 1})
    if rng.randf() < 0.08:
        drops.append({"id": "accessory_yupei", "count": 1})
    return drops

static func _gregorian_to_jdn(year: int, month: int, day: int) -> int:
    var a := int((14 - month) / 12.0)
    var y := year + 4800 - a
    var m := month + 12 * a - 3
    return day + int((153 * m + 2) / 5.0) + 365 * y + int(y / 4.0) - int(y / 100.0) + int(y / 400.0) - 32045
