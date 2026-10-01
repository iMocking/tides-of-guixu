# Credits & third-party notices

## Bundled addons

### Terrain3D v1.0.2-stable — `addons/terrain_3d/`

- Author: Cory Petkovsek, Roope Palmroos and contributors
- Source: https://github.com/TokisanGames/Terrain3D (tag `v1.0.2-stable`)
- Licence: MIT (full text in `addons/terrain_3d/LICENSE.txt`)
- What it is used for: the world map — the runtime clipmap that carries 高山 /
  断崖 / 湖泊 / 密林 / 雪地 and the collision the player walks on.
- Nothing in this project modifies the addon; it is the official release archive
  with the demo project stripped out.

### Quaternius Nature Pack — `assets/models/vegetation/`

- Author: Quaternius (https://quaternius.com, https://quaternius.itch.io)
- Licence: **CC0 1.0** (public domain dedication) — no attribution required, credited here anyway
- Source used: the `public/glb/nature_pack/` mirror in
  https://github.com/trebeljahr/quaternius-showcase (self-contained `.glb` files)
- Contents: 74 models — trees (Common / Birch / Pine / Willow, plus Dead and Snow
  variants), bushes, berry bushes, ferns, plants, grass, flowers, rocks
  (plain / mossy / snow-covered) and stumps & logs.
- What it is used for: every tree, shrub, tuft of grass, flower, boulder and log in
  the world map. `PropModels` only merges each `.glb` into one mesh and keeps the
  artist's materials untouched — nothing is recoloured or rebuilt.

### godot-mcp-toolkit — `addons/godot_mcp_toolkit/`

Editor tooling only; see its own `ATTRIBUTIONS.md`.

## Generated at runtime

Every other asset in the world map is generated from code, so there is nothing
to license:

| Thing | Where it comes from |
|---|---|
| Terrain height, biomes and landmark pads | `scripts/world/terrain_data.gd` (FastNoiseLite) |
| Terrain3D surface layers (albedo + normal) | `Terrain3DWorld._make_texture_asset()` via `NoiseTexture2D` |
| Lake water surface | the inline shader in `scripts/world/world_features.gd` |
| Placement, sizing and rotation of every prop | `WorldFeatures` (`scripts/world/world_features.gd`) |
| 牌坊 / 大殿 / 亭 / 塔 / 院墙 / 石灯笼 | `scripts/world/ancient_architecture.gd` + Godot primitive meshes |
| Lake water surface | the inline shader in `scripts/world/world_features.gd` |

## Fonts

- `assets/fonts/HarmonyOS_Sans_SC.ttf` — see `assets/fonts/HarmonyOS_Sans_LICENSE.txt`.
