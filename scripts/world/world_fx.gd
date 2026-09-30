class_name WorldFX
## Lightweight procedural VFX helpers built from meshes and particles.

static func spawn_aoe_ring(parent: Node, world_position: Vector3, color: Color, radius: float, duration: float = 0.5) -> void:
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.42
    torus.outer_radius = 0.62
    ring.mesh = torus
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.82)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 2.8
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material_override = material
    parent.add_child(ring)
    ring.global_position = world_position + Vector3.UP * 0.12
    ring.scale = Vector3.ONE * 0.08
    var tween := ring.create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring, "scale", Vector3.ONE * maxf(radius, 0.2), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(ring, "transparency", 1.0, duration)
    tween.chain().tween_callback(ring.queue_free)

static func spawn_hit_spark(parent: Node, world_position: Vector3, color: Color, strength: float = 1.0) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = maxi(8, int(16.0 * strength))
    particles.lifetime = 0.5
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.local_coords = false
    var process_material := ParticleProcessMaterial.new()
    process_material.direction = Vector3.UP
    process_material.spread = 180.0
    process_material.initial_velocity_min = 2.0 * strength
    process_material.initial_velocity_max = 5.5 * strength
    process_material.gravity = Vector3(0.0, -10.0, 0.0)
    process_material.scale_min = 0.06
    process_material.scale_max = 0.18 * strength
    process_material.color = color
    particles.process_material = process_material
    var quad := QuadMesh.new()
    quad.size = Vector2(0.20, 0.20)
    particles.draw_pass_1 = quad
    parent.add_child(particles)
    particles.global_position = world_position
    particles.emitting = true
    var timer := parent.get_tree().create_timer(1.4)
    timer.timeout.connect(particles.queue_free)

static func add_projectile_trail(projectile: Node3D, color: Color) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = 28
    particles.lifetime = 0.35
    particles.local_coords = false
    particles.emitting = true
    var process_material := ParticleProcessMaterial.new()
    process_material.direction = Vector3(0.0, 0.0, 1.0)
    process_material.spread = 25.0
    process_material.initial_velocity_min = 0.2
    process_material.initial_velocity_max = 1.0
    process_material.gravity = Vector3.ZERO
    process_material.scale_min = 0.08
    process_material.scale_max = 0.22
    process_material.color = Color(color.r, color.g, color.b, 0.72)
    particles.process_material = process_material
    var quad := QuadMesh.new()
    quad.size = Vector2(0.16, 0.16)
    particles.draw_pass_1 = quad
    projectile.add_child(particles)

static func spawn_dash_trail(parent: Node, from_position: Vector3, to_position: Vector3, color: Color) -> void:
    var distance := from_position.distance_to(to_position)
    var steps := maxi(3, int(distance / 1.2))
    for i in range(steps + 1):
        var t := float(i) / float(steps)
        var position := from_position.lerp(to_position, t)
        spawn_hit_spark(parent, position + Vector3.UP * 0.4, color, 0.45)