extends Area3D
class_name Projectile

var speed := 18.0
var damage := 10.0
var element := "none"
var direction := Vector3.FORWARD
var source: Node = null
var team := "player"
var life := 4.0

func setup(new_direction: Vector3, new_damage: float, new_element: String, new_source: Node, new_team: String = "player") -> void:
    direction = new_direction.normalized()
    damage = new_damage
    element = new_element
    source = new_source
    team = new_team

func _ready() -> void:
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.28
    shape.shape = sphere
    add_child(shape)

    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.22
    mesh.height = 0.44
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = GameData.element_color(element)
    material.emission_enabled = true
    material.emission = GameData.element_color(element)
    material.emission_energy_multiplier = 2.2
    mesh_instance.material_override = material
    add_child(mesh_instance)

    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    life -= delta
    if life <= 0.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body == source:
        return
    if team == "enemy" and body.is_in_group("enemies"):
        return
    if team == "player" and body.is_in_group("player"):
        return
    if body.has_method("take_damage"):
        body.call("take_damage", damage, element, global_position, source)
        queue_free()