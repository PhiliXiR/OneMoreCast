"""Generate issue #101's review-only Home Water Pine kit in Blender."""
import math
import os

import bpy
from mathutils import Vector


OUT = os.environ["ONE_MORE_CAST_HOME_WATER_PINE_OUT"]
os.makedirs(OUT, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):
    bpy.data.collections.remove(item)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1400
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (0.018, 0.028, 0.035)


def make_material(name, color, roughness, metallic=0.0):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return result


BARK = make_material("Pine bark | muted umber", (0.105, 0.060, 0.035), 0.92)
BARK_LICHEN = make_material("Pine bark | lichen-worn", (0.21, 0.23, 0.15), 0.88)
NEEDLE_DARK = make_material("Pine needles | lake shadow", (0.025, 0.085, 0.060), 0.88)
NEEDLE_FADED = make_material("Pine needles | wind-faded", (0.065, 0.125, 0.075), 0.91)
GROUND = make_material("Review ground | blue slate", (0.055, 0.090, 0.085), 1.0)


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


LANDMARK = collection("PINE_LANDMARK_TALL")
STANDARD = collection("PINE_STANDARD")
LEANING = collection("PINE_SMALL_LEANING")
REVIEW = collection("REVIEW_COMPOSITION")


def move_to(obj, target):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    target.objects.link(obj)
    return obj


def cone(name, loc, radius1, radius2, depth, material, target, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2,
                                   depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return move_to(obj, target)


def cylinder(name, loc, radius, depth, material, target, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=depth,
                                       location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return move_to(obj, target)


def pine_variant(name, base, height, crown, target, lean=0.0, sparse=False):
    """Layered, low-poly pine with a narrow, weathered crown."""
    x, y, z = base
    trunk_height = height * 0.77
    trunk = cylinder(name + "_weathered_trunk", (x, y, z + trunk_height / 2),
                     max(0.12, crown * 0.12), trunk_height, BARK, target,
                     rotation=(0, lean, 0))
    # A broken crown and slightly different tier widths keep each silhouette authored.
    levels = 5 if sparse else 6
    for tier in range(levels):
        fraction = tier / max(1, levels - 1)
        tier_z = z + height * (0.28 + fraction * 0.62)
        width = crown * (1.0 - fraction * 0.70)
        if sparse and tier in (1, 3):
            width *= 0.72
        tier_height = height * (0.23 if tier < levels - 1 else 0.20)
        offset = lean * (tier_z - z) * 0.70
        cone(name + "_needle_tier_%02d" % (tier + 1),
             (x + offset, y, tier_z), width, width * 0.17, tier_height,
             NEEDLE_DARK if tier % 2 == 0 else NEEDLE_FADED, target)
    cone(name + "_wind_cut_crown", (x + lean * height * 0.70, y, z + height * 0.93),
         crown * 0.23, 0.025, height * 0.22, NEEDLE_FADED, target)
    # Broken, directional branch stubs interrupt the regular tier rhythm and
    # make the family feel wind-worked rather than like a generic foliage pack.
    for index, angle in enumerate((0.55, 3.55, 5.15)):
        branch_z = z + height * (0.42 + index * 0.13)
        length = crown * (0.55 - index * 0.08)
        branch = cylinder(name + "_weathered_branch_%02d" % (index + 1),
                          (x + math.cos(angle) * length * 0.34, y + math.sin(angle) * length * 0.34, branch_z),
                          crown * 0.035, length, BARK_LICHEN, target,
                          rotation=(math.pi / 2, 0, angle))
        branch.rotation_euler.rotate_axis("Y", -0.20 + index * 0.09)
    # One small lichen plate signals age without turning the kit into a texture showcase.
    cylinder(name + "_lichen_scar", (x + crown * 0.09, y - crown * 0.10, z + trunk_height * 0.42),
             crown * 0.045, trunk_height * 0.22, BARK_LICHEN, target,
             rotation=(math.pi / 2, 0, 0))
    return trunk


# Three deliberately separate scales for a layered far-bank tree line.
pine_variant("landmark_pine", (-3.3, 0.4, 0), 8.4, 2.15, LANDMARK, lean=-0.05)
pine_variant("standard_pine", (1.1, 0.2, 0), 5.9, 1.65, STANDARD, lean=0.025)
pine_variant("leaning_pine", (4.3, 0.8, 0), 3.9, 1.20, LEANING, lean=0.22, sparse=True)

# Review-only composition context, excluded from every proposed runtime GLB.
bpy.ops.mesh.primitive_plane_add(size=28, location=(0.5, 0, -0.015))
ground = bpy.context.object
ground.name = "Review_only_shore_ground"
ground.data.materials.append(GROUND)
move_to(ground, REVIEW)

for x, y, scale in ((-6.2, 1.8, 1.8), (-5.5, 2.4, 1.35), (6.4, 2.2, 1.55), (7.2, 1.3, 1.15)):
    pine_variant("background_silhouette_%s_%s" % (x, y), (x, y, 0), scale * 3.2, scale, REVIEW,
                 lean=0.05, sparse=True)


def review_label(text, location):
    bpy.ops.object.text_add(location=location, rotation=(math.pi / 2, 0, 0))
    label = bpy.context.object
    label.name = "Review_label_" + text.lower().replace(" ", "_")
    label.data.body = text
    label.data.align_x = "CENTER"
    label.data.size = 0.38
    label.data.extrude = 0.008
    label.data.materials.append(BARK_LICHEN)
    return move_to(label, REVIEW)


review_label("LANDMARK", (-3.3, -1.25, 0.12))
review_label("STANDARD", (1.1, -1.10, 0.12))
review_label("LEANING", (4.3, -0.62, 0.12))


def look_at(camera, point):
    camera.rotation_euler = (Vector(point) - camera.location).to_track_quat("-Z", "Y").to_euler()


bpy.ops.object.camera_add(location=(15.5, -19.0, 10.8))
camera = bpy.context.object
camera.name = "Review_camera_tree_line"
camera.data.lens = 52
look_at(camera, (0.0, 0.55, 3.3))
move_to(camera, REVIEW)
scene.camera = camera

for name, loc, energy, color in (
    ("Review_key_neutral", (2, -6, 14), 2100, (0.78, 0.84, 0.76)),
    ("Review_fill_lake", (-9, -2, 8), 1500, (0.30, 0.50, 0.70)),
):
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = 7
    light.data.color = color
    look_at(light, (0, 0, 2.5))
    move_to(light, REVIEW)


def export_collection(target, filename, base_offset):
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in target.all_objects if obj.type == "MESH"]
    original_locations = {obj: obj.location.copy() for obj in meshes}
    # Source stays composed as a tree line, while each candidate GLB starts at
    # its own trunk base for later placement after approval.
    for obj in meshes:
        obj.location -= Vector(base_offset)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, filename), export_format="GLB",
                              use_selection=True, export_materials="EXPORT")
    for obj, location in original_locations.items():
        obj.location = location


scene.render.filepath = os.path.join(OUT, "home_water_pine_tree_line_preview.png")
bpy.ops.render.render(write_still=True)
export_collection(LANDMARK, "home_water_pine_landmark.glb", (-3.3, 0.4, 0))
export_collection(STANDARD, "home_water_pine_standard.glb", (1.1, 0.2, 0))
export_collection(LEANING, "home_water_pine_leaning.glb", (4.3, 0.8, 0))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "home_water_pine_kit.blend"))
