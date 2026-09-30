class_name FashionData
## Player fashion (时装) catalogue - a purely cosmetic layer over the equipment.
##
## An outfit never touches stats.  It only swaps the look of the character:
## robe / trim / glow colours on the base body, a handful of procedural
## accessories and an optional aura.  FashionVisuals turns a resolved appearance
## dictionary into nodes, so the in-world player and the wardrobe preview can
## never drift apart.
##
## Row fields:
##   name / desc - display text
##   rarity      - 1..5, drives the frame colour, gloss and glow strength
##   element     - spiritual root association (flavour only)
##   realm       - minimum realm index required to unlock
##   cost        - item id -> count, consumed on unlock ({} = free)
##   parts       - procedural accessories, see FashionVisuals.PART_IDS
##   aura        - "none" / "mist" / "ember" / "halo" / "star"
##   palettes    - colour schemes; index 0 is the original colouring

const AURA_KINDS: Array[String] = ["none", "mist", "ember", "halo", "star"]
const PART_IDS: Array[String] = ["crown", "cape", "sash", "pauldron", "orbit", "halo"]

## Outfits a brand new character already owns.
const STARTER_OWNED: Array[String] = ["suxin", "qingzhu"]

const FASHION := {
    "suxin": {
        "name": "素心道袍",
        "desc": "初入山门时人各一件的素色道袍，针脚朴拙，却洗不掉那一点松烟墨香。",
        "rarity": 1,
        "element": "none",
        "realm": 0,
        "cost": {},
        "parts": ["sash"],
        "aura": "none",
        "palettes": [
            {"name": "素白", "robe": "#e6e3d8", "trim": "#b3b8ad", "glow": "#f2f7f0"},
            {"name": "竹青", "robe": "#9fb59a", "trim": "#6f8a6a", "glow": "#cdf3d6"},
            {"name": "玄墨", "robe": "#3b414a", "trim": "#7d8794", "glow": "#b8c6d8"},
        ],
    },
    "qingzhu": {
        "name": "青竹客",
        "desc": "取南岭青竹织成的客袍，行走时衣袂如竹叶翻风，最宜轻身步法。",
        "rarity": 2,
        "element": "wood",
        "realm": 0,
        "cost": {},
        "parts": ["sash", "cape"],
        "aura": "none",
        "palettes": [
            {"name": "竹青", "robe": "#7fc98a", "trim": "#4e8f5c", "glow": "#c8ffd4"},
            {"name": "霜白", "robe": "#dfe9df", "trim": "#a9c0aa", "glow": "#eafff0"},
            {"name": "沉碧", "robe": "#2f6b4a", "trim": "#8fbf9a", "glow": "#8cffc0"},
        ],
    },
    "liuyun": {
        "name": "流云仙衣",
        "desc": "云锦裁成，衣上流云似水非水，行走间周身浮起一层薄薄寒雾。",
        "rarity": 2,
        "element": "water",
        "realm": 1,
        "cost": {"material_jingshi": 320, "material_lingcao": 6},
        "parts": ["cape", "orbit"],
        "aura": "mist",
        "palettes": [
            {"name": "流云白", "robe": "#dbe9f5", "trim": "#8fb6d8", "glow": "#bfe4ff"},
            {"name": "沧海蓝", "robe": "#4f8fd0", "trim": "#2f5f96", "glow": "#9fd8ff"},
            {"name": "月华银", "robe": "#c8d6e0", "trim": "#8d9fb0", "glow": "#e8f4ff"},
        ],
    },
    "chiyan": {
        "name": "赤炎战袍",
        "desc": "以火浣布缝制，触之微烫；怒意上涌时，衣角会腾起细碎的赤焰。",
        "rarity": 3,
        "element": "fire",
        "realm": 1,
        "cost": {"material_jingshi": 480, "material_yaodan": 3},
        "parts": ["pauldron", "cape"],
        "aura": "ember",
        "palettes": [
            {"name": "赤炎", "robe": "#c8492c", "trim": "#ff9a3c", "glow": "#ff5a1e"},
            {"name": "焦岩", "robe": "#7a3b2a", "trim": "#c98a52", "glow": "#ff7a2a"},
            {"name": "烬灰", "robe": "#4a4038", "trim": "#c06a3a", "glow": "#ffb066"},
        ],
    },
    "xuanwu": {
        "name": "玄武甲胄",
        "desc": "仿玄武背甲所铸，重而不滞，护心处嵌一枚镇岳石。",
        "rarity": 3,
        "element": "earth",
        "realm": 2,
        "cost": {"material_jingshi": 620, "material_yaodan": 4},
        "parts": ["pauldron", "crown"],
        "aura": "none",
        "palettes": [
            {"name": "玄武墨", "robe": "#5b6470", "trim": "#c9a75e", "glow": "#a8d8c8"},
            {"name": "玄黄", "robe": "#7a6a4a", "trim": "#e0c070", "glow": "#ffe9a8"},
            {"name": "铁青", "robe": "#3f4a52", "trim": "#9fb0b8", "glow": "#c0e8ff"},
        ],
    },
    "jinyi": {
        "name": "鎏金锦衣",
        "desc": "金线九千匝，织成云雷纹；衣着加身时，身后隐约现出一轮淡金佛光。",
        "rarity": 4,
        "element": "metal",
        "realm": 2,
        "cost": {"material_jingshi": 900, "material_yaodan": 6},
        "parts": ["crown", "sash", "cape"],
        "aura": "halo",
        "palettes": [
            {"name": "鎏金", "robe": "#c9a24a", "trim": "#ffe08a", "glow": "#ffd97a"},
            {"name": "绛紫", "robe": "#7a3f8f", "trim": "#e0a8ff", "glow": "#d9a0ff"},
            {"name": "玉白", "robe": "#e8e4d4", "trim": "#d8b96a", "glow": "#fff0b8"},
        ],
    },
    "baize": {
        "name": "白泽瑞服",
        "desc": "白泽知万物之情，其纹绣于衣上，可避百邪；星辉绕身，久视不散。",
        "rarity": 4,
        "element": "metal",
        "realm": 3,
        "cost": {"material_jingshi": 1200, "material_yaodan": 8},
        "parts": ["crown", "orbit", "halo"],
        "aura": "star",
        "palettes": [
            {"name": "瑞白", "robe": "#eceff2", "trim": "#a8c4e0", "glow": "#dff0ff"},
            {"name": "星霜", "robe": "#b9c9d8", "trim": "#7f9fc4", "glow": "#ffffff"},
            {"name": "墨玉", "robe": "#39424e", "trim": "#c9d6e4", "glow": "#b8e0ff"},
        ],
    },
    "taowu": {
        "name": "梼杌妖衣",
        "desc": "以梼杌残皮所制，衣袂间常闻低吼；煞气缠身，妖邪不敢近。",
        "rarity": 4,
        "element": "fire",
        "realm": 3,
        "cost": {"material_jingshi": 1100, "material_yaodan": 10},
        "parts": ["pauldron", "orbit"],
        "aura": "ember",
        "palettes": [
            {"name": "妖赤", "robe": "#8f2f28", "trim": "#ff7a4a", "glow": "#ff3a1e"},
            {"name": "骨白", "robe": "#b9ab98", "trim": "#8f5a4a", "glow": "#ff9a6a"},
            {"name": "玄煞", "robe": "#3a2b32", "trim": "#a04a5a", "glow": "#ff6a8a"},
        ],
    },
    "zhulong": {
        "name": "烛龙衮服",
        "desc": "烛龙衔烛照九阴，衮服之上金鳞流转，昼夜晦明皆随其衣色。",
        "rarity": 5,
        "element": "fire",
        "realm": 4,
        "cost": {"material_jingshi": 2000, "material_yaodan": 16},
        "parts": ["crown", "cape", "halo", "orbit"],
        "aura": "halo",
        "palettes": [
            {"name": "烛龙金", "robe": "#d8a63a", "trim": "#ffe9a0", "glow": "#ffcf5a"},
            {"name": "赤霄", "robe": "#b0342c", "trim": "#ff9a4a", "glow": "#ff6a2a"},
            {"name": "幽明", "robe": "#2f2b3f", "trim": "#d8b96a", "glow": "#c8b0ff"},
        ],
    },
    "hongmeng": {
        "name": "鸿蒙道袍",
        "desc": "鸿蒙初开时一缕清气得成，衣无缝合，望之若有若无，是仙途尽头的一件旧衣。",
        "rarity": 5,
        "element": "wood",
        "realm": 5,
        "cost": {"material_jingshi": 2600, "material_yaodan": 20},
        "parts": ["crown", "cape", "halo", "orbit", "sash"],
        "aura": "star",
        "palettes": [
            {"name": "鸿蒙青", "robe": "#4f8f7a", "trim": "#e8e0b8", "glow": "#b8ffd8"},
            {"name": "太初玄", "robe": "#2b3340", "trim": "#9fb8d8", "glow": "#c8e8ff"},
            {"name": "紫气", "robe": "#5a4a8f", "trim": "#e0c8ff", "glow": "#d8b8ff"},
        ],
    },
}


static func ids() -> Array[String]:
    var result: Array[String] = []
    for id in FASHION.keys():
        result.append(str(id))
    return result


static func has(id: String) -> bool:
    return FASHION.has(id)


static func count() -> int:
    return FASHION.size()


## Raw table row (no localization, no colour parsing).
static func row(id: String) -> Dictionary:
    var data: Variant = FASHION.get(id, {})
    if data is Dictionary:
        return data
    return {}


static func name(id: String) -> String:
    return str(row(id).get("name", id))


static func desc(id: String) -> String:
    return str(row(id).get("desc", ""))


static func rarity(id: String) -> int:
    return clampi(int(row(id).get("rarity", 1)), 1, 5)


static func element(id: String) -> String:
    return str(row(id).get("element", "none"))


static func realm_requirement(id: String) -> int:
    return maxi(int(row(id).get("realm", 0)), 0)


static func cost(id: String) -> Dictionary:
    var data: Variant = row(id).get("cost", {})
    if data is Dictionary:
        return data
    return {}


static func parts(id: String) -> Array:
    var data: Variant = row(id).get("parts", [])
    if data is Array:
        return data
    return []


static func aura(id: String) -> String:
    var kind := str(row(id).get("aura", "none"))
    if not AURA_KINDS.has(kind):
        return "none"
    return kind


static func palettes(id: String) -> Array:
    var data: Variant = row(id).get("palettes", [])
    if data is Array:
        return data
    return []


static func palette_count(id: String) -> int:
    return maxi(palettes(id).size(), 1)


## Resolved colour scheme: {"name": String, "robe": Color, "trim": Color, "glow": Color}
static func palette(id: String, index: int) -> Dictionary:
    var list := palettes(id)
    var entry: Dictionary = {}
    if not list.is_empty():
        var pick: Variant = list[clampi(index, 0, list.size() - 1)]
        if pick is Dictionary:
            entry = pick
    return {
        "name": str(entry.get("name", "")),
        "robe": Color(str(entry.get("robe", "#6bd0a0"))),
        "trim": Color(str(entry.get("trim", "#cfd8d0"))),
        "glow": Color(str(entry.get("glow", "#9ff0c8"))),
    }


static func rarity_color(id: String) -> Color:
    return GameData.rarity_color(rarity(id))


## Runtime appearance consumed by FashionVisuals, the player and the preview.
static func appearance(id: String, palette_index: int = 0, aura_enabled: bool = true) -> Dictionary:
    if not has(id):
        return {}
    return {
        "id": id,
        "name": name(id),
        "rarity": rarity(id),
        "element": element(id),
        "palette": clampi(palette_index, 0, palette_count(id) - 1),
        "colors": palette(id, palette_index),
        "parts": parts(id).duplicate(),
        "aura": aura(id) if aura_enabled else "none",
    }


static func part_name(part_id: String) -> String:
    return LocaleData.text("fashion_part_" + part_id)


static func aura_name(kind: String) -> String:
    return LocaleData.text("fashion_aura_" + kind)


static func part_list_text(id: String) -> String:
    var names: Array[String] = []
    for part_id in parts(id):
        names.append(part_name(str(part_id)))
    if names.is_empty():
        return LocaleData.text("fashion_part_none")
    return " · ".join(names)


static func cost_text(id: String) -> String:
    var entries := cost(id)
    if entries.is_empty():
        return LocaleData.text("fashion_free")
    var chunks: Array[String] = []
    for item_id in entries.keys():
        chunks.append("%s ×%d" % [GameData.item_name(str(item_id)), int(entries[item_id])])
    return " · ".join(chunks)


static func requirement_text(id: String) -> String:
    var requirement := realm_requirement(id)
    if requirement <= 0:
        return ""
    return LocaleData.text("fashion_block_realm") % GameData.realm_name(requirement)