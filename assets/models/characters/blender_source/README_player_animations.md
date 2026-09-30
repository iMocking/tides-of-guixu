# Godot character animations

Generated from `D:\stores\blender\output\person.blend` with Blender 5.2.
Output files:

- `character_rigged_animated.blend` - Blender source with the rig and all actions.
- `character_animated.glb` - glTF 2.0 binary for Godot 4 (skeleton + animation clips).
- `generate_godot_animations.py` - reproducible generator script.

## Animation clips

All clips start at frame 0 and use 24 FPS.

| Clip | Frames | Duration | Loop in Godot | Notes |
|---|---:|---:|---|---|
| Idle | 0-48 | 2.00 s | yes | subtle breathing / weight shift |
| Walk | 0-24 | 1.00 s | yes | in-place cycle, feet grounded |
| Run | 0-16 | 0.67 s | yes | in-place cycle, two short flight phases |
| Jump | 0-36 | 1.50 s | no | crouch -> takeoff -> apex -> land -> recover |
| Attack_Knife | 0-28 | 1.17 s | no | right-arm knife slash; put your weapon under `wrist.R` |
| Dodge | 0-24 | 1.00 s | no | lateral dodge to character's left (+X); contains root motion |
| Death | 0-48 | 2.00 s | no | stagger, buckle, fall to back |
| Meditate | 0-72 | 3.00 s | yes | seated meditation; subtle breathing |
| Sleep_Side | 0-72 | 3.00 s | yes | lying on character's left side; subtle breathing |

## Godot import notes

1. Copy `character_animated.glb` into the Godot project.
2. Select the imported scene in the FileSystem dock and open the Import tab.
3. Set `Animation > Import Animation` to enabled and import all clips.
4. In the Advanced Import Settings, the clips should appear as `Idle`, `Walk`,
   `Run`, `Jump`, `Attack_Knife`, `Dodge`, `Death`, `Meditate`, `Sleep_Side`.
5. Set `Loop Mode` to `Linear` for Idle / Walk / Run / Meditate / Sleep_Side.
6. `Dodge` contains ~0.9 m of root motion on the `root` bone. Use it as root
   motion or remove the root track if your controller drives movement.
7. For the knife attack, add a `BoneAttachment3D` below the `wrist.R` bone and
   place the weapon under it. The attack animation is authored for that socket.

## Texture warning

The source `.blend` currently points to MPFB textures in a Blender 5.1 profile
that does not exist on this machine (for example
`...\Blender\5.1\extensions\...\middleage_lightskinned_female_diffuse.png`).
Because of that, those image files cannot be embedded in the `.glb`; the
geometry, skeleton and animations are correct, but you may need to relink the
textures before final export if you want the original look.

## Re-running the generator

```powershell
& "C:\Apps\Blender 5.2\blender.exe" --background "D:\stores\blender\output\person.blend" `
  --python "D:\stores\blender\output\godot_character\generate_godot_animations.py" `
  -- "D:\stores\blender\output\person.blend" "D:\stores\blender\output\godot_character"
```
