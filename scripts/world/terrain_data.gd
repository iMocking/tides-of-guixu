class_name TerrainData
extends RefCounted
## Shared procedural world field for the 归墟之潮 map.
##
## One instance owns the whole terrain definition: the noise stack that builds
## the height, the biome palette and the landmark layout.  Both terrain back
## ends read from it - `TerrainGenerator` (the streamed placeholder mesh used
## when Terrain3D is unavailable) and `Terrain3DWorld` (the Terrain3D clipmap) -
## so a tree, an enemy or a shrine always lands on the same surface no matter
## which renderer is active.
##
## Layout in metres (+X east, -Z north), all of it inside the generated
## -512 .. 1024 m of clipmap:
##   * 云梦泽    start basin    around the origin: flat, holds the shrine and NPCs
##   * 苍梧山脉  high mountains  to the north, up to ~135 m, snow above ~58 m
##   * 断崖      cliffs          the terraced south face of the massif
##   * 明镜湖    lake            to the east
##   * 幽冥林    dense forest    to the west
##   * 玄山洞    cave mouth      cut into the cliff - the dungeon entrance
##   * 古风建筑  gate / pavilion / pagoda around the start basin

## --- streamed fallback mesh (`TerrainGenerator`) -------------------------
const CHUNK_SIZE := 32.0
const CHUNK_RESOLUTION := 16
const VIEW_RADIUS_CHUNKS := 4

## --- Terrain3D clipmap ---------------------------------------------------
## A region holds `REGION_SIZE` vertices a side, `VERTEX_SPACING` metres apart,
## so one region covers `REGION_SPAN` metres of world.  `REGION_RADIUS` regions
## are generated either side of the origin (1 => a 3x3 grid).
const REGION_SIZE := 256
const VERTEX_SPACING := 2.0
## Equals REGION_SIZE * VERTEX_SPACING; spelled out so it folds as a constant.
const REGION_SPAN := 512.0
const REGION_RADIUS := 1
## Hard cap Terrain3D allows on the clipmap.
const REGION_MAP_SIZE := 32

## --- vertical scale ------------------------------------------------------
const BASE_LEVEL := 5.0
const HILL_AMPLITUDE := 5.4
const DETAIL_AMPLITUDE := 1.1
## Sits below every natural land form, so the lake is the only place the
## surface drops under the waterline.
const WATER_LEVEL := -4.0
const MIN_HEIGHT := -22.0
const MAX_HEIGHT := 220.0
const SNOW_LINE := 50.0
const ROCK_LINE := 24.0
## Terrace height used by the cliff shaper.
const CLIFF_STEP := 6.5

## --- 云梦泽 start basin --------------------------------------------------
## Kept flat so the shrine, NPC and quest content stays readable, then eased
## into the procedural landscape.
const FLAT_RADIUS := 54.0
const FLAT_BLEND := 50.0

## --- 苍梧山脉 / 断崖 -----------------------------------------------------
const MASSIF_CENTER := Vector2(0.0, -300.0)
const MASSIF_RADIUS := Vector2(392.0, 288.0)
const MASSIF_HEIGHT := 172.0
## The escarpment band: the south face of the massif is terraced hardest here.
const CLIFF_BAND_CENTER := -150.0
const CLIFF_BAND_HALF := 118.0

## --- 明镜湖 --------------------------------------------------------------
const LAKE_CENTER := Vector2(178.0, 96.0)
const LAKE_RADIUS := 96.0
const LAKE_DEPTH := 13.0

## --- 幽冥林 --------------------------------------------------------------
const FOREST_CENTER := Vector2(-182.0, 46.0)
const FOREST_RADIUS := 212.0

## --- texture palette -----------------------------------------------------
## Terrain3D packs a base id (5 bits) and an overlay id (5 bits) into one
## 32-bit control value that is smuggled through a 32-bit float.  Id 0 is
## therefore reserved: keeping every *base* id at 1 or above keeps the packed
## float a normal number instead of a subnormal, which is what makes control
## maps survive a round trip through Godot's Image API.
const TEX_VOID := 0
const TEX_GRASS := 1
const TEX_FOREST := 2
const TEX_SNOW := 3
const TEX_ROCK := 4
const TEX_CLIFF := 5
const TEX_SAND := 6
const TEX_LAKEBED := 7
const TEXTURE_COUNT := 8

## Albedo tint, tiling scale, roughness and normal strength of each painted
## layer.  The textures themselves are generated from noise at runtime
## (`Terrain3DWorld`) so the project keeps its zero-external-asset rule.
const TEXTURES := [
    {"id": TEX_VOID, "name_key": "terrain_tex_void", "albedo": "#4a7d46", "uv": 0.055, "rough": 0.96, "normal": 0.55, "ao": 0.50},
    {"id": TEX_GRASS, "name_key": "terrain_tex_grass", "albedo": "#52854c", "uv": 0.060, "rough": 0.95, "normal": 0.55, "ao": 0.50},
    {"id": TEX_FOREST, "name_key": "terrain_tex_forest", "albedo": "#335c37", "uv": 0.075, "rough": 0.93, "normal": 0.70, "ao": 0.60},
    {"id": TEX_SNOW, "name_key": "terrain_tex_snow", "albedo": "#e2ecf2", "uv": 0.045, "rough": 0.62, "normal": 0.30, "ao": 0.40},
    {"id": TEX_ROCK, "name_key": "terrain_tex_rock", "albedo": "#7b7a6c", "uv": 0.070, "rough": 0.92, "normal": 0.85, "ao": 0.60},
    {"id": TEX_CLIFF, "name_key": "terrain_tex_cliff", "albedo": "#5d584c", "uv": 0.055, "rough": 0.94, "normal": 1.00, "ao": 0.60},
    {"id": TEX_SAND, "name_key": "terrain_tex_sand", "albedo": "#c2ad7c", "uv": 0.080, "rough": 0.90, "normal": 0.35, "ao": 0.50},
    {"id": TEX_LAKEBED, "name_key": "terrain_tex_lakebed", "albedo": "#4a5a4e", "uv": 0.090, "rough": 0.80, "normal": 0.45, "ao": 0.50},
]

## --- biomes --------------------------------------------------------------
const BIOME_GRASS := "grass"
const BIOME_FOREST := "forest"
const BIOME_ROCK := "rock"
const BIOME_CLIFF := "cliff"
const BIOME_SNOW := "snow"
const BIOME_SAND := "sand"
const BIOME_LAKEBED := "lakebed"

const BIOMES := [
    {"id": BIOME_LAKEBED, "name_key": "biome_lakebed", "texture": TEX_LAKEBED, "color": "#3d4a42", "label": "湖底"},
    {"id": BIOME_SAND, "name_key": "biome_sand", "texture": TEX_SAND, "color": "#b8a271", "label": "汀洲"},
    {"id": BIOME_GRASS, "name_key": "biome_grass", "texture": TEX_GRASS, "color": "#4a7d46", "label": "青芜原"},
    {"id": BIOME_FOREST, "name_key": "biome_forest", "texture": TEX_FOREST, "color": "#2f5d3a", "label": "幽冥林"},
    {"id": BIOME_ROCK, "name_key": "biome_rock", "texture": TEX_ROCK, "color": "#6b6b5e", "label": "石岭"},
    {"id": BIOME_CLIFF, "name_key": "biome_cliff", "texture": TEX_CLIFF, "color": "#585349", "label": "断崖"},
    {"id": BIOME_SNOW, "name_key": "biome_snow", "texture": TEX_SNOW, "color": "#dbe6ea", "label": "雪巅"},
]

## Slope (rise over run) at which bare rock takes over from grass, and at which
## a face counts as a cliff rather than a scree slope.
const SLOPE_ROCK := 0.62
const SLOPE_CLIFF := 1.05

## --- landmarks -----------------------------------------------------------
## Flattened plots carved into the field so the buildings, the cave mouth and
## the lake jetty always sit on level ground.  `height` is filled in by
## `setup()` from the surrounding landscape; `blend` is the easing distance.
const PADS := [
    {"id": "shrine", "center": Vector2(0.0, 26.0), "radius": 30.0, "blend": 18.0},
    {"id": "gate", "center": Vector2(0.0, -20.0), "radius": 13.0, "blend": 10.0},
    {"id": "pavilion", "center": Vector2(36.0, 44.0), "radius": 15.0, "blend": 10.0},
    {"id": "pagoda", "center": Vector2(-38.0, 50.0), "radius": 14.0, "blend": 10.0},
    {"id": "hall", "center": Vector2(-12.0, 70.0), "radius": 17.0, "blend": 11.0},
    {"id": "cave", "center": Vector2(-58.0, -118.0), "radius": 24.0, "blend": 16.0},
]

## Where each landmark sits in the world.  The feature builder, the camera and
## the tests all read this so nothing drifts out of sync with the terrain.
const LANDMARKS := {
    "gate": Vector2(0.0, -20.0),
    "shrine": Vector2(0.0, 26.0),
    "pavilion": Vector2(36.0, 44.0),
    "pagoda": Vector2(-38.0, 50.0),
    "hall": Vector2(-12.0, 70.0),
    "jetty": Vector2(112.0, 96.0),
    "cave": Vector2(-58.0, -118.0),
}

## How far below the shoreline the water sheet is drawn, and how far past the
## waterline it extends so the plane never shows a hard edge against the bank.
const WATER_OVERHANG := 26.0

var world_seed := 0
var _hills: FastNoiseLite
var _detail: FastNoiseLite
var _ridge: FastNoiseLite
var _moisture: FastNoiseLite
var _cliff: FastNoiseLite
var _shore: FastNoiseLite
var _forest: FastNoiseLite
var _pad_heights: Dictionary = {}
## Same data as `PADS`, flattened into typed arrays: `height()` runs once per
## clipmap vertex (a quarter of a million times per region), so the pad test has
## to avoid Dictionary lookups and Variant boxing.
var _pad_centres := PackedVector2Array()
var _pad_reach := PackedFloat32Array()
var _pad_radius := PackedFloat32Array()
var _pad_level := PackedFloat32Array()
var _pad_bounds := Rect2()
var _lake_reach := 0.0


static func create(seed_value: int) -> TerrainData:
    var field := TerrainData.new()
    field.setup(seed_value)
    return field


func setup(seed_value: int) -> void:
    world_seed = seed_value
    _hills = _make(seed_value, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0030, FastNoiseLite.FRACTAL_FBM, 4, 0.50, 2.00)
    _detail = _make(seed_value + 11, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0165, FastNoiseLite.FRACTAL_FBM, 3, 0.48, 2.10)
    _ridge = _make(seed_value + 104729, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0042, FastNoiseLite.FRACTAL_RIDGED, 4, 0.52, 2.15)
    _moisture = _make(seed_value + 7919, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0055, FastNoiseLite.FRACTAL_FBM, 2, 0.50, 2.00)
    _cliff = _make(seed_value + 15485863, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0115, FastNoiseLite.FRACTAL_FBM, 2, 0.50, 2.00)
    _shore = _make(seed_value + 32452843, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0090, FastNoiseLite.FRACTAL_FBM, 2, 0.50, 2.00)
    _forest = _make(seed_value + 49979687, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0075, FastNoiseLite.FRACTAL_FBM, 3, 0.55, 2.00)
    _cache_pad_heights()


static func _make(seed_value: int, noise_type: int, frequency: float, fractal: int, octaves: int, gain: float, lacunarity: float) -> FastNoiseLite:
    var noise := FastNoiseLite.new()
    noise.seed = seed_value
    noise.noise_type = noise_type
    noise.frequency = frequency
    noise.fractal_type = fractal
    noise.fractal_octaves = octaves
    noise.fractal_gain = gain
    noise.fractal_lacunarity = lacunarity
    return noise


## Pads are levelled to whatever the landscape does underneath them, so the
## height has to be sampled after the noise is live - and before pads are
## applied, otherwise they would read each other.
func _cache_pad_heights() -> void:
    _pad_heights.clear()
    _pad_centres.clear()
    _pad_reach.clear()
    _pad_radius.clear()
    _pad_level.clear()
    var bounds := Rect2()
    for i in PADS.size():
        var pad: Dictionary = PADS[i]
        var centre: Vector2 = pad["center"]
        var radius := float(pad["radius"])
        var blend := float(pad["blend"])
        var level := float(pad["height"]) if pad.has("height") else _base_height(centre.x, centre.y)
        _pad_heights[pad["id"]] = level
        _pad_centres.append(centre)
        _pad_radius.append(radius)
        _pad_reach.append(radius + blend)
        _pad_level.append(level)
        var box := Rect2(centre - Vector2(radius + blend, radius + blend), Vector2(radius + blend, radius + blend) * 2.0)
        bounds = box if i == 0 else bounds.merge(box)
    _pad_bounds = bounds
    # `lake_distance()` warps the shoreline by at most 15 m, so anything further
    # out than this cannot possibly be carved.
    _lake_reach = LAKE_RADIUS + 16.0


func pad_height(id: String) -> float:
    return float(_pad_heights.get(id, BASE_LEVEL))


## World position of a landmark, sitting on the ground.
func landmark_position(id: String) -> Vector3:
    var flat: Vector2 = LANDMARKS.get(id, Vector2.ZERO)
    return sample(flat.x, flat.y)


func landmark_count() -> int:
    return LANDMARKS.size()


# ---------------------------------------------------------------- field ---

## Land height in metres.  Single source of truth for every other system.
func height(x: float, z: float) -> float:
    return clampf(_shaped_height(x, z), MIN_HEIGHT, MAX_HEIGHT)


func sample(x: float, z: float) -> Vector3:
    return Vector3(x, height(x, z), z)


func _shaped_height(x: float, z: float) -> float:
    return _apply_pads(_base_height(x, z), x, z)


## Everything except the landmark pads.
func _base_height(x: float, z: float) -> float:
    var h := _raw_height(x, z)
    h = _apply_lake(h, x, z)
    return _apply_start_basin(h, x, z)


## Noise-only landscape: rolling meadow, the 苍梧山脉 massif and its terraced
## escarpment.
func _raw_height(x: float, z: float) -> float:
    var hills := _hills.get_noise_2d(x, z)
    var detail := _detail.get_noise_2d(x, z)
    var massif := mountain_mask(x, z)

    var h := BASE_LEVEL + hills * HILL_AMPLITUDE + detail * DETAIL_AMPLITUDE
    # Away from 苍梧山脉 there is no mountain to shape, so the two ridge lookups
    # (and the terracing below) are skipped entirely.
    if massif > 0.0:
        var ridge := 1.0 - absf(_ridge.get_noise_2d(x, z))
        ridge = ridge * ridge * (3.0 - 2.0 * ridge)
        h += ridge * ridge * massif * MASSIF_HEIGHT
        # A second, tighter ridge family breaks the big shape into separate peaks.
        var spur := 1.0 - absf(_ridge.get_noise_2d(x * 2.7 + 511.0, z * 2.7 - 733.0))
        h += spur * spur * massif * MASSIF_HEIGHT * 0.22

    # 断崖: terracing turns the massif's flanks into stacked shelves.  Strongest
    # in the escarpment band in front of the range, fading out over the meadow
    # so the start basin stays walkable.
    var terrace := clampf(_cliff_band(z) * 0.90 + massif * 0.55, 0.0, 1.0)
    if terrace <= 0.0:
        return h
    terrace = clampf(terrace * (1.0 + _cliff.get_noise_2d(x, z) * 0.20), 0.0, 1.0)
    if terrace > 0.001:
        h = lerpf(h, terrace_height(h, CLIFF_STEP), terrace)
    return h


## Smooth 0..1 mask of the 苍梧山脉 massif, warped so the outline is not a
## plain ellipse.
func mountain_mask(x: float, z: float) -> float:
    var dx := (x - MASSIF_CENTER.x) / MASSIF_RADIUS.x
    var dz := (z - MASSIF_CENTER.y) / MASSIF_RADIUS.y
    var d2 := dx * dx + dz * dz
    # The two warps below can pull the rim in by at most 0.38, so beyond 1.5
    # the mask is exactly zero and the noise lookups can be skipped.
    if d2 > 2.25:
        return 0.0
    var d := sqrt(d2)
    d += _detail.get_noise_2d(x * 0.55 + 91.0, z * 0.55 - 17.0) * 0.26
    d -= _moisture.get_noise_2d(x * 0.30, z * 0.30) * 0.12
    return clampf(1.0 - smoothstep(0.30, 1.0, d), 0.0, 1.0)


func _cliff_band(z: float) -> float:
    var t := absf(z - CLIFF_BAND_CENTER) / CLIFF_BAND_HALF
    return clampf(1.0 - t, 0.0, 1.0)


## Quantises a height into flat shelves separated by steep risers, which reads
## as stacked cliff faces once the mesh is built.
static func terrace_height(h: float, step: float) -> float:
    var t := h / step
    var shelf := floorf(t)
    var frac := t - shelf
    frac = smoothstep(0.58, 1.0, frac)
    return (shelf + frac) * step


# --------------------------------------------------------------- biomes ---

## 0..1 forest density.  High inside 幽冥林, tapering off with height so the
## treeline is respected.
func forest_mask(x: float, z: float) -> float:
    return forest_mask_at(x, z, height(x, z))


## Same, for callers that already know the ground height - the clipmap builder
## evaluates this a quarter of a million times per region, so it is worth
## avoiding a second full height sample.
func forest_mask_at(x: float, z: float, height_value: float) -> float:
    var d := Vector2(x, z).distance_to(FOREST_CENTER)
    var core := 1.0 - smoothstep(FOREST_RADIUS * 0.30, FOREST_RADIUS, d)
    var patch := _forest.get_noise_2d(x, z) * 0.5 + 0.5
    var mask := clampf(core * 0.85 + patch * 0.45 - 0.18, 0.0, 1.0)
    var height_fade := 1.0 - smoothstep(ROCK_LINE - 6.0, ROCK_LINE + 10.0, height_value)
    return clampf(mask * height_fade, 0.0, 1.0)


func moisture(x: float, z: float) -> float:
    return clampf(_moisture.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)


func lake_distance(x: float, z: float) -> float:
    return Vector2(x, z).distance_to(LAKE_CENTER) + _shore.get_noise_2d(x, z) * 15.0


func lake_mask(x: float, z: float) -> float:
    return clampf(1.0 - smoothstep(LAKE_RADIUS * 0.55, LAKE_RADIUS, lake_distance(x, z)), 0.0, 1.0)


## Painted texture id for a point, given its height, local slope (rise over
## run) and forest density.  This is the hot path - the clipmap builder calls it
## once per vertex - so it returns the packed integer id directly, with no
## strings, dictionaries or allocations.
func biome_texture_for(height_value: float, slope: float, forest: float) -> int:
    if height_value < WATER_LEVEL - 0.35:
        return TEX_LAKEBED
    if height_value < WATER_LEVEL + 1.6:
        return TEX_SAND
    if height_value > SNOW_LINE and slope < 2.2:
        return TEX_SNOW
    if slope > SLOPE_CLIFF:
        return TEX_CLIFF
    if slope > SLOPE_ROCK or height_value > ROCK_LINE:
        return TEX_ROCK
    if forest > 0.34:
        return TEX_FOREST
    return TEX_GRASS


## Biome id for a point given its height, local slope and forest density.
func biome_for(height_value: float, slope: float, forest: float) -> String:
    var texture := biome_texture_for(height_value, slope, forest)
    if texture == TEX_LAKEBED:
        return BIOME_LAKEBED
    if texture == TEX_SAND:
        return BIOME_SAND
    if texture == TEX_SNOW:
        return BIOME_SNOW
    if texture == TEX_CLIFF:
        return BIOME_CLIFF
    if texture == TEX_ROCK:
        return BIOME_ROCK
    if texture == TEX_FOREST:
        return BIOME_FOREST
    return BIOME_GRASS


func biome_at(x: float, z: float) -> String:
    var h := height(x, z)
    var step := maxf(VERTEX_SPACING, 1.0)
    var dx := height(x + step, z) - height(x - step, z)
    var dz := height(x, z + step) - height(x, z - step)
    var slope := maxf(absf(dx), absf(dz)) / (2.0 * step)
    return biome_for(h, slope, forest_mask(x, z))


static func biome_by_id(id: String) -> Dictionary:
    for entry in BIOMES:
        if str(entry["id"]) == id:
            return entry
    return BIOMES[2]


static func biome_label(id: String) -> String:
    return str(biome_by_id(id).get("label", id))


static func texture_id_for(id: String) -> int:
    return int(biome_by_id(id)["texture"])


static func texture_row(texture_id: int) -> Dictionary:
    for entry in TEXTURES:
        if int(entry["id"]) == texture_id:
            return entry
    return TEXTURES[0]


static func biome_color(id: String) -> Color:
    return Color(str(biome_by_id(id)["color"]))


static func landscape_name() -> String:
    return "\u82cd\u68a7\u5c71\u8109"


# ------------------------------------------------------------- shaping ---

func _apply_lake(h: float, x: float, z: float) -> float:
    var dx := x - LAKE_CENTER.x
    if dx < -_lake_reach or dx > _lake_reach:
        return h
    var dz := z - LAKE_CENTER.y
    if dz < -_lake_reach or dz > _lake_reach:
        return h
    var d := lake_distance(x, z)
    if d >= LAKE_RADIUS:
        return h
    var t := 1.0 - smoothstep(LAKE_RADIUS * 0.60, LAKE_RADIUS, d)
    # A bowl that starts just under the waterline at the rim and bottoms out in
    # the middle; `minf` keeps the carve from raising already low ground.
    var bowl := WATER_LEVEL - 1.0 - LAKE_DEPTH * (1.0 - smoothstep(0.0, LAKE_RADIUS * 0.80, d))
    return lerpf(h, minf(h, bowl), t)


func _apply_pads(h: float, x: float, z: float) -> float:
    if not _pad_bounds.has_point(Vector2(x, z)):
        return h
    for i in _pad_centres.size():
        var centre := _pad_centres[i]
        var reach := _pad_reach[i]
        var dx := x - centre.x
        if dx < -reach or dx > reach:
            continue
        var dz := z - centre.y
        if dz < -reach or dz > reach:
            continue
        var d := sqrt(dx * dx + dz * dz)
        if d > reach:
            continue
        h = lerpf(h, _pad_level[i], 1.0 - smoothstep(_pad_radius[i], reach, d))
    return h


func _apply_start_basin(h: float, x: float, z: float) -> float:
    var d := sqrt(x * x + z * z)
    var t := clampf((d - FLAT_RADIUS) / FLAT_BLEND, 0.0, 1.0)
    var weight := t * t * (3.0 - 2.0 * t)
    return lerpf(BASE_LEVEL, h, weight)


# -------------------------------------------------------------- region ---

## Clipmap cell that contains the given world position.
static func region_of(x: float, z: float) -> Vector2i:
    return Vector2i(int(floor(x / REGION_SPAN)), int(floor(z / REGION_SPAN)))


## Origin of the whole generated block - the world-space corner of the lowest
## region, which is where the clipmap image gets anchored.
static func block_origin() -> Vector2:
    return Vector2(float(-REGION_RADIUS) * REGION_SPAN, float(-REGION_RADIUS) * REGION_SPAN)


## Origin of a clipmap region in world space.
static func region_origin(location: Vector2i) -> Vector2:
    return Vector2(float(location.x) * REGION_SPAN, float(location.y) * REGION_SPAN)


## Every clipmap cell the world is generated for, centred on the origin.
static func region_locations() -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    for gz in range(-REGION_RADIUS, REGION_RADIUS + 1):
        for gx in range(-REGION_RADIUS, REGION_RADIUS + 1):
            out.append(Vector2i(gx, gz))
    return out


## True when a world position falls inside the generated clipmap.
static func inside_world(x: float, z: float) -> bool:
    var loc := region_of(x, z)
    return absi(loc.x) <= REGION_RADIUS and absi(loc.y) <= REGION_RADIUS
