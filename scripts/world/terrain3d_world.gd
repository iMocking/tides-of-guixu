extends Node3D
class_name Terrain3DWorld
## Terrain3D-backed world map for 归墟之潮.
##
## Wraps the Terrain3D GDExtension addon: it builds the clipmap, paints the
## biome textures and streams the collision the player walks on.  The heights
## themselves come from `TerrainData`, which is also what the placeholder
## fallback (`TerrainGenerator`) renders, so the two back ends produce the same
## landscape.
##
## Everything here is generated at runtime from noise - no imported heightmaps,
## no texture files - which keeps the project's zero-external-asset rule while
## still giving the map高山 / 悬崖 / 湖泊 / 密林 / 雪地 / 秘境 / 古风建筑.
##
## Call `start()` once the node is in the tree and poll `is_ready()`; the
## clipmap is built in row bands across frames so the loading screen keeps
## animating while it works.

const FIELD_SCRIPT := preload("res://scripts/world/terrain_data.gd")

## Terrain3D registers itself as a class, so this is how we tell whether the
## addon actually loaded for this engine build.
const TERRAIN_CLASS := "Terrain3D"
const ASSETS_CLASS := "Terrain3DAssets"
const TEXTURE_CLASS := "Terrain3DTextureAsset"

## Resolution of the generated albedo / normal layers.
const TEXTURE_SIZE := 256
## How far from the camera Terrain3D keeps physics shapes alive.
const COLLISION_RADIUS := 190.0
const COLLISION_SHAPE_SIZE := 16.0

var field: TerrainData
var terrain: Node3D = null
var available := false
var started := false
var finished := false

var _camera: Camera3D
var _assets: Resource = null
var _total_regions := 0
var _built_regions := 0
var _progress := 0.0
var _error := ""


## True when the Terrain3D GDExtension is present in this build.
static func is_supported() -> bool:
    return ClassDB.class_exists(TERRAIN_CLASS) and ClassDB.class_exists(ASSETS_CLASS)


func start(seed_value: int, camera: Camera3D = null) -> void:
    if started:
        return
    started = true
    _camera = camera
    field = FIELD_SCRIPT.create(seed_value)
    _total_regions = FIELD_SCRIPT.region_locations().size()
    available = is_supported()
    if not available:
        _error = "Terrain3D addon not loaded"
        finished = true
        return
    _run()


func _run() -> void:
    if not await _create_terrain():
        return
    if not await _create_textures():
        return
    await _build_regions()
    _finish()


# ------------------------------------------------------------- building ---

func _create_terrain() -> bool:
    if not is_inside_tree():
        _error = "node is not in the scene tree"
        finished = true
        return false
    terrain = ClassDB.instantiate(TERRAIN_CLASS) as Node3D
    if terrain == null:
        _error = "could not instantiate Terrain3D"
        available = false
        finished = true
        return false
    terrain.name = "Terrain3D"
    # Region geometry has to be set before any data is written.
    terrain.region_size = FIELD_SCRIPT.REGION_SIZE
    terrain.vertex_spacing = FIELD_SCRIPT.VERTEX_SPACING
    # Keep everything in memory: the world is regenerated from the seed on
    # every run, and we never want the addon writing into the repo.
    terrain.data_directory = ""
    terrain.save_16_bit = false
    add_child(terrain)
    # Terrain3D builds its Data / Material / Collision objects on entering the
    # tree, so the properties only exist from the next frame onwards.
    await get_tree().process_frame
    terrain.collision_mode = 1
    terrain.collision_radius = COLLISION_RADIUS
    terrain.collision_shape_size = COLLISION_SHAPE_SIZE
    terrain.cast_shadows = 1
    if _camera != null and is_instance_valid(_camera):
        terrain.set_camera(_camera)
    if terrain.data == null or terrain.assets == null or terrain.material == null:
        _error = "Terrain3D did not initialise"
        available = false
        finished = true
        return false
    _assets = terrain.assets
    return true


## Every painted layer is a pair of noise textures - an albedo ramp with the
## height packed into alpha, and a normal/roughness map - matching what the
## official CodeGenerated demo does.
func _create_textures() -> bool:
    var assets: Resource = terrain.assets
    for row in FIELD_SCRIPT.TEXTURES:
        var asset := await _make_texture_asset(row)
        if asset == null:
            _error = "texture generation failed"
            finished = true
            return false
        assets.set_texture(int(row["id"]), asset)
    terrain.assets = assets
    terrain.material.auto_shader = false
    terrain.material.world_background = 0
    if terrain.material.has_method("set_shader_param"):
        terrain.material.set_shader_param("blend_sharpness", 0.86)
    terrain.assets = assets
    await get_tree().process_frame
    return true


func _make_texture_asset(row: Dictionary) -> Resource:
    var id := int(row["id"])
    var tint := Color(str(row["albedo"]))

    var noise := FastNoiseLite.new()
    noise.seed = field.world_seed + id * 7717 + 13
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.016 + 0.0035 * float(id)
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 4
    noise.fractal_gain = 0.5
    noise.fractal_lacunarity = 2.1

    var ramp := Gradient.new()
    ramp.set_color(0, tint.darkened(0.24))
    ramp.set_color(1, tint.lightened(0.18))

    var albedo_noise := NoiseTexture2D.new()
    albedo_noise.width = TEXTURE_SIZE
    albedo_noise.height = TEXTURE_SIZE
    albedo_noise.seamless = true
    albedo_noise.color_ramp = ramp
    albedo_noise.noise = noise
    await albedo_noise.changed
    var albedo_image: Image = albedo_noise.get_image()
    if albedo_image == null:
        return null
    albedo_image.generate_mipmaps()

    var normal_noise := NoiseTexture2D.new()
    normal_noise.width = TEXTURE_SIZE
    normal_noise.height = TEXTURE_SIZE
    normal_noise.seamless = true
    normal_noise.as_normal_map = true
    normal_noise.bump_strength = 2.6 + float(id) * 0.5
    normal_noise.noise = noise
    await normal_noise.changed
    var normal_image: Image = normal_noise.get_image()
    if normal_image == null:
        return null
    normal_image.generate_mipmaps()

    # Terrain3D wants roughness in the alpha of the normal map; a plain noise
    # texture leaves it at 1.0, so instead of rewriting a quarter of a million
    # pixels we let the layer tint carry the look and only nudge the modifier.
    var asset: Resource = ClassDB.instantiate(TEXTURE_CLASS)
    asset.name = str(row["name_key"])
    asset.albedo_texture = ImageTexture.create_from_image(albedo_image)
    asset.normal_texture = ImageTexture.create_from_image(normal_image)
    asset.albedo_color = tint.lightened(0.24)
    asset.uv_scale = float(row["uv"])
    asset.normal_depth = float(row["normal"])
    asset.ao_strength = float(row["ao"])
    asset.roughness = float(row["rough"]) - 0.9
    asset.detiling_rotation = 0.18 + float(id) * 0.05
    asset.detiling_shift = 0.05 * float(id)
    return asset


## Builds the whole clipmap in one go.
##
## Terrain3D slices an imported image into region-sized pieces itself, and only
## the *last* slice triggers the mesh rebuild - importing region by region meant
## nine rebuilds and a cost that grew with every region.  One block image means
## one rebuild.
##
## The work is split into region-row bands so the loading screen keeps
## animating; each band writes `_progress` for the loading bar.
func _build_regions() -> void:
    var size := int(FIELD_SCRIPT.REGION_SIZE)
    var side := FIELD_SCRIPT.REGION_RADIUS * 2 + 1
    var grid := size * side
    var stride := grid + 2
    var step := float(FIELD_SCRIPT.VERTEX_SPACING)
    var origin := FIELD_SCRIPT.block_origin()
    var count := grid * grid

    # --- heights, with a one-vertex border so slopes are exact at the seams ---
    var heights := PackedFloat32Array()
    heights.resize(stride * stride)
    var row := 0
    while row < grid:
        var last := mini(row + size, grid)
        for j in range(row - 1, last + 1):
            if j < -1 or j > grid:
                continue
            var world_z := origin.y + float(j) * step
            var base := (j + 1) * stride
            for i in range(-1, grid + 1):
                heights[base + i + 1] = field.height(origin.x + float(i) * step, world_z)
        row = last
        _progress = 0.60 * float(row) / float(grid)
        if row < grid:
            if not is_inside_tree():
                return
            await get_tree().process_frame

    # --- biome per vertex ----------------------------------------------------
    var texture_ids := PackedInt32Array()
    texture_ids.resize(count)
    row = 0
    while row < grid:
        var last := mini(row + size, grid)
        for j in range(row, last):
            var world_z := origin.y + float(j) * step
            var base := (j + 1) * stride
            var out_row := j * grid
            for i in grid:
                var ground := heights[base + i + 1]
                var slope := maxf(
                    absf(heights[base + i + 2] - heights[base + i]),
                    absf(heights[base + stride + i + 1] - heights[base - stride + i + 1])
                ) / (2.0 * step)
                var forest := field.forest_mask_at(origin.x + float(i) * step, world_z, ground)
                texture_ids[out_row + i] = field.biome_texture_for(ground, slope, forest)
        row = last
        _progress = 0.60 + 0.35 * float(row) / float(grid)
        if row < grid:
            if not is_inside_tree():
                return
            await get_tree().process_frame

    # --- packed control map --------------------------------------------------
    # A biome edge is dithered against the first neighbouring biome that
    # differs, which turns a hard texture border into a speckled transition.
    var controls := PackedInt32Array()
    controls.resize(count)
    for j in grid:
        var out_row := j * grid
        for i in grid:
            var index := out_row + i
            var base_id := texture_ids[index]
            var overlay_id := base_id
            if i > 0 and texture_ids[index - 1] != base_id:
                overlay_id = texture_ids[index - 1]
            elif i < grid - 1 and texture_ids[index + 1] != base_id:
                overlay_id = texture_ids[index + 1]
            elif j > 0 and texture_ids[index - grid] != base_id:
                overlay_id = texture_ids[index - grid]
            elif j < grid - 1 and texture_ids[index + grid] != base_id:
                overlay_id = texture_ids[index + grid]
            if overlay_id == base_id:
                controls[index] = pack_control(base_id, overlay_id, 0)
            else:
                controls[index] = pack_control(base_id, overlay_id,
                    64 + int(hash_unit(i, j, base_id * 37 + overlay_id) * 158.0))
    _progress = 0.97

    # --- hand it to Terrain3D -----------------------------------------------
    var inner := PackedFloat32Array()
    inner.resize(count)
    for j in grid:
        var src := (j + 1) * stride + 1
        var dst := j * grid
        for i in grid:
            inner[dst + i] = heights[src + i]

    var height_image: Image = Image.create_from_data(grid, grid, false, Image.FORMAT_RF, inner.to_byte_array())
    var control_image: Image = Image.create_from_data(grid, grid, false, Image.FORMAT_RF, controls.to_byte_array())
    if height_image == null or control_image == null:
        _error = "could not build the clipmap images"
        finished = true
        return
    terrain.data.import_images(
        [height_image, control_image, null],
        Vector3(origin.x, 0.0, origin.y),
        0.0,
        1.0
    )
    _built_regions = _total_regions
    _progress = 1.0


func _finish() -> void:
    finished = true
    if terrain != null and terrain.data != null:
        terrain.data.calc_height_range(false)


# ------------------------------------------------------------- queries ---

func is_ready() -> bool:
    return finished and _built_regions >= _total_regions


func get_progress() -> float:
    return clampf(_progress, 0.0, 1.0)


func get_error() -> String:
    return _error


## Number of clipmap regions currently in the terrain; the fallback exposes the
## same call so `GameWorld.is_world_ready()` does not care which one is live.
func get_loaded_chunk_count() -> int:
    if terrain != null and terrain.data != null:
        return int(terrain.data.get_region_count())
    return _built_regions


## Terrain3D owns its own clipmap, so there is nothing to stream by hand; the
## call is kept so `GameWorld` can drive either back end identically.
func update_stream(_center: Vector3, _force: bool = false) -> void:
    pass


## Height of the surface in metres.  Reads the real heightmap so anything that
## queries it agrees with what the player walks on, falling back to the shared
## field outside the generated grid.
func sample_height(x: float, z: float) -> float:
    if terrain != null and terrain.data != null:
        var sampled: float = terrain.data.get_height(Vector3(x, 0.0, z))
        if not is_nan(sampled) and not is_inf(sampled):
            return sampled
    if field != null:
        return field.height(x, z)
    return 0.0


func ground_position(x: float, z: float) -> Vector3:
    return Vector3(x, sample_height(x, z), z)


func set_camera(camera: Camera3D) -> void:
    _camera = camera
    if terrain != null and is_instance_valid(camera):
        terrain.set_camera(camera)


## Number of painted layers handed to the Terrain3D asset list.
func get_texture_count() -> int:
    if _assets != null:
        return int(_assets.get_texture_count())
    return 0


## Base texture id painted at a world position (0 when nothing is painted).
func control_base_id(x: float, z: float) -> int:
    if terrain != null and terrain.data != null:
        return int(terrain.data.get_control_base_id(Vector3(x, 0.0, z)))
    return 0


## The live Terrain3DCollision mode; 0 means collision is switched off.
func collision_mode() -> int:
    if terrain != null:
        return int(terrain.collision_mode)
    return 0


func mean_height() -> float:
    if terrain == null or terrain.data == null:
        return 0.0
    var range: Vector2 = terrain.data.get_height_range()
    return (range.x + range.y) * 0.5


func height_range() -> Vector2:
    if terrain == null or terrain.data == null:
        return Vector2.ZERO
    return terrain.data.get_height_range()


# ---------------------------------------------------------- control map ---

## Packs a Terrain3D control pixel: 5-bit base id, 5-bit overlay id, 8-bit
## blend.  See `controlmap_format.md` in the addon docs.
static func pack_control(base_id: int, overlay_id: int, blend: int) -> int:
    return ((base_id & 0x1F) << 27) | ((overlay_id & 0x1F) << 22) | ((blend & 0xFF) << 14)


static func unpack_base(value: int) -> int:
    return (value >> 27) & 0x1F


static func unpack_overlay(value: int) -> int:
    return (value >> 22) & 0x1F


static func unpack_blend(value: int) -> int:
    return (value >> 14) & 0xFF


## Deterministic 0..1 hash used for biome edges and scatter placement.
static func hash_unit(a: int, b: int, salt: int) -> float:
    var h := (a * 73856093) ^ (b * 19349663) ^ (salt * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    h = h ^ (h >> 16)
    return float(absi(h) % 100003) / 100003.0
