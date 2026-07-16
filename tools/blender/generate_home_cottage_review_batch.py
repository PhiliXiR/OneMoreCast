"""Generate issue #98's editable Home Cottage review batch with Blender."""
import math
import os

import bpy
from mathutils import Vector

OUT = os.environ["ONE_MORE_CAST_HOME_COTTAGE_OUT"]
os.makedirs(OUT, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1200
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (0.025, 0.04, 0.055)


def material(name, color, roughness=0.65, metallic=0.0):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return result


WOOD = material("Weathered wood", (0.22, 0.12, 0.07), 0.78)
WOOD_LIGHT = material("Weathered wood light", (0.38, 0.23, 0.13), 0.75)
ROOF = material("Dark roof", (0.045, 0.055, 0.065), 0.9)
WINDOW = material("Warm window glass", (0.95, 0.45, 0.14), 0.25, 0.0)
BRASS = material("Restrained brass iron", (0.22, 0.13, 0.045), 0.45, 0.65)
MOSS = material("Faded moss cloth", (0.11, 0.19, 0.12), 0.85)
SKIN = material("Mara skin", (0.42, 0.21, 0.12), 0.72)
HAIR = material("Mara dark hair", (0.04, 0.018, 0.01), 0.8)


def collection(name):
    item = bpy.data.collections.new(name)
    scene.collection.children.link(item)
    return item


EXTERIOR = collection("EXTERIOR_SHELL")
INTERIOR = collection("INTERIOR_ROOFLESS")
MARA = collection("MARA_VALE")
REVIEW = collection("REVIEW_LIGHTS_AND_CAMERAS")


def move_to(obj, target):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    target.objects.link(obj)
    return obj


def cube(name, loc, scale, mat, target, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("Soft weathering", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    obj.data.materials.append(mat)
    return move_to(obj, target)


def cylinder(name, loc, radius, depth, mat, target, vertices=10):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return move_to(obj, target)


# Exterior: X is the six-metre frontage, Y faces the dock/porch.
cube("Exterior_Foundation", (0, 0, 0.15), (3.15, 2.65, 0.15), BRASS, EXTERIOR, 0.04)
for x in (-3.0, -1.5, 1.5, 3.0):
    for y in (-2.5, 2.5):
        cube("Exterior_Wall_Plank", (x, y, 1.65), (0.70, 0.10, 1.35), WOOD, EXTERIOR, 0.03)
for y in (-1.5, 0, 1.5):
    cube("Exterior_Side_Wall_West", (-3.0, y, 1.65), (0.10, 0.65, 1.35), WOOD, EXTERIOR, 0.03)
    cube("Exterior_Side_Wall_East", (3.0, y, 1.65), (0.10, 0.65, 1.35), WOOD, EXTERIOR, 0.03)
cube("Exterior_Porch_Deck", (0, -3.15, 0.4), (2.4, 0.7, 0.12), WOOD_LIGHT, EXTERIOR, 0.04)
for x in (-2.1, 2.1):
    cylinder("Exterior_Porch_Post", (x, -3.65, 1.75), 0.10, 2.7, WOOD_LIGHT, EXTERIOR)
cube("Exterior_Porch_Awning", (0, -3.35, 3.0), (2.55, 0.65, 0.12), ROOF, EXTERIOR, 0.03)
cube("Exterior_Single_Porch_Door", (0, -2.49, 1.45), (0.48, 0.06, 1.15), WOOD_LIGHT, EXTERIOR, 0.02)
cylinder("Exterior_Door_Handle", (0.32, -2.72, 1.45), 0.045, 0.06, BRASS, EXTERIOR, 8).rotation_euler = (math.pi / 2, 0, 0)
for x in (-1.7, 1.7):
    cube("Exterior_Warm_Window", (x, -2.61, 1.85), (0.48, 0.06, 0.48), WINDOW, EXTERIOR, 0.02)
for x in (-2.2, 2.2):
    cube("Exterior_Gable", (x, 0, 3.15), (0.78, 2.5, 0.45), WOOD, EXTERIOR, 0.03)
roof_left = cube("Exterior_Dark_Gable_Roof_West", (-1.62, 0, 3.45), (1.95, 2.90, 0.16), ROOF, EXTERIOR, 0.03)
roof_left.rotation_euler = (0, -0.48, 0)
roof_right = cube("Exterior_Dark_Gable_Roof_East", (1.62, 0, 3.45), (1.95, 2.90, 0.16), ROOF, EXTERIOR, 0.03)
roof_right.rotation_euler = (0, 0.48, 0)
for x in (-2.65, 2.65):
    cylinder("Exterior_Rain_Barrel", (x, 2.8, 0.65), 0.35, 0.9, WOOD_LIGHT, EXTERIOR)
cube("Exterior_Rod_Rack", (2.35, -2.75, 1.35), (0.35, 0.12, 0.75), BRASS, EXTERIOR, 0.02)

# Interior: roofless, six by five metres, door at dock-facing Y edge.
cube("Interior_Floor_6m_x_5m", (0, 0, 0.08), (3.0, 2.5, 0.08), WOOD_LIGHT, INTERIOR, 0.03)
for x in (-3.0, 3.0):
    cube("Interior_Side_Wall", (x, 0, 1.45), (0.08, 2.5, 1.45), WOOD, INTERIOR, 0.03)
cube("Interior_Back_Wall", (0, 2.5, 1.45), (3.0, 0.08, 1.45), WOOD, INTERIOR, 0.03)
for x in (-2.15, -0.75, 0.75, 2.15):
    cube("Interior_Door_Wall_Segment", (x, -2.5, 1.45), (0.55, 0.08, 1.45), WOOD, INTERIOR, 0.03)
cube("Interior_Door_Frame", (0, -2.48, 1.45), (0.55, 0.06, 1.20), WOOD_LIGHT, INTERIOR, 0.02)
# Desk is the immediate route target; Mara stands beyond it near the stove.
cube("Interior_Field_Journal_Desk", (-1.55, -0.45, 0.95), (0.78, 0.42, 0.10), WOOD_LIGHT, INTERIOR, 0.03)
for x in (-2.15, -0.95):
    for y in (-0.75, -0.15):
        cube("Interior_Desk_Leg", (x, y, 0.48), (0.06, 0.06, 0.45), WOOD, INTERIOR)
cube("Interior_Journal", (-1.55, -0.45, 1.08), (0.28, 0.20, 0.025), MOSS, INTERIOR, 0.01)
cylinder("Interior_Iron_Stove", (1.85, 1.35, 0.75), 0.42, 1.3, BRASS, INTERIOR, 12)
cylinder("Interior_Stove_Pipe", (1.85, 1.35, 1.85), 0.12, 1.1, BRASS, INTERIOR, 10)
for x in (-2.5, 2.55):
    cube("Interior_Shelves", (x, 1.8, 1.35), (0.30, 0.22, 1.05), WOOD_LIGHT, INTERIOR, 0.02)
    for z in (0.75, 1.25, 1.75):
        cube("Interior_Shelf_Plank", (x, 1.55, z), (0.32, 0.06, 0.035), WOOD, INTERIOR)
cube("Interior_Bed_Nook", (-2.15, 1.25, 0.48), (0.65, 0.90, 0.20), WOOD, INTERIOR, 0.03)
cube("Interior_Bed_Roll", (-2.15, 1.25, 0.73), (0.56, 0.78, 0.10), MOSS, INTERIOR, 0.03)
cube("Interior_Tackle_Crate", (0.85, -1.65, 0.38), (0.38, 0.30, 0.30), WOOD_LIGHT, INTERIOR, 0.02)
cube("Interior_Rod_Lean", (2.45, -1.25, 1.10), (0.04, 0.04, 1.25), BRASS, INTERIOR)
bpy.context.object.rotation_euler = (0, 0.28, 0)

# Simple low-poly Mara Vale, posed facing the incoming route and ready for an idle animation.
cylinder("Mara_Boots", (0.95, 0.55, 0.28), 0.22, 0.55, BRASS, MARA, 6)
cylinder("Mara_Coat", (0.95, 0.55, 1.05), 0.38, 1.15, MOSS, MARA, 8)
bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, location=(0.95, 0.55, 1.92), radius=0.28)
head = bpy.context.object
head.name = "Mara_Head"
head.data.materials.append(SKIN)
move_to(head, MARA)
cube("Mara_Hair", (0.95, 0.66, 2.10), (0.28, 0.16, 0.14), HAIR, MARA, 0.05)
for x in (0.62, 1.28):
    cylinder("Mara_Arm", (x, 0.55, 1.28), 0.10, 0.75, MOSS, MARA, 6)
bpy.ops.object.armature_add(enter_editmode=True, location=(0.95, 0.55, 0))
idle = bpy.context.object
idle.name = "Mara_Idle_Rig"
root_bone = idle.data.edit_bones[0]
root_bone.name = "idle_root"
root_bone.head = (0, 0, 0)
root_bone.tail = (0, 0, 1.8)
bpy.ops.object.mode_set(mode="OBJECT")
move_to(idle, MARA)
for obj in [item for item in MARA.objects if item.type == "MESH"]:
    obj.parent = idle
idle.animation_data_create()
idle_action = bpy.data.actions.new("Mara_Restrained_Idle")
idle.animation_data.action = idle_action
idle.pose.bones["idle_root"].rotation_mode = "XYZ"
for frame, tilt in ((1, 0.0), (30, 0.025), (60, 0.0)):
    idle.pose.bones["idle_root"].rotation_euler = (0, tilt, 0)
    idle.pose.bones["idle_root"].keyframe_insert("rotation_euler", frame=frame)


def look_at(camera, point):
    camera.rotation_euler = (Vector(point) - camera.location).to_track_quat("-Z", "Y").to_euler()


def camera(name, location, target):
    bpy.ops.object.camera_add(location=location)
    item = bpy.context.object
    item.name = name
    item.data.lens = 46
    look_at(item, target)
    return move_to(item, REVIEW)


review_camera = camera("Review_Camera", (9.5, -11.0, 7.0), (0, 0, 1.4))
interior_camera = camera("Interior_Review_Camera", (0, -0.5, 9.5), (0, 0.0, 0.0))
for name, loc, energy, color in (("Key", (4, -5, 8), 1200, (1.0, 0.52, 0.28)), ("Fill", (-5, 2, 5), 800, (0.25, 0.45, 1.0))):
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = bpy.context.object
    light.name = "Review_" + name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = 5.0
    light.data.color = color
    move_to(light, REVIEW)


def export_collection(target, filename):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in target.all_objects:
        if obj.type in {"MESH", "ARMATURE"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = next((obj for obj in target.all_objects if obj.type == "MESH"), None)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, filename), export_format="GLB", use_selection=True, export_materials="EXPORT")


INTERIOR.hide_render = True
MARA.hide_render = True
scene.camera = review_camera
scene.render.filepath = os.path.join(OUT, "home_cottage_exterior_preview.png")
bpy.ops.render.render(write_still=True)
INTERIOR.hide_render = False
MARA.hide_render = False
EXTERIOR.hide_render = True
scene.camera = interior_camera
scene.render.filepath = os.path.join(OUT, "home_cottage_interior_preview.png")
bpy.ops.render.render(write_still=True)
EXTERIOR.hide_render = False
export_collection(EXTERIOR, "home_cottage_exterior_shell.glb")
export_collection(INTERIOR, "home_cottage_interior_roofless.glb")
export_collection(MARA, "mara_vale_idle_ready.glb")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "home_cottage_source.blend"))
