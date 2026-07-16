"""Generate issue #105's review-only Home Water mountain backdrop kit in Blender."""
import math
import os

import bpy
from mathutils import Vector


OUT = os.environ["ONE_MORE_CAST_HOME_WATER_MOUNTAIN_OUT"]
os.makedirs(OUT, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for item in list(bpy.data.collections):
    bpy.data.collections.remove(item)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1600
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (0.075, 0.100, 0.115)


def material(name, color, roughness=0.9):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1.0)
    result.use_nodes = True
    result.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*color, 1.0)
    result.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = roughness
    return result


SLATE = material("Mountain slate | muted blue-gray", (0.18, 0.265, 0.295))
MOSS = material("Mountain forest | muted moss", (0.13, 0.285, 0.135))
ROCK = material("Mountain exposure | restrained charcoal", (0.255, 0.275, 0.255))
WATER = material("Review water | deep lake ink", (0.035, 0.17, 0.245), 0.62)
PAPER = material("Review labels | field paper", (0.92, 0.80, 0.46))


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


REVIEW = collection("REVIEW_COMPOSITION_ONLY")
NORTH = collection("MOUNTAIN_NORTH_RIDGE")
EAST = collection("MOUNTAIN_EAST_SADDLE")
SOUTH = collection("MOUNTAIN_SOUTH_BENCH")
WEST = collection("MOUNTAIN_WEST_SHOULDER")


def move_to(obj, target):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    target.objects.link(obj)
    return obj


def mesh(name, vertices, faces, target, mat):
    data = bpy.data.meshes.new(name + "_mesh")
    data.from_pydata(vertices, [], faces)
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    target.objects.link(obj)
    return obj


def ridge_segment(name, target, center, heading, heights, width, depth):
    """A triangulated, hand-shaped low-poly ridge with an intentionally low saddle."""
    cx, cy = center
    forward = Vector((math.cos(heading), math.sin(heading), 0))
    side = Vector((-forward.y, forward.x, 0))
    count = len(heights)
    vertices = []
    # Ridge, inner foot, outer foot: uneven triangles avoid terrain-grid reading.
    for i, height in enumerate(heights):
        t = i / (count - 1) - 0.5
        ridge = Vector((cx, cy, 0)) + forward * (t * width)
        wobble = math.sin(i * 2.17) * depth * 0.10
        vertices.append(tuple(ridge + side * wobble + Vector((0, 0, height))))
    for i in range(count):
        t = i / (count - 1) - 0.5
        base = Vector((cx, cy, 0)) + forward * (t * width)
        vertices.append(tuple(base - side * depth * (0.42 + (i % 2) * 0.08)))
        vertices.append(tuple(base + side * depth * (0.52 - (i % 3) * 0.05)))
    faces = []
    for i in range(count - 1):
        ridge_a, ridge_b = i, i + 1
        inner_a, outer_a = count + i * 2, count + i * 2 + 1
        inner_b, outer_b = count + (i + 1) * 2, count + (i + 1) * 2 + 1
        faces.extend([(ridge_a, inner_a, inner_b), (ridge_a, inner_b, ridge_b),
                      (ridge_a, outer_b, outer_a), (ridge_a, ridge_b, outer_b),
                      (inner_a, outer_a, outer_b), (inner_a, outer_b, inner_b)])
    body = mesh(name + "_slopes", vertices, faces, target, SLATE)
    body.data.materials.append(MOSS)
    # The inward lower facets are moss/forest slopes; the ridge and occasional
    # outer facets remain slate so the kit reads as forested, not fully grassy.
    for face_index, polygon in enumerate(body.data.polygons):
        if face_index % 6 in (0, 1):
            polygon.material_index = 1
    # A few small angular rock exposures are accents, not a snow-like cap.
    for index in (1, count - 3):
        t = index / (count - 1) - 0.5
        p = Vector((cx, cy, 0)) + forward * (t * width) + side * depth * 0.07
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.48, location=(p.x, p.y, heights[index] * 0.63))
        rock = move_to(bpy.context.object, target)
        rock.name = name + "_restrained_rock_%02d" % index
        rock.scale = (1.6, 0.7, 0.65)
        rock.data.materials.append(ROCK)
    # Sparse forest masses sit below the skyline, preserving the silhouette.
    for index in range(2, count - 1):
        t = index / (count - 1) - 0.5
        p = Vector((cx, cy, 0)) + forward * (t * width) - side * depth * 0.22
        for offset in (-0.55, 0.25):
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.48, radius2=0.05,
                                            depth=1.7 + (index % 2) * 0.3,
                                            location=(p.x + side.x * offset, p.y + side.y * offset, 0.85))
            tree = move_to(bpy.context.object, target)
            tree.name = name + "_forest_mass_%02d" % index
            tree.data.materials.append(MOSS)
    return body


# Four authored profiles span the compass: the deliberately varied saddles make
# a static, nearly continuous basin without a generic terrain or placement system.
specs = [
    ("north_ridge", NORTH, (0, 10), 0.0, [4.8, 6.7, 5.2, 7.1, 5.0, 6.2, 4.5], 13, 5),
    ("east_saddle", EAST, (12, 0), math.pi / 2, [4.1, 5.8, 4.3, 3.3, 5.6, 6.4, 4.2], 13, 5),
    ("south_bench", SOUTH, (0, -10), math.pi, [3.9, 5.0, 4.6, 5.8, 4.0, 5.2, 3.8], 13, 5),
    ("west_shoulder", WEST, (-12, 0), -math.pi / 2, [4.4, 6.5, 5.1, 4.0, 4.7, 6.1, 4.3], 13, 5),
]
for spec in specs:
    ridge_segment(*spec)

bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=8.2, depth=0.12, location=(0, 0, -0.14))
lake = move_to(bpy.context.object, REVIEW)
lake.name = "Review_only_home_water"
lake.data.materials.append(WATER)


def label(text, location):
    bpy.ops.object.text_add(location=location, rotation=(0, 0, 0))
    obj = move_to(bpy.context.object, REVIEW)
    obj.name = "Review_label_" + text.lower().replace(" ", "_")
    obj.data.body = text
    obj.data.align_x = "CENTER"
    obj.data.size = 0.55
    obj.data.extrude = 0.01
    obj.data.materials.append(PAPER)
    return obj


label("NORTH RIDGE", (0, 7.8, 0.2))
label("EAST SADDLE", (7.8, 0, 0.2))
label("SOUTH BENCH", (0, -7.8, 0.2))
label("WEST SHOULDER", (-7.8, 0, 0.2))


def look_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


bpy.ops.object.camera_add(location=(20, -25, 20))
camera = move_to(bpy.context.object, REVIEW)
camera.name = "Review_camera_all_around_basin"
camera.data.lens = 48
look_at(camera, (0, 0, 2.6))
scene.camera = camera

for name, loc, energy, color in (
    ("Review_key", (4, -12, 24), 4500, (0.86, 0.91, 0.84)),
    ("Review_fill", (-16, 4, 13), 3200, (0.42, 0.60, 0.72)),
):
    bpy.ops.object.light_add(type="AREA", location=loc)
    lamp = move_to(bpy.context.object, REVIEW)
    lamp.name = name
    lamp.data.energy = energy
    lamp.data.shape = "DISK"
    lamp.data.size = 10
    lamp.data.color = color
    look_at(lamp, (0, 0, 2.5))


def export_collection(target, filename):
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in target.all_objects if obj.type == "MESH"]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, filename), export_format="GLB",
                              use_selection=True, export_materials="EXPORT")


scene.render.filepath = os.path.join(OUT, "home_water_mountain_basin_preview.png")
bpy.ops.render.render(write_still=True)
for name, target, *_ in specs:
    export_collection(target, "home_water_mountain_%s.glb" % name)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "home_water_mountain_kit.blend"))
