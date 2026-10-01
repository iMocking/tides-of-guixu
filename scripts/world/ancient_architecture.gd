class_name AncientArchitecture
extends RefCounted
## Procedural 古风建筑 parts.
##
## Every builder returns a `Node3D` whose origin sits on the ground plane, so
## callers only have to position the root and the whole structure follows the
## terrain.  Everything is assembled from Godot primitives with flat stylised
## colours - the project ships no external model or texture files.

const RED := Color(0.494, 0.145, 0.110)
const DEEP_RED := Color(0.353, 0.098, 0.078)
const GOLD := Color(0.780, 0.620, 0.290)
const WOOD := Color(0.278, 0.184, 0.118)
const DARK_WOOD := Color(0.180, 0.122, 0.086)
const TILE := Color(0.169, 0.196, 0.235)
const TILE_RIDGE := Color(0.243, 0.278, 0.325)
const STONE := Color(0.541, 0.525, 0.470)
const PALE_STONE := Color(0.706, 0.694, 0.639)
const INK := Color(0.043, 0.051, 0.063)

## Scene groups so callers can count what a builder produced without
## depending on the auto-generated node names Godot hands out for duplicates.
const GROUP_PAIFANG := "arch_paifang"
const GROUP_PAVILION := "arch_pavilion"
const GROUP_PAGODA := "arch_pagoda"
const GROUP_HALL := "arch_hall"
const GROUP_LANTERN := "arch_lantern"
const GROUP_WALL := "arch_wall"

static var _materials: Dictionary = {}


static func material_for(color: Color, emission := Color(0.0, 0.0, 0.0, 1.0), emission_energy := 0.0, unshaded := false) -> StandardMaterial3D:
    var key := "%s|%.2f|%d" % [color.to_html(false), emission_energy, 1 if unshaded else 0]
    if _materials.has(key):
        return _materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.82
    mat.metallic = 0.0
    if emission_energy > 0.0:
        mat.emission_enabled = true
        mat.emission = emission
        mat.emission_energy_multiplier = emission_energy
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _materials[key] = mat
    return mat


static func clear_material_cache() -> void:
    _materials.clear()


# ------------------------------------------------------------- pieces ---

static func box(size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.material_override = material_for(color)
    node.position = position
    return node


static func cylinder(radius: float, height: float, position: Vector3, color: Color, segments := 16) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = segments
    node.mesh = mesh
    node.material_override = material_for(color)
    node.position = position
    return node


static func tapering(bottom_radius: float, top_radius: float, height: float, position: Vector3, color: Color, segments := 16) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = bottom_radius
    mesh.top_radius = top_radius
    mesh.height = height
    mesh.radial_segments = segments
    node.mesh = mesh
    node.material_override = material_for(color)
    node.position = position
    return node


static func sphere(radius: float, position: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    node.mesh = mesh
    node.material_override = material_for(color)
    node.position = position
    return node


## Four-sided hip roof: a squashed pyramid with the eaves pushed out past the
## walls, so it reads as a tiled Chinese roof.
static func roof(width: float, depth: float, height: float, position: Vector3, color := TILE) -> Node3D:
    var root := Node3D.new()
    root.name = "Roof"
    var eaves := box(Vector3(width, 0.22, depth), position, DARK_WOOD)
    root.add_child(eaves)
    var cone := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = 1.0
    mesh.top_radius = 0.0
    mesh.height = 1.0
    mesh.radial_segments = 4
    cone.mesh = mesh
    cone.material_override = material_for(color)
    cone.scale = Vector3(width * 0.5, height, depth * 0.5)
    cone.position = position + Vector3(0.0, height * 0.5, 0.0)
    root.add_child(cone)
    var ridge := box(Vector3(width * 0.16, 0.26, depth * 1.02), position + Vector3(0.0, height, 0.0), TILE_RIDGE)
    root.add_child(ridge)
    return root


static func finial(height: float, radius: float, origin: Vector3) -> Node3D:
    var root := Node3D.new()
    root.name = "Finial"
    root.add_child(cylinder(radius * 0.35, height, origin + Vector3(0.0, height * 0.5, 0.0), GOLD, 10))
    root.add_child(sphere(radius, origin + Vector3(0.0, height + radius * 0.6, 0.0), GOLD))
    return root


# ---------------------------------------------------------- structures ---

## 牌坊 - the memorial arch that marks the entrance to the start basin.
static func paifang(width := 9.0, height := 6.4) -> Node3D:
    var root := Node3D.new()
    root.name = "Paifang"
    root.add_to_group(GROUP_PAIFANG)
    root.add_child(box(Vector3(width + 1.6, 0.45, 2.6), Vector3(0.0, 0.22, 0.0), PALE_STONE))
    var pillar_positions := [-width * 0.5, -width * 0.167, width * 0.167, width * 0.5]
    for x in pillar_positions:
        root.add_child(cylinder(0.32, height, Vector3(x, height * 0.5, 0.0), DEEP_RED, 12))
        root.add_child(box(Vector3(0.9, 0.35, 0.9), Vector3(x, 0.35, 0.0), PALE_STONE))
    for i in range(3):
        var bay_width := width if i == 1 else width * 0.666
        var y := height * (0.72 if i == 0 else 0.95)
        root.add_child(box(Vector3(bay_width, 0.42, 0.85), Vector3(0.0, y, 0.0), RED))
        root.add_child(box(Vector3(bay_width * 1.06, 0.16, 1.02), Vector3(0.0, y + 0.30, 0.0), GOLD))
    var plaque := box(Vector3(2.5, 1.15, 0.34), Vector3(0.0, height * 0.80, 0.5), GOLD)
    root.add_child(plaque)
    root.add_child(box(Vector3(2.9, 0.5, 0.7), Vector3(0.0, height + 0.30, 0.0), RED))
    root.add_child(roof(width * 1.02, 2.4, 1.3, Vector3(0.0, height + 0.55, 0.0)))
    return root


## 亭 - an open hexagonal pavilion.
static func pavilion(radius := 3.2, pillar_height := 3.0) -> Node3D:
    var root := Node3D.new()
    root.name = "Pavilion"
    root.add_to_group(GROUP_PAVILION)
    root.add_child(cylinder(radius + 0.7, 0.42, Vector3(0.0, 0.21, 0.0), PALE_STONE, 6))
    root.add_child(cylinder(radius + 0.35, 0.30, Vector3(0.0, 0.52, 0.0), STONE, 6))
    for i in range(6):
        var angle := TAU * float(i) / 6.0
        var x := cos(angle) * radius
        var z := sin(angle) * radius
        root.add_child(cylinder(0.19, pillar_height, Vector3(x, 0.67 + pillar_height * 0.5, z), DEEP_RED, 10))
    var beam_y := 0.67 + pillar_height
    root.add_child(cylinder(radius + 0.25, 0.34, Vector3(0.0, beam_y + 0.17, 0.0), RED, 6))
    var cone := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = radius + 1.5
    mesh.top_radius = 0.35
    mesh.height = 1.9
    mesh.radial_segments = 6
    cone.mesh = mesh
    cone.material_override = material_for(TILE)
    cone.position = Vector3(0.0, beam_y + 0.34 + 0.95, 0.0)
    root.add_child(cone)
    root.add_child(finial(0.85, 0.34, Vector3(0.0, beam_y + 2.25, 0.0)))
    return root


## 楼阁 - a stacked pagoda.
static func pagoda(levels := 5, base_radius := 3.0) -> Node3D:
    var root := Node3D.new()
    root.name = "Pagoda"
    root.add_to_group(GROUP_PAGODA)
    root.add_child(cylinder(base_radius + 1.1, 0.7, Vector3(0.0, 0.35, 0.0), PALE_STONE, 8))
    var y := 0.7
    var radius := base_radius
    for level in range(levels):
        var body_height := 2.1 - float(level) * 0.16
        root.add_child(cylinder(radius, body_height, Vector3(0.0, y + body_height * 0.5, 0.0), DEEP_RED if level % 2 == 0 else RED, 8))
        root.add_child(cylinder(radius * 0.96, 0.16, Vector3(0.0, y + 0.08, 0.0), GOLD, 8))
        var eave := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.bottom_radius = radius + 1.25
        mesh.top_radius = radius * 0.55
        mesh.height = 1.05
        mesh.radial_segments = 8
        eave.mesh = mesh
        eave.material_override = material_for(TILE)
        eave.position = Vector3(0.0, y + body_height + 0.5, 0.0)
        root.add_child(eave)
        y += body_height + 1.0
        radius *= 0.86
    root.add_child(finial(1.5, 0.5, Vector3(0.0, y, 0.0)))
    return root


## 大殿 - a hall with a colonnade and a hipped roof.
static func hall(width := 13.0, depth := 8.0, wall_height := 4.0) -> Node3D:
    var root := Node3D.new()
    root.name = "Hall"
    root.add_to_group(GROUP_HALL)
    root.add_child(box(Vector3(width + 3.0, 0.75, depth + 3.0), Vector3(0.0, 0.375, 0.0), PALE_STONE))
    root.add_child(box(Vector3(width + 1.6, 0.35, depth + 1.6), Vector3(0.0, 0.90, 0.0), STONE))
    var floor_y := 1.075
    # Back and side walls, leaving the south face open for the doors.
    root.add_child(box(Vector3(width, wall_height, 0.5), Vector3(0.0, floor_y + wall_height * 0.5, -depth * 0.5), DEEP_RED))
    for side in [-1.0, 1.0]:
        root.add_child(box(Vector3(0.5, wall_height, depth), Vector3(side * width * 0.5, floor_y + wall_height * 0.5, 0.0), DEEP_RED))
    # Front: a door bay flanked by two window bays.
    root.add_child(box(Vector3(width * 0.26, wall_height, 0.5), Vector3(0.0, floor_y + wall_height * 0.5, depth * 0.5), INK))
    for side in [-1.0, 1.0]:
        root.add_child(box(Vector3(width * 0.30, wall_height, 0.5), Vector3(side * width * 0.33, floor_y + wall_height * 0.5, depth * 0.5), RED))
    var columns := 6
    for i in range(columns):
        var x := lerpf(-width * 0.5, width * 0.5, float(i) / float(columns - 1))
        root.add_child(cylinder(0.36, wall_height + 0.8, Vector3(x, floor_y + (wall_height + 0.8) * 0.5, depth * 0.5 + 1.3), DEEP_RED, 12))
    var eave_y := floor_y + wall_height + 0.8
    root.add_child(box(Vector3(width + 3.2, 0.5, depth + 3.2), Vector3(0.0, eave_y + 0.25, 0.0), WOOD))
    root.add_child(roof(width + 5.0, depth + 5.0, 3.4, Vector3(0.0, eave_y + 0.5, 0.0)))
    return root


## 石灯笼 - a small stone lantern to line the courtyard.
static func stone_lantern(height := 1.5) -> Node3D:
    var root := Node3D.new()
    root.name = "StoneLantern"
    root.add_to_group(GROUP_LANTERN)
    root.add_child(cylinder(0.34, 0.22, Vector3(0.0, 0.11, 0.0), STONE, 8))
    root.add_child(cylinder(0.16, height * 0.55, Vector3(0.0, 0.22 + height * 0.275, 0.0), STONE, 8))
    root.add_child(box(Vector3(0.62, 0.5, 0.62), Vector3(0.0, 0.22 + height * 0.55 + 0.25, 0.0), PALE_STONE))
    var lamp := band(Vector3(0.40, 0.32, 0.40), Vector3(0.0, 0.22 + height * 0.55 + 0.25, 0.0), Color(1.0, 0.86, 0.55), 1.6)
    root.add_child(lamp)
    root.add_child(tapering(0.52, 0.10, 0.5, Vector3(0.0, 0.22 + height * 0.55 + 0.72, 0.0), TILE, 4))
    return root


## A glowing block - the lamp in a lantern or the plaque on a gate.
static func band(size: Vector3, position: Vector3, color: Color, energy := 1.4) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.material_override = material_for(color, color, energy)
    node.position = position
    return node


## 院墙 - a run of courtyard wall with a tiled cap.
static func wall(from_point: Vector2, to_point: Vector2, height := 2.2, thickness := 0.5) -> Node3D:
    var root := Node3D.new()
    root.name = "Wall"
    root.add_to_group(GROUP_WALL)
    var delta := to_point - from_point
    var length := delta.length()
    if length <= 0.01:
        return root
    var mid := (from_point + to_point) * 0.5
    root.position = Vector3(mid.x, 0.0, mid.y)
    root.rotation.y = -atan2(delta.y, delta.x)
    root.add_child(box(Vector3(length, height, thickness), Vector3(0.0, height * 0.5, 0.0), DEEP_RED))
    root.add_child(box(Vector3(length + 0.3, 0.24, thickness + 0.4), Vector3(0.0, height + 0.12, 0.0), TILE))
    root.add_child(box(Vector3(length + 0.3, 0.14, thickness + 0.16), Vector3(0.0, height + 0.31, 0.0), TILE_RIDGE))
    return root
