# 美术资源替换指南

> 当前构建环境无外网访问，本轮新增的 OBJ 角色 / 武器模型为项目自制低多边形占位资源，可直接用同名 GLB / FBX 替换。

当前项目为了在没有网络下载的情况下保持可运行，全部使用程序化生成的胶囊体、方块、球体和实时音效作为占位。
要把项目推进到接近《鬼谷八荒》与《蜀山初章》的观感，可以按下面分类替换。

## 推荐资源站
- Kenney：免费低多边形模型、UI 包、音效，授权宽松，适合快速替换原型。
- Quaternius：低多边形角色、怪物、自然环境，风格统一。
- Mixamo：人物骨骼与动画，可导出 FBX/GLB，适合常规 3D 视角。
- Poly Haven：PBR 材质、HDRI 天空、环境贴图，适合提升画面。
- OpenGameArt：免费 2D/3D 素材合集，授权各异，使用前确认。
- itch.io / Godot Asset Library：独立作者素材与 UI 主题。
- Sketchfab / Fab：可购买的仙侠类模型、特效、动作包。

## 建议目录结构
- `assets/models/characters/`：玩家、NPC、敌人模型与动画。
- `assets/models/environment/`：地形、树木、岩石、建筑、山门。
- `assets/models/weapons/`：剑、法宝、武器挂点模型。
- `assets/models/fashion/`：时装挂件（头冠、披风、腰封、护肩、法珠、背光）。
- `assets/textures/`：角色贴图、环境贴图、UI 图标。
- `assets/vfx/`：五行技能、命中、突破、环境粒子。
- `assets/audio/bgm/`：主菜单、野外、战斗、洞府音乐。
- `assets/audio/sfx/`：脚步、挥剑、技能、拾取、升级、UI 点击。
- `assets/ui/`：面板边框、按钮、图标、字体。

## 界面文案与默认道号
界面文案集中在 `scripts/data/locale_data.gd` → `locale_extra.gd` → `locale_extra2.gd` → `locale_extra3.gd`
四张表里（后者是前者的回退），改文案只要改对应键即可。默认道号是 `default_player_name`
（当前为「陈梦飞」）；若再次更换默认名，把 `GameState.LEGACY_DEFAULT_PLAYER_NAME` 指向上一版默认名，
旧存档就会在下次读档时自动升级。

## 玩家角色模型（骨骼动画）
`assets/models/characters/player_animated.glb` 是当前玩家角色：137 骨骼 + 9 段动作，由 `CharacterModel` 装载。
替换成自己的角色时，按下列约定即可少改代码：
- **动作名**：`CharacterModel` 按名字取片段（`Idle` / `Run` / `Jump` / `Attack_Knife` / `Dodge` / `Death`），
  改名后同步改 `CLIP_*` 常量；需要无缝循环的动作加进 `LOOP_CLIPS`（循环模式在运行时设置，不改导入配置）
- **武器骨骼**：改 `WEAPON_BONE`（默认 `wrist.R`）。握持位姿是运行时算的——把刀身对齐「手腕 → 第一个子骨骼」方向，
  再向角色正面偏 `WEAPON_TILT_DEG`（38°），握把落在 `WEAPON_FIST_OFFSET`（0.13 m）处
- **体型**：改 `TARGET_HEIGHT`（1.94 m）即可整体缩放；脚底高度自动对齐 y = 0
- **配对材质**：导入的 glTF 若缺贴图会全白，`MESH_ROLES` 按「网格名 + 材质名」关键词分配占位配色，
  新模型的命名若不同，调整这张表即可；名字里带 `suit` / `robe` 等关键词的网格会被时装系统接管
- **时装锚点**：`FashionVisuals` 里的 `WAIST_Y` / `HEAD_Y` / `SHOULDER_X` / `SHOULDER_Y` / `FRONT_Z` / `BACK_Z`
  是量在当前模型上的（脚底 y = 0、腰 0.97、肩 1.35、头 1.53、面朝 +Z），换模型后按同样方法量一遍即可

## 时装挂件
时装系统的挂件（头冠 / 披风 / 腰封 / 护肩 / 法珠 / 背光）与光效目前由 `FashionVisuals`
程序化生成（环体、方块、球体 + 自发光材质）。要换成正式模型，把 `_part_*` / `_build_aura`
里的 PrimitiveMesh 换成 `assets/models/fashion/` 下的 GLB 实例即可，
锚点常量（`WAIST_Y` / `HEAD_Y` / `SHOULDER_X` / `SHOULDER_Y` / `FRONT_Z` / `BACK_Z`）已按
占位角色 `player_base.obj` 量好，替换角色模型后同步调整即可。

## 替换步骤
1. 将 `.glb` / `.gltf` / `.fbx` 模型导入 Godot，统一缩放和朝向。
2. 在 Player、Enemy 脚本中把 CapsuleMesh 换成模型实例，保留 CollisionShape3D。
3. 给模型添加 AnimationPlayer，并把移动、待机、攻击、受击、死亡挂到状态机。
4. 用 StandardMaterial3D 或 ORM 材质替换占位颜色。
5. 把程序化音效替换为 AudioStreamPlayer 与音频文件。
6. 用九宫格 StyleBox 和图标替换 ThemeBuilder 的纯色样式。

## 版权提醒
只下载授权允许在商业项目中使用的资源，并在 `CREDITS.md` 中记录作者、来源和许可证。

