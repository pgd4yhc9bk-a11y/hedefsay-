"""Parmak kemiği olmayan Meshy modeline elleri kapatabilmek için 'fingers_l/r' kemikleri ekler (Blender/bpy).
Elin bilekten parmak ucuna doğru dış yarısındaki köşeler, el kemiğinden yumuşak geçişle yeni kemiğe bağlanır.
Kullanım: /tmp/bvenv/bin/python tools_parmak_kemigi.py giris.glb cikis.glb"""
import sys, bpy
from mathutils import Vector
src, dst = sys.argv[1], sys.argv[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
mesh = max([o for o in bpy.data.objects if o.type == 'MESH'], key=lambda o: len(o.vertex_groups) * 1000000 + len(o.data.vertices))
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
info = {}
for side, hand, end in (('r', 'hand_r', 'RightHand_End'), ('l', 'hand_l', 'LeftHand_End')):
    h = eb[hand]
    e = eb[end]
    wrist = arm.matrix_world @ h.head
    tip = arm.matrix_world @ h.tail   # el kemiğinin ucu = parmak uçları (End kemiği yalnızca yön işareti)
    fb = eb.new('fingers_' + side)
    mw_inv = arm.matrix_world.inverted()
    fb.head = mw_inv @ wrist.lerp(tip, 0.5)
    fb.tail = mw_inv @ tip
    fb.roll = h.roll
    fb.parent = h
    fb.use_connect = False
    info[side] = (hand, wrist, tip)
    print(side, 'bilek', tuple(round(v, 3) for v in wrist), 'uc', tuple(round(v, 3) for v in tip))
bpy.ops.object.mode_set(mode='OBJECT')
# ağırlıklar: el grubundaki köşeler, el ekseninde %45'ten sonra yeni kemiğe geçer
for side, (hand, wrist, tip) in info.items():
    hg = mesh.vertex_groups.get(hand)
    fg = mesh.vertex_groups.new(name='fingers_' + side)
    axis = tip - wrist
    L = axis.length
    axis.normalize()
    n = 0
    for v in mesh.data.vertices:
        w = 0.0
        for g in v.groups:
            if g.group == hg.index:
                w = g.weight
        if w < 0.05:
            continue
        p = mesh.matrix_world @ v.co
        t = (p - wrist).dot(axis) / L
        if t <= 0.42:
            continue
        k = min(1.0, (t - 0.42) / 0.18)
        k = k * k * (3 - 2 * k)
        fg.add([v.index], w * k, 'REPLACE')
        hg.add([v.index], w * (1 - k), 'REPLACE')
        n += 1
    print(side, 'parmak köşesi', n)
# eller: köşe rengiyle koyulaştır (Meshy dokusunda eller neredeyse beyaz; fener ışığında parlıyordu)
col = mesh.data.color_attributes.new(name='Col', type='FLOAT_COLOR', domain='POINT')
hand_ids = {mesh.vertex_groups[n].index for n in ('hand_l', 'hand_r', 'fingers_l', 'fingers_r') if mesh.vertex_groups.get(n)}
for v in mesh.data.vertices:
    w = sum(g.weight for g in v.groups if g.group in hand_ids)
    k = 1.0 - 0.55 * min(1.0, w)
    col.data[v.index].color = (k, k * 0.96, k * 0.93, 1.0)
mesh.data.color_attributes.active_color = col
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_animations=True, export_animation_mode='ACTIONS',
                          export_skins=True, export_image_format='JPEG', export_vertex_color='ACTIVE')
print('yazildi', dst)
