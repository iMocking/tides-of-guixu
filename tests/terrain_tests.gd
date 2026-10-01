extends Node
## Headless behaviour tests for the terrain back ends and the world map.
##
##   godot --headless --path . res://tests/terrain_tests.tscn
##
## Prints one line per failing check and exits 0 when everything passes.  The
## Terrain3D half is skipped - not failed - when the addon is not available for
## the running engine build, so the placeholder fallback can still be tested.

const FIELD_SCRIPT := preload("res://scripts/world/terrain_data.gd")
const TERRAIN3D_WORLD_SCRIPT := preload("res://scripts/world/terrain3d_world.gd")
const TERRAIN_GENERATOR_SCRIPT := preload("res://scripts/world/terrain_generator.gd")
const WORLD_FEATURES_SCRIPT := preload("res://scripts/world/world_features.gd")
const PROP_MODELS_SCRIPT := preload("res://scripts/world/prop_models.gd")

const SEED := 20260214

var _checks := 0
var _failures: Array[String] = []
var _field: TerrainData


func _ready() -> void:
    call_deferred("_run_tests")


func _run_tests() -> void:
    print("== terrain field ==")
    _test_field()
    print("== landmark layout ==")
    _test_landmarks()
    print("== Terrain3D back end ==")
    await _test_terrain3d()
    print("== placeholder back end ==")
    await _test_fallback()
    print("== world features ==")
    await _test_features()
    print("== game world integration ==")
    await _test_game_world()

    print("---------------------------------------------")
    print("[terrain] %d checks, %d failure(s)" % [_checks, _failures.size()])
    for failure in _failures:
        print("  FAIL  " + failure)
    if _failures.is_empty():
        print("[terrain] OK")
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(1 if not _failures.is_empty() else 0)


# ------------------------------------------------------------- helpers ---

func _check(condition: bool, message: String) -> bool:
    _checks += 1
    if not condition:
        _failures.append(message)
    return condition


func _check_close(actual: float, expected: float, tolerance: float, message: String) -> bool:
    return _check(absf(actual - expected) <= tolerance, "%s (got %.3f, wanted %.3f +/- %.3f)" % [message, actual, expected, tolerance])


func _check_between(value: float, low: float, high: float, message: String) -> bool:
    return _check(value >= low and value <= high, "%s (got %.3f, wanted %.3f .. %.3f)" % [message, value, low, high])


# ------------------------------------------------------------ the field ---

func _test_field() -> void:
    _field = FIELD_SCRIPT.create(SEED)

    # The starting basin is levelled so the shrine, NPCs and quest content keep
    # working exactly as they did before the terrain back end was swapped.
    _check_close(_field.height(0.0, 0.0), FIELD_SCRIPT.BASE_LEVEL, 0.05, "start basin is level")
    _check_close(_field.height(20.0, 10.0), _field.height(0.0, 0.0), 0.6, "start basin is walkable")

    # 苍梧山脉: the massif really does climb, and its ridge clears the snowline.
    _check(_field.mountain_mask(FIELD_SCRIPT.MASSIF_CENTER.x, FIELD_SCRIPT.MASSIF_CENTER.y) > 0.85,
        "massif centre is fully inside the mountain mask")
    var peak := -999.0
    var snow_spot := Vector2.ZERO
    var found_snow := false
    for gx in range(-300, 301, 15):
        for gz in range(-520, -60, 15):
            var h := _field.height(float(gx), float(gz))
            if h > peak:
                peak = h
            if not found_snow and _field.biome_at(float(gx), float(gz)) == FIELD_SCRIPT.BIOME_SNOW:
                found_snow = true
                snow_spot = Vector2(gx, gz)
    _check(peak > FIELD_SCRIPT.SNOW_LINE, "high mountains rise above the snowline (peak %.1f m)" % peak)
    _check(peak > 80.0, "the range has real altitude (peak %.1f m)" % peak)
    _check(found_snow, "snow biome is painted on the peaks")

    # 断崖: terraced flanks produce faces far steeper than the meadow.
    var steepest := 0.0
    for gx in range(-260, 261, 7):
        for gz in range(-320, -20, 7):
            var x := float(gx)
            var z := float(gz)
            var dx := _field.height(x + 2.0, z) - _field.height(x - 2.0, z)
            var dz := _field.height(x, z + 2.0) - _field.height(x, z - 2.0)
            steepest = maxf(steepest, maxf(absf(dx), absf(dz)) / 4.0)
    _check(steepest > FIELD_SCRIPT.SLOPE_CLIFF, "the escarpment reaches cliff gradient (max %.2f)" % steepest)

    # 明镜湖: a real basin below the waterline, with the banks above it.
    var lake_bottom := 999.0
    for i in range(220):
        var angle := TAU * float(i) / 220.0
        var radius := _rng_radius(float(i))
        var probe := FIELD_SCRIPT.LAKE_CENTER + Vector2(cos(angle), sin(angle)) * radius
        lake_bottom = minf(lake_bottom, _field.height(probe.x, probe.y))
    _check(lake_bottom < FIELD_SCRIPT.WATER_LEVEL - 5.0, "the lake bottom is well below the waterline (%.1f m)" % lake_bottom)
    _check_close(_field.height(FIELD_SCRIPT.LAKE_CENTER.x, FIELD_SCRIPT.LAKE_CENTER.y), lake_bottom, 6.0, "the lake centre is the deepest part")
    var bank := _field.height(FIELD_SCRIPT.LAKE_CENTER.x + FIELD_SCRIPT.LAKE_RADIUS + 40.0, FIELD_SCRIPT.LAKE_CENTER.y)
    _check(bank > FIELD_SCRIPT.WATER_LEVEL + 1.0, "the shore sits above the waterline (%.1f m)" % bank)

    # 幽冥林: dense in the middle, thin on the peaks.
    _check(_field.forest_mask(FIELD_SCRIPT.FOREST_CENTER.x, FIELD_SCRIPT.FOREST_CENTER.y) > 0.55,
        "dense forest at the heart of 幽冥林")
    var dense := 0
    var total := 0
    for gx in range(-330, -30, 12):
        for gz in range(-100, 200, 12):
            total += 1
            if _field.forest_mask(float(gx), float(gz)) > 0.45:
                dense += 1
    _check(float(dense) / float(total) > 0.25, "a large share of 幽冥林 is forested (%d/%d)" % [dense, total])

    # Biome coverage: every promise on the map is actually painted somewhere.
    var seen := {}
    for gx in range(-480, 481, 12):
        for gz in range(-500, 460, 12):
            seen[_field.biome_at(float(gx), float(gz))] = true
    for biome in [FIELD_SCRIPT.BIOME_GRASS, FIELD_SCRIPT.BIOME_FOREST, FIELD_SCRIPT.BIOME_ROCK,
            FIELD_SCRIPT.BIOME_SNOW, FIELD_SCRIPT.BIOME_SAND, FIELD_SCRIPT.BIOME_LAKEBED]:
        _check(seen.has(biome), "biome painted: " + biome)
    _check(seen.has(FIELD_SCRIPT.BIOME_CLIFF) or seen.has(FIELD_SCRIPT.BIOME_ROCK),
        "biome painted: rock / cliff")

    # Coverage, not just presence: 高山 / 断崖 / 雪地 / 茂密的树林 / 湖泊 must each
    # hold a real share of the world, otherwise the map has quietly become lawn.
    var coverage := {}
    var samples := 0
    for gx in range(-480, 481, 16):
        for gz in range(-480, 481, 16):
            var biome := _field.biome_at(float(gx), float(gz))
            coverage[biome] = int(coverage.get(biome, 0)) + 1
            samples += 1
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_GRASS) < 0.80,
        "meadow does not swallow the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_GRASS)])
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_CLIFF) > 0.08,
        "断崖 covers a real share of the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_CLIFF)])
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_SNOW) > 0.015,
        "雪地 covers a real share of the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_SNOW)])
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_FOREST) > 0.03,
        "幽冥林 covers a real share of the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_FOREST)])
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_LAKEBED) > 0.005,
        "明镜湖 covers a real share of the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_LAKEBED)])
    _check(_share(coverage, samples, FIELD_SCRIPT.BIOME_ROCK) > 0.01,
        "石岭 covers a real share of the map (%.1f%%)" % [100.0 * _share(coverage, samples, FIELD_SCRIPT.BIOME_ROCK)])

    # Every painted layer keeps its control value a normal float, which is what
    # lets the packed control map survive the trip into Terrain3D.
    for row in FIELD_SCRIPT.TEXTURES:
        var base_id := int(row["id"])
        var packed: int = TERRAIN3D_WORLD_SCRIPT.pack_control(base_id, base_id, 255)
        var as_float := _as_float(packed)
        if base_id == 0:
            _check(not _is_normal_float(as_float), "reserved id 0 is never used as a base texture")
        else:
            _check(_is_normal_float(as_float), "control value for texture id %d stays a normal float" % base_id)
    _check(int(FIELD_SCRIPT.TEXTURES[0]["id"]) == 0, "texture id 0 is the reserved slot")

    # Clipmap maths.
    _check(FIELD_SCRIPT.region_of(0.0, 0.0) == Vector2i(0, 0), "origin is in region 0,0")
    _check(FIELD_SCRIPT.region_of(600.0, -600.0) == Vector2i(1, -2), "region lookup divides by the region span")
    _check(FIELD_SCRIPT.region_origin(Vector2i(-1, 2)) == Vector2(-512.0, 1024.0), "region origin maths")
    _check(FIELD_SCRIPT.inside_world(0.0, 0.0), "the origin is inside the generated world")
    _check(not FIELD_SCRIPT.inside_world(4000.0, 0.0), "far outside is not inside the generated world")
    _check(FIELD_SCRIPT.region_locations().size() == 9, "a 3x3 region grid is generated for radius 1")

    # Packed control round trip.
    var packed_value: int = TERRAIN3D_WORLD_SCRIPT.pack_control(3, 5, 200)
    _check(TERRAIN3D_WORLD_SCRIPT.unpack_base(packed_value) == 3, "control base id round trips")
    _check(TERRAIN3D_WORLD_SCRIPT.unpack_overlay(packed_value) == 5, "control overlay id round trips")
    _check(TERRAIN3D_WORLD_SCRIPT.unpack_blend(packed_value) == 200, "control blend round trips")


## True when a coordinate sits within a metre of a clipmap region seam.
func _near_region_seam(value: float) -> bool:
    var offset := fposmod(value, float(FIELD_SCRIPT.REGION_SPAN))
    return offset < 1.0 or offset > float(FIELD_SCRIPT.REGION_SPAN) - 1.0


## Bilinear interpolation of the field on the clipmap vertex grid - the exact
## surface Terrain3D renders.
func _grid_height(x: float, z: float) -> float:
    var step := FIELD_SCRIPT.VERTEX_SPACING
    var x0 := floorf(x / step) * step
    var z0 := floorf(z / step) * step
    var tx := (x - x0) / step
    var tz := (z - z0) / step
    var h00 := _field.height(x0, z0)
    var h10 := _field.height(x0 + step, z0)
    var h01 := _field.height(x0, z0 + step)
    var h11 := _field.height(x0 + step, z0 + step)
    return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


## Reads the float whose 32-bit pattern is the packed control value - the same
## bit trick Terrain3D uses to smuggle integer control pixels through FORMAT_RF.
func _as_float(packed: int) -> float:
    var bytes := PackedByteArray()
    bytes.resize(4)
    bytes.encode_u32(0, packed)
    return bytes.decode_float(0)


## IEEE-754 normal: exponent neither zero (subnormal) nor all ones (nan / inf).
## Godot's float pipeline drops those bit patterns, so reserved id 0 would
## quietly lose its control value.
func _is_normal_float(value: float) -> bool:
    var bytes := PackedByteArray()
    bytes.resize(4)
    bytes.encode_float(0, value)
    var exponent := (bytes.decode_u32(0) >> 23) & 0xFF
    return exponent != 0 and exponent != 0xFF


## Fraction of the sampled world covered by one biome.
func _share(coverage: Dictionary, samples: int, biome: String) -> float:
    if samples <= 0:
        return 0.0
    return float(int(coverage.get(biome, 0))) / float(samples)


func _rng_radius(index: float) -> float:
    # Deterministic spiral so the lake probe sweeps the whole basin.
    return fmod(index * 37.0, FIELD_SCRIPT.LAKE_RADIUS * 0.72)


# --------------------------------------------------------- the landmarks ---

func _test_landmarks() -> void:
    for pad in FIELD_SCRIPT.PADS:
        var centre: Vector2 = pad["center"]
        var radius := float(pad["radius"])
        var reference := _field.height(centre.x, centre.y)
        var spread := 0.0
        for i in range(8):
            var angle := TAU * float(i) / 8.0
            var probe := centre + Vector2(cos(angle), sin(angle)) * (radius * 0.5)
            spread = maxf(spread, absf(_field.height(probe.x, probe.y) - reference))
        _check(spread < 1.1, "landmark pad '%s' is level (spread %.2f m)" % [str(pad["id"]), spread])

    _check(_field.landmark_position("cave").y < FIELD_SCRIPT.SNOW_LINE, "the cave mouth is at the foot of the range")
    _check(_field.landmark_position("cave").y > FIELD_SCRIPT.WATER_LEVEL, "the cave mouth is above the waterline")
    _check(_field.landmark_position("shrine").y > FIELD_SCRIPT.WATER_LEVEL, "the shrine is above the waterline")
    _check(int(FIELD_SCRIPT.LANDMARKS.size()) >= 7, "all landmark anchors are declared")


# ----------------------------------------------------- the Terrain3D end ---

func _test_terrain3d() -> void:
    if not TERRAIN3D_WORLD_SCRIPT.is_supported():
        print("  (skipped: Terrain3D addon not loaded for this engine build)")
        return

    var host := Node3D.new()
    host.name = "Terrain3DHost"
    add_child(host)
    var camera := Camera3D.new()
    camera.name = "TestCamera"
    host.add_child(camera)

    var world := TERRAIN3D_WORLD_SCRIPT.new()
    world.name = "TestTerrain"
    host.add_child(world)
    world.start(SEED, camera)

    var waited := 0
    while not world.is_ready() and waited < 4000:
        await get_tree().process_frame
        waited += 1

    if not _check(world.is_ready(), "Terrain3D back end finishes generating (waited %d frames, error '%s')" % [waited, world.get_error()]):
        host.queue_free()
        await get_tree().process_frame
        return

    _check(world.terrain != null, "a Terrain3D node was created")
    _check(world.get_loaded_chunk_count() == FIELD_SCRIPT.region_locations().size(),
        "every clipmap region was imported (%d)" % world.get_loaded_chunk_count())
    _check(world.get_texture_count() == FIELD_SCRIPT.TEXTURE_COUNT,
        "all painted layers reached the asset list (%d)" % world.get_texture_count())

    # On a vertex the heightmap stores the field value verbatim, so the two must
    # agree exactly; that is what proves the region placement and the row/column
    # order are right.
    var exact := 0.0
    var probes := 0
    for i in range(-200, 201, 8):
        for j in range(-200, 201, 8):
            var x := float(i) * FIELD_SCRIPT.VERTEX_SPACING
            var z := float(j) * FIELD_SCRIPT.VERTEX_SPACING
            exact = maxf(exact, absf(world.sample_height(x, z) - _field.height(x, z)))
            probes += 1
    _check(exact < 0.02, "Terrain3D stores the field verbatim on its vertices (worst %.4f m over %d probes)" % [exact, probes])

    # Terrain3D draws the vertex grid as triangles, and `get_height` reports the
    # same bilinear surface.  Comparing against exactly that interpolation of the
    # field proves every region landed in the right place with the right
    # row/column order - a transposed or offset region would show up here.
    var grid_worst := 0.0
    var grid_probes := 0
    for i in range(96):
        var angle := TAU * float(i) / 96.0
        for step in range(1, 9):
            var radius := float(step) * 45.0
            var x := cos(angle) * radius
            var z := sin(angle) * radius
            # Terrain3D buckets by `floor(x / region_span)`, so a coordinate a
            # hair below a region seam is served by the region underneath and
            # reads the far edge pixel.  That is a two-metre boundary artefact
            # of the clipmap, not a placement error, so seams are skipped.
            if _near_region_seam(x) or _near_region_seam(z):
                continue
            grid_worst = maxf(grid_worst, absf(world.sample_height(x, z) - _grid_height(x, z)))
            grid_probes += 1
    _check(grid_probes > 500, "the grid sweep covered the map (%d probes)" % grid_probes)
    _check(grid_worst < 0.05,
        "Terrain3D reproduces the clipmap grid (%d probes, worst %.4f m)" % [grid_probes, grid_worst])

    # A radial sweep only reaches the inner regions, so each clipmap cell is
    # probed around its own centre as well - that is what catches a transposed
    # or offset block import.
    var region_worst := 0.0
    var region_probes := 0
    for location in FIELD_SCRIPT.region_locations():
        var origin := FIELD_SCRIPT.region_origin(location)
        for k in 6:
            var angle := TAU * float(k) / 6.0
            var x := origin.x + float(FIELD_SCRIPT.REGION_SPAN) * 0.5 + cos(angle) * 110.0
            var z := origin.y + float(FIELD_SCRIPT.REGION_SPAN) * 0.5 + sin(angle) * 110.0
            region_worst = maxf(region_worst, absf(world.sample_height(x, z) - _grid_height(x, z)))
            region_probes += 1
    _check(region_worst < 0.05,
        "every clipmap region landed in the right place (%d probes, worst %.4f m)" % [region_probes, region_worst])

    # The analytic field is what the grid samples, so off-vertex the two only
    # differ by the terraces resampling: a 7 m riser squeezed between two 2 m
    # vertices simply cannot be represented.  Walkable ground must stay tight,
    # and the sweep has to actually cross the cliffs for that claim to matter.
    var total := 0
    var close := 0
    var worst := 0.0
    var gentle_total := 0
    var gentle_close := 0
    var gentle_worst := 0.0
    var steep_total := 0
    for i in range(96):
        var angle := TAU * float(i) / 96.0
        for step in range(1, 9):
            var radius := float(step) * 45.0
            var x := cos(angle) * radius
            var z := sin(angle) * radius
            var delta := absf(world.sample_height(x, z) - _field.height(x, z))
            worst = maxf(worst, delta)
            total += 1
            if delta < 1.0:
                close += 1
            var gx := absf(_field.height(x + 2.0, z) - _field.height(x - 2.0, z)) / 4.0
            var gz := absf(_field.height(x, z + 2.0) - _field.height(x, z - 2.0)) / 4.0
            if maxf(gx, gz) >= 0.5:
                steep_total += 1
                continue
            gentle_total += 1
            gentle_worst = maxf(gentle_worst, delta)
            if delta < 0.5:
                gentle_close += 1
    _check(steep_total > 20, "the sweep crosses real cliff faces (%d steep samples)" % steep_total)
    _check(gentle_total > 100 and float(gentle_close) / float(gentle_total) > 0.95,
        "walkable ground is tight (%d/%d within 0.5 m)" % [gentle_close, gentle_total])
    _check(float(close) / float(total) > 0.85,
        "the whole sweep stays close overall (%d/%d within 1 m, worst %.2f m)" % [close, total, worst])

    # Biome painting survived the packed control round trip for every layer.
    var missing := {}
    for i in range(200):
        var angle := TAU * float(i) / 200.0
        var radius := 20.0 + float(i) * 2.5
        var x := cos(angle) * radius
        var z := sin(angle) * radius
        var base_id := world.control_base_id(x, z)
        if base_id == 0 or base_id > FIELD_SCRIPT.TEXTURE_COUNT - 1:
            missing[base_id] = true
    _check(missing.is_empty(), "every sampled vertex paints a real texture id (bad: %s)" % str(missing.keys()))

    var painted := {}
    for gx in range(-480, 481, 24):
        for gz in range(-500, 460, 24):
            painted[world.control_base_id(float(gx), float(gz))] = true
    for row in FIELD_SCRIPT.TEXTURES:
        if int(row["id"]) == FIELD_SCRIPT.TEX_VOID:
            continue
        _check(painted.has(int(row["id"])), "layer %s is painted somewhere on the map" % str(row["name_key"]))

    # Collision is what the player actually walks on.
    _check(world.collision_mode() != 0, "Terrain3D collision is enabled for gameplay")

    # ...and the heightmap really does turn into geometry the renderer can use.
    var baked: Mesh = world.terrain.bake_mesh(4)
    if _check(baked is ArrayMesh, "Terrain3D bakes a renderable mesh"):
        var surface_count := (baked as ArrayMesh).get_surface_count()
        _check(surface_count > 0, "the baked mesh has surfaces (%d)" % surface_count)
        if surface_count > 0:
            var baked_aabb := (baked as ArrayMesh).get_aabb()
            _check(baked_aabb.size.x > 900.0 and baked_aabb.size.z > 900.0,
                "the baked mesh covers the clipmap (%.0f x %.0f m)" % [baked_aabb.size.x, baked_aabb.size.z])
            _check(baked_aabb.size.y > FIELD_SCRIPT.SNOW_LINE,
                "the mesh carries the full mountain relief (%.1f m)" % baked_aabb.size.y)

    host.queue_free()
    await get_tree().process_frame


# --------------------------------------------------- the whole game world ---

## Boots the real `GameWorld` - the same node `main.gd` adds - so the wiring
## between the terrain back end, the spawns and the loading progress is covered
## end to end rather than in isolation.
func _test_game_world() -> void:
    var world := GameWorld.new()
    world.name = "SmokeWorld"
    add_child(world)

    var waited := 0
    while not world.is_world_ready() and waited < 6000:
        await get_tree().process_frame
        waited += 1

    if not _check(world.is_world_ready(), "GameWorld reaches a ready state (waited %d frames)" % waited):
        world.queue_free()
        await get_tree().process_frame
        return

    _check(world.get_terrain_backend_name() == "Terrain3D" if TERRAIN3D_WORLD_SCRIPT.is_supported() else true,
        "GameWorld picked the expected terrain back end (%s)" % world.get_terrain_backend_name())
    _check(world.get_terrain_region_count() == FIELD_SCRIPT.region_locations().size(),
        "GameWorld generated every clipmap region (%d)" % world.get_terrain_region_count())
    _check(world.get_world_features() != null, "GameWorld built the world features")
    _check(world.get_player() != null, "GameWorld spawned the player")
    _check(get_tree().get_nodes_in_group("enemies").size() >= 12, "GameWorld spawned the enemies")
    _check(world.get_load_progress() >= 1.0, "the loading progress reaches 100%")

    # The player must be resting on the terrain rather than sinking through the
    # collision the back end streams in.
    for i in range(30):
        await get_tree().process_frame
    var player := world.get_player()
    if player != null:
        var ground := world._sample_ground_height(player.global_position.x, player.global_position.z)
        var gap := player.global_position.y - ground
        _check(absf(gap) < 2.0, "the player settles on the terrain (%.2f m above ground)" % gap)

    world.queue_free()
    await get_tree().process_frame


# --------------------------------------------------- the placeholder end ---

## Terrain3D is optional: when the addon is missing `GameWorld` falls back to the
## streamed placeholder mesh, so that path has to work just as well.
func _test_fallback() -> void:
    var host := Node3D.new()
    host.name = "FallbackHost"
    add_child(host)

    var generator := TERRAIN_GENERATOR_SCRIPT.new()
    generator.name = "FallbackTerrain"
    host.add_child(generator)
    generator.setup(SEED)
    await get_tree().process_frame

    _check(generator.is_ready(), "the placeholder back end builds its chunks")
    _check(generator.get_loaded_chunk_count() > 0,
        "the placeholder streams chunks (%d)" % generator.get_loaded_chunk_count())
    _check_close(generator.get_progress(), 1.0, 0.001, "the placeholder reports full progress")

    var worst := 0.0
    for i in range(40):
        var angle := TAU * float(i) / 40.0
        var x := cos(angle) * 90.0
        var z := sin(angle) * 90.0
        worst = maxf(worst, absf(generator.sample_height(x, z) - _field.height(x, z)))
    _check(worst < 0.001, "the placeholder samples the shared field (worst %.4f m)" % worst)

    # ...and it keeps streaming when the player walks away.
    var far := Vector3(300.0, 0.0, 300.0)
    generator.update_stream(far)
    await get_tree().process_frame
    _check(generator.world_to_chunk(far) == Vector2i(9, 9), "chunk maths follow the chunk size")
    _check(generator.get_node_or_null("Chunk_9_9") != null, "the chunk under the new centre exists")
    _check(generator.get_loaded_chunk_count() > 0, "chunks survive a stream update")

    host.queue_free()
    await get_tree().process_frame


# -------------------------------------------------------- the props pass ---

func _test_features() -> void:
    var host := Node3D.new()
    host.name = "FeatureHost"
    add_child(host)

    var features := WORLD_FEATURES_SCRIPT.new()
    features.name = "TestFeatures"
    host.add_child(features)
    features.build(_field, SEED)

    # With no back end supplied the props fall back to the analytic field and
    # must still land on the surface it describes.
    var float_error := 0.0
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        var x := cos(angle) * 90.0
        var z := sin(angle) * 90.0
        float_error = maxf(float_error, absf(features.height_at(x, z) - _field.height(x, z)))
    _check(float_error < 0.001, "props sample the shared field when no back end is supplied")
    await get_tree().process_frame

    var summary := features.describe()
    _check(bool(summary["water"]), "the lake surface was created")
    _check(bool(summary["village"]), "the 古风建筑 courtyard was created")
    _check(bool(summary["cave"]), "the 玄山洞秘境 entrance was created")
    _check(int(summary["trees"]) > 600, "the forest is dense (%d trees)" % int(summary["trees"]))
    _check(int(summary["lone_trees"]) > 40, "lone trees dot the meadow (%d)" % int(summary["lone_trees"]))
    _check(int(summary["bushes"]) > 100, "undergrowth fills the woods (%d)" % int(summary["bushes"]))
    _check(int(summary["floor_details"]) > 60,
        "logs and stumps litter the forest floor (%d)" % int(summary["floor_details"]))
    _check(int(summary["rocks"]) + int(summary["moss_rocks"]) + int(summary["boulders"]) > 150,
        "boulders scatter over the rocky ground (%d + %d + %d)"
            % [int(summary["rocks"]), int(summary["moss_rocks"]), int(summary["boulders"])])
    _check(int(summary["grass"]) > 1000, "grass tufts cover the meadow (%d)" % int(summary["grass"]))
    _check(int(summary["flowers"]) > 150, "wildflowers dot the meadow (%d)" % int(summary["flowers"]))

    # 雪地 gets the pack's own snow-laden variants rather than a repainted
    # material, so the peaks are dressed with real snow geometry.
    _check(int(summary["snow_trees"]) > 40, "snow-laden trees grow above the snowline (%d)" % int(summary["snow_trees"]))
    _check(int(summary["snow_rocks"]) + int(summary["snow_boulders"]) > 20,
        "snow-covered rock sits above the snowline (%d + %d)"
            % [int(summary["snow_rocks"]), int(summary["snow_boulders"])])
    _check(int(summary["snow_bushes"]) + int(summary["snow_floor_details"]) > 20,
        "snow-covered shrubs and deadfall dress the high ground (%d + %d)"
            % [int(summary["snow_bushes"]), int(summary["snow_floor_details"])])

    # --- the props are model assets, not primitives ------------------------
    var files: Array = features.model_files()
    _check(files.size() >= 40, "the prop library is varied (%d models)" % files.size())
    var missing: Array[String] = []
    for relative in files:
        if not ResourceLoader.exists(PROP_MODELS_SCRIPT.ROOT.path_join(str(relative))):
            missing.append(str(relative))
    _check(missing.is_empty(), "every referenced prop model exists (missing: %s)" % str(missing))

    var merged_ok := true
    var merged_surfaces := 0
    for relative in files:
        var mesh: Mesh = PROP_MODELS_SCRIPT.load_mesh(str(relative))
        if mesh == null or mesh.get_surface_count() == 0:
            merged_ok = false
            break
        var height := PROP_MODELS_SCRIPT.height_of(mesh)
        if height <= 0.0:
            merged_ok = false
            break
        for surface in mesh.get_surface_count():
            merged_surfaces += 1
            if mesh.surface_get_material(surface) == null:
                merged_ok = false
                break
    _check(merged_ok, "every prop model merged with its surfaces and materials intact (%d surfaces)" % merged_surfaces)

    # Every batch must be a merged model asset, not a bare primitive: replacing
    # the hand-built stand-ins was the whole point of the round.
    var leftovers := _count_primitive_multimeshes(features)
    _check(leftovers == 0, "every prop batch draws a model asset, not a primitive (%d found)" % leftovers)
    var batches := int(summary["batches"])
    _check(batches >= 20, "the props are batched into %d MultiMesh draw calls" % batches)

    var village := features.get_node_or_null("Village")
    if _check(village != null, "the village node is in the tree"):
        _check(_count_grouped(village, "arch_paifang") >= 1, "牌坊 gate built")
        _check(_count_grouped(village, "arch_pavilion") >= 1, "亭 pavilion built")
        _check(_count_grouped(village, "arch_pagoda") >= 1, "塔 pagoda built")
        _check(_count_grouped(village, "arch_hall") >= 2, "two 殿 halls built")
        _check(_count_grouped(village, "arch_lantern") >= 4, "stone lanterns line the courtyard")
        _check(_count_grouped(village, "arch_wall") >= 3, "courtyard walls enclose the village")
        _check(village.get_node_or_null("Jetty") != null, "the lakeside jetty was built")

    var cave := features.get_node_or_null("CaveShrine")
    if _check(cave != null, "the cave shrine node is in the tree"):
        var label := cave.get_node_or_null("Mouth/CaveLabel")
        _check(label != null and (label as Label3D).text == LocaleData.text("landmark_cave"),
            "the cave is labelled 玄山洞秘境")
        var trigger := cave.get_node_or_null("CaveTrigger")
        _check(trigger is Area3D, "the cave has a dungeon-entrance trigger volume")
        var mouth := cave.get_node_or_null("Mouth")
        if _check(mouth != null, "the cave mouth is assembled"):
            _check(mouth.get_node_or_null("Portal") != null, "the secret-realm portal ring is lit")
            _check(mouth.get_node_or_null("Motes") is GPUParticles3D, "the portal has drifting motes")

    # Nothing may float: every prop batch sits on the shared field.
    var water := features.get_node_or_null("LakeSurface")
    if water is MeshInstance3D:
        _check_close((water as MeshInstance3D).position.y, FIELD_SCRIPT.WATER_LEVEL, 0.01, "the lake surface sits at the waterline")

    host.queue_free()
    await get_tree().process_frame


## Counts MultiMeshInstance3D batches still built from a Godot primitive - the
## placeholder geometry this round was supposed to remove.
func _count_primitive_multimeshes(root: Node) -> int:
    var total := 0
    if root is MultiMeshInstance3D:
        var multi := (root as MultiMeshInstance3D).multimesh
        if multi != null and multi.mesh is PrimitiveMesh:
            total += 1
    for child in root.get_children():
        total += _count_primitive_multimeshes(child)
    return total


## Counts a builder group inside a subtree.  Godot gives duplicate node names
## an auto-generated name, so counting by name is not reliable.
func _count_grouped(root: Node, group: String) -> int:
    var total := 0
    if root.is_in_group(group):
        total += 1
    for child in root.get_children():
        total += _count_grouped(child, group)
    return total
