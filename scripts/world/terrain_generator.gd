extends Node3D
class_name TerrainGenerator
## Streamed placeholder terrain.
##
## This is the fallback used when the Terrain3D addon is not available for the
## running engine build: it builds low-poly, vertex-coloured chunks around the
## player and frees the ones that leave the streaming radius.  The heights come
## from `TerrainData`, the same field `Terrain3DWorld` feeds into the clipmap,
## so switching back ends does not move the world under the player's feet.

const FIELD_SCRIPT := preload("res://scripts/world/terrain_data.gd")

var field: TerrainData
var ready_state := false

var _material: StandardMaterial3D
var _chunks: Dictionary = {}
var _last_center_chunk := Vector2i(999999, 999999)


func setup(world_seed: int) -> void:
    field = FIELD_SCRIPT.create(world_seed)

    _material = StandardMaterial3D.new()
    _material.vertex_color_use_as_albedo = true
    _material.roughness = 0.97
    _material.metallic = 0.0
    _material.albedo_color = Color.WHITE

    update_stream(Vector3.ZERO, true)
    ready_state = true


func update_stream(center: Vector3, force := false) -> void:
    if _material == null:
        return
    var center_chunk := world_to_chunk(center)
    if not force and center_chunk == _last_center_chunk:
        return
    _last_center_chunk = center_chunk

    var keep := {}
    for dz in range(-FIELD_SCRIPT.VIEW_RADIUS_CHUNKS, FIELD_SCRIPT.VIEW_RADIUS_CHUNKS + 1):
        for dx in range(-FIELD_SCRIPT.VIEW_RADIUS_CHUNKS, FIELD_SCRIPT.VIEW_RADIUS_CHUNKS + 1):
            var coord := center_chunk + Vector2i(dx, dz)
            keep[coord] = true
            if not _chunks.has(coord):
                _build_chunk(coord)

    for coord in _chunks.keys():
        if not keep.has(coord):
            _remove_chunk(coord)


func get_loaded_chunk_count() -> int:
    return _chunks.size()


func is_ready() -> bool:
    return ready_state and not _chunks.is_empty()


func get_progress() -> float:
    return 1.0 if ready_state else 0.0


func world_to_chunk(world_position: Vector3) -> Vector2i:
    return Vector2i(
        int(floorf(world_position.x / FIELD_SCRIPT.CHUNK_SIZE)),
        int(floorf(world_position.z / FIELD_SCRIPT.CHUNK_SIZE))
    )


## Continuous terrain height, used by the mesh, the collision and spawn
## placement.
func sample_height(x: float, z: float) -> float:
    if field == null:
        return 0.0
    return field.height(x, z)


func ground_position(x: float, z: float) -> Vector3:
    return Vector3(x, sample_height(x, z), z)


func _build_chunk(coord: Vector2i) -> void:
    var chunk := Node3D.new()
    chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
    chunk.position = Vector3(coord.x * FIELD_SCRIPT.CHUNK_SIZE, 0.0, coord.y * FIELD_SCRIPT.CHUNK_SIZE)

    var resolution := FIELD_SCRIPT.CHUNK_RESOLUTION
    var step := FIELD_SCRIPT.CHUNK_SIZE / float(resolution)
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
            # Godot's SurfaceTool front faces use the opposite winding from what
            # a plain cross-product intuition suggests for this grid; keep the
            # normals facing up so the terrain is visible from above and
            # CharacterBody3D collides with the surface.
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
    st.set_uv(Vector2(a.x, a.z) / FIELD_SCRIPT.CHUNK_SIZE)
    st.add_vertex(a)
    st.set_color(color)
    st.set_uv(Vector2(b.x, b.z) / FIELD_SCRIPT.CHUNK_SIZE)
    st.add_vertex(b)
    st.set_color(color)
    st.set_uv(Vector2(c.x, c.z) / FIELD_SCRIPT.CHUNK_SIZE)
    st.add_vertex(c)


func _vertex_color(point: Vector3) -> Color:
    var color := FIELD_SCRIPT.biome_color(field.biome_at(point.x, point.z))
    var snow := clampf((sample_height(point.x, point.z) - FIELD_SCRIPT.SNOW_LINE) / 24.0, 0.0, 1.0)
    return color.lerp(Color(0.88, 0.92, 0.94), snow * 0.70)


func _remove_chunk(coord: Vector2i) -> void:
    var chunk: Variant = _chunks.get(coord)
    if chunk is Node:
        (chunk as Node).queue_free()
    _chunks.erase(coord)
