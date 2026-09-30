extends Node
## Headless behaviour tests for the fashion (时装) system.
##
##   godot --headless --path . res://tests/fashion_tests.tscn
##
## Prints one line per failing check and exits 0 when everything passes.  The
## user save file is backed up first and restored at the end, so running the
## tests never eats a real playthrough.

var _checks := 0
var _failures: Array[String] = []
var _had_save := false
var _save_backup := ""
var _restored := false


func _ready() -> void:
    # Deferred: the tree is still building the first scene, so adding our own
    # nodes here would fail with "parent node is busy setting up children".
    call_deferred("_run_tests")


func _run_tests() -> void:
    if get_node_or_null("/root/GameState") == null:
        print("[fashion] GameState autoload missing")
        get_tree().quit(2)
        return

    _backup_save()

    print("== fashion data ==")
    _test_data()
    print("== fashion state ==")
    _test_state()
    print("== fashion persistence ==")
    _test_persistence()
    print("== fashion visuals ==")
    _test_visuals()
    print("== character model ==")
    await _test_character_model()
    print("== player integration ==")
    await _test_player()
    print("== wardrobe panel ==")
    await _test_panel()
    print("== game ui integration ==")
    await _test_game_ui()

    _restore_save()

    print("---------------------------------------------")
    print("[fashion] %d checks, %d failure(s)" % [_checks, _failures.size()])
    for failure in _failures:
        print("  FAIL  " + failure)
    if _failures.is_empty():
        print("[fashion] OK")
    # Let pending queue_free() calls run so the sub-viewports shut down
    # cleanly instead of leaking render targets at exit.
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(1 if not _failures.is_empty() else 0)


func _exit_tree() -> void:
    # Safety net: never leave a test save behind if a check threw us out early.
    _restore_save()


# ------------------------------------------------------------- utilities ---
func check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)


## Bind-pose bounds of the collected body meshes, in world space.
func _body_aabb(model: CharacterModel) -> AABB:
    var out := AABB()
    var first := true
    for mesh in model.meshes:
        if mesh.mesh == null:
            continue
        var box: AABB = mesh.global_transform * mesh.get_aabb()
        out = box if first else out.merge(box)
        first = false
    return out


func _backup_save() -> void:
    if FileAccess.file_exists(GameState.SAVE_PATH):
        _had_save = true
        _save_backup = FileAccess.get_file_as_string(GameState.SAVE_PATH)


func _restore_save() -> void:
    if _restored:
        return
    _restored = true
    if _had_save:
        var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
        if file != null:
            file.store_string(_save_backup)
            file.close()
    elif FileAccess.file_exists(GameState.SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))


func _write_save(payload: Dictionary) -> void:
    var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(payload))
    file.close()


# ------------------------------------------------------------------ data ---
func _test_data() -> void:
    check(FashionData.count() >= 8, "expected at least 8 outfits, found %d" % FashionData.count())
    var ids := FashionData.ids()
    check(ids.size() == FashionData.count(), "ids() must list every outfit")
    check(ids.size() == FashionData.FASHION.size(), "ids() must match the raw table")

    var seen := {}
    var auras := {}
    for id in ids:
        var key := str(id)
        check(not seen.has(key), "duplicate outfit id " + key)
        seen[key] = true
        check(FashionData.has(key), "has(%s)" % key)
        check(FashionData.name(key) != "" and FashionData.name(key) != key, "outfit %s needs a name" % key)
        check(FashionData.desc(key).length() >= 8, "outfit %s needs a description" % key)
        var rarity := FashionData.rarity(key)
        check(rarity >= 1 and rarity <= 5, "outfit %s rarity out of range (%d)" % [key, rarity])
        var requirement := FashionData.realm_requirement(key)
        check(requirement >= 0 and requirement < GameData.REALMS.size(), "outfit %s realm gate out of range" % key)
        check(FashionData.rarity_color(key).a > 0.9, "outfit %s rarity colour must be opaque" % key)

        for part_id in FashionData.parts(key):
            check(FashionData.PART_IDS.has(str(part_id)), "outfit %s uses unknown part %s" % [key, part_id])
        check(FashionData.AURA_KINDS.has(FashionData.aura(key)), "outfit %s has an invalid aura" % key)
        auras[FashionData.aura(key)] = true
        check(FashionData.palette_count(key) >= 2, "outfit %s should offer at least two colour schemes" % key)

        for i in range(FashionData.palette_count(key)):
            var scheme := FashionData.palette(key, i)
            check(str(scheme["name"]) != "", "palette %d of %s needs a name" % [i, key])
            for channel in ["robe", "trim", "glow"]:
                var colour: Color = scheme[channel]
                check(colour.a > 0.9, "palette %d of %s has a transparent %s" % [i, key, channel])

        for item_id in FashionData.cost(key).keys():
            check(not GameData.item_row(str(item_id)).is_empty(), "outfit %s costs unknown item %s" % [key, item_id])
            check(int(FashionData.cost(key)[item_id]) > 0, "outfit %s cost for %s must be positive" % [key, item_id])

        var appearance := FashionData.appearance(key, 1, false)
        check(str(appearance.get("id", "")) == key, "appearance id mismatch for " + key)
        check(int(appearance.get("palette", -1)) == 1, "appearance palette mismatch for " + key)
        check(str(appearance.get("aura", "x")) == "none", "aura toggle ignored for " + key)
        var appearance_parts: Array = appearance.get("parts", [])
        check(appearance_parts.size() == FashionData.parts(key).size(), "appearance parts mismatch for " + key)
        check(FashionData.part_list_text(key) != "", "part list text for " + key)
        check(FashionData.cost_text(key) != "", "cost text for " + key)
        if requirement <= 0:
            check(FashionData.requirement_text(key) == "", "no realm gate means no realm text for " + key)
        else:
            check(FashionData.requirement_text(key) != "", "a realm gate needs requirement text for " + key)

    check(FashionData.appearance("definitely_not_an_outfit").is_empty(), "unknown outfit must resolve to {}")
    check(auras.size() >= 4, "the catalogue should cover several aura kinds")
    check(FashionData.STARTER_OWNED.size() >= 1, "new characters need at least one starter outfit")
    for starter in FashionData.STARTER_OWNED:
        check(FashionData.has(str(starter)), "starter outfit %s must exist" % starter)


# ----------------------------------------------------------------- state ---
func _test_state() -> void:
    GameState.start_new_game()
    check(GameState.fashion_owned_count() == FashionData.STARTER_OWNED.size(), "a new character owns the starter outfits")
    check(GameState.fashion_worn == "", "a new character wears no fashion")
    check(int(GameState.stats.get("fashion_owned", -1)) == GameState.fashion_owned_count(), "fashion_owned stat mirrors the collection")
    check(GameState.fashion_appearance().is_empty(), "no worn outfit means an empty appearance")

    check(GameState.wear_fashion("suxin"), "wearing an owned outfit succeeds")
    check(GameState.fashion_worn == "suxin", "worn outfit is tracked")
    check(str(GameState.fashion_appearance().get("id", "")) == "suxin", "worn appearance reports the outfit")
    check(not GameState.wear_fashion("zhulong"), "an unowned outfit cannot be worn")
    check(GameState.fashion_worn == "suxin", "a failed wear leaves the current outfit alone")
    check(GameState.is_fashion_worn("suxin"), "is_fashion_worn()")

    GameState.set_fashion_palette("suxin", 2)
    check(GameState.get_fashion_palette("suxin") == 2, "dye index is stored")
    var expected: Color = FashionData.palette("suxin", 2)["robe"]
    var worn := GameState.fashion_appearance()
    var colours: Dictionary = worn.get("colors", {})
    var robe: Color = colours.get("robe", Color.BLACK)
    check(robe.is_equal_approx(expected), "the worn robe follows the dye")
    GameState.set_fashion_palette("suxin", 99)
    check(GameState.get_fashion_palette("suxin") == FashionData.palette_count("suxin") - 1, "dye index is clamped")

    # Realm gate, then material gate.
    GameState.realm_index = 0
    check(GameState.get_fashion_blocker("liuyun") != "", "a realm-1 outfit is blocked at realm 0")
    check(not GameState.can_unlock_fashion("liuyun"), "a gated outfit is not unlockable")
    check(not GameState.unlock_fashion("liuyun"), "unlocking a gated outfit fails")
    check(not GameState.has_fashion("liuyun"), "a failed unlock grants nothing")

    GameState.realm_index = 5
    check(GameState.get_fashion_blocker("liuyun") != "", "missing materials block the unlock")
    var cost := FashionData.cost("liuyun")
    for item_id in cost.keys():
        GameState.add_item(str(item_id), int(cost[item_id]))
    check(GameState.get_fashion_blocker("liuyun") == "", "supplying the materials clears the blocker")
    check(GameState.can_unlock_fashion("liuyun"), "can_unlock_fashion()")

    var stones_before := GameState.count_item("material_jingshi")
    check(GameState.unlock_fashion("liuyun"), "unlocking with the materials succeeds")
    check(GameState.has_fashion("liuyun"), "the unlocked outfit is owned")
    check(GameState.count_item("material_jingshi") == stones_before - int(cost.get("material_jingshi", 0)), "unlocking consumes the spirit stones")
    check(GameState.get_fashion_blocker("liuyun") == LocaleData.text("fashion_owned"), "owned outfits report as owned")
    check(not GameState.unlock_fashion("liuyun"), "an outfit cannot be unlocked twice")
    check(int(GameState.stats.get("fashion_owned", -1)) == GameState.fashion_owned_count(), "the collection stat follows unlocks")

    # Aura toggle on an outfit that actually has one.
    check(GameState.get_fashion_aura_enabled("liuyun"), "auras default to on")
    GameState.set_fashion_aura_enabled("liuyun", false)
    check(not GameState.get_fashion_aura_enabled("liuyun"), "the aura toggle is stored")
    check(GameState.wear_fashion("liuyun"), "wearing the freshly unlocked outfit")
    check(str(GameState.fashion_appearance().get("aura", "x")) == "none", "a disabled aura is not rendered")
    GameState.set_fashion_aura_enabled("liuyun", true)
    check(str(GameState.fashion_appearance().get("aura", "x")) == FashionData.aura("liuyun"), "re-enabling the aura restores it")

    GameState.take_off_fashion()
    check(GameState.fashion_worn == "", "taking the outfit off clears it")
    check(GameState.fashion_appearance().is_empty(), "no appearance once taken off")

    check(InputMap.has_action("toggle_fashion"), "toggle_fashion input action is registered")
    check(GameState.get_binding_label("toggle_fashion") == "U", "default fashion hotkey is U, got %s" % GameState.get_binding_label("toggle_fashion"))
    check(GameState.BINDABLE_ACTIONS.has("toggle_fashion"), "the hotkey can be rebound in the settings panel")


# ----------------------------------------------------------- persistence ---
func _test_persistence() -> void:
    GameState.wear_fashion("liuyun")
    GameState.set_fashion_palette("liuyun", 1)
    GameState.set_fashion_aura_enabled("liuyun", false)
    var owned_before := GameState.fashion_owned_count()
    GameState.save_game()

    GameState.fashion_owned = {}
    GameState.fashion_style = {}
    GameState.fashion_worn = ""
    check(GameState.load_game(), "the save file loads")
    check(GameState.fashion_owned_count() == owned_before, "owned outfits survive a save/load round-trip")
    check(GameState.fashion_worn == "liuyun", "the worn outfit survives a save/load round-trip")
    check(GameState.get_fashion_palette("liuyun") == 1, "the dye survives a save/load round-trip")
    check(not GameState.get_fashion_aura_enabled("liuyun"), "the aura toggle survives a save/load round-trip")
    var appearance := GameState.fashion_appearance()
    check(str(appearance.get("id", "")) == "liuyun", "the appearance is rebuilt after loading")
    check(str(appearance.get("aura", "x")) == "none", "the disabled aura stays off after loading")

    # A save written before the fashion system existed.
    _write_save({"player_name": "legacy", "inventory": [], "equipment": {}})
    check(GameState.load_game(), "a legacy save still loads")
    check(GameState.get_time_string() != "", "a save without calendar data still reports a time")
    check(str(GameState.get_pillars().get("text", "")) != "", "a save without calendar data still resolves the pillars")
    check(GameState.fashion_owned_count() == FashionData.STARTER_OWNED.size(), "legacy saves receive the starter outfits")
    check(GameState.fashion_worn == "", "legacy saves wear no fashion")

    # A tampered save must be sanitised instead of crashing.
    _write_save({
        "player_name": "tampered",
        "fashion_owned": {"suxin": true, "not_a_real_outfit": true},
        "fashion_worn": "not_a_real_outfit",
        "fashion_style": {"suxin": {"palette": 99, "aura": false}},
    })
    check(GameState.load_game(), "a tampered save still loads")
    check(GameState.fashion_owned_count() == 1, "unknown outfit ids are dropped")
    check(GameState.fashion_worn == "", "an unknown worn outfit falls back to none")
    check(GameState.get_fashion_palette("suxin") == FashionData.palette_count("suxin") - 1, "an out-of-range dye index is clamped")
    check(not GameState.get_fashion_aura_enabled("suxin"), "a stored aura toggle is kept")


# --------------------------------------------------------------- visuals ---
func _test_visuals() -> void:
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    add_child(mesh)

    # CharacterModel leaves the material a mesh should fall back to on its meta.
    var base := StandardMaterial3D.new()
    base.albedo_color = FashionVisuals.BASE_ROBE
    mesh.material_override = base
    mesh.set_meta(FashionVisuals.BASE_MATERIAL_META, base)

    FashionVisuals.apply_body(mesh, {})
    var material := mesh.material_override as StandardMaterial3D
    check(material == base, "an empty appearance restores the base material")

    var appearance := FashionData.appearance("chiyan", 0, true)
    FashionVisuals.apply_body(mesh, appearance)
    material = mesh.material_override as StandardMaterial3D
    var expected: Color = FashionData.palette("chiyan", 0)["robe"]
    check(material != null and material.albedo_color.is_equal_approx(expected), "an outfit recolours the body")
    check(material != null and material.emission_enabled, "an outfit adds an emissive glow")

    FashionVisuals.apply_body(mesh, {})
    check(mesh.material_override == base, "taking the outfit off restores the base material again")
    mesh.queue_free()

    for id in FashionData.ids():
        var key := str(id)
        var rig := FashionVisuals.build_rig(FashionData.appearance(key, 0, true))
        check(rig.name == FashionVisuals.RIG_NAME, "rig is named after the shared constant (%s)" % key)
        var part_count := 0
        for child in rig.get_children():
            if str(child.name).begins_with("Part_"):
                part_count += 1
        check(part_count == FashionData.parts(key).size(), "rig builds every part of %s (%d vs %d)" % [key, part_count, FashionData.parts(key).size()])
        var expects_aura := FashionData.aura(key) != "none"
        check((rig.get_node_or_null("Aura") != null) == expects_aura, "aura node presence for " + key)
        FashionVisuals.animate(rig, 1.25, 1.0)
        rig.free()

    var bare := FashionVisuals.build_rig({})
    check(bare.get_child_count() == 0, "an empty appearance builds an empty rig")
    bare.free()

    # Idle motion keeps moving the accessories.
    var rig := FashionVisuals.build_rig(FashionData.appearance("zhulong", 0, true))
    var parts: Dictionary = rig.get_meta(FashionVisuals.PARTS_META, {})
    var cape := parts.get("cape", null) as Node3D
    var orbit := parts.get("orbit", null) as Node3D
    check(cape != null and orbit != null, "the rig exposes its parts by id")
    if cape != null and orbit != null:
        FashionVisuals.animate(rig, 1.0, 0.0)
        var cape_a := cape.transform
        var orbit_a := orbit.transform
        FashionVisuals.animate(rig, 3.4, 1.0)
        check(not cape_a.is_equal_approx(cape.transform), "the cape sways over time")
        check(not orbit_a.is_equal_approx(orbit.transform), "the orbs keep orbiting")
    rig.free()


# ------------------------------------------------------- player / preview ---
func _test_player() -> void:
    GameState.wear_fashion("")
    var player := Player.new()
    add_child(player)
    await get_tree().process_frame

    var model: CharacterModel = player._character
    check(model != null, "the player builds a character model")
    if model == null:
        player.queue_free()
        return
    check(model.outfit_meshes.size() > 0, "the character exposes clothing meshes")
    check(player.is_animated(), "the player body is animation driven")
    check(player._fashion_rig == null, "the player has no rig while nothing is worn")

    GameState.wear_fashion("suxin")
    check(player._fashion_rig != null, "wearing an outfit builds the rig on the player")
    if player._fashion_rig != null:
        var rig: Node3D = player._fashion_rig
        var parts: Dictionary = rig.get_meta(FashionVisuals.PARTS_META, {})
        check(parts.size() == FashionData.parts("suxin").size(), "the player rig matches the outfit parts")

    var cloth: MeshInstance3D = model.outfit_meshes[0]
    var material := cloth.material_override as StandardMaterial3D
    var expected: Color = FashionData.palette("suxin", GameState.get_fashion_palette("suxin"))["robe"]
    check(material != null and material.albedo_color.is_equal_approx(expected), "the clothing follows the outfit")

    GameState.take_off_fashion()
    check(player._fashion_rig == null, "taking the outfit off clears the player rig")
    var base: Material = cloth.get_meta(FashionVisuals.BASE_MATERIAL_META, null)
    check(cloth.material_override == base, "taking the outfit off restores the clothing material")
    player.queue_free()


# ------------------------------------------------------- character model ---
func _test_character_model() -> void:
    var model := CharacterModel.new()
    add_child(model)
    model.build()
    await get_tree().process_frame

    check(model.animated, "the animated GLB loads")
    check(model.skeleton != null, "the model exposes its skeleton (137 bones)")
    check(model.animation_player != null, "the model exposes its animation player")
    check(model.meshes.size() >= 8, "every body mesh is collected (%d)" % model.meshes.size())
    check(model.outfit_meshes.size() >= 1, "clothing meshes are classified for the fashion system")

    for clip in ["Idle", "Walk", "Run", "Jump", "Attack_Knife", "Dodge", "Death", "Meditate", "Sleep_Side"]:
        check(model.has_clip(clip), "clip %s is available" % clip)
    check(absf(model.clip_length("Idle") - 2.0) < 0.05, "Idle lasts 2 s")
    check(absf(model.clip_length("Dodge") - 1.0) < 0.05, "Dodge lasts 1 s")
    for clip in CharacterModel.LOOP_CLIPS:
        var anim := model.animation_player.get_animation(clip)
        check(anim != null and anim.loop_mode == Animation.LOOP_LINEAR, "clip %s loops" % clip)
    for clip in ["Jump", "Attack_Knife", "Dodge", "Death"]:
        var anim := model.animation_player.get_animation(clip)
        check(anim != null and anim.loop_mode == Animation.LOOP_NONE, "clip %s plays once" % clip)

    # The world is built around ~1.95 m characters.
    var box := _body_aabb(model)
    check(box.size.y > 0.0, "the body has a measurable height")
    check(absf(box.size.y - CharacterModel.TARGET_HEIGHT) < 0.05, "the body is scaled to %.2f m (got %.2f)" % [CharacterModel.TARGET_HEIGHT, box.size.y])
    check(absf(box.position.y) < 0.05, "the feet stand on the ground plane (got %.3f)" % box.position.y)

    check(model.weapon_socket != null, "a weapon socket is created")
    if model.weapon_socket != null:
        check(model.weapon_socket.bone_name == CharacterModel.WEAPON_BONE, "the socket rides " + CharacterModel.WEAPON_BONE)

    model.set_weapon("weapon_qingfeng")
    await get_tree().process_frame
    check(model.weapon_mesh != null and model.weapon_mesh.mesh != null, "the equipped weapon shows up in the hand")
    if model.weapon_mesh != null and model.weapon_mesh.mesh != null:
        var blade: AABB = model.weapon_mesh.get_aabb()
        var tip := model.weapon_mesh.global_position + model.weapon_mesh.global_transform.basis * Vector3(0.0, blade.end.y, 0.0)
        print("      weapon grip=%s tip=%s" % [str(model.weapon_mesh.global_position.snappedf(0.01)), str(tip.snappedf(0.01))])
        var to_tip := tip - model.weapon_mesh.global_position
        check(to_tip.length() > 1.0, "the blade keeps its authored length (%.2f m)" % to_tip.length())
        check(tip.y > 0.0, "the blade tip stays above the ground (y=%.2f)" % tip.y)
        check(tip.z > 0.2, "the blade points forward instead of through the legs (z=%.2f)" % tip.z)

    # Seeking through the attack clip must move both the skeleton and the
    # sword: proof that the bone socket really grips the weapon.
    var head_index := model.skeleton.find_bone("head")
    model.play(CharacterModel.CLIP_ATTACK, 1.0, 0.0)
    model.animation_player.seek(0.30, true)
    await get_tree().process_frame
    var head_a: Vector3 = model.skeleton.get_bone_global_pose(head_index).origin
    var grip_a: Vector3 = model.weapon_mesh.global_position
    model.animation_player.seek(0.85, true)
    await get_tree().process_frame
    var head_b: Vector3 = model.skeleton.get_bone_global_pose(head_index).origin
    var grip_b: Vector3 = model.weapon_mesh.global_position
    check(head_a.distance_to(head_b) > 0.005, "the skeleton is driven by the animation")
    check(grip_a.distance_to(grip_b) > 0.05, "the sword follows the hand through the swing")

    # Accessories ride the skeleton rather than floating beside it.
    var rig := FashionVisuals.build_rig(FashionData.appearance("zhulong", 0, true))
    model.add_child(rig)
    model.mount_fashion_rig(rig)
    var parts: Dictionary = rig.get_meta(FashionVisuals.PARTS_META, {})
    var crown := parts.get("crown", null) as Node3D
    check(crown != null, "the crown is part of the rig")
    if crown != null:
        var parent := crown.get_parent()
        check(parent is BoneAttachment3D, "the crown is mounted on a bone")
        if parent is BoneAttachment3D:
            check((parent as BoneAttachment3D).bone_name == "head", "the crown rides the head")
    var cape := parts.get("cape", null) as Node3D
    if cape != null and cape.get_parent() is BoneAttachment3D:
        check((cape.get_parent() as BoneAttachment3D).bone_name == "spine01", "the cape rides the chest")
    FashionVisuals.dispose_rig(rig)
    # queue_free() detaches at the end of the frame, so ask whether the part
    # still belongs to the scene instead of whether it is already gone.
    check(crown == null or not crown.is_inside_tree(), "disposing the rig detaches the mounted parts from the body")

    model.queue_free()


# --------------------------------------------------------------- game UI ---
func _test_game_ui() -> void:
    GameState.start_new_game()
    var player := Player.new()
    add_child(player)

    var ui := GameUI.new()
    get_tree().root.add_child(ui)
    ui.set_player(player)

    check(ui._fashion_panel != null, "GameUI builds the wardrobe panel")
    check(ui._all_panels.has(ui._fashion_panel), "the wardrobe panel is registered with the panel manager")
    check(ui._char_values.has("fashion"), "the character sheet has a fashion row")
    check(ui._character_preview != null, "the character sheet embeds the wardrobe mirror")

    var hotkey := InputEventAction.new()
    hotkey.action = "toggle_fashion"
    hotkey.pressed = true
    ui._unhandled_input(hotkey)
    check(ui._fashion_panel.visible, "the fashion hotkey opens the wardrobe")
    check(ui._any_panel_active(), "an open wardrobe counts as an active panel")

    ui._unhandled_input(hotkey)
    check(ui._fashion_panel.is_closing(), "pressing the hotkey again closes the wardrobe")

    GameState.wear_fashion("suxin")
    ui._refresh_character_panel()
    check(ui._char_values["fashion"].text == FashionData.name("suxin"), "the character sheet shows the worn outfit")
    GameState.take_off_fashion()
    ui._refresh_character_panel()
    check(ui._char_values["fashion"].text == LocaleData.text("fashion_none"), "the character sheet reports no outfit")

    ui.queue_free()
    player.queue_free()


# -------------------------------------------------------------- wardrobe ---
func _test_panel() -> void:
    var panel := FashionPanel.new()
    get_tree().root.add_child(panel)
    panel.open()
    check(panel.visible, "the wardrobe panel opens")

    var list: VBoxContainer = panel._list
    check(list != null, "the wardrobe builds its list")
    if list != null:
        check(list.get_child_count() == FashionData.count(), "the wardrobe lists every outfit (%d vs %d)" % [list.get_child_count(), FashionData.count()])

    panel._selected = "liuyun"
    panel._refresh_detail()
    check(panel._palette_row.get_child_count() == FashionData.palette_count("liuyun"), "the dye chips match the outfit")
    check(panel._detail_name.text == FashionData.name("liuyun"), "the detail column shows the outfit name")

    panel._selected = "zhulong"
    panel._refresh_detail()
    check(panel._unlock_button.visible, "a locked outfit offers the unlock button")
    check(panel._unlock_button.disabled, "the unlock button stays disabled while blocked")
    check(panel._wear_button.disabled, "an unowned outfit cannot be worn from the panel")

    panel._selected = "suxin"
    panel._refresh_detail()
    check(not panel._wear_button.disabled, "an owned outfit can be worn from the panel")
    check(not panel._unlock_button.visible, "an owned outfit hides the unlock button")

    panel.close()
    panel.queue_free()

    # The character sheet asks the mirror for the current look every frame, so
    # an unchanged appearance must not rebuild the rig every time.
    var mirror := FashionPreview.new()
    get_tree().root.add_child(mirror)
    mirror.set_appearance(FashionData.appearance("chiyan", 0, true))
    await get_tree().process_frame
    var rig_a: Node3D = mirror._rig
    check(rig_a != null, "the mirror builds a rig for the shown outfit")
    mirror.set_appearance(FashionData.appearance("chiyan", 0, true))
    check(mirror._rig == rig_a, "the same appearance does not rebuild the rig")
    mirror.set_appearance(FashionData.appearance("chiyan", 1, true))
    check(mirror._rig != rig_a, "choosing another dye rebuilds the rig")
    mirror.queue_free()
