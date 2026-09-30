extends StaticBody3D
class_name NPC

var npc_id := "elder_shushan"
var display_name := "NPC"
var title := ""

func setup(id: String) -> void:
    npc_id = id
    var data := GameData.npc(id)
    display_name = str(data.get("name", id))
    title = str(data.get("title", ""))

func _ready() -> void:
    add_to_group("npcs")
    _build_body()

func _build_body() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.44
    capsule.height = 1.7
    collision.shape = capsule
    collision.position = Vector3(0.0, 0.85, 0.0)
    add_child(collision)

    var model := _load_mesh("res://assets/models/characters/npc_elder.obj")
    if model != null:
        var model_instance := MeshInstance3D.new()
        model_instance.mesh = model
        var model_material := StandardMaterial3D.new()
        model_material.albedo_color = Color(0.24, 0.28, 0.42)
        model_material.roughness = 0.8
        model_material.cull_mode = BaseMaterial3D.CULL_DISABLED
        model_instance.material_override = model_material
        add_child(model_instance)
    else:
        var robe := MeshInstance3D.new()
        var robe_mesh := CylinderMesh.new()
        robe_mesh.top_radius = 0.25
        robe_mesh.bottom_radius = 0.48
        robe_mesh.height = 1.35
        robe.mesh = robe_mesh
        var robe_material := StandardMaterial3D.new()
        robe_material.albedo_color = Color(0.24, 0.28, 0.42)
        robe_material.roughness = 0.8
        robe.material_override = robe_material
        robe.position = Vector3(0.0, 0.68, 0.0)
        add_child(robe)

        var head := MeshInstance3D.new()
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.24
        head_mesh.height = 0.48
        head.mesh = head_mesh
        var head_material := StandardMaterial3D.new()
        head_material.albedo_color = Color(0.78, 0.68, 0.55)
        head.material_override = head_material
        head.position = Vector3(0.0, 1.55, 0.0)
        add_child(head)

    var label := Label3D.new()
    label.text = display_name + "\n" + title
    label.position = Vector3(0.0, 2.15, 0.0)
    ThemeBuilder.style_world_label(label, 28, Color(1.0, 0.88, 0.56))
    add_child(label)

    var quest_mark := Label3D.new()
    quest_mark.name = "QuestMark"
    quest_mark.text = "!"
    quest_mark.position = Vector3(0.0, 2.75, 0.0)
    ThemeBuilder.style_world_label(quest_mark, 46, Color(1.0, 0.78, 0.25))
    add_child(quest_mark)


func _load_mesh(path: String) -> Mesh:
    if not ResourceLoader.exists(path):
        return null
    var resource := load(path)
    if resource is Mesh:
        return resource as Mesh
    return null


func interact() -> void:
    EventBus.dialogue_requested.emit(npc_id)