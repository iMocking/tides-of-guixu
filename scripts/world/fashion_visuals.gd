class_name FashionVisuals
## Turns a resolved fashion appearance (FashionData.appearance) into nodes and
## paint, shared by the in-world Player and the wardrobe preview.
##
## Everything is procedural: a rigged GLB whose textures could not be embedded
## still gets coloured robes, crowns, capes and auras without any extra art.
##
## Two conventions the rest of the code relies on:
##   * `base material` - CharacterModel stores the material a mesh should fall
##     back to on the mesh's meta, so taking an outfit off restores it;
##   * `base transform` - after a rig is mounted on the skeleton, each part
##     remembers the transform it was mounted with, so the idle animation only
##     has to add small deltas on top of it.

const BASE_ROBE := Color(0.42, 0.82, 0.62)
const BASE_ROUGHNESS := 0.65
const RIG_NAME := "FashionRig"
## Mesh meta keys shared with CharacterModel.
const BASE_MATERIAL_META := "fashion_base_material"
const BASE_TRANSFORM_META := "fashion_base_transform"
## Rigs remember their parts and the sockets they were mounted on.
const PARTS_META := "fashion_parts"
const SOCKETS_META := "fashion_sockets"

## Anchors measured on the player character (assets/models/characters/
## player_animated.glb, ~1.62 m tall).  CharacterModel scales the body to
## TARGET_HEIGHT, and the rig is mounted inside that same scale, so these stay
## in the source model's units: feet y = 0, waist ~0.97, shoulder line ~1.35,
## head 1.42-1.60 and the body faces +Z (toes at +Z, movement aims local +Z).
const WAIST_Y := 0.97
const HEAD_Y := 1.53
const SHOULDER_X := 0.17
const SHOULDER_Y := 1.35
const ORBIT_Y := 1.25
const FRONT_Z := 0.15
const BACK_Z := -0.13

# ------------------------------------------------------------- body colour --
## Recolours one clothing mesh.  An empty appearance restores the material the
## mesh was built with (see CharacterModel).
static func apply_body(mesh: MeshInstance3D, appearance: Dictionary) -> void:
    if mesh == null:
        return
    if appearance.is_empty():
        mesh.material_override = mesh.get_meta(BASE_MATERIAL_META, null)
        return

    var material := mesh.material_override as StandardMaterial3D
    if material == null or material.resource_name != "FashionOverride":
        material = StandardMaterial3D.new()
        material.resource_name = "FashionOverride"
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        mesh.material_override = material

    var colors: Dictionary = appearance.get("colors", {})
    var rarity := clampi(int(appearance.get("rarity", 1)), 1, 5)
    var robe: Color = colors.get("robe", BASE_ROBE)
    var glow: Color = colors.get("glow", Color.WHITE)
    material.albedo_color = robe
    material.roughness = clampf(0.80 - 0.10 * float(rarity), 0.22, 0.80)
    material.metallic = clampf(0.14 * float(rarity - 2), 0.0, 0.62)
    material.emission_enabled = true
    material.emission = Color(glow.r, glow.g, glow.b)
    material.emission_energy_multiplier = 0.12 + 0.06 * float(rarity)


## Recolours every clothing mesh of a body.
static func apply_outfit(meshes: Array, appearance: Dictionary) -> void:
    for node in meshes:
        var mesh := node as MeshInstance3D
        if mesh != null:
            apply_body(mesh, appearance)


# ------------------------------------------------------------------- rig ----
## Complete accessory rig (parts + aura) for one appearance.  Never returns
## null: an empty appearance yields an empty node so callers can add it blindly.
static func build_rig(appearance: Dictionary) -> Node3D:
    var rig := Node3D.new()
    rig.name = RIG_NAME
    var parts := {}
    rig.set_meta(PARTS_META, parts)
    if appearance.is_empty():
        return rig
    var colors: Dictionary = appearance.get("colors", {})
    var trim: Color = colors.get("trim", Color.WHITE)
    var glow: Color = colors.get("glow", Color.WHITE)
    for part_id in appearance.get("parts", []):
        var part := _build_part(str(part_id), trim, glow)
        if part != null:
            parts[str(part_id)] = part
            rig.add_child(part)
    var aura := _build_aura(
        str(appearance.get("aura", "none")),
        glow,
        clampi(int(appearance.get("rarity", 1)), 1, 5)
    )
    if aura != null:
        rig.add_child(aura)
    return rig


## Frees a rig, including the parts that were mounted on the skeleton.
static func dispose_rig(rig: Node3D) -> void:
    if rig == null or not is_instance_valid(rig):
        return
    for socket in rig.get_meta(SOCKETS_META, []):
        var node := socket as Node
        if node != null and is_instance_valid(node):
            if node.get_parent() != null:
                node.get_parent().remove_child(node)
            node.queue_free()
    if rig.get_parent() != null:
        rig.get_parent().remove_child(rig)
    rig.queue_free()


static func _build_part(part_id: String, trim: Color, glow: Color) -> Node3D:
    match part_id:
        "crown":
            return _part_crown(trim, glow)
        "cape":
            return _part_cape(trim, glow)
        "sash":
            return _part_sash(trim, glow)
        "pauldron":
            return _part_pauldron(trim, glow)
        "orbit":
            return _part_orbit(glow)
        "halo":
            return _part_halo(glow)
    return null


static func _part_crown(trim: Color, glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_crown"
    root.position = Vector3(0.0, HEAD_Y + 0.01, 0.0)

    var band := TorusMesh.new()
    band.inner_radius = 0.085
    band.outer_radius = 0.115
    band.rings = 24
    band.ring_segments = 6
    root.add_child(_mesh_node(band, _material(trim, glow, 0.65, 0.28), "CrownBand"))

    var gem := SphereMesh.new()
    gem.radius = 0.030
    gem.height = 0.060
    var gem_node := _mesh_node(gem, _material(glow, glow, 0.25, 0.18), "CrownGem")
    gem_node.position = Vector3(0.0, 0.025, FRONT_Z * 0.85)
    root.add_child(gem_node)
    return root


static func _part_cape(trim: Color, glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_cape"
    root.position = Vector3(0.0, 1.42, BACK_Z)

    var cloth := BoxMesh.new()
    cloth.size = Vector3(0.42, 0.85, 0.040)
    var cloth_node := _mesh_node(cloth, _material(trim, glow, 0.15, 0.44, 0.94), "CapeCloth")
    cloth_node.position = Vector3(0.0, -0.42, 0.0)
    root.add_child(cloth_node)

    var clasp := TorusMesh.new()
    clasp.inner_radius = 0.100
    clasp.outer_radius = 0.140
    clasp.rings = 20
    clasp.ring_segments = 6
    var clasp_node := _mesh_node(clasp, _material(glow, glow, 0.45, 0.30), "CapeClasp")
    clasp_node.position = Vector3(0.0, 0.01, 0.02)
    root.add_child(clasp_node)
    return root


static func _part_sash(trim: Color, glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_sash"
    root.position = Vector3(0.0, WAIST_Y, 0.0)

    var belt := TorusMesh.new()
    belt.inner_radius = 0.175
    belt.outer_radius = 0.215
    belt.rings = 24
    belt.ring_segments = 6
    belt.material = _material(trim, glow, 0.35, 0.40)
    var belt_node := MeshInstance3D.new()
    belt_node.name = "SashBelt"
    belt_node.mesh = belt
    root.add_child(belt_node)

    var knot := BoxMesh.new()
    knot.size = Vector3(0.11, 0.09, 0.07)
    var knot_node := _mesh_node(knot, _material(glow, glow, 0.30, 0.35), "SashKnot")
    knot_node.position = Vector3(0.0, -0.03, FRONT_Z)
    root.add_child(knot_node)
    return root


static func _part_pauldron(trim: Color, glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_pauldron"

    var shell := SphereMesh.new()
    shell.radius = 0.100
    shell.height = 0.160
    var material := _material(trim, glow, 0.55, 0.32)
    for side in [-1.0, 1.0]:
        var node := _mesh_node(shell, material, "PauldronLeft" if side < 0.0 else "PauldronRight")
        node.position = Vector3(SHOULDER_X * side, SHOULDER_Y, 0.0)
        node.scale = Vector3(1.0, 0.72, 1.0)
        root.add_child(node)
    return root


static func _part_orbit(glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_orbit"
    root.position = Vector3(0.0, ORBIT_Y, 0.0)

    var orb := SphereMesh.new()
    orb.radius = 0.040
    orb.height = 0.080
    var material := _material(glow, glow, 0.20, 0.22)
    var count := 3
    for i in range(count):
        var angle := TAU * float(i) / float(count)
        var node := _mesh_node(orb, material, "Orb%d" % i)
        node.position = Vector3(cos(angle) * 0.45, 0.0, sin(angle) * 0.45)
        root.add_child(node)
    return root


static func _part_halo(glow: Color) -> Node3D:
    var root := Node3D.new()
    root.name = "Part_halo"
    root.position = Vector3(0.0, HEAD_Y - 0.01, BACK_Z * 1.6)
    root.rotation_degrees = Vector3(90.0, 0.0, 0.0)

    var ring := TorusMesh.new()
    ring.inner_radius = 0.170
    ring.outer_radius = 0.210
    ring.rings = 32
    ring.ring_segments = 6
    root.add_child(_mesh_node(ring, _material(glow, glow, 0.35, 0.28, 0.82), "HaloRing"))
    return root


# ------------------------------------------------------------------ aura ----
static func _build_aura(kind: String, glow: Color, rarity: int) -> Node3D:
    if kind == "" or kind == "none":
        return null
    var root := Node3D.new()
    root.name = "Aura"

    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.40
    ring_mesh.outer_radius = 0.48
    ring_mesh.rings = 32
    ring_mesh.ring_segments = 6
    var ring := _mesh_node(ring_mesh, _material(glow, glow, 0.0, 0.40, 0.42), "AuraRing")
    ring.position = Vector3(0.0, 0.04, 0.0)
    root.add_child(ring)

    var light := OmniLight3D.new()
    light.name = "AuraLight"
    light.position = Vector3(0.0, 0.95, 0.0)
    light.light_color = Color(glow.r, glow.g, glow.b)
    light.light_energy = 0.5 + 0.16 * float(rarity)
    light.omni_range = 3.2
    light.shadow_enabled = false
    light.set_meta("base_energy", light.light_energy)
    root.add_child(light)

    if kind == "halo":
        var halo_mesh := TorusMesh.new()
        halo_mesh.inner_radius = 0.30
        halo_mesh.outer_radius = 0.34
        halo_mesh.rings = 32
        halo_mesh.ring_segments = 6
        var halo := _mesh_node(halo_mesh, _material(glow, glow, 0.30, 0.30, 0.70), "AuraHalo")
        halo.position = Vector3(0.0, 1.72, 0.0)
        root.add_child(halo)
    else:
        root.add_child(_build_particles(kind, glow, rarity))
    return root


static func _build_particles(kind: String, glow: Color, rarity: int) -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.name = "AuraParticles"
    particles.amount = 10 + rarity * 3
    particles.lifetime = 1.9
    particles.emitting = true
    particles.visibility_aabb = AABB(Vector3(-2.0, -0.6, -2.0), Vector3(4.0, 4.0, 4.0))

    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = 0.35
    process.direction = Vector3(0.0, 1.0, 0.0)
    process.spread = 24.0
    process.initial_velocity_min = 0.22
    process.initial_velocity_max = 0.62
    process.gravity = Vector3(0.0, 0.9, 0.0) if kind == "mist" else Vector3(0.0, 0.18, 0.0)
    process.scale_min = 0.5
    process.scale_max = 1.15

    var ramp := Gradient.new()
    var soft := Color(glow.r, glow.g, glow.b, 0.0)
    var bright := Color(glow.r, glow.g, glow.b, 0.85)
    ramp.set_color(0, soft)
    ramp.set_color(1, soft)
    ramp.add_point(0.35, bright)
    # color_ramp expects a texture, not a bare Gradient.
    var ramp_texture := GradientTexture1D.new()
    ramp_texture.gradient = ramp
    process.color_ramp = ramp_texture
    particles.process_material = process

    var dot := SphereMesh.new()
    dot.radius = 0.028
    dot.height = 0.056
    var material := _material(glow, glow, 0.0, 0.30, 0.9)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    dot.material = material
    particles.draw_pass_1 = dot
    particles.position = Vector3(0.0, 0.25, 0.0)
    return particles


# ------------------------------------------------------------- animation ----
## Idle motion for the rig: cape sway, orbiting orbs, a spinning halo and the
## breathing aura.  `speed` (0..1) makes the cloth trail while running.
##
## Deltas are composed onto each part's mounted base transform, so this works
## whether the rig is a plain child of the body or was mounted on bones.
static func animate(rig: Node3D, time: float, speed: float = 0.0) -> void:
    if rig == null or not is_instance_valid(rig):
        return
    var parts: Dictionary = rig.get_meta(PARTS_META, {})

    var cape := _part(parts, "cape")
    if cape != null:
        var pitch := deg_to_rad(6.0 + speed * 16.0 + sin(time * 2.4) * 3.5)
        var roll := deg_to_rad(sin(time * 1.7) * 2.0)
        cape.transform = _base_of(cape) * Transform3D(Basis.from_euler(Vector3(pitch, 0.0, roll)), Vector3.ZERO)

    var orbit := _part(parts, "orbit")
    if orbit != null:
        var yaw := deg_to_rad(fmod(time * 92.0, 360.0))
        var bob := sin(time * 2.0) * 0.05
        orbit.transform = _base_of(orbit) * Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), Vector3(0.0, bob, 0.0))

    var halo := _part(parts, "halo")
    if halo != null:
        var sway := deg_to_rad(sin(time * 1.2) * 7.0)
        halo.transform = _base_of(halo) * Transform3D(Basis.from_euler(Vector3(0.0, 0.0, sway)), Vector3.ZERO)

    var crown := _part(parts, "crown")
    if crown != null:
        var turn := deg_to_rad(sin(time * 0.8) * 6.0)
        crown.transform = _base_of(crown) * Transform3D(Basis.from_euler(Vector3(0.0, turn, 0.0)), Vector3.ZERO)

    var aura_ring := rig.get_node_or_null("Aura/AuraRing") as Node3D
    if aura_ring != null:
        var pulse := 1.0 + sin(time * 1.6) * 0.05
        aura_ring.scale = Vector3(pulse, 1.0, pulse)
        aura_ring.rotation_degrees.y = fmod(time * 26.0, 360.0)

    var aura_light := rig.get_node_or_null("Aura/AuraLight") as OmniLight3D
    if aura_light != null:
        var base_energy := float(aura_light.get_meta("base_energy", aura_light.light_energy))
        aura_light.light_energy = base_energy * (0.86 + 0.14 * sin(time * 2.2))


static func _part(parts: Dictionary, part_id: String) -> Node3D:
    var node := parts.get(part_id, null) as Node3D
    if node == null or not is_instance_valid(node):
        return null
    return node


static func _base_of(node: Node3D) -> Transform3D:
    return node.get_meta(BASE_TRANSFORM_META, node.transform)


# ---------------------------------------------------------------- helpers ---
static func _mesh_node(mesh: Mesh, material: Material, node_name: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.material_override = material
    return node


static func _material(color: Color, emission: Color, metallic: float, roughness: float, alpha: float = 1.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, alpha)
    material.metallic = metallic
    material.roughness = roughness
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if alpha < 1.0:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if emission.a > 0.0:
        material.emission_enabled = true
        material.emission = Color(emission.r, emission.g, emission.b)
        material.emission_energy_multiplier = 1.15
    return material