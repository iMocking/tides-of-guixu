extends Control
class_name FashionPreview
## Wardrobe mirror: a slowly spinning 3D preview of the player character wearing
## the selected outfit.
##
## It drives the very same CharacterModel + FashionVisuals pair as the in-world
## Player, so the mirror can never show something the world would not.  Nothing
## in here touches saved state.

const SPIN_SPEED := 22.0
## Degrees of yaw per pixel dragged.
const DRAG_SENSITIVITY := 0.55
## How long the mirror waits after a drag before turning on its own again.
const AUTO_SPIN_RESUME_DELAY := 3.0

var _viewport: SubViewport
var _stage: Node3D
var _character: CharacterModel
var _rig: Node3D
## Whether the model turns by itself.  Switched off for the character sheet,
## where the player turns it by hand instead.
var auto_spin := true

var _appearance: Dictionary = {}
var _applied := false
var _time := 0.0
## Yaw of the model, in degrees.
var _yaw := 0.0
var _dragging := false
var _spin_pause := 0.0


func _ready() -> void:
    # The model is turned by dragging, so the mirror takes mouse input.
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_DRAG
    clip_contents = true
    gui_input.connect(_on_gui_input)

    var container := SubViewportContainer.new()
    container.name = "PreviewViewport"
    container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    container.stretch = true
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(container)

    _viewport = SubViewport.new()
    _viewport.size = Vector2i(360, 460)
    _viewport.transparent_bg = true
    _viewport.own_world_3d = true
    _viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    container.add_child(_viewport)

    _stage = Node3D.new()
    _stage.name = "Stage"
    _viewport.add_child(_stage)

    _character = CharacterModel.new()
    _character.name = "Character"
    _character.build()
    _stage.add_child(_character)
    _character.set_weapon(str(GameState.equipment.get("weapon", "")))
    if _character.animated:
        _character.play(CharacterModel.CLIP_IDLE, 1.0, 0.0)

    var pedestal := MeshInstance3D.new()
    pedestal.name = "Pedestal"
    var ring := TorusMesh.new()
    ring.inner_radius = 0.80
    ring.outer_radius = 0.94
    ring.rings = 40
    ring.ring_segments = 6
    pedestal.mesh = ring
    var pedestal_material := StandardMaterial3D.new()
    pedestal_material.albedo_color = Color(0.28, 0.62, 0.52, 0.42)
    pedestal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    pedestal_material.roughness = 0.35
    pedestal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    pedestal.material_override = pedestal_material
    _stage.add_child(pedestal)

    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.0, 0.0, 0.0, 0.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.80, 0.90, 0.86)
    env.ambient_light_energy = 1.15
    env_node.environment = env
    _viewport.add_child(env_node)

    var key_light := DirectionalLight3D.new()
    key_light.rotation_degrees = Vector3(-30.0, -26.0, 0.0)
    key_light.light_energy = 1.05
    _viewport.add_child(key_light)

    var rim_light := DirectionalLight3D.new()
    rim_light.rotation_degrees = Vector3(-12.0, 150.0, 0.0)
    rim_light.light_energy = 0.55
    rim_light.light_color = Color(0.72, 0.86, 1.0)
    _viewport.add_child(rim_light)

    var camera := Camera3D.new()
    camera.fov = 36.0
    camera.current = true
    _viewport.add_child(camera)
    camera.look_at_from_position(Vector3(0.0, 1.15, 3.30), Vector3(0.0, 0.98, 0.0), Vector3.UP)

    set_appearance({})


## Shows an outfit (owned or not) without touching the saved state.
func set_appearance(appearance: Dictionary) -> void:
    # The character sheet asks for the current look every frame, so ignore
    # requests that would rebuild the same rig.
    if _applied and appearance == _appearance:
        return
    _applied = true
    _appearance = appearance
    if _character != null:
        FashionVisuals.apply_outfit(_character.outfit_meshes, appearance)
    if _rig != null and is_instance_valid(_rig):
        FashionVisuals.dispose_rig(_rig)
    _rig = null
    if appearance.is_empty() or _stage == null:
        return
    _rig = FashionVisuals.build_rig(appearance)
    _stage.add_child(_rig)
    _character.mount_fashion_rig(_rig)


## Mirrors the equipped weapon so the silhouette matches the world.
func set_weapon(weapon_id: String) -> void:
    if _character != null:
        _character.set_weapon(weapon_id)


## A hidden mirror has nothing to show, so the skeleton stops ticking with it.
func _notification(what: int) -> void:
    if what != NOTIFICATION_VISIBILITY_CHANGED or _character == null:
        return
    _character.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
    if _stage == null or not is_visible_in_tree():
        return
    _time += delta
    if auto_spin and not _dragging:
        if _spin_pause > 0.0:
            _spin_pause = maxf(_spin_pause - delta, 0.0)
        else:
            _yaw = wrapf(_yaw + delta * SPIN_SPEED, 0.0, 360.0)
    _apply_yaw()
    FashionVisuals.animate(_rig, _time, 0.0)


## Drag with the left mouse button to turn the model by hand.
func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index != MOUSE_BUTTON_LEFT:
            return
        _dragging = button.pressed
        _spin_pause = 0.0 if _dragging else AUTO_SPIN_RESUME_DELAY
        accept_event()
    elif event is InputEventMouseMotion and _dragging:
        var motion := event as InputEventMouseMotion
        _yaw = wrapf(_yaw + motion.relative.x * DRAG_SENSITIVITY, 0.0, 360.0)
        _spin_pause = 0.0
        _apply_yaw()
        accept_event()


func _apply_yaw() -> void:
    var pose := _stage.rotation_degrees
    pose.y = _yaw
    _stage.rotation_degrees = pose
