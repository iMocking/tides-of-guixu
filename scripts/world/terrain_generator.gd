extends Node3D
class_name TerrainGenerator
## Runtime large-world terrain component.
##
## Builds low-poly, vertex-coloured chunks around the player and frees chunks
## that leave the streaming radius.  The central safe zone stays flat so the
## existing NPC / enemy / combat layout is unaffected.

const DATA := preload("res://scripts/world/terrain_data.gd")

var _height_noise := FastNoiseLite.new()
var _mountain_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()
var _material: StandardMaterial3D
var _chunks: Dictionary = {}
var _last_center_chunk := Vector2i(999999, 999999)
var _world_seed := 0


func setup(world_seed: int) -> void:
    _world_seed = world_seed

    _height_noise.seed = world_seed
    _height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _height_noise.frequency = DATA.NOISE_FREQUENCY
    _height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    _height_noise.fractal_octaves = 4
    _height_noise.fractal_gain = 0.52
    _height_noise.fractal_lacunarity = 2.1

    _mountain_noise.seed = world_seed + 104729
    _mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _mountain_noise.frequency = DATA.MOUNTAIN_FREQUENCY
    _mountain_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
    _mountain_noise.fractal_octaves = 3

    _moisture_noise.seed = world_seed + 7919
    _moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _moisture_noise.frequency = DATA.MOISTURE_FREQUENCY

    _material = StandardMaterial3D.new()
    _material.vertex_color_use_as_albedo = true
    _material.roughness = 0.97
    _material.metallic = 0.0
    _material.albedo_color = Color.WHITE

    update_stream(Vector3.ZERO, true)


func update_stream(center: Vector3, force := false) -> void:
    if _material == null:
        return
    var center_chunk := world_to_chunk(center)
    if not force and center_chunk == _last_center_chunk:
        return
    _last_center_chunk = center_chunk

    var keep := {}
    for dz in range(-DATA.VIEW_RADIUS_CHUNKS, DATA.VIEW_RADIUS_CHUNKS + 1):
        for dx in range(-DATA.VIEW_RADIUS_CHUNKS, DATA.VIEW_RADIUS_CHUNKS + 1):
            var coord := center_chunk + Vector2i(dx, dz)
            keep[coord] = true
            if not _chunks.has(coord):
                _build_chunk(coord)

    for coord in _chunks.keys():
        if not keep.has(coord):
            _remove_chunk(coord)


func get_loaded_chunk_count() -> int:
    return _chunks.size()


func world_to_chunk(world_position: Vector3) -> Vector2i:
    return Vector2i(
        int(floor(world_position.x / DATA.CHUNK_SIZE)),
        int(floor(world_position.z / DATA.CHUNK_SIZE))
    )


## Continuous terrain height used by the mesh, collision and spawn placement.
func sample_height(x: float, z: float) -> float:
    var base := _height_noise.get_noise_2d(x, z) * DATA.HEIGHT_SCALE
    var ridge := absf(_mountain_noise.get_noise_2d(x, z))
    var mountain := pow(ridge, 1.8) * DATA.MOUNTAIN_SCALE
    var raw := DATA.BASE_HEIGHT + base + mountain

    var distance := sqrt(x * x + z * z)
    var flat_t := clampf((distance - DATA.FLAT_RADIUS) / DATA.FLAT_BLEND, 0.0, 1.0)
    var blend := flat_t * flat_t * (3.0 - 2.0 * flat_t)
    return clampf(DATA.BASE_HEIGHT + (raw - DATA.BASE_HEIGHT) * blend, DATA.MIN_HEIGHT, DATA.MAX_HEIGHT)


func sample_moisture(x: float, z: float) -> float:
    return clampf(_moisture_noise.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)


func sample_biome(x: float, z: float) -> Dictionary:
    return DATA.biome_for_height(sample_height(x, z))


func _build_chunk(coord: Vector2i) -> void:
    var chunk := Node3D.new()
    chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
    chunk.position = Vector3(coord.x * DATA.CHUNK_SIZE, 0.0, coord.y * DATA.CHUNK_SIZE)

    var resolution := DATA.CHUNK_RESOLUTION
    var step := DATA.CHUNK_SIZE / float(resolution)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for j in range(resolution):
        for i in range(resolution):
            var x0 := float(i) * step
            var x1 := float(i + 1) * step
            var z0 := float(j) * step
            var z1 := float(j + 1) * step
            var p00 := Vector3(x0, sample_height(chunk.position.x + x0, chunk.position.z + z0), z0)
            var p10 := Vector3(x1, sample_height(chunk.position.x + x1, chunk.position.z + z0), z0)
            var p01 := Vector3(x0, sample_height(chunk.position.x + x0, chunk.position.z + z1), z1)
            var p11 := Vector3(x1, sample_height(chunk.position.x + x1, chunk.position.z + z1), z1)
            var color := _vertex_color(p00)
            # Godot's SurfaceTool front faces use the opposite winding from
            # what a plain cross-product intuition suggests for this grid.
            # Keep the normals facing up so the terrain is visible from above
            # and CharacterBody3D collides with the surface.
            _add_terrain_triangle(st, p00, p11, p01, color)
            _add_terrain_triangle(st, p00, p10, p11, color)

    st.generate_normals()
    var mesh := st.commit()
    if mesh == null:
        chunk.queue_free()
        return

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _material
    chunk.add_child(mesh_instance)

    var shape := mesh.create_trimesh_shape()
    if shape != null:
        if shape is ConcavePolygonShape3D:
            (shape as ConcavePolygonShape3D).backface_collision = true
        var body := StaticBody3D.new()
        body.name = "Collision"
        var collision := CollisionShape3D.new()
        collision.shape = shape
        body.add_child(collision)
        chunk.add_child(body)

    add_child(chunk)
    _chunks[coord] = chunk


func _add_terrain_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
    st.set_color(color)
    st.set_uv(Vector2(a.x, a.z) / DATA.CHUNK_SIZE)
    st.add_vertex(a)
    st.set_color(color)
    st.set_uv(Vector2(b.x, b.z) / DATA.CHUNK_SIZE)
    st.add_vertex(b)
    st.set_color(color)
    st.set_uv(Vector2(c.x, c.z) / DATA.CHUNK_SIZE)
    st.add_vertex(c)


func _vertex_color(point: Vector3) -> Color:
    var height := sample_height(point.x, point.z)
    var color := DATA.biome_color(height)
    var snow := clampf((height - 22.0) / 18.0, 0.0, 1.0)
    return color.lerp(Color(0.88, 0.92, 0.94), snow * 0.65)


func _remove_chunk(coord: Vector2i) -> void:
    var chunk: Variant = _chunks.get(coord)
    if chunk is Node:
        (chunk as Node).queue_free()
    _chunks.erase(coord)
