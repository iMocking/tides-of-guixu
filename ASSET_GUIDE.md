# 美术资源替换指南

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
- `assets/textures/`：角色贴图、环境贴图、UI 图标。
- `assets/vfx/`：五行技能、命中、突破、环境粒子。
- `assets/audio/bgm/`：主菜单、野外、战斗、洞府音乐。
- `assets/audio/sfx/`：脚步、挥剑、技能、拾取、升级、UI 点击。
- `assets/ui/`：面板边框、按钮、图标、字体。

## 替换步骤
1. 将 `.glb` / `.gltf` / `.fbx` 模型导入 Godot，统一缩放和朝向。
2. 在 Player、Enemy 脚本中把 CapsuleMesh 换成模型实例，保留 CollisionShape3D。
3. 给模型添加 AnimationPlayer，并把移动、待机、攻击、受击、死亡挂到状态机。
4. 用 StandardMaterial3D 或 ORM 材质替换占位颜色。
5. 把程序化音效替换为 AudioStreamPlayer 与音频文件。
6. 用九宫格 StyleBox 和图标替换 ThemeBuilder 的纯色样式。

## 版权提醒
只下载授权允许在商业项目中使用的资源，并在 `CREDITS.md` 中记录作者、来源和许可证。

