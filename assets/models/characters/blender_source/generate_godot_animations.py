# generate_godot_animations.py
# Blender 5.2+ headless script: create game-ready actions for the MPFB/CC-like
# character in person.blend, then save a .blend and export a .glb for Godot 4.
#
# Usage (from PowerShell):
#   & "C:\Apps\Blender 5.2\blender.exe" --background person.blend --python generate_godot_animations.py -- person.blend "D:\stores\blender\output\godot_character"
#
import bpy
import math
import os
import sys
import time
from copy import deepcopy
from mathutils import Vector, Quaternion, Matrix

# ---------------------------------------------------------------------------
# configuration
# ---------------------------------------------------------------------------
DEFAULT_RIG_NAME = 'Human.001.rig'
FPS = 24

# All bones that the animation system will drive.  The rig also has fingers,
# face, tongue and helper bones, but these are left at rest so the exported
# clips stay compact.
CONTROLLED = [
    'root',
    'pelvis.L', 'pelvis.R',
    'spine05', 'spine04', 'spine03', 'spine02', 'spine01',
    'neck01', 'neck02', 'neck03', 'head',
    'clavicle.L', 'shoulder01.L', 'upperarm01.L', 'upperarm02.L',
    'lowerarm01.L', 'lowerarm02.L', 'wrist.L',
    'clavicle.R', 'shoulder01.R', 'upperarm01.R', 'upperarm02.R',
    'lowerarm01.R', 'lowerarm02.R', 'wrist.R',
    'upperleg01.L', 'upperleg02.L', 'lowerleg01.L', 'lowerleg02.L',
    'foot.L', 'toe1-1.L',
    'upperleg01.R', 'upperleg02.R', 'lowerleg01.R', 'lowerleg02.R',
    'foot.R', 'toe1-1.R',
]

AXES = {
    'X': Vector((1.0, 0.0, 0.0)),
    'Y': Vector((0.0, 1.0, 0.0)),
    'Z': Vector((0.0, 0.0, 1.0)),
}

# These actions are one-shot except the ones in LOOP_ACTIONS.
LOOP_ACTIONS = {'Idle', 'Walk', 'Run', 'Meditate', 'Sleep_Side'}

# The main body meshes with visible geometry.  Human/Human.001 are base meshes
# whose mask modifiers hide every face; they are skipped for ground detection.
GROUND_MESH_NAMES = []


# ---------------------------------------------------------------------------
# small helpers
# ---------------------------------------------------------------------------
def clamp(x, a, b):
    return max(a, min(b, x))


def smoothstep(t):
    t = clamp(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def world_axis_rotation(pbone, x_deg=0.0, y_deg=0.0, z_deg=0.0):
    """Return a local pose quaternion that rotates around the armature-space
    axes X/Y/Z.  This keeps the animation definitions independent of each
    bone's roll/orientation."""
    rest = pbone.bone.matrix_local.to_3x3().normalized()
    q = Quaternion((1.0, 0.0, 0.0, 0.0))
    # Apply X, then Y, then Z in the bone's rest frame.  For the moderate
    # rotations used here the order is not visually critical.
    for axis_name, angle in (('X', x_deg), ('Y', y_deg), ('Z', z_deg)):
        if abs(angle) > 1e-8:
            local_axis = (rest.inverted() @ AXES[axis_name]).normalized()
            q = q @ Quaternion(local_axis, math.radians(angle))
    return q


def world_to_root_local(vec_world):
    root_pb = get_rig().pose.bones['root']
    rest = root_pb.bone.matrix_local.to_3x3().normalized()
    return rest.inverted() @ Vector(vec_world)


def get_rig():
    obj = bpy.data.objects.get(DEFAULT_RIG_NAME)
    if obj and obj.type == 'ARMATURE':
        return obj
    for o in bpy.context.scene.objects:
        if o.type == 'ARMATURE':
            return o
    raise RuntimeError('No armature found in scene')


def reset_all_pose_bones():
    rig = get_rig()
    for pb in rig.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.location = (0.0, 0.0, 0.0)
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)


def blank_pose():
    return {'root': {'X': 0.0, 'Y': 0.0, 'Z': 0.0, 'loc': (0.0, 0.0, 0.0)}}


def make_pose(rot=None, root_loc=None, root_rot=None):
    """Create a pose dict.  rot/root_rot values are degrees around armature
    axes.  root_loc is an absolute world-space delta for the root bone."""
    p = blank_pose()
    if root_loc is not None:
        p['root']['loc'] = tuple(root_loc)
    if root_rot:
        p['root'].update(root_rot)
    if rot:
        for bone_name, axes in rot.items():
            p.setdefault(bone_name, {})
            p[bone_name].update(axes)
    return p


# ---------------------------------------------------------------------------
# action / curve helpers
# ---------------------------------------------------------------------------
def action_fcurves(action):
    for layer in action.layers:
        for strip in layer.strips:
            try:
                for channelbag in strip.channelbags:
                    for fc in channelbag.fcurves:
                        yield fc
            except AttributeError:
                pass


def set_action_interpolation(action, interpolation='LINEAR'):
    for fc in action_fcurves(action):
        for kp in fc.keyframe_points:
            kp.interpolation = interpolation
        fc.update()


def new_action(name):
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    return act


# ---------------------------------------------------------------------------
# pose application and ground detection
# ---------------------------------------------------------------------------
def detect_visible_ground_meshes():
    """Return names of evaluated mesh objects that actually have polygons.
    The two base meshes have all faces hidden by mask modifiers and must not
    be used for ground detection."""
    global GROUND_MESH_NAMES
    rig = get_rig()
    if rig.animation_data:
        rig.animation_data.action = None
    reset_all_pose_bones()
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    names = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH':
            continue
        eo = obj.evaluated_get(dg)
        me = eo.to_mesh()
        try:
            if len(me.polygons) > 0:
                names.append(obj.name)
        finally:
            eo.to_mesh_clear()
    GROUND_MESH_NAMES = names
    print('[anim] ground meshes:', GROUND_MESH_NAMES)
    return names


def eval_min_z():
    dg = bpy.context.evaluated_depsgraph_get()
    min_z = 1.0e9
    for name in GROUND_MESH_NAMES:
        obj = bpy.data.objects.get(name)
        if not obj:
            continue
        eo = obj.evaluated_get(dg)
        mw = eo.matrix_world
        for corner in eo.bound_box:
            z = (mw @ Vector(corner)).z
            if z < min_z:
                min_z = z
    return min_z


def ground_character():
    """Adjust root location so the lowest visible mesh point touches z=0.
    Works with no action assigned, which is how the generator calls it."""
    root_pb = get_rig().pose.bones['root']
    bpy.context.view_layer.update()
    min_z = eval_min_z()
    if min_z > 1.0e8:
        return
    if abs(min_z) > 1.0e-6:
        root_pb.location = root_pb.location + world_to_root_local(Vector((0.0, 0.0, -min_z)))
        bpy.context.view_layer.update()


def apply_pose_values(pose, ground=False):
    rig = get_rig()
    for bone_name in CONTROLLED:
        pb = rig.pose.bones.get(bone_name)
        if not pb:
            continue
        axes = pose.get(bone_name, {})
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = world_axis_rotation(
            pb,
            axes.get('X', 0.0),
            axes.get('Y', 0.0),
            axes.get('Z', 0.0),
        )
        pb.location = (0.0, 0.0, 0.0)

    root_pb = rig.pose.bones['root']
    root_loc = pose.get('root', {}).get('loc', (0.0, 0.0, 0.0))
    root_pb.location = world_to_root_local(Vector(root_loc))

    if ground:
        ground_character()


def insert_pose_keyframes(frame):
    rig = get_rig()
    for bone_name in CONTROLLED:
        pb = rig.pose.bones.get(bone_name)
        if not pb:
            continue
        pb.keyframe_insert('rotation_quaternion', frame=frame)
    rig.pose.bones['root'].keyframe_insert('location', frame=frame)


# ---------------------------------------------------------------------------
# pose interpolation for hand-authored key poses
# ---------------------------------------------------------------------------
class PoseTrack:
    def __init__(self, keys):
        # keys: list of (frame, pose_dict)
        self.keys = sorted(keys, key=lambda item: item[0])
        self.bones = set()
        for _, pose in self.keys:
            for bone_name in pose.keys():
                self.bones.add(bone_name)
        self.bones = list(self.bones)

    @staticmethod
    def _axis_value(pose, bone_name, axis):
        return float(pose.get(bone_name, {}).get(axis, 0.0))

    def sample(self, frame):
        if frame <= self.keys[0][0]:
            return deepcopy(self.keys[0][1])
        if frame >= self.keys[-1][0]:
            return deepcopy(self.keys[-1][1])
        left = self.keys[0]
        right = self.keys[-1]
        for i in range(len(self.keys) - 1):
            if self.keys[i][0] <= frame <= self.keys[i + 1][0]:
                left, right = self.keys[i], self.keys[i + 1]
                break
        f0, p0 = left
        f1, p1 = right
        u = 0.0 if f1 == f0 else smoothstep((frame - f0) / float(f1 - f0))
        out = {}
        # rotations
        for bone_name in CONTROLLED:
            bone_out = {}
            for axis in ('X', 'Y', 'Z'):
                v0 = self._axis_value(p0, bone_name, axis)
                v1 = self._axis_value(p1, bone_name, axis)
                bone_out[axis] = v0 + (v1 - v0) * u
            out[bone_name] = bone_out
        # root location
        l0 = p0.get('root', {}).get('loc', (0.0, 0.0, 0.0))
        l1 = p1.get('root', {}).get('loc', (0.0, 0.0, 0.0))
        out['root']['loc'] = tuple(l0[i] + (l1[i] - l0[i]) * u for i in range(3))
        return out


# ---------------------------------------------------------------------------
# procedural cycles
# ---------------------------------------------------------------------------
def pose_idle(frame, n=48):
    ph = 2.0 * math.pi * frame / float(n)
    breath = math.sin(ph)
    sway = math.sin(ph * 0.5)
    return make_pose(
        root_loc=(0.005 * sway, 0.0, BASE_Z + 0.003 * breath),
        root_rot={'X': 0.8 * breath, 'Y': 0.4 * sway},
        rot={
            'spine05': {'X': 0.5 * breath},
            'spine04': {'X': 0.8 * breath},
            'spine03': {'X': 1.2 * breath},
            'spine02': {'X': 1.8 * breath, 'Y': -0.5 * sway},
            'spine01': {'X': -0.6 * breath},
            'neck01': {'X': -0.5 * breath},
            'head': {'X': -0.7 * breath, 'Y': 0.5 * sway},
            'upperarm02.L': {'X': 1.8 * breath, 'Y': -1.0 * sway},
            'upperarm02.R': {'X': 1.8 * breath, 'Y': 1.0 * sway},
            'lowerarm01.L': {'X': -6.0 - 1.5 * breath},
            'lowerarm01.R': {'X': -6.0 - 1.5 * breath},
        },
    )


def pose_walk(frame, n=24):
    ph = 2.0 * math.pi * frame / float(n)
    s = math.sin(ph)
    c2 = math.cos(2.0 * ph)
    A_leg = 25.0
    K_knee = 50.0
    A_arm = 24.0

    thigh_l = -A_leg * s
    thigh_r = A_leg * s
    knee_l = K_knee * max(0.0, math.sin(ph)) ** 1.25
    knee_r = K_knee * max(0.0, -math.sin(ph)) ** 1.25
    foot_l = -0.45 * (thigh_l + knee_l) + 4.0 * s
    foot_r = -0.45 * (thigh_r + knee_r) - 4.0 * s

    return make_pose(
        root_loc=(0.008 * s, 0.0, BASE_Z + 0.012 - 0.018 * c2),
        root_rot={'X': 2.0, 'Y': 1.2 * s, 'Z': -4.0 * s},
        rot={
            'spine05': {'X': 1.0 + 0.5 * c2, 'Z': 1.0 * s},
            'spine04': {'X': 1.5 + 0.8 * c2, 'Z': 1.5 * s},
            'spine03': {'X': 2.0 + 1.0 * c2, 'Z': 2.0 * s},
            'spine02': {'X': 2.5 + 0.8 * c2, 'Z': 2.5 * s, 'Y': -0.8 * s},
            'spine01': {'X': 1.0, 'Z': 1.5 * s},
            'neck01': {'X': -1.0, 'Z': -1.0 * s},
            'head': {'X': -1.5, 'Z': -1.5 * s},
            'upperarm02.L': {'X': A_arm * s, 'Y': -2.0 - 1.5 * s},
            'upperarm02.R': {'X': -A_arm * s, 'Y': 2.0 + 1.5 * s},
            'lowerarm01.L': {'X': -14.0 - 10.0 * max(0.0, -s)},
            'lowerarm01.R': {'X': -14.0 - 10.0 * max(0.0, s)},
            'upperleg02.L': {'X': thigh_l, 'Y': -1.0 * s},
            'upperleg02.R': {'X': thigh_r, 'Y': 1.0 * s},
            'lowerleg01.L': {'X': knee_l},
            'lowerleg01.R': {'X': knee_r},
            'lowerleg02.L': {'X': 0.20 * knee_l},
            'lowerleg02.R': {'X': 0.20 * knee_r},
            'foot.L': {'X': foot_l},
            'foot.R': {'X': foot_r},
            'toe1-1.L': {'X': -0.25 * foot_l},
            'toe1-1.R': {'X': -0.25 * foot_r},
        },
    )


def pose_run(frame, n=16):
    ph = 2.0 * math.pi * frame / float(n)
    s = math.sin(ph)
    c2 = math.cos(2.0 * ph)
    A_leg = 38.0
    K_knee = 85.0
    A_arm = 44.0

    thigh_l = -A_leg * s
    thigh_r = A_leg * s
    knee_l = 10.0 + K_knee * max(0.0, math.sin(ph)) ** 1.35
    knee_r = 10.0 + K_knee * max(0.0, -math.sin(ph)) ** 1.35
    foot_l = -0.40 * (thigh_l + knee_l) + 8.0 * s
    foot_r = -0.40 * (thigh_r + knee_r) - 8.0 * s
    # Two small flight phases per cycle.  Kept deliberately subtle here so
    # the clip also works when the game code drives root motion itself.
    bob = 0.02 + 0.055 * (0.5 - 0.5 * c2)

    return make_pose(
        root_loc=(0.012 * s, -0.015, BASE_Z + bob),
        root_rot={'X': 11.0 + 2.0 * c2, 'Y': 2.0 * s, 'Z': -6.0 * s},
        rot={
            'spine05': {'X': 2.0, 'Z': 1.5 * s},
            'spine04': {'X': 3.0, 'Z': 2.0 * s},
            'spine03': {'X': 4.0, 'Z': 3.0 * s},
            'spine02': {'X': 6.0 + 1.0 * c2, 'Z': 4.0 * s, 'Y': -1.5 * s},
            'spine01': {'X': 4.0, 'Z': 2.0 * s},
            'neck01': {'X': -5.0},
            'head': {'X': -6.0, 'Z': -2.0 * s},
            'upperarm02.L': {'X': 5.0 + A_arm * s, 'Y': -12.0},
            'upperarm02.R': {'X': 5.0 - A_arm * s, 'Y': 12.0},
            'lowerarm01.L': {'X': -72.0 - 18.0 * max(0.0, -s)},
            'lowerarm01.R': {'X': -72.0 - 18.0 * max(0.0, s)},
            'wrist.L': {'X': -8.0},
            'wrist.R': {'X': -8.0},
            'upperleg02.L': {'X': thigh_l, 'Y': -1.5 * s},
            'upperleg02.R': {'X': thigh_r, 'Y': 1.5 * s},
            'lowerleg01.L': {'X': knee_l},
            'lowerleg01.R': {'X': knee_r},
            'lowerleg02.L': {'X': 0.18 * knee_l},
            'lowerleg02.R': {'X': 0.18 * knee_r},
            'foot.L': {'X': foot_l},
            'foot.R': {'X': foot_r},
            'toe1-1.L': {'X': -0.2 * foot_l},
            'toe1-1.R': {'X': -0.2 * foot_r},
        },
    )


# ---------------------------------------------------------------------------
# key-posed actions
# ---------------------------------------------------------------------------
def build_jump_track():
    z = BASE_Z
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, z))),
        (6, make_pose(root_loc=(0.0, 0.0, z - 0.12), rot={
            'spine05': {'X': 5.0}, 'spine04': {'X': 7.0}, 'spine03': {'X': 9.0},
            'spine02': {'X': 14.0}, 'spine01': {'X': 6.0},
            'upperleg02.L': {'X': -38.0}, 'upperleg02.R': {'X': -38.0},
            'lowerleg01.L': {'X': 70.0}, 'lowerleg01.R': {'X': 70.0},
            'lowerleg02.L': {'X': 12.0}, 'lowerleg02.R': {'X': 12.0},
            'foot.L': {'X': -28.0}, 'foot.R': {'X': -28.0},
            'upperarm02.L': {'X': 46.0, 'Y': -4.0},
            'upperarm02.R': {'X': 46.0, 'Y': 4.0},
            'lowerarm01.L': {'X': -20.0}, 'lowerarm01.R': {'X': -20.0},
        })),
        (12, make_pose(root_loc=(0.0, 0.0, z + 0.10), rot={
            'spine03': {'X': 3.0}, 'spine02': {'X': 5.0},
            'upperleg02.L': {'X': 6.0}, 'upperleg02.R': {'X': 6.0},
            'lowerleg01.L': {'X': 4.0}, 'lowerleg01.R': {'X': 4.0},
            'foot.L': {'X': 30.0}, 'foot.R': {'X': 30.0},
            'upperarm02.L': {'X': -118.0, 'Y': -6.0},
            'upperarm02.R': {'X': -118.0, 'Y': 6.0},
            'lowerarm01.L': {'X': -8.0}, 'lowerarm01.R': {'X': -8.0},
        })),
        (18, make_pose(root_loc=(0.0, 0.0, z + 0.52), rot={
            'spine03': {'X': -2.0}, 'spine02': {'X': -4.0},
            'upperleg02.L': {'X': -48.0}, 'upperleg02.R': {'X': -48.0},
            'lowerleg01.L': {'X': 86.0}, 'lowerleg01.R': {'X': 86.0},
            'lowerleg02.L': {'X': 10.0}, 'lowerleg02.R': {'X': 10.0},
            'foot.L': {'X': -12.0}, 'foot.R': {'X': -12.0},
            'upperarm02.L': {'X': -80.0, 'Y': -22.0},
            'upperarm02.R': {'X': -80.0, 'Y': 22.0},
            'lowerarm01.L': {'X': -28.0}, 'lowerarm01.R': {'X': -28.0},
        })),
        (24, make_pose(root_loc=(0.0, 0.0, z + 0.18), rot={
            'spine02': {'X': 4.0},
            'upperleg02.L': {'X': -12.0}, 'upperleg02.R': {'X': -12.0},
            'lowerleg01.L': {'X': 26.0}, 'lowerleg01.R': {'X': 26.0},
            'foot.L': {'X': -16.0}, 'foot.R': {'X': -16.0},
            'upperarm02.L': {'X': -30.0, 'Y': -12.0},
            'upperarm02.R': {'X': -30.0, 'Y': 12.0},
            'lowerarm01.L': {'X': -16.0}, 'lowerarm01.R': {'X': -16.0},
        })),
        (30, make_pose(root_loc=(0.0, 0.0, z - 0.14), rot={
            'spine05': {'X': 6.0}, 'spine04': {'X': 9.0}, 'spine03': {'X': 12.0},
            'spine02': {'X': 18.0}, 'spine01': {'X': 8.0},
            'upperleg02.L': {'X': -44.0}, 'upperleg02.R': {'X': -44.0},
            'lowerleg01.L': {'X': 80.0}, 'lowerleg01.R': {'X': 80.0},
            'lowerleg02.L': {'X': 10.0}, 'lowerleg02.R': {'X': 10.0},
            'foot.L': {'X': -30.0}, 'foot.R': {'X': -30.0},
            'upperarm02.L': {'X': -38.0, 'Y': -20.0},
            'upperarm02.R': {'X': -38.0, 'Y': 20.0},
            'lowerarm01.L': {'X': -28.0}, 'lowerarm01.R': {'X': -28.0},
        })),
        (36, make_pose(root_loc=(0.0, 0.0, z))),
    ])


def build_attack_track():
    z = BASE_Z
    ready = {
        'spine03': {'X': 3.0, 'Z': 6.0}, 'spine02': {'X': 5.0, 'Z': 10.0},
        'spine01': {'X': 2.0, 'Z': 6.0},
        'upperarm02.R': {'X': -34.0, 'Y': 10.0},
        'lowerarm01.R': {'X': -62.0}, 'wrist.R': {'X': -8.0},
        'upperarm02.L': {'X': -20.0, 'Y': -12.0},
        'lowerarm01.L': {'X': -48.0}, 'wrist.L': {'X': -6.0},
    }
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, z), rot=ready)),
        (5, make_pose(root_loc=(0.0, 0.0, z - 0.03), root_rot={'Z': 8.0}, rot={
            'spine05': {'Z': 4.0}, 'spine04': {'Z': 7.0}, 'spine03': {'X': -2.0, 'Z': 11.0},
            'spine02': {'X': 0.0, 'Z': 24.0}, 'spine01': {'X': -4.0, 'Z': 14.0},
            'upperarm02.R': {'X': 130.0, 'Y': 20.0}, 'lowerarm01.R': {'X': -100.0},
            'wrist.R': {'X': -20.0},
            'upperarm02.L': {'X': -50.0, 'Y': -20.0}, 'lowerarm01.L': {'X': -72.0},
            'upperleg02.L': {'X': -8.0}, 'upperleg02.R': {'X': 5.0},
            'lowerleg01.L': {'X': 12.0}, 'lowerleg01.R': {'X': 8.0},
        })),
        (10, make_pose(root_loc=(0.0, -0.14, z - 0.05), root_rot={'Z': -10.0}, rot={
            'spine05': {'X': 4.0, 'Z': -6.0}, 'spine04': {'X': 6.0, 'Z': -9.0},
            'spine03': {'X': 10.0, 'Z': -13.0},
            'spine02': {'X': 14.0, 'Z': -24.0}, 'spine01': {'X': 8.0, 'Z': -14.0},
            'upperarm02.R': {'X': -96.0, 'Y': -16.0}, 'lowerarm01.R': {'X': -16.0},
            'wrist.R': {'X': 12.0},
            'upperarm02.L': {'X': 18.0, 'Y': 12.0}, 'lowerarm01.L': {'X': -32.0},
            'upperleg02.L': {'X': -22.0}, 'upperleg02.R': {'X': -12.0},
            'lowerleg01.L': {'X': 32.0}, 'lowerleg01.R': {'X': 22.0},
            'foot.L': {'X': -14.0}, 'foot.R': {'X': -10.0},
        })),
        (14, make_pose(root_loc=(0.0, -0.18, z - 0.06), root_rot={'Z': -12.0}, rot={
            'spine05': {'X': 5.0, 'Z': -7.0}, 'spine04': {'X': 8.0, 'Z': -10.0},
            'spine03': {'X': 12.0, 'Z': -15.0},
            'spine02': {'X': 18.0, 'Z': -28.0}, 'spine01': {'X': 10.0, 'Z': -16.0},
            'upperarm02.R': {'X': -58.0, 'Y': -20.0, 'Z': -10.0},
            'lowerarm01.R': {'X': -68.0}, 'wrist.R': {'X': 6.0},
            'upperarm02.L': {'X': 28.0, 'Y': 14.0}, 'lowerarm01.L': {'X': -22.0},
            'upperleg02.L': {'X': -26.0}, 'upperleg02.R': {'X': -14.0},
            'lowerleg01.L': {'X': 38.0}, 'lowerleg01.R': {'X': 26.0},
            'foot.L': {'X': -16.0}, 'foot.R': {'X': -12.0},
        })),
        (20, make_pose(root_loc=(0.0, -0.08, z - 0.01), rot={
            'spine03': {'X': 3.0, 'Z': 4.0}, 'spine02': {'X': 6.0, 'Z': 8.0},
            'spine01': {'X': 3.0, 'Z': 5.0},
            'upperarm02.R': {'X': -30.0, 'Y': 8.0}, 'lowerarm01.R': {'X': -58.0},
            'wrist.R': {'X': -6.0},
            'upperarm02.L': {'X': -22.0, 'Y': -10.0}, 'lowerarm01.L': {'X': -46.0},
        })),
        (28, make_pose(root_loc=(0.0, 0.0, z), rot=ready)),
    ])


def build_dodge_track():
    z = BASE_Z
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, z))),
        (4, make_pose(root_loc=(0.0, 0.0, z - 0.08), root_rot={'Y': 8.0}, rot={
            'spine03': {'X': 5.0, 'Y': -2.0}, 'spine02': {'X': 10.0, 'Y': -5.0},
            'spine01': {'X': 5.0},
            'upperleg02.L': {'X': -30.0, 'Y': -10.0},
            'upperleg02.R': {'X': -30.0, 'Y': 10.0},
            'lowerleg01.L': {'X': 55.0}, 'lowerleg01.R': {'X': 55.0},
            'foot.L': {'X': -22.0}, 'foot.R': {'X': -22.0},
            'upperarm02.L': {'X': -12.0, 'Y': -16.0}, 'upperarm02.R': {'X': -12.0, 'Y': 16.0},
            'lowerarm01.L': {'X': -34.0}, 'lowerarm01.R': {'X': -34.0},
        })),
        (10, make_pose(root_loc=(0.42, 0.0, z + 0.14), root_rot={'Y': 24.0}, rot={
            'spine03': {'X': 3.0, 'Y': -8.0}, 'spine02': {'X': 5.0, 'Y': -14.0},
            'spine01': {'X': 2.0, 'Y': -8.0},
            'upperleg02.L': {'X': -10.0, 'Y': -38.0},
            'upperleg02.R': {'X': -46.0, 'Y': 16.0},
            'lowerleg01.L': {'X': 22.0}, 'lowerleg01.R': {'X': 84.0},
            'foot.L': {'X': -10.0}, 'foot.R': {'X': -28.0},
            'upperarm02.L': {'X': -18.0, 'Y': -52.0},
            'upperarm02.R': {'X': -42.0, 'Y': 18.0},
            'lowerarm01.L': {'X': -20.0}, 'lowerarm01.R': {'X': -70.0},
        })),
        (16, make_pose(root_loc=(0.78, 0.0, z - 0.10), root_rot={'Y': 15.0}, rot={
            'spine03': {'X': 8.0, 'Y': -4.0}, 'spine02': {'X': 14.0, 'Y': -6.0},
            'spine01': {'X': 7.0},
            'upperleg02.L': {'X': -36.0, 'Y': -14.0},
            'upperleg02.R': {'X': -40.0, 'Y': 16.0},
            'lowerleg01.L': {'X': 66.0}, 'lowerleg01.R': {'X': 72.0},
            'foot.L': {'X': -26.0}, 'foot.R': {'X': -28.0},
            'upperarm02.L': {'X': -16.0, 'Y': -34.0},
            'upperarm02.R': {'X': -24.0, 'Y': 18.0},
            'lowerarm01.L': {'X': -26.0}, 'lowerarm01.R': {'X': -52.0},
        })),
        (24, make_pose(root_loc=(0.90, 0.0, z), rot={
            'upperarm02.L': {'Y': -4.0}, 'upperarm02.R': {'Y': 4.0},
            'lowerarm01.L': {'X': -8.0}, 'lowerarm01.R': {'X': -8.0},
        })),
    ])


def build_death_track():
    # Root z is determined by ground_character() for this clip, so only x/y
    # root motion is supplied in the poses.
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, 0.0), root_rot={'X': -8.0}, rot={
            'spine05': {'X': -3.0}, 'spine04': {'X': -5.0}, 'spine03': {'X': -7.0},
            'spine02': {'X': -14.0, 'Z': 5.0}, 'spine01': {'X': -10.0},
            'neck01': {'X': -4.0}, 'head': {'X': -6.0},
            'upperarm02.L': {'X': -28.0, 'Y': -58.0},
            'upperarm02.R': {'X': -28.0, 'Y': 58.0},
            'lowerarm01.L': {'X': -20.0}, 'lowerarm01.R': {'X': -20.0},
        })),
        (8, make_pose(root_loc=(0.0, 0.16, 0.0), root_rot={'X': -22.0}, rot={
            'spine02': {'X': -8.0}, 'spine01': {'X': -6.0},
            'head': {'X': -8.0},
            'upperleg02.L': {'X': 20.0, 'Y': -8.0},
            'upperleg02.R': {'X': -10.0, 'Y': 8.0},
            'lowerleg01.L': {'X': 32.0}, 'lowerleg01.R': {'X': 22.0},
            'foot.L': {'X': -16.0}, 'foot.R': {'X': -12.0},
            'upperarm02.L': {'X': -16.0, 'Y': -66.0},
            'upperarm02.R': {'X': -16.0, 'Y': 66.0},
            'lowerarm01.L': {'X': -34.0}, 'lowerarm01.R': {'X': -34.0},
        })),
        (16, make_pose(root_loc=(0.0, 0.24, 0.0), root_rot={'X': -48.0}, rot={
            'spine02': {'X': 12.0}, 'spine01': {'X': 7.0},
            'head': {'X': 8.0},
            'upperleg02.L': {'X': -58.0, 'Y': -12.0},
            'upperleg02.R': {'X': -58.0, 'Y': 12.0},
            'lowerleg01.L': {'X': 98.0}, 'lowerleg01.R': {'X': 98.0},
            'lowerleg02.L': {'X': 12.0}, 'lowerleg02.R': {'X': 12.0},
            'foot.L': {'X': -24.0}, 'foot.R': {'X': -24.0},
            'upperarm02.L': {'X': -48.0, 'Y': -42.0},
            'upperarm02.R': {'X': -48.0, 'Y': 42.0},
            'lowerarm01.L': {'X': -48.0}, 'lowerarm01.R': {'X': -48.0},
        })),
        (26, make_pose(root_loc=(0.0, 0.30, 0.0), root_rot={'X': -76.0}, rot={
            'spine02': {'X': 4.0}, 'spine01': {'X': 2.0},
            'head': {'X': 12.0},
            'upperleg02.L': {'X': -12.0, 'Y': -22.0},
            'upperleg02.R': {'X': -12.0, 'Y': 22.0},
            'lowerleg01.L': {'X': 42.0}, 'lowerleg01.R': {'X': 42.0},
            'foot.L': {'X': -16.0}, 'foot.R': {'X': -16.0},
            'upperarm02.L': {'X': -18.0, 'Y': -72.0},
            'upperarm02.R': {'X': -18.0, 'Y': 72.0},
            'lowerarm01.L': {'X': -24.0}, 'lowerarm01.R': {'X': -24.0},
        })),
        (36, make_pose(root_loc=(0.0, 0.32, 0.0), root_rot={'X': -90.0}, rot={
            'spine02': {'X': 0.0}, 'spine01': {'X': 0.0},
            'head': {'X': 10.0},
            'upperleg02.L': {'X': -12.0, 'Y': -16.0},
            'upperleg02.R': {'X': -12.0, 'Y': 16.0},
            'lowerleg01.L': {'X': 34.0}, 'lowerleg01.R': {'X': 34.0},
            'foot.L': {'X': -10.0}, 'foot.R': {'X': -10.0},
            'upperarm02.L': {'X': -6.0, 'Y': -78.0},
            'upperarm02.R': {'X': -6.0, 'Y': 78.0},
            'lowerarm01.L': {'X': -18.0}, 'lowerarm01.R': {'X': -18.0},
        })),
        (48, make_pose(root_loc=(0.0, 0.32, 0.0), root_rot={'X': -90.0}, rot={
            'spine02': {'X': 0.0},
            'head': {'X': 8.0},
            'upperleg02.L': {'X': -10.0, 'Y': -14.0},
            'upperleg02.R': {'X': -10.0, 'Y': 14.0},
            'lowerleg01.L': {'X': 30.0}, 'lowerleg01.R': {'X': 30.0},
            'upperarm02.L': {'X': -2.0, 'Y': -74.0},
            'upperarm02.R': {'X': -2.0, 'Y': 74.0},
            'lowerarm01.L': {'X': -14.0}, 'lowerarm01.R': {'X': -14.0},
        })),
    ])


def build_meditate_track():
    # Cross-legged approximation.  The z position is solved by
    # ground_character() at every frame.
    base = {
        'upperleg01.L': {'Y': -10.0}, 'upperleg01.R': {'Y': 10.0},
        'upperleg02.L': {'X': -36.0, 'Y': -52.0},
        'upperleg02.R': {'X': -36.0, 'Y': 52.0},
        'lowerleg01.L': {'X': 108.0, 'Y': 10.0},
        'lowerleg01.R': {'X': 108.0, 'Y': -10.0},
        'lowerleg02.L': {'X': 10.0}, 'lowerleg02.R': {'X': 10.0},
        'foot.L': {'X': -12.0, 'Y': -8.0}, 'foot.R': {'X': -12.0, 'Y': 8.0},
        'upperarm02.L': {'X': 0.0, 'Y': 25.0},
        'upperarm02.R': {'X': 0.0, 'Y': -25.0},
        'lowerarm01.L': {'X': -10.0, 'Y': 5.0},
        'lowerarm01.R': {'X': -10.0, 'Y': -5.0},
        'wrist.L': {'X': -8.0}, 'wrist.R': {'X': -8.0},
        'spine02': {'X': 2.0}, 'spine01': {'X': 1.0},
        'neck01': {'X': -2.0}, 'head': {'X': -2.0},
    }
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, 0.0), rot=base)),
        (18, make_pose(root_loc=(0.0, 0.0, 0.0), rot={
            **base,
            'spine02': {'X': 4.0}, 'spine01': {'X': 2.0},
            'head': {'X': -3.0},
        })),
        (36, make_pose(root_loc=(0.0, 0.0, 0.0), rot={
            **base,
            'spine02': {'X': 0.0}, 'spine01': {'X': 0.0},
            'head': {'X': -1.0},
        })),
        (54, make_pose(root_loc=(0.0, 0.0, 0.0), rot={
            **base,
            'spine02': {'X': 4.0}, 'spine01': {'X': 2.0},
            'head': {'X': -3.0},
        })),
        (72, make_pose(root_loc=(0.0, 0.0, 0.0), rot=base)),
    ])


def build_sleep_side_track():
    # Lie on the character's left side (root rolled +90 deg around Y).
    # Grounding solves the resting height.
    base = {
        'spine03': {'X': 2.0}, 'spine02': {'X': 4.0, 'Y': 3.0},
        'spine01': {'X': 2.0}, 'neck01': {'X': -2.0},
        'head': {'X': 5.0, 'Z': 8.0},
        'upperarm02.L': {'X': -112.0, 'Y': -18.0},
        'lowerarm01.L': {'X': -82.0, 'Y': -8.0},
        'wrist.L': {'X': -8.0},
        'upperarm02.R': {'X': -38.0, 'Y': 28.0},
        'lowerarm01.R': {'X': -92.0},
        'wrist.R': {'X': -8.0},
        'upperleg02.L': {'X': -18.0, 'Y': -8.0},
        'lowerleg01.L': {'X': 48.0}, 'lowerleg02.L': {'X': 8.0},
        'foot.L': {'X': -12.0},
        'upperleg02.R': {'X': -30.0, 'Y': 10.0},
        'lowerleg01.R': {'X': 68.0}, 'lowerleg02.R': {'X': 10.0},
        'foot.R': {'X': -16.0},
    }
    return PoseTrack([
        (0, make_pose(root_loc=(0.0, 0.0, 0.0), root_rot={'Y': 90.0}, rot=base)),
        (24, make_pose(root_loc=(0.0, 0.0, 0.0), root_rot={'Y': 90.0}, rot={
            **base,
            'spine02': {'X': 6.0, 'Y': 3.0},
            'head': {'X': 6.0, 'Z': 8.0},
        })),
        (48, make_pose(root_loc=(0.0, 0.0, 0.0), root_rot={'Y': 90.0}, rot={
            **base,
            'spine02': {'X': 3.0, 'Y': 3.0},
            'head': {'X': 4.0, 'Z': 8.0},
        })),
        (72, make_pose(root_loc=(0.0, 0.0, 0.0), root_rot={'Y': 90.0}, rot=base)),
    ])


# ---------------------------------------------------------------------------
# extra vertical motion for grounded one-shot actions
# ---------------------------------------------------------------------------
def sample_extra_z(key_values, frame):
    """Piecewise smooth interpolation for an extra world-Z offset."""
    if frame <= key_values[0][0]:
        return float(key_values[0][1])
    if frame >= key_values[-1][0]:
        return float(key_values[-1][1])
    for i in range(len(key_values) - 1):
        f0, v0 = key_values[i]
        f1, v1 = key_values[i + 1]
        if f0 <= frame <= f1:
            u = 0.0 if f1 == f0 else smoothstep((frame - f0) / float(f1 - f0))
            return float(v0) + (float(v1) - float(v0)) * u
    return 0.0


def jump_extra_z(frame):
    return sample_extra_z([
        (0, 0.0), (6, 0.0), (12, 0.08), (18, 0.55),
        (24, 0.20), (30, 0.0), (36, 0.0),
    ], frame)


def dodge_extra_z(frame):
    return sample_extra_z([
        (0, 0.0), (4, 0.0), (10, 0.16), (16, 0.0), (24, 0.0),
    ], frame)


# ---------------------------------------------------------------------------
# generation
# ---------------------------------------------------------------------------
def generate_action(name, frames, pose_func, ground_func=None, extra_z_func=None, loop=False):
    rig = get_rig()
    if rig.animation_data is None:
        rig.animation_data_create()
    act = new_action(name)
    # Ensure a clean starting pose independent of the previous action.
    rig.animation_data.action = None
    reset_all_pose_bones()

    for frame in frames:
        pose = pose_func(frame)
        ground = ground_func(frame) if ground_func else False
        # Pose and (optionally) ground with no action assigned so the
        # dependency graph cannot overwrite our manual values from an
        # already-keyed action.
        rig.animation_data.action = None
        reset_all_pose_bones()
        apply_pose_values(pose, ground=ground)
        # Optional additional vertical offset applied after grounding (used
        # for the flight phases of Run).
        if extra_z_func:
            extra_z = extra_z_func(frame)
            if abs(extra_z) > 1e-8:
                root_pb = rig.pose.bones['root']
                root_pb.location = root_pb.location + world_to_root_local(Vector((0.0, 0.0, extra_z)))
                bpy.context.view_layer.update()
        # Now attach the action and record the current pose.
        rig.animation_data.action = act
        insert_pose_keyframes(frame)

    rig.animation_data.action = None
    reset_all_pose_bones()
    act.use_frame_range = True
    act.frame_start = float(frames[0])
    act.frame_end = float(frames[-1])
    act.use_cyclic = bool(loop)
    set_action_interpolation(act, 'LINEAR')
    return act


def build_all_actions():
    acts = {}
    # cycles: key 0..N inclusive so the last frame duplicates frame 0
    cycles = [
        ('Idle', 48, pose_idle, True),
        ('Walk', 24, pose_walk, True),
        ('Run', 16, pose_run, True),
    ]
    for name, n, func, loop in cycles:
        print('[anim] building cycle:', name)
        if name == 'Walk':
            # Keep the lowest foot on the floor during the whole cycle.
            acts[name] = generate_action(
                name, range(0, n + 1), lambda f, fn=func: fn(f),
                ground_func=lambda f: True, loop=loop)
        elif name == 'Run':
            # Ground contact plus two short flight phases per cycle.
            acts[name] = generate_action(
                name, range(0, n + 1), lambda f, fn=func: fn(f),
                ground_func=lambda f: True,
                extra_z_func=lambda f: 0.065 * max(0.0, -math.cos(4.0 * math.pi * f / float(n))),
                loop=loop)
        else:
            acts[name] = generate_action(name, range(0, n + 1), lambda f, fn=func: fn(f), loop=loop)

    # one-shot / interpolated actions
    print('[anim] building Jump')
    jump_track = build_jump_track()
    acts['Jump'] = generate_action('Jump', range(0, 37), jump_track.sample, ground_func=lambda f: True, extra_z_func=jump_extra_z, loop=False)

    print('[anim] building Attack_Knife')
    attack_track = build_attack_track()
    acts['Attack_Knife'] = generate_action('Attack_Knife', range(0, 29), attack_track.sample, ground_func=lambda f: True, loop=False)

    print('[anim] building Dodge')
    dodge_track = build_dodge_track()
    acts['Dodge'] = generate_action('Dodge', range(0, 25), dodge_track.sample, ground_func=lambda f: True, extra_z_func=dodge_extra_z, loop=False)

    print('[anim] building Death (grounded)')
    death_track = build_death_track()
    acts['Death'] = generate_action('Death', range(0, 49), death_track.sample,
                                    ground_func=lambda f: f >= 0, loop=False)

    print('[anim] building Meditate (grounded)')
    med_track = build_meditate_track()
    acts['Meditate'] = generate_action('Meditate', range(0, 73), med_track.sample,
                                       ground_func=lambda f: f >= 0, loop=True)

    print('[anim] building Sleep_Side (grounded)')
    sleep_track = build_sleep_side_track()
    acts['Sleep_Side'] = generate_action('Sleep_Side', range(0, 73), sleep_track.sample,
                                         ground_func=lambda f: f >= 0, loop=True)
    return acts


# ---------------------------------------------------------------------------
# validation / export
# ---------------------------------------------------------------------------
def collect_bone_positions(action, frames_to_check):
    rig = get_rig()
    old_action = rig.animation_data.action if rig.animation_data else None
    rig.animation_data.action = action
    rows = []
    for f in frames_to_check:
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        row = {'frame': f}
        for bone_name in ('root', 'head', 'foot.L', 'foot.R', 'wrist.L', 'wrist.R'):
            pb = rig.pose.bones.get(bone_name)
            if pb:
                p = pb.head
                row[bone_name] = (round(p.x, 4), round(p.y, 4), round(p.z, 4))
        rows.append(row)
    rig.animation_data.action = old_action
    return rows


def print_action_summary(actions):
    rig = get_rig()
    print('\n[anim] === action summary ===')
    for name, act in actions.items():
        print(f'  {name:14s} frames {act.frame_start:.0f}-{act.frame_end:.0f} '
              f'cyclic={act.use_cyclic} fcurves={sum(1 for _ in action_fcurves(act))}')
    # Print a few joint positions to make headless debugging easier.
    for name in ('Walk', 'Run', 'Jump', 'Death', 'Meditate', 'Sleep_Side'):
        act = actions.get(name)
        if not act:
            continue
        frames = [int(act.frame_start), int((act.frame_start + act.frame_end) // 2), int(act.frame_end)]
        print(f'[anim] joint check {name}:')
        for row in collect_bone_positions(act, frames):
            print('   ', row)


def export_godot(blend_path, glb_path):
    rig = get_rig()
    # Leave the scene in rest pose for a clean export.
    if rig.animation_data:
        rig.animation_data.action = None
    reset_all_pose_bones()
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print('[anim] saved blend:', blend_path)

    # Export all actions as separate glTF animation clips.
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_animations=True,
        export_animation_mode='ACTIONS',
        export_anim_slide_to_zero=True,
        export_optimize_animation_size=True,
        export_bake_animation=True,
        export_anim_single_armature=True,
        export_yup=True,
        export_morph_animation=False,
        export_extra_animations=False,
    )
    print('[anim] exported glb:', glb_path, 'bytes', os.path.getsize(glb_path))


def main():
    argv = sys.argv
    if '--' in argv:
        argv = argv[argv.index('--') + 1:]
    else:
        argv = []
    input_blend = os.path.abspath(argv[0]) if len(argv) >= 1 else os.path.abspath('person.blend')
    out_dir = os.path.abspath(argv[1]) if len(argv) >= 2 else os.path.dirname(input_blend)
    os.makedirs(out_dir, exist_ok=True)

    # If the script is run with a .blend already loaded via --background, the
    # input path is only informational.  If not, open it explicitly.
    current = bpy.data.filepath
    if not current or os.path.abspath(current) != input_blend:
        print('[anim] opening blend:', input_blend)
        bpy.ops.wm.open_mainfile(filepath=input_blend)

    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = 0

    detect_visible_ground_meshes()

    # A small base translation keeps the shoes on the floor in the rest pose.
    # It is computed from the actual visible geometry.
    global BASE_Z
    rig = get_rig()
    if rig.animation_data:
        rig.animation_data.action = None
    reset_all_pose_bones()
    bpy.context.view_layer.update()
    rest_min_z = eval_min_z()
    BASE_Z = max(0.0, -rest_min_z) if rest_min_z < 1e8 else 0.0
    print(f'[anim] rest min z = {rest_min_z:.6f}, BASE_Z = {BASE_Z:.6f}')

    t0 = time.time()
    actions = build_all_actions()
    print(f'[anim] action generation took {time.time() - t0:.1f}s')
    print_action_summary(actions)

    blend_out = os.path.join(out_dir, 'character_rigged_animated.blend')
    glb_out = os.path.join(out_dir, 'character_animated.glb')
    export_godot(blend_out, glb_out)
    print('[anim] done')


if __name__ == '__main__':
    main()




