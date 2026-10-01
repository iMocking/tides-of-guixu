class_name LocaleExtra4
## Fourth locale shard: the world map - terrain back ends, biomes and the
## landmarks placed on top of them.

const TEXT := {
    "world_map_ready": "世界地图生成完毕",
    "world_terrain_backend": "地形后端",
    "world_terrain_loading": "正在生成地形 %d / %d",
    "world_features_placing": "正在铺陈山林、湖泊与古建",
    "world_terrain_fallback": "未检测到 Terrain3D，使用内置流式地形",

    "landmark_gate": "云梦山门",
    "landmark_shrine": "归墟殿",
    "landmark_pavilion": "观澜亭",
    "landmark_pagoda": "镇岳塔",
    "landmark_hall": "藏书阁",
    "landmark_jetty": "明镜渡口",
    "landmark_cave": "玄山洞秘境",
    "landmark_cave_enter": "踏入玄山洞秘境",
    "landmark_cave_log": "玄山洞秘境  ·  副本入口",
    "landmark_cave_hint": "洞口幽深，寒意扑面而来",

    "biome_lakebed": "湖底",
    "biome_sand": "汀洲",
    "biome_grass": "青芜原",
    "biome_forest": "幽冥林",
    "biome_rock": "石岭",
    "biome_cliff": "断崖",
    "biome_snow": "雪巅",

    "terrain_tex_void": "底色",
    "terrain_tex_grass": "草甸",
    "terrain_tex_forest": "林地",
    "terrain_tex_snow": "积雪",
    "terrain_tex_rock": "岩石",
    "terrain_tex_cliff": "崖壁",
    "terrain_tex_sand": "沙洲",
    "terrain_tex_lakebed": "湖床",

    "landmark_cloud_massif": "苍梧山脉",
    "landmark_mirror_lake": "明镜湖",
    "landmark_dark_woods": "幽冥林",
    "landmark_cliff_ridge": "断崖",
}

static func text(key: String) -> String:
    return str(TEXT.get(key, key))
