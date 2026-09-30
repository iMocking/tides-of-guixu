class_name TerrainData
## Data-driven parameters and biome ranges for the large-world terrain generator.

const CHUNK_SIZE := 32.0
const CHUNK_RESOLUTION := 16
const VIEW_RADIUS_CHUNKS := 4

const HEIGHT_SCALE := 17.0
const MOUNTAIN_SCALE := 24.0
const BASE_HEIGHT := 0.0
const MIN_HEIGHT := -4.0
const MAX_HEIGHT := 46.0

const NOISE_FREQUENCY := 0.014
const MOUNTAIN_FREQUENCY := 0.008
const MOISTURE_FREQUENCY := 0.020

## A broad, flat safe area around the origin keeps the current NPC / combat
## content readable, then blends into procedural hills and mountains.
const FLAT_RADIUS := 74.0
const FLAT_BLEND := 22.0

const BIOMES := [
    {"id": "meadow", "name": "\u9752\u82dc\u539f", "color": "#4a7d46", "min_height": -4.0, "max_height": 6.0},
    {"id": "forest", "name": "\u5e7d\u6797", "color": "#2f5d3a", "min_height": 3.0, "max_height": 15.0},
    {"id": "rock", "name": "\u77f3\u5cad", "color": "#6b6b5e", "min_height": 13.0, "max_height": 27.0},
    {"id": "snow", "name": "\u96ea\u5dc5", "color": "#dbe6ea", "min_height": 24.0, "max_height": 64.0},
]


static func biome_for_height(height: float) -> Dictionary:
    var chosen: Dictionary = BIOMES[0]
    for biome in BIOMES:
        var data := biome as Dictionary
        if height >= float(data.get("min_height", -999.0)) and height <= float(data.get("max_height", 999.0)):
            chosen = data
    return chosen


static func biome_color(height: float) -> Color:
    return Color(str(biome_for_height(height).get("color", "#4a7d46")))
