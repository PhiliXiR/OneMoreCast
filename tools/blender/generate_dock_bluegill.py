"""Generate issue #67's editable Blender source and Godot-ready candidate."""
import bpy, math, os
from mathutils import Vector
OUT = os.environ["ONE_MORE_CAST_BLUEGILL_OUT"]
os.makedirs(OUT, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
def mat(name, c, use_texture=False):
 m=bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True; nodes=m.node_tree.nodes; bsdf=nodes.get("Principled BSDF"); bsdf.inputs["Base Color"].default_value=(*c,1); bsdf.inputs["Roughness"].default_value=.55
 if use_texture:
  texture=nodes.new("ShaderNodeTexImage"); texture.image=palette; texture.interpolation="Linear"; m.node_tree.links.new(texture.outputs["Color"],bsdf.inputs["Base Color"])
 return m
def sphere(name, loc, scale, material):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=loc); o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(material); bpy.ops.object.shade_smooth(); return o
def cone(name, loc, scale, rot, material):
 bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=1,radius2=0,depth=1,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(material); return o
bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
palette=bpy.data.images.new("dock_bluegill_palette",128,64)
pixels=[]
for y in range(64):
 for x in range(128):
  u=x/127; v=y/63; belly=max(0,(v-.48)/.52); bar=max(0, math.sin((u*.92+.08)*math.pi*6))**22
  r=(.18*(1-belly)+.88*belly)*(1-.45*bar); g=(.38*(1-belly)+.56*belly)*(1-.45*bar); b=(.20*(1-belly)+.19*belly)*(1-.45*bar)
  pixels.extend([r,g,b,1])
palette.pixels=pixels; palette.filepath_raw=os.path.join(OUT,"dock_bluegill_palette.png"); palette.file_format="PNG"; palette.save(); palette.pack()
body=mat("Bluegill olive body",(.29,.50,.28),True); belly,fin,dark,eye=[mat(n,c) for n,c in [("Bluegill warm belly",(.86,.62,.30)),("Bluegill fin amber",(.88,.39,.10)),("Bluegill bars and ear",(.055,.12,.10)),("Bluegill eye",(.97,.82,.35))]]
sphere("Bluegill_Body",(0,0,0),(1.04,.34,.78),body); sphere("Bluegill_Belly",(.08,-.20,-.28),(.85,.18,.37),belly)
for i,x in enumerate([-.40,-.18,.04,.26]): sphere("Bluegill_Vertical_Bar_%02d"%i,(x,-.338,.05),(.030,.015,.43),dark)
sphere("Bluegill_Ear_Flap",(.43,-.33,.12),(.18,.03,.26),dark); sphere("Bluegill_Eye",(.68,-.34,.29),(.075,.025,.075),eye); sphere("Bluegill_Eye_Back",(.685,-.355,.29),(.032,.014,.032),dark)
cone("Bluegill_Dorsal_Fin",(-.08,0,.72),(.58,.07,.36),(0,math.pi/2,0),fin)
for i,x in enumerate([-.38,-.22,-.06,.10,.26]): cone("Bluegill_Dorsal_Ray_%02d"%i,(x,-.01,.76),(.055,.025,.28-abs(x)*.09),(0,0,0),fin)
cone("Bluegill_Anal_Fin",(-.08,0,-.69),(.40,.07,.30),(0,math.pi/2,math.pi),fin); cone("Bluegill_Pectoral_Fin",(.28,-.32,-.05),(.32,.05,.35),(.35,.55,-.25),fin); cone("Bluegill_Tail",(-1.02,0,0),(.30,.07,.55),(0,-math.pi/2,0),fin)
bpy.ops.object.armature_add(enter_editmode=True); arm=bpy.context.object; arm.name="FishSkeleton"; arm.data.name="FishSkeleton"; root=arm.data.edit_bones[0]; root.name="root"; root.head,root.tail=(.7,0,0),(0,0,0); spine=arm.data.edit_bones.new("spine"); spine.head,spine.tail,spine.parent=(0,0,0),(-.65,0,0),root; tail=arm.data.edit_bones.new("tail"); tail.head,tail.tail,tail.parent=(-.65,0,0),(-1.25,0,0),spine; bpy.ops.object.mode_set(mode="OBJECT")
for o in [o for o in bpy.context.scene.objects if o.type=="MESH"]:
 world_matrix = o.matrix_world.copy()
 o.parent = arm
 o.parent_type = "BONE"
 o.parent_bone = "tail" if "Tail" in o.name else "root"
 o.matrix_world = world_matrix
def action(name, values):
 a=bpy.data.actions.new(name); arm.animation_data_create(); arm.animation_data.action=a
 for bone,amp in [("tail",1), ("spine",-.45)]:
  p=arm.pose.bones[bone]; p.rotation_mode="XYZ"
  for frame,value in values: p.rotation_euler=(0,value*amp,0); p.keyframe_insert("rotation_euler",frame=frame)
 t=arm.animation_data.nla_tracks.new(); t.name=name; s=t.strips.new(name,1,a); s.action_frame_start=1; s.action_frame_end=values[-1][0]; arm.animation_data.action=None
action("calm_swim",[(1,0),(20,.25),(40,0),(60,-.25),(80,0)]); action("struggle_surge",[(1,0),(7,.65),(14,-.70),(21,.52),(28,0)]); action("landed_presentation",[(1,0),(9,.38),(18,-.28),(30,0)])
bpy.context.scene.render.engine="BLENDER_EEVEE"; bpy.context.scene.render.resolution_x=900; bpy.context.scene.render.resolution_y=600; bpy.context.scene.world.color=(.025,.06,.08)
def track_camera(camera, point):
    camera.rotation_euler = (point - camera.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.camera_add(location=(3.2, -5.2, 2.2)); camera=bpy.context.object; camera.name="ReviewCamera"; track_camera(camera, Vector((0,0,0))); bpy.context.scene.camera=camera
bpy.ops.object.light_add(type='AREA', location=(2,-3,4)); bpy.context.object.data.energy=900; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=5
bpy.context.scene.render.filepath=os.path.join(OUT,"dock_bluegill_preview.png"); bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,"dock_bluegill.blend")); bpy.ops.object.select_all(action="SELECT"); bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,"dock_bluegill.glb"),export_format="GLB",export_animations=True,export_nla_strips=True,export_materials="EXPORT")
