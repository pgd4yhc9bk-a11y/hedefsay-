"""Meshy GLB dosyalarını oyun için hafifletir (Blender/bpy): yüz sayısını azaltır (deri ağırlıkları korunur),
dokuları küçültür, animasyonlarla birlikte yeniden GLB yazar.
Kullanım: /tmp/bvenv/bin/python tools_meshy_hafiflet.py giris.glb cikis.glb hedef_yuz [doku_px]"""
import sys, bpy
src, dst, target = sys.argv[1], sys.argv[2], int(sys.argv[3])
tex = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
fmt = sys.argv[5] if len(sys.argv) > 5 else 'AUTO'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for ob in [o for o in bpy.data.objects if o.type == 'MESH']:
    n = len(ob.data.polygons)
    if n > target:
        bpy.context.view_layer.objects.active = ob
        for o in bpy.data.objects:
            o.select_set(o == ob)
        m = ob.modifiers.new('azalt', 'DECIMATE')
        m.ratio = target / n
        # deri (armature) değiştiricisinden önce uygula
        while ob.modifiers[0].name != 'azalt':
            bpy.ops.object.modifier_move_up(modifier='azalt')
        bpy.ops.object.modifier_apply(modifier='azalt')
        print(ob.name, n, '->', len(ob.data.polygons))
for img in bpy.data.images:
    if img.size[0] > tex:
        img.scale(tex, int(img.size[1] * tex / img.size[0]))
        img.pack()
        print('doku', img.name, '->', img.size[:])
anims = len(bpy.data.actions)
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_animations=True, export_animation_mode='ACTIONS',
                          export_skins=True, export_image_format=fmt)
print('yazildi', dst, 'animasyon', anims)
