extends Area3D
class_name LootOrb

var drops: Array = []
var _time := 0.0
var _base_y := 0.0

func setup(new_drops: Array) -> void:
    drops = new_drops

func _ready() -> void:
    add_to_group("loot")
    _base_y = global_position.y
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.75
    shape.shape = sphere
    add_child(shape)

    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.28
    mesh.height = 0.56
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.82, 0.32, 0.85)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.72, 0.22)
    material.emission_energy_multiplier = 2.6
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.78, 0.36)
    light.light_energy = 0.7
    light.omni_range = 3.5
    add_child(light)

    body_entered.connect(_on_body_entered)

func snap_to_position(new_position: Vector3) -> void:
    global_position = new_position
    _base_y = new_position.y

func _process(delta: float) -> void:
    _time += delta
    global_position.y = _base_y + sin(_time * 2.4) * 0.16
    rotate_y(delta * 1.5)

func collect() -> void:
    for drop in drops:
        if drop is Dictionary:
            var remaining := GameState.add_item(str(drop.get("id", "")), int(drop.get("count", 1)))
            if remaining > 0:
                EventBus.toast_requested.emit(LocaleData.text("inventory_full"), Color(0.95, 0.62, 0.42))
    queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        collect()