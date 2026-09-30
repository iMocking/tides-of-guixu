extends Node3D
class_name GameWorld

const TERRAIN_GENERATOR_SCRIPT := preload("res://scripts/world/terrain_generator.gd")

var player: Player
var _camera: Camera3D
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _world_env: WorldEnvironment
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _fireflies: GPUParticles3D
var _terrain_generator
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 8.0
# Orbit camera tuning. Both camera modes share the same yaw/pitch so rotating
# the view feels identical, they only differ in their framing presets.
const INITIAL_ENEMY_COUNT := 12
const RESPAWN_POSITION := Vector3(0.0, 0.0, 0.0)
const CAMERA_PITCH_MIN := -0.25
const CAMERA_PITCH_MAX := 1.30
const CAMERA_DISTANCE_MIN := 6.0
const CAMERA_DISTANCE_MAX := 42.0
const CAMERA_TOPDOWN_YAW := 0.7853982
const CAMERA_TOPDOWN_PITCH := 0.75
const CAMERA_TOPDOWN_DISTANCE := 25.0
const CAMERA_THIRD_PERSON_PITCH := 0.32
const CAMERA_THIRD_PERSON_DISTANCE := 15.0
const CAMERA_DRAG_SCALE := 4.0

var _camera_distance := CAMERA_TOPDOWN_DISTANCE
var _yaw := CAMERA_TOPDOWN_YAW
var _pitch := CAMERA_TOPDOWN_PITCH
var _camera_shake := 0.0
var _rotate_drag := false
var _snap_camera := true
var _last_camera_mode := -1

func _ready() -> void:
    _rng.randomize()
    _build_environment()
    _setup_terrain()
    _build_ground()
    _build_props()
    _spawn_player()
    _spawn_npcs()
    _spawn_initial_enemies()
    _build_camera()
    EventBus.damage_number_requested.connect(_on_damage_number_requested)
    EventBus.camera_shake_requested.connect(_on_camera_shake_requested)
    EventBus.settings_changed.connect(_apply_camera_settings)
    _apply_camera_settings()

func get_player() -> Player:
    return player


func is_world_ready() -> bool:
    if player == null or _terrain_generator == null:
        return false
    return _terrain_generator.get_loaded_chunk_count() > 0

func _build_environment() -> void:
    _world_env = WorldEnvironment.new()
    _environment = Environment.new()
    _environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    _sky_material = ProceduralSkyMaterial.new()
    _sky_material.sky_top_color = Color(0.22, 0.40, 0.62)
    _sky_material.sky_horizon_color = Color(0.68, 0.78, 0.74)
    _sky_material.ground_bottom_color = Color(0.08, 0.12, 0.12)
    _sky_material.ground_horizon_color = Color(0.28, 0.36, 0.32)
    sky.sky_material = _sky_material
    _environment.sky = sky
    _environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    _environment.ambient_light_energy = 1.2
    _environment.fog_enabled = true
    _environment.fog_light_color = Color(0.48, 0.58, 0.58)
    _environment.fog_light_energy = 0.72
    _environment.fog_density = 0.005
    _environment.background_energy_multiplier = 1.25
    _environment.tonemap_exposure = 1.12
    _environment.adjustment_enabled = true
    _environment.adjustment_brightness = 1.20
    _environment.adjustment_contrast = 1.02
    _environment.adjustment_saturation = 1.08
    _world_env.environment = _environment
    add_child(_world_env)

    _sun = DirectionalLight3D.new()
    _sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
    _sun.light_energy = 1.55
    _sun.shadow_enabled = true
    add_child(_sun)

    var fill_light := DirectionalLight3D.new()
    fill_light.rotation_degrees = Vector3(-38.0, 142.0, 0.0)
    fill_light.light_color = Color(0.66, 0.76, 1.0)
    fill_light.light_energy = 0.38
    fill_light.shadow_enabled = false
    add_child(fill_light)

    _moon = DirectionalLight3D.new()
    _moon.rotation_degrees = Vector3(-58.0, 145.0, 0.0)
    _moon.light_color = Color(0.62, 0.72, 1.0)
    _moon.light_energy = 0.0
    _moon.shadow_enabled = false
    add_child(_moon)

    _fireflies = GPUParticles3D.new()
    _fireflies.amount = 90
    _fireflies.lifetime = 3.0
    _fireflies.emitting = false
    _fireflies.local_coords = false
    var firefly_material := ParticleProcessMaterial.new()
    firefly_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    firefly_material.emission_box_extents = Vector3(62.0, 10.0, 62.0)
    firefly_material.direction = Vector3.UP
    firefly_material.spread = 180.0
    firefly_material.initial_velocity_min = 0.05
    firefly_material.initial_velocity_max = 0.35
    firefly_material.gravity = Vector3.ZERO
    firefly_material.scale_min = 0.07
    firefly_material.scale_max = 0.16
    firefly_material.color = Color(0.78, 1.0, 0.38, 0.85)
    _fireflies.process_material = firefly_material
    var firefly_mesh := SphereMesh.new()
    firefly_mesh.radius = 0.06
    firefly_mesh.height = 0.12
    _fireflies.draw_pass_1 = firefly_mesh
    _fireflies.position = Vector3(0.0, 5.0, 0.0)
    add_child(_fireflies)

func _setup_terrain() -> void:
    _terrain_generator = TERRAIN_GENERATOR_SCRIPT.new()
    _terrain_generator.name = "TerrainGenerator"
    add_child(_terrain_generator)
    _terrain_generator.setup(_rng.randi())


func _sample_ground_height(x: float, z: float) -> float:
    if _terrain_generator == null:
        return 0.0
    return float(_terrain_generator.sample_height(x, z))


func _build_ground() -> void:
    # TerrainGenerator supplies the streamed ground mesh and collision.  The
    # original central dirt path remains as a cheap landmark for the flat
    # starting area.
    var path := MeshInstance3D.new()
    var path_mesh := PlaneMesh.new()
    path_mesh.size = Vector2(8.0, 120.0)
    path.mesh = path_mesh
    var path_material := StandardMaterial3D.new()
    path_material.albedo_color = Color(0.44, 0.37, 0.28)
    path_material.roughness = 1.0
    path.material_override = path_material
    path.position = Vector3(0.0, 0.005, 0.0)
    add_child(path)

func _build_props() -> void:
    for i in range(90):
        var angle := _rng.randf_range(0.0, TAU)
        var radius := _rng.randf_range(8.0, 78.0)
        var prop_position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        if prop_position.length() < 8.0:
            continue
        if i % 4 == 0:
            _add_tree(prop_position)
        elif i % 4 == 1:
            _add_rock(prop_position)
        else:
            _add_grass(prop_position)
    for i in range(26):
        var angle := _rng.randf_range(0.0, TAU)
        var radius := _rng.randf_range(92.0, 122.0)
        var mountain_position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        _add_mountain(mountain_position)

func _add_tree(position: Vector3) -> void:
    position.y = _sample_ground_height(position.x, position.z)
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.36
    trunk_mesh.height = _rng.randf_range(2.2, 3.2)
    trunk.mesh = trunk_mesh
    var trunk_material := StandardMaterial3D.new()
    trunk_material.albedo_color = Color(0.32, 0.22, 0.14)
    trunk.material_override = trunk_material
    trunk.position = position + Vector3(0.0, trunk_mesh.height * 0.5, 0.0)
    add_child(trunk)

    var canopy := MeshInstance3D.new()
    var canopy_mesh := SphereMesh.new()
    canopy_mesh.radius = _rng.randf_range(1.2, 2.1)
    canopy_mesh.height = canopy_mesh.radius * 2.0
    canopy.mesh = canopy_mesh
    var canopy_material := StandardMaterial3D.new()
    canopy_material.albedo_color = Color(0.20 + _rng.randf() * 0.10, 0.44 + _rng.randf() * 0.16, 0.22)
    canopy.material_override = canopy_material
    canopy.position = position + Vector3(0.0, trunk_mesh.height + canopy_mesh.radius * 0.65, 0.0)
    add_child(canopy)

func _add_rock(position: Vector3) -> void:
    position.y = _sample_ground_height(position.x, position.z)
    var rock := MeshInstance3D.new()
    var rock_mesh := BoxMesh.new()
    var size := Vector3(_rng.randf_range(0.5, 2.1), _rng.randf_range(0.35, 1.25), _rng.randf_range(0.5, 2.1))
    rock_mesh.size = size
    rock.mesh = rock_mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.34, 0.38, 0.34)
    material.roughness = 0.95
    rock.material_override = material
    rock.position = position + Vector3(0.0, size.y * 0.5, 0.0)
    rock.rotation_degrees = Vector3(_rng.randf_range(-8.0, 8.0), _rng.randf_range(0.0, 360.0), _rng.randf_range(-8.0, 8.0))
    add_child(rock)

func _add_grass(position: Vector3) -> void:
    position.y = _sample_ground_height(position.x, position.z)
    var grass := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(_rng.randf_range(0.35, 0.65), _rng.randf_range(0.5, 0.9))
    grass.mesh = quad
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.21 + _rng.randf() * 0.09, 0.38 + _rng.randf() * 0.15, 0.22)
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.roughness = 1.0
    grass.material_override = material
    grass.position = position + Vector3(0.0, quad.size.y * 0.5, 0.0)
    grass.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
    add_child(grass)

func _add_mountain(position: Vector3) -> void:
    position.y = _sample_ground_height(position.x, position.z)
    var mountain := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = _rng.randf_range(9.0, 18.0)
    mesh.height = _rng.randf_range(24.0, 46.0)
    mountain.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.24, 0.29, 0.31)
    material.roughness = 1.0
    mountain.material_override = material
    mountain.position = position + Vector3(0.0, mesh.height * 0.5 - 4.0, 0.0)
    mountain.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
    add_child(mountain)

func _spawn_player() -> void:
    player = Player.new()
    player.position = Vector3(0.0, _sample_ground_height(0.0, 0.0), 0.0)
    add_child(player)

func _spawn_npcs() -> void:
    for npc_id in GameData.NPCS.keys():
        var data := GameData.npc(str(npc_id))
        var position: Variant = data.get("position", {})
        var npc := NPC.new()
        npc.setup(str(npc_id))
        if position is Dictionary:
            npc.position = Vector3(float(position.get("x", 6.0)), 0.0, float(position.get("z", -7.0)))
            npc.position.y = _sample_ground_height(npc.position.x, npc.position.z) + float(position.get("y", 0.0))
        add_child(npc)

func _spawn_initial_enemies() -> void:
    for i in range(INITIAL_ENEMY_COUNT):
        _spawn_enemy()

func _spawn_enemy() -> void:
    var angle := _rng.randf_range(0.0, TAU)
    var radius := _rng.randf_range(12.0, 48.0)
    var x := cos(angle) * radius
    var z := sin(angle) * radius
    var enemy := Enemy.new()
    enemy.setup(GameData.random_enemy_id(GameState.realm_index, _rng), _rng)
    enemy.position = Vector3(x, _sample_ground_height(x, z), z)
    add_child(enemy)

func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.fov = float(GameState.settings.get("camera_fov", 55.0))
    _camera.current = true
    add_child(_camera)

func _process(delta: float) -> void:
    if player != null and _terrain_generator != null:
        _terrain_generator.update_stream(player.global_position)
    _spawn_timer -= delta
    if _spawn_timer <= 0.0:
        _spawn_timer = 24.0
        if get_tree().get_nodes_in_group("enemies").size() < 16:
            _spawn_enemy()
    _update_day_night(delta)
    _handle_camera_keys(delta)
    _update_camera(delta)
    if Input.is_action_just_pressed("toggle_camera"):
        _toggle_camera_mode()

func _update_day_night(_delta: float) -> void:
    if _sun == null or _environment == null or _sky_material == null:
        return
    var hour := float(int(GameState.game_time.get("hour", 12))) + float(int(GameState.game_time.get("minute", 0))) / 60.0
    var sun_factor := clampf(sin((hour - 6.0) / 24.0 * TAU), -1.0, 1.0)
    var daylight := clampf((sun_factor + 1.0) * 0.5, 0.0, 1.0)
    _sun.light_energy = daylight * 1.55
    _sun.light_color = Color(1.0, 0.96, 0.86)
    _sun.rotation_degrees.x = -80.0 + 160.0 * clampf((hour - 6.0) / 12.0, 0.0, 1.0)
    _moon.light_energy = (1.0 - daylight) * 0.22
    _sky_material.sky_top_color = Color(0.05, 0.07, 0.15).lerp(Color(0.27, 0.46, 0.70), daylight)
    _sky_material.sky_horizon_color = Color(0.10, 0.12, 0.20).lerp(Color(0.78, 0.87, 0.83), daylight)
    _sky_material.ground_bottom_color = Color(0.025, 0.03, 0.045).lerp(Color(0.12, 0.16, 0.15), daylight)
    _sky_material.ground_horizon_color = Color(0.06, 0.075, 0.105).lerp(Color(0.44, 0.52, 0.46), daylight)
    _environment.ambient_light_energy = 0.40 + daylight * 0.80
    _environment.fog_density = lerpf(0.011, 0.0035, daylight)
    _environment.fog_light_color = Color(0.08, 0.10, 0.15).lerp(Color(0.48, 0.58, 0.56), daylight)
    _fireflies.emitting = daylight < 0.22

func _update_camera(delta: float) -> void:
    if _camera == null or player == null:
        return
    var target := player.global_position + Vector3.UP * 1.25
    var direction := Vector3(cos(_pitch) * sin(_yaw), sin(_pitch), cos(_pitch) * cos(_yaw))
    var desired := _resolve_camera_collision(target, target + direction * _camera_distance)
    var weight := 1.0
    if not _snap_camera:
        weight = clampf(1.0 - exp(-12.0 * delta), 0.0, 1.0)
    _camera.global_position = _camera.global_position.lerp(desired, weight)
    _snap_camera = false
    _camera.look_at(target, Vector3.UP)
    if _camera_shake > 0.001:
        _camera.global_position += Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _camera_shake
        _camera_shake = maxf(0.0, _camera_shake - delta * 1.6)

## Keyboard rotation (Q / E) and view reset (R).

func _handle_camera_keys(delta: float) -> void:
    if get_tree().paused:
        return
    var rotate := Input.get_axis("camera_rotate_left", "camera_rotate_right")
    if absf(rotate) > 0.001:
        var speed := deg_to_rad(float(GameState.settings.get("camera_rotate_speed", 110.0)))
        _yaw -= rotate * speed * delta
    if Input.is_action_just_pressed("camera_reset"):
        _apply_camera_preset(int(GameState.settings.get("camera_mode", 0)), true)
        EventBus.toast_requested.emit(LocaleData.text("camera_reset_toast"), Color(0.72, 0.90, 1.0))

## Shared mouse-look maths for captured mouse and right/middle button dragging.

func _rotate_camera(delta: Vector2) -> void:
    if delta == Vector2.ZERO:
        return
    _yaw -= delta.x
    var invert := -1.0 if bool(GameState.settings.get("invert_y", false)) else 1.0
    _pitch = clampf(_pitch + delta.y * invert, CAMERA_PITCH_MIN, CAMERA_PITCH_MAX)

## Pulls the camera closer when static geometry blocks the view and keeps it
## above the ground.

func _resolve_camera_collision(origin: Vector3, desired: Vector3) -> Vector3:
    var space := get_world_3d().direct_space_state
    if space != null:
        var query := PhysicsRayQueryParameters3D.create(origin, desired)
        query.hit_from_inside = false
        if player is CollisionObject3D:
            query.exclude = [(player as CollisionObject3D).get_rid()]
        var hit := space.intersect_ray(query)
        if not hit.is_empty() and hit.get("collider") is StaticBody3D:
            var hit_position: Vector3 = hit.get("position", desired)
            var offset := hit_position - origin
            if offset.length() > 1.0:
                desired = origin + offset.normalized() * maxf(offset.length() - 0.4, 1.0)
    desired.y = maxf(desired.y, _sample_ground_height(desired.x, desired.z) + 0.9)
    return desired

## Applies the framing preset of a camera mode, optionally resetting the yaw.

func _apply_camera_preset(mode: int, reset_yaw: bool) -> void:
    if mode == 1:
        _camera_distance = CAMERA_THIRD_PERSON_DISTANCE
        _pitch = CAMERA_THIRD_PERSON_PITCH
    else:
        _camera_distance = CAMERA_TOPDOWN_DISTANCE
        _pitch = CAMERA_TOPDOWN_PITCH
    if reset_yaw:
        _yaw = CAMERA_TOPDOWN_YAW
    _pitch = clampf(_pitch, CAMERA_PITCH_MIN, CAMERA_PITCH_MAX)
    _snap_camera = true

func _toggle_camera_mode() -> void:
    var next_mode := 1 if int(GameState.settings.get("camera_mode", 0)) == 0 else 0
    GameState.set_setting("camera_mode", next_mode)
    EventBus.toast_requested.emit(LocaleData.text("camera_mode") + ": " + LocaleData.text("camera_top_down" if next_mode == 0 else "camera_third_person"), Color(0.72, 0.90, 1.0))

func _unhandled_input(event: InputEvent) -> void:
    if get_tree().paused:
        return
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        var sensitivity := float(GameState.settings.get("mouse_sensitivity", 0.0025))
        var mode := int(GameState.settings.get("camera_mode", 0))
        if mode == 1 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            _rotate_camera(motion.relative * sensitivity)
        elif _rotate_drag:
            _rotate_camera(motion.relative * sensitivity * CAMERA_DRAG_SCALE)
        return
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
            _camera_distance = clampf(_camera_distance - 1.2, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)
        elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
            _camera_distance = clampf(_camera_distance + 1.2, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)
        elif button.button_index == MOUSE_BUTTON_MIDDLE or button.button_index == MOUSE_BUTTON_RIGHT:
            _rotate_drag = button.pressed

func _apply_camera_settings() -> void:
    if _camera != null:
        _camera.fov = float(GameState.settings.get("camera_fov", 55.0))
    _apply_display_settings()
    var mode := int(GameState.settings.get("camera_mode", 0))
    if mode != _last_camera_mode:
        _last_camera_mode = mode
        _apply_camera_preset(mode, false)
    if mode == 1 and not get_tree().paused:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Brightness / screen filter / fog / shadows driven by the settings panel.
func _apply_display_settings() -> void:
    if _environment == null:
        return
    var preset := GameState.get_filter_preset()
    var base_brightness := float(GameState.DEFAULT_SETTINGS.get("brightness", 1.2))
    var user_brightness := float(GameState.settings.get("brightness", base_brightness))
    _environment.adjustment_enabled = true
    _environment.adjustment_saturation = float(preset[0])
    _environment.adjustment_contrast = float(preset[1])
    _environment.adjustment_brightness = float(preset[2]) * (user_brightness / maxf(base_brightness, 0.01))
    _environment.fog_enabled = bool(GameState.settings.get("fog", true))
    if _sun != null:
        _sun.shadow_enabled = bool(GameState.settings.get("shadows", true))


func _on_camera_shake_requested(amount: float) -> void:
    var scale := float(GameState.combat_fx_level()) / 2.0
    if scale <= 0.0:
        return
    _camera_shake = maxf(_camera_shake, amount * scale)

func _on_damage_number_requested(amount: float, global_position: Vector3, is_crit: bool, element: String) -> void:
    if GameState.combat_fx_level() <= 0:
        return
    if not bool(GameState.settings.get("show_damage_numbers", true)):
        return
    var label := Label3D.new()
    label.text = "-%d" % int(maxf(amount, 1.0))
    if is_crit:
        label.text = LocaleData.text("crit") + " -%d" % int(maxf(amount, 1.0))
    ThemeBuilder.style_world_label(label, 42 if is_crit else 34, GameData.element_color(element))
    label.position = global_position
    add_child(label)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", global_position + Vector3(0.0, 1.6, 0.0), 0.75)
    tween.tween_property(label, "modulate:a", 0.0, 0.75)
    tween.chain().tween_callback(label.queue_free)