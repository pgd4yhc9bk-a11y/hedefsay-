"""Nehir'in prototip 3D modeli (Blender/bpy ile): skin modifier gövde + saç + iskelet (otomatik ağırlık) -> godot/proto/nehir.glb
Yüzsüz, Inside tarzı sade bir çocuk figürü. Ölçü: metre, boy ~1.47. Blender ekseni: Z yukarı, +X ileri, +Y sol.
Çalıştırma: /tmp/bvenv/bin/python tools_nehir3d.py"""
import bpy, bmesh, os, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)

# --- gövde iskelet noktaları: ad -> (konum, yarıçap)
P = {
 'pelvis': ((0.0, 0, 0.80), 0.105), 'spine': ((0.005, 0, 0.95), 0.098), 'chest': ((0.0, 0, 1.09), 0.112),
 'neck': ((0.005, 0, 1.205), 0.042), 'headb': ((0.012, 0, 1.26), 0.075), 'head': ((0.014, 0, 1.335), 0.118), 'headtop': ((0.010, 0, 1.425), 0.092),
}
for s, y in (('L', 1), ('R', -1)):
    P.update({
     f'hip{s}': ((0.0, 0.062 * y, 0.765), 0.074), f'knee{s}': ((0.012, 0.066 * y, 0.43), 0.048),
     f'ankle{s}': ((0.0, 0.066 * y, 0.075), 0.040), f'toe{s}': ((0.125, 0.066 * y, 0.035), 0.034),
     f'sho{s}': ((0.0, 0.142 * y, 1.155), 0.050), f'elb{s}': ((0.0, 0.158 * y, 0.925), 0.037),
     f'wri{s}': ((0.008, 0.160 * y, 0.705), 0.030), f'hand{s}': ((0.018, 0.160 * y, 0.635), 0.034),
    })
E = [('pelvis', 'spine'), ('spine', 'chest'), ('chest', 'neck'), ('neck', 'headb'), ('headb', 'head'), ('head', 'headtop')]
for s in 'LR':
    E += [('pelvis', f'hip{s}'), (f'hip{s}', f'knee{s}'), (f'knee{s}', f'ankle{s}'), (f'ankle{s}', f'toe{s}'),
          ('chest', f'sho{s}'), (f'sho{s}', f'elb{s}'), (f'elb{s}', f'wri{s}'), (f'wri{s}', f'hand{s}')]
names = list(P.keys())
me = bpy.data.meshes.new('govde')
me.from_pydata([P[n][0] for n in names], [(names.index(a), names.index(b)) for a, b in E], [])
ob = bpy.data.objects.new('Nehir', me); bpy.context.collection.objects.link(ob)
bpy.context.view_layer.objects.active = ob; ob.select_set(True)
sk = ob.modifiers.new('skin', 'SKIN'); sk.use_smooth_shade = True; sk.branch_smoothing = 0.6
for i, n in enumerate(names):
    r = P[n][1]; sv = me.skin_vertices[0].data[i]; sv.radius = (r, r)
    if n.startswith('hand'): sv.radius = (0.022, 0.034)       # yassı el
    if n.startswith('toe') or n.startswith('ankle'): sv.radius = (r * 1.0, r * 0.85)
    if n in ('pelvis',): sv.radius = (0.085, 0.112)
    if n == 'chest': sv.radius = (0.088, 0.122)
    if n == 'spine': sv.radius = (0.080, 0.100)
me.skin_vertices[0].data[names.index('pelvis')].use_root = True
ss = ob.modifiers.new('sub', 'SUBSURF'); ss.levels = 2; ss.render_levels = 2
bpy.ops.object.modifier_apply(modifier='skin'); bpy.ops.object.modifier_apply(modifier='sub')

# --- malzemeler: bölgeye göre (ceket, pantolon, bot, ten)
def mat(n, c):
    m = bpy.data.materials.new(n); m.diffuse_color = (*c, 1); m.use_nodes = True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*c, 1); return m
mats = [mat('ceket', (0.09, 0.10, 0.12)), mat('pantolon', (0.05, 0.05, 0.06)), mat('bot', (0.03, 0.025, 0.02)), mat('ten', (0.42, 0.36, 0.32)), mat('sac', (0.05, 0.035, 0.03))]
for m in mats: ob.data.materials.append(m)
for f in ob.data.polygons:
    c = f.center
    if c.z > 1.235: f.material_index = 3
    elif c.z < 0.72 and abs(c.y) > 0.125 and c.z > 0.55: f.material_index = 3      # eller
    elif c.z < 0.115: f.material_index = 2
    elif c.z < 0.70 and abs(c.y) < 0.125: f.material_index = 1
    else: f.material_index = 0
# ceket eteği: kalçanın altına hafif genişleyen halka (gövdeye bağlı)
bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.135, radius2=0.112, depth=0.16, location=(0.0, 0, 0.73))
hem = bpy.context.active_object; hem.scale = (0.82, 1.0, 1.0); hem.name = 'etek'
bpy.ops.object.shade_smooth(); hem.data.materials.append(mats[0])
bm = bmesh.new(); bm.from_mesh(hem.data)
for f in [f for f in bm.faces if len(f.verts) > 4]: bm.faces.remove(f)   # alt/üst kapakları aç (tüp)
bm.to_mesh(hem.data); bm.free()
sol = hem.modifiers.new('kal', 'SOLIDIFY'); sol.thickness = 0.012
bpy.context.view_layer.objects.active = hem; bpy.ops.object.modifier_apply(modifier='kal')
# saç: başın arkası ve üstü + iki yanda kulak hizasına inen kısım
hv = [ob.matrix_world @ v.co for v in ob.data.vertices if v.co.z > 1.28]   # gerçek kafa ölçüsü (skin+subsurf sonrası)
hc = Vector(((max(v.x for v in hv) + min(v.x for v in hv)) / 2, 0, (max(v.z for v in hv) + 1.28) / 2 + 0.02))
hr = (max(v.x for v in hv) - min(v.x for v in hv)) / 2; hy = max(v.y for v in hv); hz = max(v.z for v in hv)
print('kafa merkez', hc, 'yaricap x', hr, 'y', hy, 'tepe', hz)
R = hr * 1.09
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1.0, location=(hc.x - 0.014, 0, hz - R + 0.014))
hair = bpy.context.active_object; hair.name = 'sac'; hair.scale = (R, R * 1.02, R)
bpy.ops.object.shade_smooth(); hair.data.materials.append(mats[4])
bm = bmesh.new(); bm.from_mesh(hair.data)
cut = [v for v in bm.verts if (v.co.x > 0.35 and v.co.z < 0.45) or (v.co.z < -0.55 and v.co.x > -0.3) or v.co.z < -0.8]   # birim küre: yüz ve çene açık, ense saçı uzun   # yüz ve ense altı açık
bmesh.ops.delete(bm, geom=cut, context='VERTS'); bm.to_mesh(hair.data); bm.free()
bpy.ops.object.transform_apply(scale=True)
sol = hair.modifiers.new('kal', 'SOLIDIFY'); sol.thickness = 0.008
bpy.context.view_layer.objects.active = hair; bpy.ops.object.modifier_apply(modifier='kal')
# hepsini tek nesnede birleştir
bpy.ops.object.select_all(action='DESELECT')
for o in (hem, hair, ob): o.select_set(True)
bpy.context.view_layer.objects.active = ob; bpy.ops.object.join()

# --- iskelet
arm = bpy.data.armatures.new('iskelet'); ao = bpy.data.objects.new('Iskelet', arm); bpy.context.collection.objects.link(ao)
bpy.context.view_layer.objects.active = ao; bpy.ops.object.mode_set(mode='EDIT')
def bone(n, h, t, par=None):
    b = arm.edit_bones.new(n); b.head = Vector(h); b.tail = Vector(t); b.roll = 0.0
    if par: b.parent = arm.edit_bones[par]; b.use_connect = False
    return b
pp = lambda n: P[n][0]
bone('hips', pp('pelvis'), (0, 0, 0.95)); bone('spine', (0, 0, 0.95), (0, 0, 1.09), 'hips'); bone('chest', (0, 0, 1.09), (0, 0, 1.205), 'spine')
bone('neck', (0, 0, 1.205), (0.01, 0, 1.27), 'chest'); bone('head', (0.01, 0, 1.27), (0.01, 0, 1.46), 'neck')
for s in 'LR':
    bone(f'thigh.{s}', pp(f'hip{s}'), pp(f'knee{s}'), 'hips'); bone(f'shin.{s}', pp(f'knee{s}'), pp(f'ankle{s}'), f'thigh.{s}')
    bone(f'foot.{s}', pp(f'ankle{s}'), pp(f'toe{s}'), f'shin.{s}')
    bone(f'upperarm.{s}', pp(f'sho{s}'), pp(f'elb{s}'), 'chest'); bone(f'forearm.{s}', pp(f'elb{s}'), pp(f'wri{s}'), f'upperarm.{s}')
    h = pp(f'wri{s}'); bone(f'hand.{s}', h, (h[0] + 0.02, h[1], h[2] - 0.11), f'forearm.{s}')
# kolların ve bacakların bükülme ekseni dünya Y (yan) olsun: roll'u buna göre ayarla
for b in arm.edit_bones:
    b.align_roll(Vector((0, 1, 0)))
bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); ao.select_set(True); bpy.context.view_layer.objects.active = ao
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
empty = [g.name for g in ob.vertex_groups if not any(g.index in [x.group for x in v.groups] for v in ob.data.vertices[:])]
print('bos grup:', empty, 'vertex', len(ob.data.vertices), 'yuz', len(ob.data.polygons))
out = f'{HERE}/godot/proto/nehir.glb'
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=False, export_animations=False, export_apply=True)
print('yazildi', out, os.path.getsize(out))
