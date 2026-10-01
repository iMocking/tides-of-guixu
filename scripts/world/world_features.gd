extends Node3D
class_name WorldFeatures
## Dresses the generated terrain with everything the world map is supposed to
## contain: 高山 / 悬崖 / 湖泊 / 茂密的树林 / 雪地 / 山洞秘境 / 古风建筑.
##
## Vegetation and rock props are real model assets - Quaternius' CC0 Nature
## Pack, mirrored as `.glb` files under `assets/models/vegetation/` and loaded by
## `PropModels` - scattered into `MultiMeshInstance3D` batches (one batch per
## model file) and placed by sampling the same `TerrainData` field the terrain
## back end renders, so nothing floats and nothing ends up in the lake.
##
## Every model keeps the material the artist authored; the only thing this file
## decides is which species goes where, how tall it grows and how it is rotated.
## Only the water surface, the portal and the 古风建筑 are still built from
## primitives.

const FIELD_SCRIPT := preload("res://scripts/world/terrain_data.gd")
const ARCH := preload("res://scripts/world/ancient_architecture.gd")
const MODELS := preload("res://scripts/world/prop_models.gd")

const TREE_TARGET := 980
const LONE_TREE_TARGET := 140
const BUSH_TARGET := 340
const ROCK_TARGET := 300
const GRASS_TARGET := 3200
const FLOWER_TARGET := 620
const SLAB_TARGET := 110
const FLOOR_TARGET := 200
const ALPINE_TREE_TARGET := 260
const ALPINE_BUSH_TARGET := 130
const ALPINE_FLOOR_TARGET := 70

## --- prop model pools ----------------------------------------------------
## Real model assets, not primitives: Quaternius' CC0 Nature Pack, mirrored as
## self-contained `.glb` files under `assets/models/vegetation/` (see
## `CREDITS.md`).  `file` is relative to that folder and `h` is the height in
## metres an instance of that model is grown to, so placement can think in world
## units instead of the pack's own scale.  Every material is used exactly as the
## artist shipped it.
const TREE_POOL := [
    {"file": "trees/PineTree_2.glb", "h": 13.0},
    {"file": "trees/PineTree_4.glb", "h": 12.5},
    {"file": "trees/PineTree_3.glb", "h": 12.0},
    {"file": "trees/PineTree_1.glb", "h": 11.0},
    {"file": "trees/PineTree_5.glb", "h": 10.5},
    {"file": "trees/BirchTree_5.glb", "h": 14.0},
    {"file": "trees/BirchTree_3.glb", "h": 13.0},
    {"file": "trees/BirchTree_2.glb", "h": 12.5},
    {"file": "trees/BirchTree_1.glb", "h": 11.5},
    {"file": "trees/BirchTree_4.glb", "h": 11.0},
    {"file": "trees/CommonTree_3.glb", "h": 12.0},
    {"file": "trees/CommonTree_2.glb", "h": 11.0},
    {"file": "trees/CommonTree_4.glb", "h": 10.0},
    {"file": "trees/CommonTree_5.glb", "h": 9.5},
    {"file": "trees/CommonTree_1.glb", "h": 9.0},
    {"file": "trees/Willow_4.glb", "h": 11.5},
    {"file": "trees/Willow_2.glb", "h": 11.0},
    {"file": "trees/Willow_1.glb", "h": 9.5},
    {"file": "trees/Willow_3.glb", "h": 8.0},
    {"file": "trees/CommonTree_Dead_3.glb", "h": 10.5},
    {"file": "trees/CommonTree_Dead_2.glb", "h": 10.0},
    {"file": "trees/CommonTree_Dead_1.glb", "h": 7.5},
    {"file": "trees/Willow_Dead_2.glb", "h": 9.5},
    {"file": "trees/Willow_Dead_1.glb", "h": 9.0},
    {"file": "trees/BirchTree_Dead_2.glb", "h": 9.0},
    {"file": "trees/BirchTree_Dead_1.glb", "h": 8.0},
]

## Above 雪线 the pack's own snow-covered variants take over, so the peaks wear
## real snow-laden geometry instead of a repainted material.
const TREE_SNOW_POOL := [
    {"file": "trees/PineTree_Snow_2.glb", "h": 13.0},
    {"file": "trees/PineTree_Snow_4.glb", "h": 12.5},
    {"file": "trees/PineTree_Snow_3.glb", "h": 12.0},
    {"file": "trees/PineTree_Snow_1.glb", "h": 11.0},
    {"file": "trees/CommonTree_Snow_3.glb", "h": 12.0},
    {"file": "trees/CommonTree_Snow_2.glb", "h": 11.0},
    {"file": "trees/CommonTree_Snow_1.glb", "h": 9.0},
    {"file": "trees/BirchTree_Snow_3.glb", "h": 13.0},
    {"file": "trees/BirchTree_Snow_2.glb", "h": 12.5},
    {"file": "trees/BirchTree_Snow_1.glb", "h": 11.5},
]

## Lone trees out on the meadow: the open, broad canopies.
const LONE_TREE_POOL := [
    {"file": "trees/CommonTree_2.glb", "h": 11.5},
    {"file": "trees/CommonTree_3.glb", "h": 12.5},
    {"file": "trees/CommonTree_4.glb", "h": 10.5},
    {"file": "trees/CommonTree_5.glb", "h": 10.0},
    {"file": "trees/Willow_1.glb", "h": 10.0},
    {"file": "trees/Willow_2.glb", "h": 11.5},
    {"file": "trees/Willow_4.glb", "h": 12.0},
    {"file": "trees/BirchTree_1.glb", "h": 12.0},
    {"file": "trees/BirchTree_4.glb", "h": 11.5},
]

const BUSH_POOL := [
    {"file": "plants/Bush_1.glb", "h": 1.9},
    {"file": "plants/Bush_2.glb", "h": 1.7},
    {"file": "plants/BushBerries_1.glb", "h": 2.0},
    {"file": "plants/BushBerries_2.glb", "h": 1.8},
    {"file": "plants/Plant_2.glb", "h": 2.4},
    {"file": "plants/Plant_5.glb", "h": 1.9},
    {"file": "plants/Plant_3.glb", "h": 1.3},
    {"file": "plants/Plant_4.glb", "h": 1.1},
    {"file": "plants/Plant_1.glb", "h": 0.7},
]

const BUSH_SNOW_POOL := [
    {"file": "plants/Bush_Snow_1.glb", "h": 1.9},
    {"file": "plants/Bush_Snow_2.glb", "h": 1.7},
]

const GRASS_POOL := [
    {"file": "plants/Grass_2.glb", "h": 1.05},
    {"file": "plants/Grass.glb", "h": 0.90},
    {"file": "plants/Grass_Short.glb", "h": 0.50},
]

const FLOWER_POOL := [
    {"file": "plants/Flowers.glb", "h": 0.70},
]

const ROCK_POOL := [
    {"file": "rocks/Rock_4.glb", "h": 1.30},
    {"file": "rocks/Rock_1.glb", "h": 1.55},
    {"file": "rocks/Rock_7.glb", "h": 1.45},
    {"file": "rocks/Rock_6.glb", "h": 1.10},
    {"file": "rocks/Rock_3.glb", "h": 1.00},
    {"file": "rocks/Rock_2.glb", "h": 0.95},
    {"file": "rocks/Rock_5.glb", "h": 1.00},
]

const ROCK_MOSS_POOL := [
    {"file": "rocks/Rock_Moss_1.glb", "h": 1.60},
    {"file": "rocks/Rock_Moss_4.glb", "h": 1.35},
    {"file": "rocks/Rock_Moss_2.glb", "h": 1.10},
    {"file": "rocks/Rock_Moss_5.glb", "h": 0.95},
    {"file": "rocks/Rock_Moss_3.glb", "h": 0.90},
]

const ROCK_SNOW_POOL := [
    {"file": "rocks/Rock_Snow_1.glb", "h": 1.65},
    {"file": "rocks/Rock_Snow_4.glb", "h": 1.40},
    {"file": "rocks/Rock_Snow_2.glb", "h": 1.15},
    {"file": "rocks/Rock_Snow_5.glb", "h": 1.00},
    {"file": "rocks/Rock_Snow_3.glb", "h": 0.95},
]

## The heavy silhouettes that make 断崖 read as broken rock: the same low-poly
## boulders, grown until they are proper outcrops.
const BOULDER_POOL := [
    {"file": "rocks/Rock_Moss_1.glb", "h": 4.6},
    {"file": "rocks/Rock_4.glb", "h": 5.4},
    {"file": "rocks/Rock_7.glb", "h": 4.2},
    {"file": "rocks/Rock_1.glb", "h": 5.0},
    {"file": "rocks/Rock_Moss_4.glb", "h": 4.4},
    {"file": "rocks/Rock_6.glb", "h": 3.6},
]

const BOULDER_SNOW_POOL := [
    {"file": "rocks/Rock_Snow_1.glb", "h": 5.2},
    {"file": "rocks/Rock_Snow_4.glb", "h": 4.6},
    {"file": "rocks/Rock_Snow_2.glb", "h": 3.8},
]

## Forest floor litter: stumps and fallen logs, with the pack's snowy variants
## for the high ground.
const FLOOR_POOL := [
    {"file": "wood/WoodLog_Moss.glb", "h": 0.85},
    {"file": "wood/WoodLog.glb", "h": 0.80},
    {"file": "wood/TreeStump_Moss.glb", "h": 0.75},
    {"file": "wood/TreeStump.glb", "h": 0.70},
]

const FLOOR_SNOW_POOL := [
    {"file": "wood/WoodLog_Snow.glb", "h": 0.80},
    {"file": "wood/TreeStump_Snow.glb", "h": 0.70},
]

## How far a prop is allowed to sink into the ground, as a fraction of its
## height - roots and rubble should not hover on a slope.
const SINK := 0.05

const WATER_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.20, 0.44, 0.47);
uniform vec3 deep_color : source_color = vec3(0.04, 0.12, 0.20);
uniform float surface_alpha = 0.80;
uniform float wave_speed = 0.55;
uniform float wave_height = 0.06;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float swell = sin(world_pos.x * 0.085 + TIME * wave_speed)
        + sin(world_pos.z * 0.104 - TIME * wave_speed * 0.8);
    VERTEX.y += swell * wave_height * 0.5;
}

void fragment() {
    float ripple = sin(world_pos.x * 0.06 + TIME * wave_speed) * 0.5
        + sin(world_pos.z * 0.052 - TIME * wave_speed * 1.15) * 0.5;
    float blend = clamp(ripple * 0.5 + 0.5, 0.0, 1.0);
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
    ALBEDO = mix(deep_color, shallow_color, blend * 0.6 + fresnel * 0.45);
    ROUGHNESS = 0.10;
    METALLIC = 0.0;
    ALPHA = clamp(surface_alpha + fresnel * 0.22, 0.0, 1.0);
    EMISSION = shallow_color * fresnel * 0.18;
}
"""

var field: TerrainData

var _provider: Object = null
var _rng := RandomNumberGenerator.new()
var _water: MeshInstance3D
var _cave_entry: Node3D
var _portal_material: StandardMaterial3D
var _cave_cooldown := 0.0
## Merged mesh + measurements per model file, so a pool entry is resolved once.
var _model_info: Dictionary = {}
## Instances actually placed, per category - reported by `describe()`.
var _placed: Dictionary = {}


## Builds every prop layer.  `seed_value` must match the terrain seed so the
## scatter stays identical between runs.  `height_provider` is the live terrain
## back end when there is one - props are then seated on the surface that is
## actually rendered instead of on its analytic twin.
func build(field_ref: TerrainData, seed_value: int, height_provider: Object = null) -> void:
    field = field_ref
    _provider = height_provider
    _rng.seed = seed_value * 2654435761 + 17
    _build_lake()
    _build_forest()
    _build_undergrowth()
    _build_rocks()
    _build_slabs()
    _build_floor()
    _build_grass()
    _build_village()
    _build_cave()


## Ground height used to seat every prop.
func height_at(x: float, z: float) -> float:
    if _provider != null and _provider.has_method("sample_height"):
        return float(_provider.call("sample_height", x, z))
    if field == null:
        return 0.0
    return field.height(x, z)


func _process(delta: float) -> void:
    if _cave_cooldown > 0.0:
        _cave_cooldown = maxf(0.0, _cave_cooldown - delta)
    if _portal_material != null:
        _portal_material.emission_energy_multiplier = 1.6 + sin(float(Time.get_ticks_msec()) / 420.0) * 0.45


# ------------------------------------------------------------ shared bits ---

func _multimesh(mesh: Mesh, material: Material, transforms: Array[Transform3D], colors: Array[Color], cast_shadow := true) -> MultiMeshInstance3D:
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = mesh
    # `use_colors` has to be in place *before* `instance_count`, otherwise the
    # buffer is allocated without a colour channel and every per-instance tint
    # is rejected.
    multi.use_colors = not colors.is_empty()
    multi.instance_count = transforms.size()
    for i in transforms.size():
        multi.set_instance_transform(i, transforms[i])
        if not colors.is_empty():
            multi.set_instance_color(i, colors[i])
    var node := MultiMeshInstance3D.new()
    node.multimesh = multi
    node.material_override = material
    if not cast_shadow:
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return node


func _near_landmark(x: float, z: float, clearance: float) -> bool:
    for key in FIELD_SCRIPT.LANDMARKS.keys():
        var spot: Vector2 = FIELD_SCRIPT.LANDMARKS[key]
        if Vector2(x, z).distance_to(spot) < clearance:
            return true
    return false


func _is_paintable(x: float, z: float) -> bool:
    if not FIELD_SCRIPT.inside_world(x, z):
        return false
    return height_at(x, z) > FIELD_SCRIPT.WATER_LEVEL + 0.9


# ------------------------------------------------------- model instancing ---

## Cached mesh + measurements for one model file.
func _model(file: String) -> Dictionary:
    if _model_info.has(file):
        return _model_info[file]
    var mesh := MODELS.load_mesh(file)
    var info := {
        "mesh": mesh,
        "height": MODELS.height_of(mesh),
        "base": MODELS.base_offset_of(mesh),
    }
    _model_info[file] = info
    return info


## One transform bucket per model in a pool.
func _new_buckets(pool: Array) -> Array:
    var buckets: Array = []
    for i in pool.size():
        var list: Array[Transform3D] = []
        buckets.append(list)
    return buckets


## Drops one instance of a random model from `pool` into its bucket, sized so the
## model stands `pool[index].h * size` metres tall and seated on the ground.
func _scatter_one(pool: Array, buckets: Array, x: float, z: float, size := 1.0, tilt := 0.0, sink := SINK) -> void:
    var index := _rng.randi_range(0, pool.size() - 1)
    var info := _model(str(pool[index]["file"]))
    if info["mesh"] == null:
        return
    var height := float(pool[index]["h"]) * size
    var scale := height / float(info["height"])
    var basis := Basis(Vector3.UP, _rng.randf() * TAU)
    if tilt > 0.0:
        basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-tilt, tilt))
        basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-tilt, tilt))
    basis = basis.scaled(Vector3(scale, scale, scale))
    var seat := height_at(x, z) + float(info["base"]) * scale - height * sink
    (buckets[index] as Array[Transform3D]).append(Transform3D(basis, Vector3(x, seat, z)))


## Emits one MultiMeshInstance3D per model that actually got used.
##
## `cast_shadow` is only left on for the silhouettes that matter - trees and
## cliff boulders.  Foliage cover, litter and small rocks are lit by the terrain's
## own shadow map and would otherwise double the primitive count for nothing.
##
## Each merged mesh keeps the artist's own surfaces, so no material override is
## applied: `MultiMeshInstance3D` draws every surface with the material it was
## authored with.  Per-instance tinting would need those materials to fold
## vertex colour into the albedo, which would mean editing the assets, so variety
## comes from species, scale and rotation instead.
func _emit(pool: Array, buckets: Array, prefix: String, cast_shadow := true) -> int:
    var total := 0
    for i in pool.size():
        var transforms: Array[Transform3D] = buckets[i]
        if transforms.is_empty():
            continue
        var info := _model(str(pool[i]["file"]))
        var mesh: Mesh = info["mesh"]
        if mesh == null:
            continue
        var node := _multimesh(mesh, null, transforms, [], cast_shadow)
        node.name = "%s_%02d" % [prefix, i]
        add_child(node)
        total += transforms.size()
    return total


## Shared acceptance test for the woodland scatter.
func _forest_slot(clearance: float) -> Vector2:
    for _attempt in 14:
        var angle := _rng.randf() * TAU
        var radius := sqrt(_rng.randf()) * (FIELD_SCRIPT.FOREST_RADIUS + 40.0)
        var x := FIELD_SCRIPT.FOREST_CENTER.x + cos(angle) * radius
        var z := FIELD_SCRIPT.FOREST_CENTER.y + sin(angle) * radius
        if not _is_paintable(x, z) or _near_landmark(x, z, clearance):
            continue
        var ground := height_at(x, z)
        var density := field.forest_mask_at(x, z, ground)
        if density < 0.28:
            continue
        if _rng.randf() > density:
            continue
        return Vector2(x, z)
    return Vector2(INF, INF)


# ------------------------------------------------------------------ 湖泊 ---

func _build_lake() -> void:
    var centre := FIELD_SCRIPT.LAKE_CENTER
    var span := FIELD_SCRIPT.LAKE_RADIUS * 2.0 + FIELD_SCRIPT.WATER_OVERHANG * 2.0
    var plane := PlaneMesh.new()
    plane.size = Vector2(span, span)
    plane.subdivide_width = 24
    plane.subdivide_depth = 24
    var shader := Shader.new()
    shader.code = WATER_SHADER
    var material := ShaderMaterial.new()
    material.shader = shader
    _water = MeshInstance3D.new()
    _water.name = "LakeSurface"
    _water.mesh = plane
    _water.material_override = material
    _water.position = Vector3(centre.x, FIELD_SCRIPT.WATER_LEVEL, centre.y)
    _water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_water)


# ------------------------------------------------------------- 茂密的树林 ---

func _build_forest() -> void:
    var trees := _new_buckets(TREE_POOL)
    var snowy := _new_buckets(TREE_SNOW_POOL)
    var lone := _new_buckets(LONE_TREE_POOL)

    var planted := 0
    var attempts := 0
    while planted < TREE_TARGET and attempts < TREE_TARGET * 10:
        attempts += 1
        var spot := _forest_slot(22.0)
        if not is_finite(spot.x):
            continue
        _scatter_one(TREE_POOL, trees, spot.x, spot.y, _rng.randf_range(0.82, 1.24))
        planted += 1

    # Open woodland up on the range, where only the pack's snow-laden trees fit.
    var alpine := 0
    attempts = 0
    while alpine < ALPINE_TREE_TARGET and attempts < ALPINE_TREE_TARGET * 24:
        attempts += 1
        var x := _rng.randf_range(-360.0, 360.0)
        var z := _rng.randf_range(-570.0, -70.0)
        if not _is_paintable(x, z) or _near_landmark(x, z, 20.0):
            continue
        var ground := height_at(x, z)
        if ground < FIELD_SCRIPT.SNOW_LINE - 14.0:
            continue
        var grade := absf(ground - height_at(x + 4.0, z)) + absf(ground - height_at(x, z + 4.0))
        if grade > 4.0:
            continue
        _scatter_one(TREE_SNOW_POOL, snowy, x, z, _rng.randf_range(0.80, 1.15))
        alpine += 1

    var alone := 0
    attempts = 0
    while alone < LONE_TREE_TARGET and attempts < LONE_TREE_TARGET * 14:
        attempts += 1
        var x := _rng.randf_range(-340.0, 300.0)
        var z := _rng.randf_range(-150.0, 320.0)
        if not _is_paintable(x, z) or _near_landmark(x, z, 26.0):
            continue
        var ground := height_at(x, z)
        if ground > FIELD_SCRIPT.ROCK_LINE - 4.0 or field.lake_mask(x, z) > 0.05:
            continue
        _scatter_one(LONE_TREE_POOL, lone, x, z, _rng.randf_range(0.85, 1.20))
        alone += 1

    _placed["trees"] = _emit(TREE_POOL, trees, "ForestTree")
    _placed["snow_trees"] = _emit(TREE_SNOW_POOL, snowy, "SnowTree")
    _placed["lone_trees"] = _emit(LONE_TREE_POOL, lone, "LoneTree")


func _build_undergrowth() -> void:
    var bushes := _new_buckets(BUSH_POOL)
    var snowy := _new_buckets(BUSH_SNOW_POOL)

    var placed := 0
    var attempts := 0
    while placed < BUSH_TARGET and attempts < BUSH_TARGET * 12:
        attempts += 1
        var spot := _forest_slot(12.0)
        if not is_finite(spot.x):
            continue
        _scatter_one(BUSH_POOL, bushes, spot.x, spot.y, _rng.randf_range(0.70, 1.30), 0.10)
        placed += 1

    var alpine := 0
    attempts = 0
    while alpine < ALPINE_BUSH_TARGET and attempts < ALPINE_BUSH_TARGET * 24:
        attempts += 1
        var x := _rng.randf_range(-330.0, 330.0)
        var z := _rng.randf_range(-560.0, -80.0)
        if not _is_paintable(x, z) or _near_landmark(x, z, 14.0):
            continue
        if height_at(x, z) < FIELD_SCRIPT.SNOW_LINE - 6.0:
            continue
        _scatter_one(BUSH_SNOW_POOL, snowy, x, z, _rng.randf_range(0.80, 1.25), 0.12)
        alpine += 1

    _placed["bushes"] = _emit(BUSH_POOL, bushes, "Bush", false)
    _placed["snow_bushes"] = _emit(BUSH_SNOW_POOL, snowy, "SnowBush", false)


## Fallen logs and stumps, tucked in among the trees.
func _build_floor() -> void:
    var litter := _new_buckets(FLOOR_POOL)
    var snowy := _new_buckets(FLOOR_SNOW_POOL)

    var placed := 0
    var attempts := 0
    while placed < FLOOR_TARGET and attempts < FLOOR_TARGET * 14:
        attempts += 1
        var spot := _forest_slot(10.0)
        if not is_finite(spot.x):
            continue
        if field.forest_mask_at(spot.x, spot.y, height_at(spot.x, spot.y)) < 0.34:
            continue
        _scatter_one(FLOOR_POOL, litter, spot.x, spot.y, _rng.randf_range(0.75, 1.30), 0.16, 0.10)
        placed += 1

    var alpine := 0
    attempts = 0
    while alpine < ALPINE_FLOOR_TARGET and attempts < ALPINE_FLOOR_TARGET * 24:
        attempts += 1
        var x := _rng.randf_range(-330.0, 330.0)
        var z := _rng.randf_range(-560.0, -80.0)
        if not _is_paintable(x, z) or _near_landmark(x, z, 12.0):
            continue
        if height_at(x, z) < FIELD_SCRIPT.SNOW_LINE - 4.0:
            continue
        _scatter_one(FLOOR_SNOW_POOL, snowy, x, z, _rng.randf_range(0.80, 1.25), 0.18, 0.12)
        alpine += 1

    _placed["floor_details"] = _emit(FLOOR_POOL, litter, "ForestFloor", false)
    _placed["snow_floor_details"] = _emit(FLOOR_SNOW_POOL, snowy, "SnowFloor", false)


# ------------------------------------------------------------ 岩石 / 巨石 ---

func _build_rocks() -> void:
    var rocks := _new_buckets(ROCK_POOL)
    var mossy := _new_buckets(ROCK_MOSS_POOL)
    var snowy := _new_buckets(ROCK_SNOW_POOL)

    var placed := 0
    var attempts := 0
    while placed < ROCK_TARGET and attempts < ROCK_TARGET * 16:
        attempts += 1
        var x := _rng.randf_range(-500.0, 500.0)
        var z := _rng.randf_range(-520.0, 480.0)
        if not _is_paintable(x, z) or field.lake_mask(x, z) > 0.08 or _near_landmark(x, z, 14.0):
            continue
        var ground := height_at(x, z)
        var rocky := ground > FIELD_SCRIPT.ROCK_LINE - 4.0
        var steep := ground - height_at(x + 5.0, z) > 1.6
        if not rocky and not steep and _rng.randf() > 0.12:
            continue
        if ground > FIELD_SCRIPT.SNOW_LINE - 6.0:
            _scatter_one(ROCK_SNOW_POOL, snowy, x, z, _rng.randf_range(0.70, 1.85), 0.20, 0.10)
        elif field.forest_mask_at(x, z, ground) > 0.45:
            _scatter_one(ROCK_MOSS_POOL, mossy, x, z, _rng.randf_range(0.70, 1.85), 0.20, 0.10)
        else:
            _scatter_one(ROCK_POOL, rocks, x, z, _rng.randf_range(0.70, 1.85), 0.20, 0.10)
        placed += 1

    _placed["rocks"] = _emit(ROCK_POOL, rocks, "Rock", false)
    _placed["moss_rocks"] = _emit(ROCK_MOSS_POOL, mossy, "MossRock", false)
    _placed["snow_rocks"] = _emit(ROCK_SNOW_POOL, snowy, "SnowRock", false)


## The heavy silhouettes along the escarpment that make 断崖 read as broken rock.
func _build_slabs() -> void:
    var slabs := _new_buckets(BOULDER_POOL)
    var snowy := _new_buckets(BOULDER_SNOW_POOL)

    var placed := 0
    var attempts := 0
    while placed < SLAB_TARGET and attempts < SLAB_TARGET * 20:
        attempts += 1
        var x := _rng.randf_range(-420.0, 420.0)
        var z := _rng.randf_range(-330.0, -10.0)
        if not _is_paintable(x, z):
            continue
        var ground := height_at(x, z)
        if absf(ground - height_at(x, z + 6.0)) < 2.2:
            continue
        if ground > FIELD_SCRIPT.SNOW_LINE:
            _scatter_one(BOULDER_SNOW_POOL, snowy, x, z, _rng.randf_range(0.70, 1.45), 0.16, 0.12)
        else:
            _scatter_one(BOULDER_POOL, slabs, x, z, _rng.randf_range(0.70, 1.45), 0.16, 0.12)
        placed += 1

    _placed["boulders"] = _emit(BOULDER_POOL, slabs, "CliffBoulder")
    _placed["snow_boulders"] = _emit(BOULDER_SNOW_POOL, snowy, "SnowBoulder")


# ------------------------------------------------------- 草丛 / 野花 ---

func _build_grass() -> void:
    var tufts := _new_buckets(GRASS_POOL)
    var blooms := _new_buckets(FLOWER_POOL)

    var placed := 0
    var attempts := 0
    while placed < GRASS_TARGET and attempts < GRASS_TARGET * 6:
        attempts += 1
        var angle := _rng.randf() * TAU
        var radius := sqrt(_rng.randf()) * 340.0
        var x := cos(angle) * radius
        var z := sin(angle) * radius
        if not _is_paintable(x, z) or field.lake_mask(x, z) > 0.05:
            continue
        var ground := height_at(x, z)
        if ground > FIELD_SCRIPT.SNOW_LINE - 8.0 or ground < FIELD_SCRIPT.WATER_LEVEL + 1.0:
            continue
        _scatter_one(GRASS_POOL, tufts, x, z, _rng.randf_range(0.70, 1.45), 0.14, 0.03)
        placed += 1

    placed = 0
    attempts = 0
    while placed < FLOWER_TARGET and attempts < FLOWER_TARGET * 8:
        attempts += 1
        var angle := _rng.randf() * TAU
        var radius := sqrt(_rng.randf()) * 300.0
        var x := cos(angle) * radius
        var z := sin(angle) * radius
        if not _is_paintable(x, z) or field.lake_mask(x, z) > 0.04:
            continue
        var ground := height_at(x, z)
        if ground > FIELD_SCRIPT.ROCK_LINE or ground < FIELD_SCRIPT.WATER_LEVEL + 1.2:
            continue
        if field.forest_mask_at(x, z, ground) > 0.55:
            continue
        _scatter_one(FLOWER_POOL, blooms, x, z, _rng.randf_range(0.80, 1.35), 0.18, 0.02)
        placed += 1

    _placed["grass"] = _emit(GRASS_POOL, tufts, "Grass", false)
    _placed["flowers"] = _emit(FLOWER_POOL, blooms, "Flower", false)


# --------------------------------------------------------------- 桃源村 ---

func _build_village() -> void:
    var court := Node3D.new()
    court.name = "Village"

    var gate := ARCH.paifang(9.0, 6.4)
    gate.name = "ShanmenGate"
    gate.position = _ground(FIELD_SCRIPT.LANDMARKS["gate"])
    gate.rotation.y = PI
    court.add_child(gate)

    var shrine := ARCH.hall(12.0, 7.0, 4.2)
    shrine.name = "ShrineHall"
    shrine.position = _ground(FIELD_SCRIPT.LANDMARKS["shrine"])
    shrine.rotation.y = PI * 0.5
    court.add_child(shrine)

    var pavilion := ARCH.pavilion(3.1, 3.0)
    pavilion.name = "GuanlanPavilion"
    pavilion.position = _ground(FIELD_SCRIPT.LANDMARKS["pavilion"])
    court.add_child(pavilion)

    var pagoda := ARCH.pagoda(5, 2.9)
    pagoda.name = "ZhenyuePagoda"
    pagoda.position = _ground(FIELD_SCRIPT.LANDMARKS["pagoda"])
    court.add_child(pagoda)

    var hall := ARCH.hall(15.0, 9.0, 4.6)
    hall.name = "LibraryHall"
    hall.position = _ground(FIELD_SCRIPT.LANDMARKS["hall"])
    hall.rotation.y = PI
    court.add_child(hall)

    # Courtyard walls tying the buildings together, plus a lantern-lined path.
    var walls := [
        [Vector2(21.0, 16.0), Vector2(21.0, 78.0)],
        [Vector2(-21.0, 16.0), Vector2(-21.0, 82.0)],
        [Vector2(-21.0, 82.0), Vector2(23.0, 82.0)],
    ]
    for span in walls:
        var start: Vector2 = span[0]
        var end: Vector2 = span[1]
        var segment := ARCH.wall(start, end, 2.1, 0.5)
        segment.position.y = height_at(segment.position.x, segment.position.z)
        court.add_child(segment)

    for i in range(6):
        var t := float(i) / 5.0
        var lantern := ARCH.stone_lantern(1.5)
        lantern.position = _ground(Vector2(lerpf(-7.0, 7.0, t), 8.0 + t * 26.0))
        lantern.rotation.y = _rng.randf() * TAU
        court.add_child(lantern)

    court.add_child(_build_jetty())
    add_child(court)


func _ground(flat: Vector2) -> Vector3:
    return Vector3(flat.x, height_at(flat.x, flat.y), flat.y)


## A short wooden pier pushed out over 明镜湖, found by walking outwards from
## the lake centre until the bank rises above the waterline.
func _build_jetty() -> Node3D:
    var root := Node3D.new()
    root.name = "Jetty"
    var outward := (FIELD_SCRIPT.LANDMARKS["jetty"] - FIELD_SCRIPT.LAKE_CENTER).normalized()
    if outward == Vector2.ZERO:
        outward = Vector2.LEFT
    var shore := FIELD_SCRIPT.LAKE_CENTER
    for i in range(260):
        var probe := FIELD_SCRIPT.LAKE_CENTER + outward * float(i)
        if height_at(probe.x, probe.y) > FIELD_SCRIPT.WATER_LEVEL + 0.9:
            shore = probe
            break
    var deck_y := FIELD_SCRIPT.WATER_LEVEL + 1.05
    var yaw := -atan2(outward.y, outward.x)
    for i in range(9):
        var spot := shore + outward * (float(i) * 1.7 - 3.4)
        var deck := MeshInstance3D.new()
        var plank := BoxMesh.new()
        plank.size = Vector3(3.0, 0.22, 1.5)
        deck.mesh = plank
        deck.material_override = ARCH.material_for(ARCH.WOOD)
        deck.position = Vector3(spot.x, deck_y, spot.y)
        deck.rotation.y = yaw
        root.add_child(deck)
    var side := Vector2(-outward.y, outward.x)
    for s in [-1.2, 1.2]:
        for i in range(3):
            var spot := shore + outward * (float(i) * 5.0 - 3.0) + side * float(s)
            var post := MeshInstance3D.new()
            var pole := CylinderMesh.new()
            pole.top_radius = 0.14
            pole.bottom_radius = 0.18
            pole.height = 3.4
            post.mesh = pole
            post.material_override = ARCH.material_for(ARCH.DARK_WOOD)
            post.position = Vector3(spot.x, deck_y - 1.6, spot.y)
            root.add_child(post)
    var lantern := ARCH.stone_lantern(1.6)
    lantern.position = Vector3(shore.x, deck_y + 0.11, shore.y) + Vector3(side.x, 0.0, side.y) * 1.6
    root.add_child(lantern)
    return root


# ------------------------------------------------------------- 山洞秘境 ---

## 玄山洞 - the dungeon entrance, cut into the foot of the 断崖.
func _build_cave() -> void:
    var root := Node3D.new()
    root.name = "CaveShrine"
    root.position = _ground(FIELD_SCRIPT.LANDMARKS["cave"])

    # A rock mass behind the mouth so the entrance reads as a hole in the
    # cliff rather than a free-standing door.
    var massif := Node3D.new()
    massif.name = "RockMass"
    root.add_child(massif)
    for i in range(11):
        var angle := PI * 0.5 + (float(i) / 10.0) * PI * 1.6
        var radius := 11.0 + _rng.randf_range(-1.5, 3.0)
        var instance := MeshInstance3D.new()
        # The cliff boulders come out of the same CC0 pack as the scatter, so
        # the secret-realm mouth is carved out of the same rock as the range.
        var info := _model(str(BOULDER_POOL[2 + i % 4]["file"]))
        if info["mesh"] == null:
            continue
        instance.mesh = info["mesh"]
        var height := _rng.randf_range(6.5, 13.0)
        var scale := height / float(info["height"])
        instance.scale = Vector3.ONE * scale
        instance.position = Vector3(cos(angle) * radius, float(info["base"]) * scale - height * 0.10, sin(angle) * radius)
        instance.rotation = Vector3(_rng.randf_range(-0.10, 0.10), angle, _rng.randf_range(-0.10, 0.10))
        massif.add_child(instance)

    var mouth := Node3D.new()
    mouth.name = "Mouth"
    mouth.position = Vector3(0.0, 0.0, 6.5)
    root.add_child(mouth)

    var frame := ARCH.material_for(Color(0.34, 0.33, 0.30))
    for side in [-1.0, 1.0]:
        var pillar := MeshInstance3D.new()
        var post := BoxMesh.new()
        post.size = Vector3(1.5, 6.4, 2.2)
        pillar.mesh = post
        pillar.material_override = frame
        pillar.position = Vector3(side * 3.1, 3.2, 0.0)
        mouth.add_child(pillar)
    var lintel := MeshInstance3D.new()
    var beam := BoxMesh.new()
    beam.size = Vector3(8.6, 1.6, 2.6)
    lintel.mesh = beam
    lintel.material_override = frame
    lintel.position = Vector3(0.0, 6.9, 0.0)
    mouth.add_child(lintel)

    # The dark interior behind the arch.
    var hall := MeshInstance3D.new()
    var room := BoxMesh.new()
    room.size = Vector3(7.4, 6.2, 14.0)
    hall.mesh = room
    hall.material_override = ARCH.material_for(Color(0.02, 0.026, 0.034))
    hall.position = Vector3(0.0, 3.1, -7.2)
    mouth.add_child(hall)

    # The portal itself: an emissive ring plus drifting motes.
    var ring := MeshInstance3D.new()
    ring.name = "Portal"
    var torus := TorusMesh.new()
    torus.inner_radius = 1.7
    torus.outer_radius = 2.4
    torus.rings = 32
    ring.mesh = torus
    _portal_material = StandardMaterial3D.new()
    _portal_material.albedo_color = Color(0.42, 0.86, 0.88, 0.85)
    _portal_material.emission_enabled = true
    _portal_material.emission = Color(0.36, 0.92, 0.86)
    _portal_material.emission_energy_multiplier = 1.8
    _portal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _portal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = _portal_material
    ring.position = Vector3(0.0, 2.6, -0.6)
    mouth.add_child(ring)

    var motes := GPUParticles3D.new()
    motes.name = "Motes"
    motes.amount = 48
    motes.lifetime = 2.4
    motes.local_coords = false
    motes.emitting = true
    var drift := ParticleProcessMaterial.new()
    drift.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    drift.emission_sphere_radius = 2.2
    drift.direction = Vector3(0.0, 1.0, 0.0)
    drift.spread = 40.0
    drift.initial_velocity_min = 0.2
    drift.initial_velocity_max = 0.9
    drift.gravity = Vector3(0.0, 0.35, 0.0)
    drift.scale_min = 0.08
    drift.scale_max = 0.22
    drift.color = Color(0.52, 1.0, 0.94, 0.85)
    motes.process_material = drift
    var mote := QuadMesh.new()
    mote.size = Vector2(0.18, 0.18)
    motes.draw_pass_1 = mote
    motes.position = Vector3(0.0, 2.6, -0.6)
    mouth.add_child(motes)

    var lamp := OmniLight3D.new()
    lamp.light_color = Color(0.45, 0.95, 0.92)
    lamp.light_energy = 2.4
    lamp.omni_range = 16.0
    lamp.position = Vector3(0.0, 3.0, 0.4)
    mouth.add_child(lamp)

    var label := Label3D.new()
    label.name = "CaveLabel"
    label.text = LocaleData.text("landmark_cave")
    label.position = Vector3(0.0, 8.6, 0.4)
    ThemeBuilder.style_world_label(label, 44, Color(0.62, 0.96, 0.92))
    mouth.add_child(label)

    var trigger := Area3D.new()
    trigger.name = "CaveTrigger"
    var zone := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 9.0
    zone.shape = sphere
    trigger.add_child(zone)
    trigger.position = Vector3(0.0, 2.0, 3.0)
    trigger.body_entered.connect(_on_cave_entered)
    root.add_child(trigger)

    _cave_entry = root
    add_child(root)


func _on_cave_entered(body: Node3D) -> void:
    if _cave_cooldown > 0.0 or not body.is_in_group("player"):
        return
    _cave_cooldown = 25.0
    EventBus.toast_requested.emit(LocaleData.text("landmark_cave_enter"), Color(0.58, 0.94, 0.90))
    EventBus.combat_log.emit(LocaleData.text("landmark_cave_log"))


# --------------------------------------------------------------- summary ---

## Every model file the prop layers reference, in pool order.
func model_files() -> Array:
    var seen := {}
    var out: Array = []
    for pool in [TREE_POOL, TREE_SNOW_POOL, LONE_TREE_POOL, BUSH_POOL, BUSH_SNOW_POOL,
            GRASS_POOL, FLOWER_POOL, ROCK_POOL, ROCK_MOSS_POOL, ROCK_SNOW_POOL,
            BOULDER_POOL, BOULDER_SNOW_POOL, FLOOR_POOL, FLOOR_SNOW_POOL]:
        for entry in pool:
            var file := str(entry["file"])
            if seen.has(file):
                continue
            seen[file] = true
            out.append(file)
    return out


## Short description of what was placed, used by the loading log and the tests.
func describe() -> Dictionary:
    var out := {}
    out["water"] = _water != null
    out["village"] = get_node_or_null("Village") != null
    out["cave"] = _cave_entry != null
    for key in _placed.keys():
        out[key] = _placed[key]
    out["models"] = model_files().size()
    out["batches"] = _count_batches(self)
    return out


## MultiMeshInstance3D batches under a node - the draw-call cost of the props.
func _count_batches(node: Node) -> int:
    var total := 0
    if node is MultiMeshInstance3D:
        total += 1
    for child in node.get_children():
        total += _count_batches(child)
    return total
