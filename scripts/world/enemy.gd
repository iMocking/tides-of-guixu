extends CharacterBody3D
class_name Enemy

var enemy_id := "demon_wolf"
var enemy_name := "Enemy"
var element := "earth"
var level := 1
var max_health := 70.0
var health := 70.0
var attack := 12.0
var defense := 3.0
var move_speed := 4.0
var aggro_range := 10.0
var attack_range := 2.0
var keep_distance := 4.0
var ranged := false
var attack_cooldown := 1.5
var xp_reward := 35.0
var color := Color(0.4, 0.6, 0.4)
var _attack_timer := 0.0
var _rng := RandomNumberGenerator.new()

func setup(id: String, rng: RandomNumberGenerator = null) -> void:
    enemy_id = id
    if rng != null:
        _rng = rng
    var data := GameData.enemy(id)
    enemy_name = str(data.get("name", id))
    element = str(data.get("element", "earth"))
    level = int(data.get("level", 1))
    max_health = float(data.get("hp", 70.0))
    health = max_health
    attack = float(data.get("atk", 10.0))
    defense = float(data.get("def", 3.0))
    move_speed = float(data.get("speed", 4.0))
    aggro_range = float(data.get("aggro", 10.0))
    attack_range = float(data.get("range", 2.0))
    keep_distance = float(data.get("keep_distance", attack_range * 0.75))
    ranged = bool(data.get("ranged", false))
    attack_cooldown = float(data.get("cooldown", 1.5))
    xp_reward = float(data.get("xp", 30.0))
    color = Color(str(data.get("color", "#5e8f5b")))
    var scale_value := float(data.get("scale", 1.0))
    scale = Vector3.ONE * scale_value

func _ready() -> void:
    add_to_group("enemies")
    if _rng.seed == 0:
        _rng.randomize()
    _build_body()
    _update_label()
    EventBus.settings_changed.connect(_update_label)

func _build_body() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.46
    capsule.height = 1.5
    collision.shape = capsule
    collision.position = Vector3(0.0, 0.75, 0.0)
    add_child(collision)

    var mesh_instance := MeshInstance3D.new()
    var model := _load_mesh("res://assets/models/characters/enemy_base.obj")
    if model != null:
        mesh_instance.mesh = model
        mesh_instance.rotation_degrees.y = 180.0
    else:
        var mesh := CapsuleMesh.new()
        mesh.radius = 0.46
        mesh.height = 1.5
        mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var label := Label3D.new()
    label.name = "NameLabel"
    label.position = Vector3(0.0, 2.05, 0.0)
    ThemeBuilder.style_world_label(label, 28, Color(1.0, 0.88, 0.72))
    add_child(label)



func _load_mesh(path: String) -> Mesh:
    if not ResourceLoader.exists(path):
        return null
    var resource := load(path)
    if resource is Mesh:
        return resource as Mesh
    return null


func _update_label() -> void:
    var label := get_node_or_null("NameLabel") as Label3D
    if label == null:
        return
    label.visible = bool(GameState.settings.get("enemy_health_bars", true))
    label.text = "%s  %d/%d" % [enemy_name, int(health), int(max_health)]

func _physics_process(delta: float) -> void:
    if health <= 0.0:
        return
    _attack_timer = maxf(0.0, _attack_timer - delta)
    var player: Variant = get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var to_player: Vector3 = player.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()
    if distance > aggro_range:
        velocity.x = 0.0
        velocity.z = 0.0
    else:
        var direction := to_player.normalized()
        if ranged:
            if distance < keep_distance:
                velocity.x = -direction.x * move_speed * 0.85
                velocity.z = -direction.z * move_speed * 0.85
            elif distance <= attack_range:
                velocity.x = 0.0
                velocity.z = 0.0
                if _attack_timer <= 0.0:
                    _attack_timer = attack_cooldown
                    _ranged_attack(player)
            else:
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
                rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), clampf(delta * 8.0, 0.0, 1.0))
        else:
            if distance <= attack_range:
                velocity.x = 0.0
                velocity.z = 0.0
                if _attack_timer <= 0.0:
                    _attack_timer = attack_cooldown
                    player.call("take_damage", attack, element, global_position, self)
            else:
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
                rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), clampf(delta * 8.0, 0.0, 1.0))
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _ranged_attack(player: Variant) -> void:
    var projectile := Projectile.new()
    var direction: Vector3 = (player.global_position + Vector3.UP * 1.0 - global_position).normalized()
    projectile.setup(direction, attack, element, self, "enemy")
    projectile.speed = 13.0
    if get_tree().current_scene != null:
        get_tree().current_scene.add_child(projectile)
        projectile.global_position = global_position + Vector3.UP * 1.0 + direction * 0.9


func take_damage(amount: float, element_in: String, source_position: Vector3, _source: Node = null) -> void:
    if health <= 0.0:
        return
    var reduced := amount * (100.0 / (100.0 + maxf(defense, 0.0)))
    reduced *= GameData.element_damage_multiplier(element_in, element)
    health = maxf(0.0, health - reduced)
    _update_label()
    GameState.record_stat("damage_dealt", reduced)
    EventBus.damage_number_requested.emit(reduced, global_position + Vector3.UP * 1.6, false, element_in)
    if get_tree().current_scene != null:
        WorldFX.spawn_hit_spark(get_tree().current_scene, global_position + Vector3.UP * 1.2, GameData.element_color(element_in), 0.65)
    if health <= 0.0:
        _die(source_position)

func _die(_source_position: Vector3) -> void:
    if get_tree().current_scene != null:
        WorldFX.spawn_aoe_ring(get_tree().current_scene, global_position + Vector3.UP * 0.2, color, 2.4, 0.8)
    GameState.record_stat("enemies_defeated", 1.0)
    var gained_xp := GameState.add_cultivation_xp(xp_reward)
    var drops := GameData.roll_loot(level, _rng)
    if not drops.is_empty() and get_tree().current_scene != null:
        var orb := LootOrb.new()
        orb.setup(drops)
        get_tree().current_scene.add_child(orb)
        orb.snap_to_position(global_position + Vector3.UP * 0.55)
    GameState.record_quest_kill(enemy_id)
    EventBus.enemy_defeated.emit(enemy_id, global_position)
    EventBus.combat_log.emit(defeat_log_line(gained_xp))
    queue_free()


## Bottom-left notification for a kill: the name followed by the cultivation
## it was worth, e.g. "击败 玄风妖狼  修为 +35".  A kill worth nothing falls
## back to just the name.
func defeat_log_line(gained_xp: float) -> String:
    if gained_xp <= 0.0:
        return LocaleData.text("enemy_defeated") % enemy_name
    return LocaleData.text("enemy_defeated_xp") % [enemy_name, LocaleData.text("cultivation"), int(round(gained_xp))]
