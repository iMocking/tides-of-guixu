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

func _ready() -> void:
    add_to_group("player")
    _build_body()
    refresh_stats()
    GameState.health = minf(GameState.health, max_health)
    GameState.qi = minf(GameState.qi, max_qi)
    EventBus.player_stats_changed.connect(refresh_stats)
    EventBus.equipment_changed.connect(refresh_stats)
    EventBus.inventory_changed.connect(refresh_stats)

func _build_body() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    collision.shape = capsule
    add_child(collision)

    var mesh_instance := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.42
    mesh.height = 1.8
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.42, 0.82, 0.62)
    material.roughness = 0.65
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var name_label := Label3D.new()
    name_label.text = GameState.player_name
    name_label.position = Vector3(0.0, 1.55, 0.0)
    ThemeBuilder.style_world_label(name_label, 32, Color(0.80, 1.0, 0.88))
    add_child(name_label)

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
        velocity = Vector3.ZERO
        move_and_slide()
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    for key in skill_cooldowns.keys():
        skill_cooldowns[key] = maxf(0.0, float(skill_cooldowns[key]) - delta)
    buff_timer = maxf(0.0, buff_timer - delta)
    if buff_timer <= 0.0:
        damage_reduction = 0.0
    _handle_input()
    _handle_movement(delta)
    _handle_actions()

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
    if _move_direction.length() > 0.05:
        target_velocity = _move_direction * move_speed
        var target_angle := atan2(_move_direction.x, _move_direction.z)
        rotation.y = lerp_angle(rotation.y, target_angle, clampf(delta * 12.0, 0.0, 1.0))
    velocity.x = target_velocity.x
    velocity.z = target_velocity.z
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _handle_actions() -> void:
    if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and get_viewport().gui_get_hovered_control() == null:
        attack_cooldown = 0.65
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
    if cam != null:
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
    EventBus.damage_number_requested.emit(reduced, global_position + Vector3.UP * 1.8, false, element)
    EventBus.camera_shake_requested.emit(0.18)
    if get_tree().current_scene != null:
        WorldFX.spawn_hit_spark(get_tree().current_scene, global_position + Vector3.UP * 1.0, GameData.element_color(element), 0.7)
    if GameState.health <= 0.0:
        EventBus.player_died.emit()

func cast_talisman_aoe(damage_value: float, radius: float, element: String) -> void:
    _aoe_attack(damage_value / maxf(attack, 1.0), radius, element)
