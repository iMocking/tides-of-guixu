class_name CharacterModel
extends Node3D
## The player's animated body.
##
## Wraps assets/models/characters/player_animated.glb - a rigged character with
## nine clips (Idle / Walk / Run / Jump / Attack_Knife / Dodge / Death /
## Meditate / Sleep_Side).  The source is ~1.62 m tall, so the node is scaled to
## TARGET_HEIGHT to match the rest of the world (enemies and the NPC are ~1.95 m).
##
## Two things the GLB cannot provide are filled in here:
##   * its textures could not be embedded, so every material renders flat white -
##     each mesh is classified by name and given a readable prototype colour;
##   * the clothing meshes are handed to the fashion system (FashionVisuals),
##     which recolours them when an outfit is worn.
##
## The class also owns the weapon socket: a BoneAttachment3D on `wrist.R` that
## keeps the sword gripped correctly through every animation.

const MODEL_PATH := "res://assets/models/characters/player_animated.glb"
const FALLBACK_OBJ := "res://assets/models/characters/player_base.obj"
const WEAPON_BONE := "wrist.R"

## Every character in the world is about this tall (enemy 1.96 m, elder 1.95 m).
const TARGET_HEIGHT := 1.94
## Distance from the mesh origin to the fist, along the blade.
const WEAPON_FIST_OFFSET := 0.13
## How far the blade is tilted away from the hand axis towards the character's
## front, so an idle sword does not stab the ground.
const WEAPON_TILT_DEG := 38.0
## Roll of the blade inside the fist (tweak if the flat faces the wrong way).
const WEAPON_ROLL_DEG := 0.0

## Where the weapon sits when no skeleton is available (procedural fallback).
const WEAPON_REST_POSITION := Vector3(0.40, 0.98, 0.0)
const WEAPON_REST_ROTATION := Vector3(-18.0, 0.0, -24.0)

const CLIP_IDLE := "Idle"
const CLIP_RUN := "Run"
const CLIP_JUMP := "Jump"
const CLIP_ATTACK := "Attack_Knife"
const CLIP_DODGE := "Dodge"
const CLIP_DEATH := "Death"
const LOOP_CLIPS: Array[String] = ["Idle", "Walk", "Run", "Meditate", "Sleep_Side"]

## "<mesh name> <material name>" (lower case) -> role.  First match wins, and
## anything unmatched keeps its own material.
const MESH_ROLES := [
    {"role": "outfit", "keywords": ["suit", "cloth", "robe", "dress", "armor", "armour", "garment", "outfit", "coat", "jacket", "skirt", "tunic"]},
    {"role": "hair", "keywords": ["hair", "ponytail", "eyebrow", "brow", "lash"]},
    {"role": "eyes", "keywords": ["eye", "high-poly"]},
    {"role": "shoe", "keywords": ["shoe", "boot", "foot", "feet"]},
    {"role": "tongue", "keywords": ["tongue"]},
    {"role": "tooth", "keywords": ["tooth", "teeth"]},
    {"role": "skin", "keywords": ["body", "muscle", "skin", "hand", "head"]},
]
const ROLE_COLORS := {
    "skin": Color(0.93, 0.76, 0.64),
    "hair": Color(0.13, 0.11, 0.14),
    "eyes": Color(0.10, 0.09, 0.11),
    "shoe": Color(0.17, 0.15, 0.15),
    "tooth": Color(0.95, 0.95, 0.93),
    "tongue": Color(0.70, 0.36, 0.36),
    "outfit": Color(0.42, 0.82, 0.62),
}

var animated := false
var animation_player: AnimationPlayer = null
var skeleton: Skeleton3D = null
var weapon_socket: BoneAttachment3D = null
var weapon_mesh: MeshInstance3D = null
## Every mesh of the body, and the subset the fashion system may recolour.
var meshes: Array[MeshInstance3D] = []
var outfit_meshes: Array[MeshInstance3D] = []
## Measured height before scaling.
var source_height := 1.0
var model_scale := 1.0

var _weapon_id := ""
var _mounted_parts: Dictionary = {}


# ------------------------------------------------------------------ build ---
## Builds the body.  Call once, then add the node to the tree.
func build() -> void:
    if not _build_animated():
        _build_fallback()


func _build_animated() -> bool:
    var packed := _load_scene(MODEL_PATH)
    if packed == null:
        return false
    var instance: Node = packed.instantiate()
    if instance == null:
        return false
    add_child(instance)

    skeleton = _find_first(instance, "Skeleton3D") as Skeleton3D
    animation_player = _find_first(instance, "AnimationPlayer") as AnimationPlayer

    var box := AABB()
    var first := true
    for node in _find_all(instance, "MeshInstance3D"):
        var mesh := node as MeshInstance3D
        if mesh == null:
            continue
        meshes.append(mesh)
        _dress_mesh(mesh)
        var local: Transform3D = _transform_up_to(mesh)
        var mesh_box: AABB = local * mesh.get_aabb()
        box = mesh_box if first else box.merge(mesh_box)
        first = false

    # The bind pose sits a hair below y = 0; lift the body so the soles touch
    # the ground plane the rest of the game uses.
    if instance is Node3D and not first:
        (instance as Node3D).position.y = -box.position.y

    source_height = maxf(box.size.y, 0.01)
    model_scale = TARGET_HEIGHT / source_height
    scale = Vector3.ONE * model_scale

    if animation_player != null:
        _prepare_animations()
        animated = animation_player.has_animation(CLIP_IDLE)
    if skeleton != null:
        _create_weapon_socket()
    if animated:
        play(CLIP_IDLE, 1.0, 0.0)
    return true


## Last-resort body when the GLB is missing: the original blocky placeholder.
func _build_fallback() -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "FallbackBody"
    var mesh := _load_mesh(FALLBACK_OBJ)
    if mesh != null:
        mesh_instance.mesh = mesh
    else:
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.42
        capsule.height = 1.8
        mesh_instance.mesh = capsule
    var material := StandardMaterial3D.new()
    material.albedo_color = ROLE_COLORS["outfit"]
    material.roughness = 0.65
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh_instance.material_override = material
    add_child(mesh_instance)
    meshes.append(mesh_instance)
    outfit_meshes.append(mesh_instance)
    mesh_instance.set_meta(FashionVisuals.BASE_MATERIAL_META, material)
    animated = false
    weapon_mesh = MeshInstance3D.new()
    weapon_mesh.name = "WeaponMesh"
    weapon_mesh.position = WEAPON_REST_POSITION
    weapon_mesh.rotation_degrees = WEAPON_REST_ROTATION
    add_child(weapon_mesh)


func _prepare_animations() -> void:
    for clip in animation_player.get_animation_list():
        var anim := animation_player.get_animation(str(clip))
        if anim == null:
            continue
        anim.loop_mode = Animation.LOOP_LINEAR if LOOP_CLIPS.has(str(clip)) else Animation.LOOP_NONE


# ---------------------------------------------------------------- dressing --
## Gives a white, texture-less mesh a readable prototype colour.
func _dress_mesh(mesh: MeshInstance3D) -> void:
    var key := (str(mesh.name) + " " + _material_name(mesh)).to_lower()
    var role := "none"
    for entry in MESH_ROLES:
        var data: Dictionary = entry
        for keyword in data["keywords"]:
            if key.find(str(keyword)) >= 0:
                role = str(data["role"])
                break
        if role != "none":
            break
    if role == "none":
        return

    var material := StandardMaterial3D.new()
    material.resource_name = "CharacterRole_" + role
    material.albedo_color = ROLE_COLORS.get(role, Color.WHITE)
    material.roughness = 0.62
    material.metallic = 0.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    if role == "outfit":
        outfit_meshes.append(mesh)
        # Remembered so FashionVisuals can restore it when no outfit is worn.
        mesh.set_meta(FashionVisuals.BASE_MATERIAL_META, material)
    else:
        mesh.set_meta(FashionVisuals.BASE_MATERIAL_META, material)


func _material_name(mesh: MeshInstance3D) -> String:
    if mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
        return ""
    var material := mesh.mesh.surface_get_material(0)
    if material == null:
        return ""
    return str(material.resource_name)


# ----------------------------------------------------------------- weapon ---
func _create_weapon_socket() -> void:
    var wrist_index := skeleton.find_bone(WEAPON_BONE)
    if wrist_index < 0:
        return
    weapon_socket = BoneAttachment3D.new()
    weapon_socket.name = "WeaponSocket"
    weapon_socket.bone_name = WEAPON_BONE
    skeleton.add_child(weapon_socket)
    weapon_socket.transform = _weapon_grip_transform(wrist_index)


## Rotation that puts the blade along the hand, tilted towards the front, with
## the fist on the grip instead of on the pommel.
func _weapon_grip_transform(wrist_index: int) -> Transform3D:
    var wrist := skeleton.get_bone_global_pose(wrist_index)
    var bone_basis := wrist.basis.orthonormalized()
    var hand_dir := Vector3.DOWN
    var children := skeleton.get_bone_children(wrist_index)
    if not children.is_empty():
        var tip := skeleton.get_bone_global_pose(int(children[0])).origin
        var candidate := tip - wrist.origin
        if candidate.length() > 0.0001:
            hand_dir = candidate.normalized()

    # Tilt the blade away from the hand axis, towards the character's front (+Z).
    var forward := Vector3(0.0, 0.0, 1.0)
    var spread := maxf(rad_to_deg(hand_dir.angle_to(forward)), 1.0)
    var weight := clampf(WEAPON_TILT_DEG / spread, 0.0, 1.0)
    var blade_dir := hand_dir.slerp(forward, weight).normalized()

    var local_dir := (bone_basis.inverse() * blade_dir).normalized()
    var basis := Basis(Quaternion(Vector3.UP, local_dir)) * Basis(Vector3.UP, deg_to_rad(WEAPON_ROLL_DEG))
    return Transform3D(basis, -local_dir * WEAPON_FIST_OFFSET)


## Shows the equipped weapon ("" = bare hands).
func set_weapon(item_id: String) -> void:
    if item_id == _weapon_id and weapon_mesh != null and weapon_mesh.mesh != null:
        return
    _weapon_id = item_id
    if weapon_mesh == null:
        weapon_mesh = MeshInstance3D.new()
        weapon_mesh.name = "WeaponMesh"
        if weapon_socket != null:
            weapon_socket.add_child(weapon_mesh)
            # The socket lives inside the body's scale; keep the sword at its
            # authored size instead of inheriting the 1.2x body scale.
            weapon_mesh.scale = Vector3.ONE / maxf(model_scale, 0.01)
        else:
            add_child(weapon_mesh)
            weapon_mesh.position = WEAPON_REST_POSITION
            weapon_mesh.rotation_degrees = WEAPON_REST_ROTATION

    if item_id == "":
        weapon_mesh.mesh = null
        return
    var row := GameData.item_row(item_id)
    var heavy := int(row.get("rarity", 1)) >= 4
    var path := "res://assets/models/weapons/great_sword.obj" if heavy else "res://assets/models/weapons/basic_sword.obj"
    var mesh := _load_mesh(path)
    if mesh == null:
        mesh = _load_mesh("res://assets/models/weapons/basic_sword.obj")
    weapon_mesh.mesh = mesh
    if mesh == null:
        return
    var material := StandardMaterial3D.new()
    material.albedo_color = GameData.item_color(item_id)
    material.metallic = 0.55
    material.roughness = 0.34
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    weapon_mesh.material_override = material


## World position of the blade tip, for tests and debugging.
func weapon_tip_position() -> Vector3:
    if weapon_mesh == null or weapon_mesh.mesh == null:
        return Vector3.INF
    var tip := weapon_mesh.get_aabb().position + weapon_mesh.get_aabb().size
    return weapon_mesh.global_transform * Vector3(0.0, tip.y, 0.0)


# ---------------------------------------------------------------- fashion ---
## Mounts a FashionVisuals rig on the body: the accessories are re-parented onto
## the bones they belong to, so a crown rides the head and a cape follows the
## spine.  Parts are remembered with their mounted base transform so
## FashionVisuals.animate() can keep adding its idle motion on top.
func mount_fashion_rig(rig: Node3D) -> void:
    if rig == null:
        return
    # Remember the sockets on the rig so FashionVisuals.dispose_rig() can take
    # the whole thing down again (the parts no longer live under the rig).
    var sockets: Array = []
    for child in rig.get_children():
        var part := child as Node3D
        if part == null:
            continue
        var bone := _part_bone(str(part.name))
        if skeleton != null and bone != "" and skeleton.find_bone(bone) >= 0:
            var attachment := BoneAttachment3D.new()
            attachment.name = str(part.name) + "Socket"
            attachment.bone_name = bone
            skeleton.add_child(attachment)
            attachment.transform = _bone_inverse(bone) * part.transform
            rig.remove_child(part)
            attachment.add_child(part)
            part.transform = Transform3D.IDENTITY
            _mounted_parts[str(part.name)] = attachment
            sockets.append(attachment)
        part.set_meta(FashionVisuals.BASE_TRANSFORM_META, part.transform)
    rig.set_meta(FashionVisuals.SOCKETS_META, sockets)


## Which bone each accessory rides (empty = keep it on the body root).
func _part_bone(part_name: String) -> String:
    match part_name:
        "Part_crown":
            return "head"
        "Part_cape":
            return "spine01"
        "Part_sash":
            return "spine03"
        "Part_pauldron":
            return "spine01"
        "Part_halo":
            return "spine01"
        "Part_orbit":
            return "spine05"
    return ""


func _bone_inverse(bone: String) -> Transform3D:
    var index := skeleton.find_bone(bone)
    if index < 0:
        return Transform3D.IDENTITY
    return skeleton.get_bone_global_pose(index).affine_inverse()


# -------------------------------------------------------------- animation ---
func has_clip(clip: String) -> bool:
    return animation_player != null and animation_player.has_animation(clip)


func clip_length(clip: String) -> float:
    if animation_player == null:
        return 0.0
    var anim := animation_player.get_animation(clip)
    return anim.length if anim != null else 0.0


func current_clip() -> String:
    if animation_player == null:
        return ""
    return str(animation_player.current_animation)


## Switches clip.  Calling it every frame with the same clip is a no-op, so the
## state machine can simply ask for the pose it wants.
func play(clip: String, speed_scale: float = 1.0, blend: float = 0.18) -> bool:
    if not has_clip(clip):
        return false
    animation_player.speed_scale = speed_scale
    if str(animation_player.current_animation) == clip and animation_player.is_playing():
        return true
    animation_player.play(clip, blend)
    return true


## Same as play(), but always restarts the clip - used when an action begins.
func restart(clip: String, speed_scale: float = 1.0, blend: float = 0.1) -> bool:
    if not has_clip(clip):
        return false
    animation_player.speed_scale = speed_scale
    animation_player.play(clip, blend)
    animation_player.seek(0.0, true)
    return true


func stop() -> void:
    if animation_player != null:
        animation_player.stop()


# ---------------------------------------------------------------- helpers ---
func _load_scene(path: String) -> PackedScene:
    if not ResourceLoader.exists(path):
        return null
    var resource := load(path)
    return resource as PackedScene


func _load_mesh(path: String) -> Mesh:
    if not ResourceLoader.exists(path):
        return null
    var resource := load(path)
    return resource as Mesh


func _find_first(node: Node, type_name: String) -> Node:
    if node.is_class(type_name):
        return node
    for child in node.get_children():
        var found := _find_first(child, type_name)
        if found != null:
            return found
    return null


func _find_all(node: Node, type_name: String) -> Array:
    var result: Array = []
    if node.is_class(type_name):
        result.append(node)
    for child in node.get_children():
        result.append_array(_find_all(child, type_name))
    return result


## Transform of `node` expressed in this model's space (works before the node
## enters the tree).
func _transform_up_to(node: Node3D) -> Transform3D:
    var result := Transform3D.IDENTITY
    var current: Node = node
    while current != null and current != self:
        if current is Node3D:
            result = (current as Node3D).transform * result
        current = current.get_parent()
    return result