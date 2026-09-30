extends CharacterBody3D
class_name Player

var max_health := 100.0
var max_qi := 50.0
var attack := 10.0
var defense := 5.0
var move_speed := 6.0
var crit_chance := 0.05
var crit_damage := 1.5
var attack_cooldown := 0.0
var skill_cooldowns: Dictionary = {}
var damage_reduction := 0.0
var buff_timer := 0.0
var _move_direction := Vector3.ZERO
var _last_move_direction := Vector3.FORWARD
var _character: CharacterModel
var _model_root: Node3D
var _fashion_rig: Node3D
var _name_label: Label3D
var _fashion_speed := 0.0
## Weapon of the procedural fallback body; the animated body grips it on a bone
## socket inside CharacterModel instead.
var _weapon_model: MeshInstance3D

const JUMP_VELOCITY := 8.0
## The old blink was 0.32 s; the authored Dodge clip is 1 s long, so the dash is
## stretched to half a second at a lower speed - same 4.8 m of ground covered -
## and the clip is played slightly fast to fit.
const DODGE_SPEED := 9.6
const DODGE_DURATION := 0.5
const DODGE_ANIM_SPEED := 1.5
const DODGE_COOLDOWN := 0.85
## Playback speed of the shared knife swing when it stands in for a spell cast.
const CAST_ANIM_SPEED := 1.3
const COMBAT_TARGET_RANGE := 15.0
const COMBAT_EXIT_DELAY := 2.5
const COMBAT_FACING_SPEED := 14.0

var _anim_time := 0.0
var _action_state := ""
var _action_timer := 0.0
var _action_duration := 0.0
var _dodge_timer := 0.0
var _dodge_cooldown := 0.0
var _dodge_direction := Vector3.ZERO
var _death_anim_started := false
var _death_tween: Tween
var _in_combat := false
var _combat_target: Node3D = null
var _combat_exit_timer := 0.0

func _ready() -> void:
    add_to_group("player")
    _build_body()
    _refresh_weapon_model()
    _refresh_fashion()
    refresh_stats()
    GameState.health = minf(GameState.health, max_health)
    GameState.qi = minf(GameState.qi, max_qi)
    EventBus.player_stats_changed.connect(refresh_stats)
    EventBus.equipment_changed.connect(refresh_stats)
    EventBus.equipment_changed.connect(_refresh_weapon_model)
    EventBus.fashion_changed.connect(_refresh_fashion)
    EventBus.inventory_changed.connect(refresh_stats)
    EventBus.player_died.connect(_on_player_died)

func _build_body() -> void:
    # A slim capsule for the slim rigged character (~1.94 m once scaled).
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.75
    collision.shape = capsule
    collision.position = Vector3(0.0, 0.875, 0.0)
    add_child(collision)

    _model_root = Node3D.new()
    _model_root.name = "ModelRoot"
    add_child(_model_root)

    _character = CharacterModel.new()
    _character.name = "Character"
    _character.build()
    _model_root.add_child(_character)

    var name_label := Label3D.new()
    name_label.text = GameState.player_name
    name_label.position = Vector3(0.0, 2.05, 0.0)
    ThemeBuilder.style_world_label(name_label, 32, Color(0.80, 1.0, 0.88))
    add_child(name_label)
    _name_label = name_label


## True when the body is animation driven (the rigged GLB could be loaded).
func is_animated() -> bool:
    return _character != null and _character.animated


func _refresh_weapon_model() -> void:
    if _character == null:
        return
    _character.set_weapon(str(GameState.equipment.get("weapon", "")))
    _weapon_model = _character.weapon_mesh


## Cosmetic layer: recolours the clothing and (re)builds the accessory rig.
## Runs whenever the worn outfit, its dye or its aura toggle changes.
func _refresh_fashion() -> void:
    if _character == null:
        return
    var appearance := GameState.fashion_appearance()
    FashionVisuals.apply_outfit(_character.outfit_meshes, appearance)
    if _fashion_rig != null and is_instance_valid(_fashion_rig):
        FashionVisuals.dispose_rig(_fashion_rig)
    _fashion_rig = null
    if appearance.is_empty():
        if _name_label != null:
            _name_label.modulate = Color(0.80, 1.0, 0.88)
        return
    _fashion_rig = FashionVisuals.build_rig(appearance)
    _model_root.add_child(_fashion_rig)
    _character.mount_fashion_rig(_fashion_rig)
    if _name_label != null:
        var colors: Dictionary = appearance.get("colors", {})
        var glow: Color = colors.get("glow", Color.WHITE)
        _name_label.modulate = Color(glow.r, glow.g, glow.b).lightened(0.30)


func refresh_stats() -> void:
    var total := GameState.get_total_stats()
    max_health = float(total["max_health"])
    max_qi = float(total["max_qi"])
    attack = float(total["attack"])
    defense = float(total["defense"])
    move_speed = float(total["move_speed"])
    crit_chance = float(total["crit_chance"])
    crit_damage = float(total["crit_damage"])
    GameState.health = minf(GameState.health, max_health)
    GameState.qi = minf(GameState.qi, max_qi)

func _physics_process(delta: float) -> void:
    if GameState.health <= 0.0:
        _play_death_animation()
        velocity = Vector3.ZERO
        move_and_slide()
        return
    _update_combat_state(delta)
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    for key in skill_cooldowns.keys():
        skill_cooldowns[key] = maxf(0.0, float(skill_cooldowns[key]) - delta)
    buff_timer = maxf(0.0, buff_timer - delta)
    _dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
    _action_timer = maxf(0.0, _action_timer - delta)
    if _action_timer <= 0.0:
        _action_state = ""
    if buff_timer <= 0.0:
        damage_reduction = 0.0
    _handle_input()
    _handle_actions()
    _handle_movement(delta)
    _update_animation(delta)

func _handle_input() -> void:
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var cam := get_viewport().get_camera_3d()
    var forward := Vector3.FORWARD
    var right := Vector3.RIGHT
    if cam != null:
        forward = -cam.global_transform.basis.z
        forward.y = 0.0
        right = cam.global_transform.basis.x
        right.y = 0.0
    forward = forward.normalized()
    right = right.normalized()
    # W/Up gives input.y = -1; subtract so it moves along camera forward.
    _move_direction = (right * input.x - forward * input.y).normalized()
    if _move_direction.length() > 0.05:
        _last_move_direction = _move_direction

func _handle_movement(delta: float) -> void:
    var target_velocity := Vector3.ZERO
    if _dodge_timer > 0.0:
        _dodge_timer = maxf(0.0, _dodge_timer - delta)
        target_velocity = _dodge_direction * DODGE_SPEED
        if not _in_combat:
            rotation.y = atan2(_dodge_direction.x, _dodge_direction.z)
    elif _move_direction.length() > 0.05:
        target_velocity = _move_direction * move_speed
        if not _in_combat:
            var target_angle := atan2(_move_direction.x, _move_direction.z)
            rotation.y = lerp_angle(rotation.y, target_angle, clampf(delta * 12.0, 0.0, 1.0))
    if _in_combat:
        _face_combat_target(delta)
    velocity.x = target_velocity.x
    velocity.z = target_velocity.z
    if not is_on_floor() or velocity.y > 0.0:
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _handle_actions() -> void:
    var dodge_pressed := Input.is_action_just_pressed("dodge")
    if dodge_pressed and _dodge_cooldown <= 0.0 and _dodge_timer <= 0.0:
        _start_dodge()
    if Input.is_action_just_pressed("jump") and not dodge_pressed and is_on_floor() and _dodge_timer <= 0.0:
        velocity.y = JUMP_VELOCITY
    if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and get_viewport().gui_get_hovered_control() == null:
        attack_cooldown = 0.65
        _set_action("attack", 0.35)
        _melee_attack(1.0, 3.0, "none")
    if Input.is_action_just_pressed("skill_1"):
        _cast_skill("skill_1")
    if Input.is_action_just_pressed("skill_2"):
        _cast_skill("skill_2")
    if Input.is_action_just_pressed("skill_3"):
        _cast_skill("skill_3")
    if Input.is_action_just_pressed("skill_4"):
        _cast_skill("skill_4")
    if Input.is_action_just_pressed("ultimate"):
        _cast_skill("ultimate")
    if Input.is_action_just_pressed("interact"):
        _interact()

func is_in_combat() -> bool:
    return _in_combat


func get_combat_target() -> Node3D:
    return _combat_target


func _update_combat_state(delta: float) -> void:
    var best_target: Node3D = null
    var best_distance := COMBAT_TARGET_RANGE
    for enemy_node in get_tree().get_nodes_in_group("enemies"):
        if not (enemy_node is Node3D):
            continue
        var enemy: Node3D = enemy_node
        if not is_instance_valid(enemy):
            continue
        var enemy_health: Variant = enemy.get("health")
        if enemy_health != null and float(enemy_health) <= 0.0:
            continue
        var distance := global_position.distance_to(enemy.global_position)
        if distance < best_distance:
            best_distance = distance
            best_target = enemy

    if best_target != null:
        _combat_target = best_target
        _combat_exit_timer = COMBAT_EXIT_DELAY
        _in_combat = true
    elif _in_combat:
        _combat_exit_timer = maxf(0.0, _combat_exit_timer - delta)
        if _combat_exit_timer <= 0.0:
            _in_combat = false
            _combat_target = null


func _face_combat_target(delta: float) -> void:
    if _combat_target == null or not is_instance_valid(_combat_target):
        return
    var direction := _combat_target.global_position - global_position
    direction.y = 0.0
    if direction.length() < 0.1:
        return
    var target_angle := atan2(direction.x, direction.z)
    rotation.y = lerp_angle(rotation.y, target_angle, clampf(delta * COMBAT_FACING_SPEED, 0.0, 1.0))


func _start_dodge() -> void:
    var direction := _move_direction
    if direction.length() < 0.1:
        direction = _last_move_direction
    direction.y = 0.0
    _dodge_direction = direction.normalized()
    _dodge_timer = DODGE_DURATION
    _dodge_cooldown = DODGE_COOLDOWN
    _set_action("dodge", DODGE_DURATION)


## Starts an action.  With an animated body the action window follows the clip,
## so the swing or the dodge step is always played out in full.
func _set_action(state_name: String, duration: float) -> void:
    var window := duration
    if is_animated():
        var clip := _action_clip(state_name)
        if clip != "":
            var speed := CAST_ANIM_SPEED if state_name == "cast" else 1.0
            if state_name == "dodge":
                speed = DODGE_ANIM_SPEED
            if _character.restart(clip, speed, 0.10):
                window = maxf(_character.clip_length(clip) / speed, 0.1)
    _action_state = state_name
    _action_timer = window
    _action_duration = maxf(window, 0.001)


func _action_clip(state_name: String) -> String:
    match state_name:
        "attack", "cast":
            return CharacterModel.CLIP_ATTACK
        "dodge":
            return CharacterModel.CLIP_DODGE
    return ""


func _update_animation(delta: float) -> void:
    if _model_root == null:
        return
    _anim_time += delta
    _fashion_speed = 1.0 if _move_direction.length() > 0.05 else 0.0
    FashionVisuals.animate(_fashion_rig, _anim_time, _fashion_speed)

    if is_animated():
        _update_animated_pose()
        return

    _model_root.position = Vector3.ZERO
    _model_root.rotation = Vector3.ZERO
    if _weapon_model != null:
        _weapon_model.position = CharacterModel.WEAPON_REST_POSITION
        _weapon_model.rotation_degrees = CharacterModel.WEAPON_REST_ROTATION

    if _action_timer > 0.0:
        var action_t := 1.0 - clampf(_action_timer / _action_duration, 0.0, 1.0)
        match _action_state:
            "attack":
                _apply_attack_pose(action_t)
            "cast":
                _apply_cast_pose(action_t)
            "dodge":
                _apply_dodge_pose(action_t)
        return

    if not is_on_floor():
        _apply_jump_pose()
    elif _move_direction.length() > 0.05:
        _apply_run_pose()
    else:
        _apply_idle_pose()


## Animation-driven body: the clips own the pose, so the state machine only has
## to pick which one should be playing.  Action clips are started once by
## _set_action(), which is why nothing is triggered for them here.
func _update_animated_pose() -> void:
    if _action_timer > 0.0:
        return
    if not is_on_floor():
        _character.play(CharacterModel.CLIP_JUMP, 1.0, 0.15)
    elif _move_direction.length() > 0.05:
        _character.play(CharacterModel.CLIP_RUN, 1.0, 0.18)
    else:
        _character.play(CharacterModel.CLIP_IDLE, 1.0, 0.20)


func _apply_idle_pose() -> void:
    _model_root.position.y = sin(_anim_time * 2.0) * 0.012
    _model_root.rotation.z = sin(_anim_time * 1.3) * 0.01


func _apply_run_pose() -> void:
    _model_root.position.y = absf(sin(_anim_time * 10.0)) * 0.075
    _model_root.rotation.x = -0.10
    _model_root.rotation.z = sin(_anim_time * 5.0) * 0.035
    if _weapon_model != null:
        _weapon_model.rotation_degrees = CharacterModel.WEAPON_REST_ROTATION + Vector3(0.0, 0.0, sin(_anim_time * 5.0) * 4.0)


func _apply_jump_pose() -> void:
    var t := clampf(velocity.y / JUMP_VELOCITY, -1.0, 1.0)
    _model_root.rotation.x = -0.14 * t
    _model_root.position.y = clampf(velocity.y * 0.012, -0.08, 0.08)


func _apply_attack_pose(t: float) -> void:
    var arc := sin(t * PI)
    _model_root.position.z = -0.14 * arc
    _model_root.rotation.x = -0.22 * arc
    if _weapon_model != null:
        _weapon_model.rotation_degrees = CharacterModel.WEAPON_REST_ROTATION + Vector3(-95.0 * arc, 25.0 * arc, 18.0 * arc)


func _apply_cast_pose(t: float) -> void:
    var arc := sin(t * PI)
    _model_root.position.y = 0.08 * arc
    _model_root.rotation.x = -0.10 * arc
    if _weapon_model != null:
        _weapon_model.rotation_degrees = CharacterModel.WEAPON_REST_ROTATION + Vector3(-45.0 * arc, 12.0 * arc, 0.0)


func _apply_dodge_pose(t: float) -> void:
    _model_root.rotation.x = -TAU * t
    _model_root.position.y = sin(t * PI) * 0.35


func _on_player_died() -> void:
    _play_death_animation()


func _play_death_animation() -> void:
    if _death_anim_started or _model_root == null:
        return
    _death_anim_started = true
    _action_state = ""
    _action_timer = 0.0
    _model_root.position = Vector3.ZERO
    _model_root.rotation = Vector3.ZERO
    _model_root.process_mode = Node.PROCESS_MODE_ALWAYS
    if is_animated():
        # The authored clip staggers, buckles and falls; PROCESS_MODE_ALWAYS
        # keeps it playing while the death panel has the tree paused.
        _character.restart(CharacterModel.CLIP_DEATH, 1.0, 0.08)
        return
    if _weapon_model != null:
        _weapon_model.position = CharacterModel.WEAPON_REST_POSITION
        _weapon_model.rotation_degrees = CharacterModel.WEAPON_REST_ROTATION + Vector3(-35.0, 0.0, -20.0)
    if _death_tween != null and _death_tween.is_valid():
        _death_tween.kill()
    _death_tween = create_tween()
    _death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _death_tween.set_parallel(true)
    _death_tween.tween_property(_model_root, "rotation", Vector3(deg_to_rad(-88.0), 0.0, 0.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _death_tween.tween_property(_model_root, "position", Vector3(0.0, 0.0, 0.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _interact() -> void:
    var nearest_npc: Node3D = null
    var nearest_npc_distance := 3.8
    for npc_node in get_tree().get_nodes_in_group("npcs"):
        if not (npc_node is Node3D):
            continue
        var npc: Node3D = npc_node
        var npc_distance := global_position.distance_to(npc.global_position)
        if npc_distance < nearest_npc_distance:
            nearest_npc = npc
            nearest_npc_distance = npc_distance
    if nearest_npc != null and nearest_npc.has_method("interact"):
        nearest_npc.call("interact")
        return
    var nearest_loot: Node3D = null
    var nearest_loot_distance := 5.0
    for orb_node in get_tree().get_nodes_in_group("loot"):
        if not (orb_node is Node3D):
            continue
        var orb: Node3D = orb_node
        var orb_distance := global_position.distance_to(orb.global_position)
        if orb_distance < nearest_loot_distance:
            nearest_loot = orb
            nearest_loot_distance = orb_distance
    if nearest_loot != null and nearest_loot.has_method("collect"):
        nearest_loot.call("collect")

func _cast_skill(id: String) -> void:
    var skill := GameData.skill(id)
    if skill.is_empty():
        return
    var qi_cost := float(skill.get("qi", 0.0))
    var cooldown := float(skill.get("cooldown", 1.0))
    if float(skill_cooldowns.get(id, 0.0)) > 0.0:
        return
    if qi_cost > 0.0 and not GameState.spend_qi(qi_cost):
        EventBus.toast_requested.emit(LocaleData.text("no_qi"), Color(0.95, 0.55, 0.45))
        return
    skill_cooldowns[id] = cooldown
    _set_action("cast", 0.45)
    var element := str(skill.get("element", "none"))
    if element != "none":
        GameState.record_element_cast(element)
    var skill_type := str(skill.get("type", "melee"))
    if skill_type == "melee":
        _melee_attack(float(skill.get("damage", 1.0)), float(skill.get("range", 3.0)), element)
    elif skill_type == "projectile":
        _fire_projectile(skill)
    elif skill_type == "aoe":
        _aoe_attack(float(skill.get("damage", 1.0)), float(skill.get("radius", 5.0)), element)
    elif skill_type == "buff":
        damage_reduction = float(skill.get("damage_reduction", 0.3))
        buff_timer = float(skill.get("duration", 6.0))
        EventBus.toast_requested.emit(LocaleData.text(id), Color(0.55, 0.85, 1.0))
    elif skill_type == "dash":
        _dash_attack(skill)
    elif skill_type == "heal":
        GameState.heal(max_health * float(skill.get("heal_ratio", 0.3)))
        damage_reduction = maxf(damage_reduction, 0.25)
        buff_timer = maxf(buff_timer, float(skill.get("duration", 6.0)))
        EventBus.toast_requested.emit(LocaleData.text(id), Color(0.65, 0.95, 0.70))

func _melee_attack(multiplier: float, range_value: float, element: String) -> void:
    var origin := global_position + Vector3.UP * 1.0
    var forward := _last_move_direction
    if _in_combat and _combat_target != null and is_instance_valid(_combat_target):
        forward = _combat_target.global_position - global_position
    if forward.length() < 0.1:
        forward = -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    for enemy_node in get_tree().get_nodes_in_group("enemies"):
        var enemy: Variant = enemy_node
        if enemy == null or not enemy.has_method("take_damage"):
            continue
        var to_enemy: Vector3 = enemy.global_position - origin
        to_enemy.y = 0.0
        if to_enemy.length() <= range_value and to_enemy.normalized().dot(forward) > 0.15:
            var damage_value := _roll_damage(attack * multiplier)
            enemy.take_damage(damage_value, element, global_position, self)
            if get_tree().current_scene != null:
                WorldFX.spawn_hit_spark(get_tree().current_scene, enemy.global_position + Vector3.UP * 1.1, GameData.element_color(element), 0.8)

func _aoe_attack(multiplier: float, radius: float, element: String) -> void:
    var origin := global_position
    if get_tree().current_scene != null:
        WorldFX.spawn_aoe_ring(get_tree().current_scene, origin + Vector3.UP * 0.05, GameData.element_color(element), radius)
    for enemy_node in get_tree().get_nodes_in_group("enemies"):
        var enemy: Variant = enemy_node
        if enemy == null or not enemy.has_method("take_damage"):
            continue
        var distance: float = enemy.global_position.distance_to(origin)
        if distance <= radius:
            var damage_value := _roll_damage(attack * multiplier)
            enemy.take_damage(damage_value, element, global_position, self)
            if get_tree().current_scene != null:
                WorldFX.spawn_hit_spark(get_tree().current_scene, enemy.global_position + Vector3.UP * 1.1, GameData.element_color(element), 0.8)

func _fire_projectile(skill: Dictionary) -> void:
    var projectile := Projectile.new()
    var cam := get_viewport().get_camera_3d()
    var direction := -global_transform.basis.z
    if _in_combat and _combat_target != null and is_instance_valid(_combat_target):
        direction = _combat_target.global_position - global_position
    elif cam != null:
        direction = -cam.global_transform.basis.z
    direction.y = 0.0
    direction = direction.normalized()
    projectile.setup(direction, _roll_damage(attack * float(skill.get("damage", 1.0))), str(skill.get("element", "none")), self)
    projectile.speed = float(skill.get("speed", 18.0))
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position + Vector3.UP * 1.0 + direction * 1.0
    WorldFX.add_projectile_trail(projectile, GameData.element_color(str(skill.get("element", "none"))))

func _dash_attack(skill: Dictionary) -> void:
    var direction := _last_move_direction
    if _in_combat and _combat_target != null and is_instance_valid(_combat_target):
        direction = _combat_target.global_position - global_position
    if direction.length() < 0.1:
        direction = -global_transform.basis.z
    direction.y = 0.0
    direction = direction.normalized()
    var from_position := global_position
    global_position += direction * float(skill.get("dash_distance", 6.0))
    if get_tree().current_scene != null:
        WorldFX.spawn_dash_trail(get_tree().current_scene, from_position, global_position, GameData.element_color(str(skill.get("element", "none"))))
    _aoe_attack(float(skill.get("damage", 1.0)), float(skill.get("range", 3.0)) + 1.5, str(skill.get("element", "none")))

func _roll_damage(base_damage: float) -> float:
    var damage_value := base_damage
    if randf() < crit_chance:
        damage_value *= crit_damage
    return damage_value

func take_damage(amount: float, element: String, _source_position: Vector3, _source: Node = null) -> void:
    if GameState.health <= 0.0:
        return
    var reduced := amount * (100.0 / (100.0 + maxf(defense, 0.0)))
    reduced *= GameData.element_damage_multiplier(element, GameState.player_element)
    reduced *= maxf(1.0 - damage_reduction, 0.1)
    GameState.take_damage(reduced)
    GameState.rumble(0.5, 0.18)
    EventBus.damage_number_requested.emit(reduced, global_position + Vector3.UP * 1.8, false, element)
    EventBus.camera_shake_requested.emit(0.18)
    if get_tree().current_scene != null:
        WorldFX.spawn_hit_spark(get_tree().current_scene, global_position + Vector3.UP * 1.0, GameData.element_color(element), 0.7)
    if GameState.health <= 0.0:
        EventBus.player_died.emit()

func revive_in_place() -> void:
    var total := GameState.get_total_stats()
    GameState.health = float(total["max_health"])
    GameState.qi = float(total["max_qi"])
    velocity = Vector3.ZERO
    attack_cooldown = 0.0
    skill_cooldowns.clear()
    buff_timer = 0.0
    damage_reduction = 0.0
    if _death_tween != null and _death_tween.is_valid():
        _death_tween.kill()
    _death_anim_started = false
    if _model_root != null:
        _model_root.position = Vector3.ZERO
        _model_root.rotation = Vector3.ZERO
        _model_root.process_mode = Node.PROCESS_MODE_INHERIT
    if is_animated():
        _character.play(CharacterModel.CLIP_IDLE, 1.0, 0.10)
    EventBus.player_stats_changed.emit()


func revive_at_spawn(spawn_position: Vector3) -> void:
    global_position = spawn_position
    revive_in_place()


func cast_talisman_aoe(damage_value: float, radius: float, element: String) -> void:
    _aoe_attack(damage_value / maxf(attack, 1.0), radius, element)
