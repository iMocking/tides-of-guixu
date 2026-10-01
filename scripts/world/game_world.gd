extends Node3D
class_name GameWorld

const TERRAIN_GENERATOR_SCRIPT := preload("res://scripts/world/terrain_generator.gd")
const TERRAIN3D_WORLD_SCRIPT := preload("res://scripts/world/terrain3d_world.gd")
const WORLD_FEATURES_SCRIPT := preload("res://scripts/world/world_features.gd")

var player: Player
var _camera: Camera3D
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _world_env: WorldEnvironment
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _fireflies: GPUParticles3D
## Active terrain back end: `Terrain3DWorld` when the Terrain3D addon loaded,
## the streamed placeholder `TerrainGenerator` otherwise.
var _terrain
var _terrain3d
var _features
var _world_seed := 0
var _terrain_ready := false
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
    _world_seed = _rng.randi()
    _build_environment()
    _setup_terrain()
    _build_ground()
    _spawn_player()
    _spawn_npcs()
    _spawn_initial_enemies()
    _build_camera()
    EventBus.damage_number_requested.connect(_on_damage_number_requested)
    EventBus.camera_shake_requested.connect(_on_camera_shake_requested)
    EventBus.settings_changed.connect(_apply_camera_settings)
    _apply_camera_settings()
    # The terrain back end may still be streaming; the props, the spawn heights
    # and the loading bar all wait on it.
    _watch_terrain()

func get_player() -> Player:
    return player


func is_world_ready() -> bool:
    return player != null and _terrain != null and _terrain_ready and _features != null


## 0..1 loading progress of the terrain back end, driven by the loading screen.
func get_load_progress() -> float:
    if is_world_ready():
        return 1.0
    if _terrain != null and _terrain.has_method("get_progress"):
        return clampf(0.08 + float(_terrain.get_progress()) * 0.86, 0.0, 0.96)
    return 0.08


## Name of the live terrain back end, so the loading log can say which one ran.
func get_terrain_backend_name() -> String:
    if _terrain3d != null:
        return "Terrain3D"
    return "TerrainGenerator"


## Number of clipmap regions / streamed chunks currently built.
func get_terrain_region_count() -> int:
    if _terrain != null and _terrain.has_method("get_loaded_chunk_count"):
        return int(_terrain.get_loaded_chunk_count())
    return 0


func get_world_features() -> Node3D:
    return _features

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

## Prefers the Terrain3D clipmap and falls back to the streamed placeholder
## mesh when the addon is unavailable for the running engine build.
func _setup_terrain() -> void:
    if TERRAIN3D_WORLD_SCRIPT.is_supported():
        _terrain3d = TERRAIN3D_WORLD_SCRIPT.new()
        _terrain3d.name = "Terrain3DWorld"
        add_child(_terrain3d)
        _terrain = _terrain3d
        _terrain3d.start(_world_seed)
        return

    _terrain = TERRAIN_GENERATOR_SCRIPT.new()
    _terrain.name = "TerrainGenerator"
    add_child(_terrain)
    _terrain.setup(_world_seed)


## Terrain3D builds its clipmap over several frames; wait for it, then dress the
## map with the forests, the lake, the village and the cave.
func _watch_terrain() -> void:
    if _terrain == null:
        return
    while not _terrain.is_ready():
        if not is_inside_tree():
            return
        await get_tree().process_frame
    await _on_terrain_ready()


func _on_terrain_ready() -> void:
    _terrain_ready = true
    if _terrain3d != null and _camera != null:
        _terrain3d.set_camera(_camera)
    _features = WORLD_FEATURES_SCRIPT.new()
    _features.name = "WorldFeatures"
    add_child(_features)
    _features.build(_terrain.field, _world_seed, _terrain)
    _reseat_actors()
    _release_actors()
    EventBus.combat_log.emit(LocaleData.text("world_map_ready") + "  ·  " + get_terrain_backend_name())
    if _terrain3d == null:
        EventBus.combat_log.emit(LocaleData.text("world_terrain_fallback"))


## Drops everything that spawned before the terrain existed back onto it.
func _reseat_actors() -> void:
    if player != null:
        player.global_position = Vector3(
            player.global_position.x,
            _sample_ground_height(player.global_position.x, player.global_position.z) + 0.25,
            player.global_position.z)
        if player is CharacterBody3D:
            (player as CharacterBody3D).velocity = Vector3.ZERO
    for node in get_tree().get_nodes_in_group("npcs"):
        if node is Node3D:
            var npc := node as Node3D
            npc.global_position.y = _sample_ground_height(npc.global_position.x, npc.global_position.z)
    for node in get_tree().get_nodes_in_group("enemies"):
        if node is Node3D:
            var mob := node as Node3D
            mob.global_position.y = _sample_ground_height(mob.global_position.x, mob.global_position.z) + 0.2


## Actors spawned during loading sit out the wait so they cannot fall through a
## world that has not finished streaming its collision yet.
func _release_actors() -> void:
    if player != null:
        player.set_physics_process(true)
    for node in get_tree().get_nodes_in_group("enemies"):
        if node is CollisionObject3D:
            (node as CollisionObject3D).set_physics_process(true)


func _sample_ground_height(x: float, z: float) -> float:
    if _terrain == null:
        return 0.0
    return float(_terrain.sample_height(x, z))


func _build_ground() -> void:
    # TerrainGenerator supplies the streamed ground mesh and collision.  The
    # original central dirt path remains as a cheap landmark for the flat
    # starting area.
    var path := MeshInstance3D.new()
    path.name = "StartPath"
    var path_mesh := PlaneMesh.new()
    path_mesh.size = Vector2(6.0, 74.0)
    path.mesh = path_mesh
    var path_material := StandardMaterial3D.new()
    path_material.albedo_color = Color(0.44, 0.37, 0.28)
    path_material.roughness = 1.0
    path.material_override = path_material
    path.position = Vector3(0.0, _sample_ground_height(0.0, 0.0) + 0.03, 0.0)
    add_child(path)

func _spawn_player() -> void:
    player = Player.new()
    player.position = Vector3(0.0, _sample_ground_height(0.0, 0.0), 0.0)
    add_child(player)
    player.set_physics_process(false)

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
    enemy.position = Vector3(x, _sample_ground_height(x, z) + 0.2, z)
    add_child(enemy)
    enemy.set_physics_process(_terrain_ready)

func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.fov = float(GameState.settings.get("camera_fov", 55.0))
    _camera.current = true
    add_child(_camera)
    if _terrain3d != null:
        _terrain3d.set_camera(_camera)

func _process(delta: float) -> void:
    if player != null and _terrain != null:
        _terrain.update_stream(player.global_position)
    _spawn_timer -= delta
    if _spawn_timer <= 0.0:
        _spawn_timer = 24.0
        if get_tree().get_nodes_in_group("enemies").size() < 16:
            _spawn_enemy()
    _update_day_night(delta)
    _handle_camera_keys(delta)
    _update_camera(delta)
    _update_cursor_peek()
    if Input.is_action_just_pressed("toggle_camera"):
        _toggle_camera_mode()

## Polled rather than event driven: holding the peek key shows the cursor at
## once, releasing it hands the mouse back, and a panel opening or closing in
## between can never leave the mode stuck.
func _update_cursor_peek() -> void:
    if get_tree().paused:
        return
    GameState.apply_mouse_mode(false)


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
    GameState.apply_mouse_mode(get_tree().paused)

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