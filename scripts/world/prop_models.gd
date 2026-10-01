class_name PropModels
extends RefCounted
## Loads the game-ready prop models in `assets/models/vegetation/` and flattens
## each one into a single `Mesh` for `MultiMeshInstance3D` instancing.
##
## The meshes are Quaternius' CC0 Nature Pack (see `CREDITS.md`): authored
## low-poly geometry whose surfaces carry flat per-material colours - no
## textures, no vertex colours.  A `.glb` arrives as a `PackedScene` holding one
## or more `MeshInstance3D` nodes, so the loader merges them into one `ArrayMesh`
## with the local transforms baked in and **one surface per source primitive**,
## leaving every authored material exactly as the artist shipped it.
##
## Because a merged mesh keeps several surfaces it costs one draw call per
## surface, which is why the scatter batches one `MultiMeshInstance3D` per model
## file rather than trying to weld primitives together.

const ROOT := "res://assets/models/vegetation"

static var _meshes: Dictionary = {}
static var _warned: Dictionary = {}


## Merged mesh for `assets/models/vegetation/<relative_path>`, or null when the
## asset is missing.
static func load_mesh(relative_path: String) -> Mesh:
    if _meshes.has(relative_path):
        return _meshes[relative_path]
    var merged := _build(ROOT.path_join(relative_path))
    _meshes[relative_path] = merged
    return merged


## Height of a merged mesh in its own units; 1.0 when it has no geometry.
static func height_of(mesh: Mesh) -> float:
    if mesh == null:
        return 1.0
    return maxf(mesh.get_aabb().size.y, 0.0001)


## How far the mesh hangs below its own origin, so instances can be lifted until
## the base rests exactly on the ground.
static func base_offset_of(mesh: Mesh) -> float:
    if mesh == null:
        return 0.0
    return -mesh.get_aabb().position.y


## Model files that produced geometry, sorted.
static func loaded_paths() -> Array:
    var out: Array = []
    for key in _meshes.keys():
        if _meshes[key] != null:
            out.append(key)
    out.sort()
    return out


static func clear_cache() -> void:
    _meshes.clear()


# ---------------------------------------------------------------- loading ---

static func _build(path: String) -> Mesh:
    if not ResourceLoader.exists(path):
        _warn_once("missing model asset: " + path)
        return null
    var resource := load(path)
    if resource is Mesh:
        return resource as Mesh
    if not (resource is PackedScene):
        _warn_once("not a model asset: " + path)
        return null
    var root := (resource as PackedScene).instantiate()
    if root == null:
        _warn_once("could not instantiate: " + path)
        return null

    var merged := ArrayMesh.new()
    merged.resource_name = path.get_file().get_basename()
    var tool := SurfaceTool.new()
    _merge(root, Transform3D.IDENTITY, merged, tool)
    root.free()

    if merged.get_surface_count() == 0:
        _warn_once("no geometry in: " + path)
        return null
    return merged


static func _merge(node: Node, inherited: Transform3D, merged: ArrayMesh, tool: SurfaceTool) -> void:
    var local := inherited
    if node is Node3D:
        local = inherited * (node as Node3D).transform
    if node is MeshInstance3D:
        var instance := node as MeshInstance3D
        var source := instance.mesh
        if source != null:
            for surface in source.get_surface_count():
                var material: Material = instance.get_active_material(surface)
                if material == null:
                    material = source.surface_get_material(surface)
                tool.clear()
                tool.begin(Mesh.PRIMITIVE_TRIANGLES)
                tool.append_from(source, surface, local)
                tool.set_material(material)
                tool.commit(merged)
                merged.surface_set_material(merged.get_surface_count() - 1, material)
    for child in node.get_children():
        _merge(child, local, merged, tool)


static func _warn_once(message: String) -> void:
    if _warned.has(message):
        return
    _warned[message] = true
    push_warning("PropModels: " + message)
