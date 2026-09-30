class_name EquipmentData
## Generated Shan Hai Jing-inspired equipment sets and their set bonuses.
##
## Each set piece is a plain item row consumed by GameData.item_row().  The
## SETS table keeps the display name, flavour text, piece list and 2/4/7-piece
## bonuses together so gameplay and UI stay in sync.

const ITEMS := {
    "set_qingfeng_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 43,
        "name": "\u6e05\u98ce\u5251",
        "desc": "\u4ee5\u6e05\u98ce\u4e4b\u529b\u94f8\u6210\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 8.0,
            "crit_chance": 0.023,
            "crit_damage": 0.059
        }
    },
    "set_qingfeng_head": {
        "type": "equipment",
        "slot": "head",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 46,
        "name": "\u6e05\u98ce\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u6e05\u98ce\u4e4b\u7eb9\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 2.0,
            "max_health": 11.0,
            "max_qi": 6.0
        }
    },
    "set_qingfeng_body": {
        "type": "equipment",
        "slot": "body",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 49,
        "name": "\u6e05\u98ce\u888d",
        "desc": "\u8863\u7532\u6d41\u8f6c\u6e05\u98ce\u7075\u5149\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 3.0,
            "max_health": 16.0,
            "max_qi": 3.0
        }
    },
    "set_qingfeng_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 52,
        "name": "\u6e05\u98ce\u88e4",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u6e05\u98ce\u4e91\u7eb9\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 2.0,
            "max_health": 13.0,
            "move_speed": 0.13
        }
    },
    "set_qingfeng_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 55,
        "name": "\u6e05\u98ce\u5c65",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u6e05\u98ce\u800c\u884c\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\u3002",
        "stats": {
            "defense": 1.0,
            "max_health": 5.0,
            "move_speed": 0.37
        }
    },
    "set_qingfeng_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 58,
        "name": "\u6e05\u98ce\u62a4\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u6e05\u98ce\u7075\u4e1d\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 5.0,
            "defense": 1.0,
            "crit_chance": 0.014
        }
    },
    "set_qingfeng_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "qingfeng",
        "rarity": 2,
        "stackable": false,
        "color": "#65c96f",
        "element": "wood",
        "value": 61,
        "name": "\u6e05\u98ce\u7389\u4f69",
        "desc": "\u4f69\u4e0a\u523b\u6709\u6e05\u98ce\u795e\u97f5\uff0c\u5251\u8d70\u8f7b\u7075\u3001\u8eab\u6cd5\u5982\u98ce\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 11.0,
            "crit_chance": 0.014,
            "crit_damage": 0.074
        }
    },
    "set_shaoxia_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 18,
        "name": "\u5c11\u4fa0\u5251",
        "desc": "\u4ee5\u5c11\u4fa0\u4e4b\u529b\u94f8\u6210\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 4.0,
            "crit_chance": 0.008,
            "crit_damage": 0.032
        }
    },
    "set_shaoxia_head": {
        "type": "equipment",
        "slot": "head",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 19,
        "name": "\u5c11\u4fa0\u5dfe",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u5c11\u4fa0\u4e4b\u7eb9\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 2.0,
            "max_health": 11.0,
            "max_qi": 5.0
        }
    },
    "set_shaoxia_body": {
        "type": "equipment",
        "slot": "body",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 20,
        "name": "\u5c11\u4fa0\u8863",
        "desc": "\u8863\u7532\u6d41\u8f6c\u5c11\u4fa0\u7075\u5149\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 3.0,
            "max_health": 17.0,
            "max_qi": 2.0
        }
    },
    "set_shaoxia_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 21,
        "name": "\u5c11\u4fa0\u88e4",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u5c11\u4fa0\u4e91\u7eb9\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 2.0,
            "max_health": 13.0,
            "move_speed": 0.05
        }
    },
    "set_shaoxia_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 23,
        "name": "\u5c11\u4fa0\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u5c11\u4fa0\u800c\u884c\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\u3002",
        "stats": {
            "defense": 1.0,
            "max_health": 6.0,
            "move_speed": 0.13
        }
    },
    "set_shaoxia_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 24,
        "name": "\u5c11\u4fa0\u62a4\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u5c11\u4fa0\u7075\u4e1d\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 3.0,
            "defense": 2.0,
            "crit_chance": 0.005
        }
    },
    "set_shaoxia_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "shaoxia",
        "rarity": 1,
        "stackable": false,
        "color": "#b89b6a",
        "element": "earth",
        "value": 25,
        "name": "\u5c11\u4fa0\u7389\u4f69",
        "desc": "\u4f69\u4e0a\u523b\u6709\u5c11\u4fa0\u795e\u97f5\uff0c\u610f\u6c14\u98ce\u53d1\u3001\u6839\u57fa\u624e\u5b9e\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 8.0,
            "crit_chance": 0.005,
            "crit_damage": 0.04
        }
    },
    "set_qinggang_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 93,
        "name": "\u9752\u94a2\u91cd\u5251",
        "desc": "\u4ee5\u9752\u94a2\u4e4b\u529b\u94f8\u6210\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 11.0,
            "crit_chance": 0.012,
            "crit_damage": 0.077
        }
    },
    "set_qinggang_head": {
        "type": "equipment",
        "slot": "head",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 100,
        "name": "\u9752\u94a2\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u9752\u94a2\u4e4b\u7eb9\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 10.0,
            "max_health": 43.0,
            "max_qi": 12.0
        }
    },
    "set_qinggang_body": {
        "type": "equipment",
        "slot": "body",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 106,
        "name": "\u9752\u94a2\u7532",
        "desc": "\u8863\u7532\u6d41\u8f6c\u9752\u94a2\u7075\u5149\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 14.0,
            "max_health": 65.0,
            "max_qi": 6.0
        }
    },
    "set_qinggang_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 113,
        "name": "\u9752\u94a2\u817f\u7532",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u9752\u94a2\u4e91\u7eb9\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 10.0,
            "max_health": 50.0,
            "move_speed": 0.06
        }
    },
    "set_qinggang_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 119,
        "name": "\u9752\u94a2\u6218\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u9752\u94a2\u800c\u884c\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\u3002",
        "stats": {
            "defense": 6.0,
            "max_health": 22.0,
            "move_speed": 0.17
        }
    },
    "set_qinggang_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 126,
        "name": "\u9752\u94a2\u62a4\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u9752\u94a2\u7075\u4e1d\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 6.0,
            "defense": 7.0,
            "crit_chance": 0.007
        }
    },
    "set_qinggang_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "qinggang",
        "rarity": 3,
        "stackable": false,
        "color": "#d9ddc7",
        "element": "metal",
        "value": 132,
        "name": "\u9752\u94a2\u864e\u7b26",
        "desc": "\u4f69\u4e0a\u523b\u6709\u9752\u94a2\u795e\u97f5\uff0c\u575a\u4e0d\u53ef\u6467\u3001\u521a\u67d4\u5e76\u6d4e\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 19.0,
            "crit_chance": 0.007,
            "crit_damage": 0.096
        }
    },
    "set_taowu_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 216,
        "name": "\u68bc\u674c\u7360\u7259",
        "desc": "\u4ee5\u68bc\u674c\u4e4b\u529b\u94f8\u6210\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 26.0,
            "crit_chance": 0.043,
            "crit_damage": 0.185
        }
    },
    "set_taowu_head": {
        "type": "equipment",
        "slot": "head",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 231,
        "name": "\u68bc\u674c\u517d\u9996\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u68bc\u674c\u4e4b\u7eb9\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 8.0,
            "max_health": 48.0,
            "max_qi": 10.0
        }
    },
    "set_taowu_body": {
        "type": "equipment",
        "slot": "body",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 245,
        "name": "\u68bc\u674c\u76ae\u7532",
        "desc": "\u8863\u7532\u6d41\u8f6c\u68bc\u674c\u7075\u5149\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 12.0,
            "max_health": 71.0,
            "max_qi": 5.0
        }
    },
    "set_taowu_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 261,
        "name": "\u68bc\u674c\u8840\u7eb9\u62a4\u817f",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u68bc\u674c\u4e91\u7eb9\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 8.0,
            "max_health": 55.0,
            "move_speed": 0.1
        }
    },
    "set_taowu_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 276,
        "name": "\u68bc\u674c\u6218\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u68bc\u674c\u800c\u884c\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\u3002",
        "stats": {
            "defense": 5.0,
            "max_health": 24.0,
            "move_speed": 0.28
        }
    },
    "set_taowu_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 291,
        "name": "\u68bc\u674c\u9aa8\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u68bc\u674c\u7075\u4e1d\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 16.0,
            "defense": 6.0,
            "crit_chance": 0.026
        }
    },
    "set_taowu_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "taowu",
        "rarity": 4,
        "stackable": false,
        "color": "#8b5a3c",
        "element": "earth",
        "value": 306,
        "name": "\u68bc\u674c\u51f6\u7b26",
        "desc": "\u4f69\u4e0a\u523b\u6709\u68bc\u674c\u795e\u97f5\uff0c\u51f6\u987d\u4e0d\u5c48\u3001\u529b\u5927\u65e0\u7a77\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 16.0,
            "crit_chance": 0.026,
            "crit_damage": 0.231
        }
    },
    "set_hongmeng_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 468,
        "name": "\u9e3f\u8499\u5f00\u5929\u5203",
        "desc": "\u4ee5\u9e3f\u8499\u4e4b\u529b\u94f8\u6210\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 34.0,
            "crit_chance": 0.068,
            "crit_damage": 0.288
        }
    },
    "set_hongmeng_head": {
        "type": "equipment",
        "slot": "head",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 500,
        "name": "\u9e3f\u8499\u9053\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u9e3f\u8499\u4e4b\u7eb9\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 16.0,
            "max_health": 81.0,
            "max_qi": 43.0
        }
    },
    "set_hongmeng_body": {
        "type": "equipment",
        "slot": "body",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 533,
        "name": "\u9e3f\u8499\u6cd5\u888d",
        "desc": "\u8863\u7532\u6d41\u8f6c\u9e3f\u8499\u7075\u5149\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 22.0,
            "max_health": 122.0,
            "max_qi": 22.0
        }
    },
    "set_hongmeng_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 565,
        "name": "\u9e3f\u8499\u4e91\u7eb9\u88e4",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u9e3f\u8499\u4e91\u7eb9\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 16.0,
            "max_health": 94.0,
            "move_speed": 0.25
        }
    },
    "set_hongmeng_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 598,
        "name": "\u9e3f\u8499\u8e0f\u865a\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u9e3f\u8499\u800c\u884c\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\u3002",
        "stats": {
            "defense": 9.0,
            "max_health": 40.0,
            "move_speed": 0.69
        }
    },
    "set_hongmeng_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 630,
        "name": "\u9e3f\u8499\u62a4\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u9e3f\u8499\u7075\u4e1d\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 20.0,
            "defense": 11.0,
            "crit_chance": 0.041
        }
    },
    "set_hongmeng_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "hongmeng",
        "rarity": 5,
        "stackable": false,
        "color": "#d8b4ff",
        "element": "none",
        "value": 663,
        "name": "\u9e3f\u8499\u6df7\u6c8c\u7389",
        "desc": "\u4f69\u4e0a\u523b\u6709\u9e3f\u8499\u795e\u97f5\uff0c\u6df7\u6c8c\u521d\u5f00\u3001\u4e07\u6cd5\u5f52\u5143\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 72.0,
            "crit_chance": 0.041,
            "crit_damage": 0.36
        }
    },
    "set_baize_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 230,
        "name": "\u767d\u6cfd\u7075\u5251",
        "desc": "\u4ee5\u767d\u6cfd\u4e4b\u529b\u94f8\u6210\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 16.0,
            "crit_chance": 0.043,
            "crit_damage": 0.172
        }
    },
    "set_baize_head": {
        "type": "equipment",
        "slot": "head",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 246,
        "name": "\u767d\u6cfd\u77e5\u4e16\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u767d\u6cfd\u4e4b\u7eb9\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 6.0,
            "max_health": 36.0,
            "max_qi": 36.0
        }
    },
    "set_baize_body": {
        "type": "equipment",
        "slot": "body",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 262,
        "name": "\u767d\u6cfd\u6587\u7ee3\u888d",
        "desc": "\u8863\u7532\u6d41\u8f6c\u767d\u6cfd\u7075\u5149\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 8.0,
            "max_health": 53.0,
            "max_qi": 18.0
        }
    },
    "set_baize_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 278,
        "name": "\u767d\u6cfd\u4e91\u7eb9\u88e4",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u767d\u6cfd\u4e91\u7eb9\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 6.0,
            "max_health": 42.0,
            "move_speed": 0.13
        }
    },
    "set_baize_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 294,
        "name": "\u767d\u6cfd\u8e0f\u4e91\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u767d\u6cfd\u800c\u884c\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\u3002",
        "stats": {
            "defense": 3.0,
            "max_health": 18.0,
            "move_speed": 0.37
        }
    },
    "set_baize_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 310,
        "name": "\u767d\u6cfd\u62a4\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u767d\u6cfd\u7075\u4e1d\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 10.0,
            "defense": 4.0,
            "crit_chance": 0.026
        }
    },
    "set_baize_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "baize",
        "rarity": 4,
        "stackable": false,
        "color": "#9fd8ff",
        "element": "water",
        "value": 326,
        "name": "\u767d\u6cfd\u901a\u7075\u7389",
        "desc": "\u4f69\u4e0a\u523b\u6709\u767d\u6cfd\u795e\u97f5\uff0c\u901a\u6653\u4e07\u7269\u3001\u7075\u53f0\u6f84\u660e\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 59.0,
            "crit_chance": 0.026,
            "crit_damage": 0.215
        }
    },
    "set_zhulong_weapon": {
        "type": "equipment",
        "slot": "weapon",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 504,
        "name": "\u70db\u9f99\u8854\u706b\u5251",
        "desc": "\u4ee5\u70db\u9f99\u4e4b\u529b\u94f8\u6210\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff1b\u6301\u4e4b\u5982\u4e0e\u795e\u517d\u540c\u5951\u3002",
        "stats": {
            "attack": 38.0,
            "crit_chance": 0.045,
            "crit_damage": 0.27
        }
    },
    "set_zhulong_head": {
        "type": "equipment",
        "slot": "head",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 539,
        "name": "\u70db\u9f99\u66dc\u65e5\u51a0",
        "desc": "\u51a0\u4e0a\u94ed\u523b\u70db\u9f99\u4e4b\u7eb9\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff0c\u4ee4\u4eba\u795e\u601d\u6e05\u660e\u3002",
        "stats": {
            "defense": 11.0,
            "max_health": 76.0,
            "max_qi": 24.0
        }
    },
    "set_zhulong_body": {
        "type": "equipment",
        "slot": "body",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 574,
        "name": "\u70db\u9f99\u7384\u9cde\u7532",
        "desc": "\u8863\u7532\u6d41\u8f6c\u70db\u9f99\u7075\u5149\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff0c\u8fdb\u9000\u4e4b\u95f4\u4e0d\u67d3\u5c18\u3002",
        "stats": {
            "defense": 16.0,
            "max_health": 113.0,
            "max_qi": 12.0
        }
    },
    "set_zhulong_legs": {
        "type": "equipment",
        "slot": "legs",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 609,
        "name": "\u70db\u9f99\u7130\u7eb9\u88e4",
        "desc": "\u4e0b\u88c5\u7ee3\u6709\u70db\u9f99\u4e91\u7eb9\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff0c\u6b65\u5c65\u6108\u53d1\u8f7b\u7a33\u3002",
        "stats": {
            "defense": 11.0,
            "max_health": 88.0,
            "move_speed": 0.18
        }
    },
    "set_zhulong_boots": {
        "type": "equipment",
        "slot": "boots",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 644,
        "name": "\u70db\u9f99\u9010\u5149\u9774",
        "desc": "\u8e0f\u5730\u5982\u5fa1\u70db\u9f99\u800c\u884c\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\u3002",
        "stats": {
            "defense": 7.0,
            "max_health": 38.0,
            "move_speed": 0.5
        }
    },
    "set_zhulong_bracers": {
        "type": "equipment",
        "slot": "bracers",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 679,
        "name": "\u70db\u9f99\u8d64\u9cde\u8155",
        "desc": "\u62a4\u8155\u7f20\u7ed5\u70db\u9f99\u7075\u4e1d\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff0c\u653b\u5b88\u8f6c\u6362\u66f4\u4e3a\u8fc5\u75be\u3002",
        "stats": {
            "attack": 23.0,
            "defense": 8.0,
            "crit_chance": 0.027
        }
    },
    "set_zhulong_accessory": {
        "type": "equipment",
        "slot": "accessory",
        "set": "zhulong",
        "rarity": 5,
        "stackable": false,
        "color": "#ff7a3c",
        "element": "fire",
        "value": 714,
        "name": "\u70db\u9f99\u591c\u660e\u7389",
        "desc": "\u4f69\u4e0a\u523b\u6709\u70db\u9f99\u795e\u97f5\uff0c\u8854\u70db\u7167\u591c\u3001\u638c\u63a7\u6666\u660e\uff0c\u4eff\u4f5b\u6709\u7075\u517d\u968f\u884c\u3002",
        "stats": {
            "max_qi": 40.0,
            "crit_chance": 0.027,
            "crit_damage": 0.338
        }
    }
}

const SETS := {
    "qingfeng": {
        "name": "\u6e05\u98ce\u5957\u88c5",
        "flavor": "\u6e05\u98ce\u65e0\u5f62\uff0c\u9752\u6728\u76f8\u751f\u3002\u5251\u950b\u63a0\u8fc7\u5982\u98ce\uff0c\u8863\u8882\u98d8\u7136\u82e5\u4e0d\u67d3\u5c18\u3002",
        "total": 7,
        "pieces": [
            "set_qingfeng_weapon",
            "set_qingfeng_head",
            "set_qingfeng_body",
            "set_qingfeng_legs",
            "set_qingfeng_boots",
            "set_qingfeng_bracers",
            "set_qingfeng_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u79fb\u52a8\u901f\u5ea6 +0.35",
                "stats": {
                    "move_speed": 0.35
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u66b4\u51fb\u7387 +3.0%",
                "stats": {
                    "crit_chance": 0.03
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u653b\u51fb +12\u3001\u79fb\u52a8\u901f\u5ea6 +0.45\u3001\u66b4\u51fb\u7387 +2.0%",
                "stats": {
                    "attack": 12.0,
                    "move_speed": 0.45,
                    "crit_chance": 0.02
                }
            }
        ]
    },
    "shaoxia": {
        "name": "\u5c11\u4fa0\u5957\u88c5",
        "flavor": "\u521d\u5165\u6c5f\u6e56\u7684\u5c11\u4fa0\u88c5\u675f\uff0c\u8f7b\u4fbf\u7ed3\u5b9e\uff0c\u653b\u5b88\u5747\u8861\uff0c\u6700\u9002\u5408\u7825\u783a\u9053\u5fc3\u3002",
        "total": 7,
        "pieces": [
            "set_shaoxia_weapon",
            "set_shaoxia_head",
            "set_shaoxia_body",
            "set_shaoxia_legs",
            "set_shaoxia_boots",
            "set_shaoxia_bracers",
            "set_shaoxia_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u6c14\u8840 +45",
                "stats": {
                    "max_health": 45.0
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u653b\u51fb +6\u3001\u9632\u5fa1 +6",
                "stats": {
                    "attack": 6.0,
                    "defense": 6.0
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u6c14\u8840 +80\u3001\u771f\u6c14 +30\u3001\u653b\u51fb +10\u3001\u9632\u5fa1 +8",
                "stats": {
                    "max_health": 80.0,
                    "max_qi": 30.0,
                    "attack": 10.0,
                    "defense": 8.0
                }
            }
        ]
    },
    "qinggang": {
        "name": "\u9752\u94a2\u5957\u88c5",
        "flavor": "\u9752\u94a2\u5343\u9524\u767e\u70bc\uff0c\u91cd\u7532\u5982\u5c71\u3002\u5b88\u5fa1\u4e4b\u9053\uff0c\u5c3d\u5728\u6c89\u7a33\u7684\u94a2\u7eb9\u4e4b\u4e2d\u3002",
        "total": 7,
        "pieces": [
            "set_qinggang_weapon",
            "set_qinggang_head",
            "set_qinggang_body",
            "set_qinggang_legs",
            "set_qinggang_boots",
            "set_qinggang_bracers",
            "set_qinggang_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u9632\u5fa1 +9",
                "stats": {
                    "defense": 9.0
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u6c14\u8840 +130",
                "stats": {
                    "max_health": 130.0
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u9632\u5fa1 +20\u3001\u6c14\u8840 +260\u3001\u653b\u51fb +14",
                "stats": {
                    "defense": 20.0,
                    "max_health": 260.0,
                    "attack": 14.0
                }
            }
        ]
    },
    "taowu": {
        "name": "\u68bc\u674c\u5957\u88c5",
        "flavor": "\u68bc\u674c\u4e43\u4e0a\u53e4\u56db\u51f6\u4e4b\u4e00\uff0c\u987d\u51f6\u4e0d\u5316\u3002\u5176\u9aa8\u5176\u76ae\uff0c\u7686\u8574\u51f6\u715e\u86ee\u529b\u3002",
        "total": 7,
        "pieces": [
            "set_taowu_weapon",
            "set_taowu_head",
            "set_taowu_body",
            "set_taowu_legs",
            "set_taowu_boots",
            "set_taowu_bracers",
            "set_taowu_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u653b\u51fb +16",
                "stats": {
                    "attack": 16.0
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u66b4\u51fb\u7387 +5.0%",
                "stats": {
                    "crit_chance": 0.05
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u653b\u51fb +30\u3001\u66b4\u51fb\u4f24\u5bb3 +30.0%\u3001\u9632\u5fa1 +12\u3001\u6c14\u8840 +120",
                "stats": {
                    "attack": 30.0,
                    "crit_damage": 0.3,
                    "defense": 12.0,
                    "max_health": 120.0
                }
            }
        ]
    },
    "hongmeng": {
        "name": "\u9e3f\u8499\u5957\u88c5",
        "flavor": "\u9e3f\u8499\u672a\u5224\uff0c\u6df7\u6c8c\u4e00\u6c14\u3002\u7740\u6b64\u5957\u88c5\uff0c\u8eab\u5fc3\u4e0e\u5929\u5730\u540c\u6e90\uff0c\u653b\u5b88\u7686\u8574\u5927\u9053\u3002",
        "total": 7,
        "pieces": [
            "set_hongmeng_weapon",
            "set_hongmeng_head",
            "set_hongmeng_body",
            "set_hongmeng_legs",
            "set_hongmeng_boots",
            "set_hongmeng_bracers",
            "set_hongmeng_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u771f\u6c14 +70\u3001\u66b4\u51fb\u7387 +2.0%",
                "stats": {
                    "max_qi": 70.0,
                    "crit_chance": 0.02
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u653b\u51fb +22\u3001\u9632\u5fa1 +18\u3001\u6c14\u8840 +180",
                "stats": {
                    "attack": 22.0,
                    "defense": 18.0,
                    "max_health": 180.0
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u653b\u51fb +45\u3001\u9632\u5fa1 +30\u3001\u6c14\u8840 +350\u3001\u771f\u6c14 +160\u3001\u66b4\u51fb\u7387 +6.0%\u3001\u79fb\u52a8\u901f\u5ea6 +0.50",
                "stats": {
                    "attack": 45.0,
                    "defense": 30.0,
                    "max_health": 350.0,
                    "max_qi": 160.0,
                    "crit_chance": 0.06,
                    "move_speed": 0.5
                }
            }
        ]
    },
    "baize": {
        "name": "\u767d\u6cfd\u5957\u88c5",
        "flavor": "\u767d\u6cfd\u77e5\u5929\u4e0b\u9b3c\u795e\u4e4b\u4e8b\uff0c\u7075\u5149\u52a0\u8eab\u3002\u771f\u5143\u6d51\u539a\uff0c\u6d1e\u5bdf\u7834\u7efd\uff0c\u66b4\u51fb\u81ea\u751f\u3002",
        "total": 7,
        "pieces": [
            "set_baize_weapon",
            "set_baize_head",
            "set_baize_body",
            "set_baize_legs",
            "set_baize_boots",
            "set_baize_bracers",
            "set_baize_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u771f\u6c14 +80",
                "stats": {
                    "max_qi": 80.0
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u66b4\u51fb\u7387 +4.0%\u3001\u653b\u51fb +18",
                "stats": {
                    "crit_chance": 0.04,
                    "attack": 18.0
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u771f\u6c14 +180\u3001\u653b\u51fb +32\u3001\u66b4\u51fb\u7387 +6.0%\u3001\u66b4\u51fb\u4f24\u5bb3 +20.0%",
                "stats": {
                    "max_qi": 180.0,
                    "attack": 32.0,
                    "crit_chance": 0.06,
                    "crit_damage": 0.2
                }
            }
        ]
    },
    "zhulong": {
        "name": "\u70db\u9f99\u5957\u88c5",
        "flavor": "\u70db\u9f99\u8854\u706b\u7167\u5e7d\u90fd\uff0c\u7741\u773c\u4e3a\u663c\uff0c\u95ed\u773c\u4e3a\u591c\u3002\u653b\u5b88\u7686\u8574\u65e5\u6708\u4e4b\u5a01\u3002",
        "total": 7,
        "pieces": [
            "set_zhulong_weapon",
            "set_zhulong_head",
            "set_zhulong_body",
            "set_zhulong_legs",
            "set_zhulong_boots",
            "set_zhulong_bracers",
            "set_zhulong_accessory"
        ],
        "bonuses": [
            {
                "pieces": 2,
                "desc": "2 \u4ef6\uff1a\u653b\u51fb +18\u3001\u6c14\u8840 +120",
                "stats": {
                    "attack": 18.0,
                    "max_health": 120.0
                }
            },
            {
                "pieces": 4,
                "desc": "4 \u4ef6\uff1a\u66b4\u51fb\u4f24\u5bb3 +25.0%\u3001\u9632\u5fa1 +14",
                "stats": {
                    "crit_damage": 0.25,
                    "defense": 14.0
                }
            },
            {
                "pieces": 7,
                "desc": "7 \u4ef6\uff1a\u653b\u51fb +38\u3001\u6c14\u8840 +260\u3001\u66b4\u51fb\u7387 +5.0%\u3001\u66b4\u51fb\u4f24\u5bb3 +30.0%",
                "stats": {
                    "attack": 38.0,
                    "max_health": 260.0,
                    "crit_chance": 0.05,
                    "crit_damage": 0.3
                }
            }
        ]
    }
}


static func item_row(id: String) -> Dictionary:
    var row: Variant = ITEMS.get(id, {})
    if row is Dictionary:
        return row
    return {}


static func set_info(set_id: String) -> Dictionary:
    var info: Variant = SETS.get(set_id, {})
    if info is Dictionary:
        return info
    return {}


static func equipment_set_name(set_id: String) -> String:
    return str(set_info(set_id).get("name", set_id))


static func set_flavor(set_id: String) -> String:
    return str(set_info(set_id).get("flavor", ""))


static func set_total_pieces(set_id: String) -> int:
    return int(set_info(set_id).get("total", 0))


static func set_piece_ids(set_id: String) -> Array:
    var pieces: Variant = set_info(set_id).get("pieces", [])
    if pieces is Array:
        return pieces
    return []


static func set_bonus_list(set_id: String) -> Array:
    var bonuses: Variant = set_info(set_id).get("bonuses", [])
    if bonuses is Array:
        return bonuses
    return []


static func set_bonus_stats(set_id: String, equipped_pieces: int) -> Dictionary:
    var result := {}
    for bonus in set_bonus_list(set_id):
        if not (bonus is Dictionary):
            continue
        var data := bonus as Dictionary
        if equipped_pieces < int(data.get("pieces", 0)):
            continue
        var stats: Variant = data.get("stats", {})
        if stats is Dictionary:
            for key in stats.keys():
                result[key] = float(result.get(key, 0.0)) + float(stats[key])
    return result


static func set_bonus_lines(set_id: String, equipped_pieces: int) -> Array[String]:
    var lines: Array[String] = []
    for bonus in set_bonus_list(set_id):
        if not (bonus is Dictionary):
            continue
        var data := bonus as Dictionary
        var threshold := int(data.get("pieces", 0))
        var prefix := "\u2714 " if equipped_pieces >= threshold else "\u25cb "
        lines.append(prefix + str(data.get("desc", "")))
    return lines
