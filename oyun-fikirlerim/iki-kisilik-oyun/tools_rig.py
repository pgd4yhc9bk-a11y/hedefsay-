"""ChatGPT'den gelen parça sayfasını (şeffaf PNG) tek tek parçalara ayırır, eklem noktalarını bulur.
Kullanım: python3 tools_rig.py kabuk|kul   -> assets/<ad>/parts/*.png ve prototip-sis/sprites/<ad>_*.png + anchors.json"""
import sys, json, os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
HERE = os.path.dirname(os.path.abspath(__file__))
name = sys.argv[1]
SCALE = float(os.environ.get('SCALE', '0.13'))
# Parça başına ek ölçek: ChatGPT gövdeyi iri, bacağı kısa çizdi; oyunda oranlar Limbo çocuğuna yaklaştırılır
PART_SCALE = {'kabuk': {'torso': 0.85, 'uleg': 1.2, 'lleg': 1.2, 'uarm': 1.15, 'larm': 1.15}, 'kul': {}}[name]
# Parça sırası (bileşenlerin y/x konumuna göre elle eşlendi)
ROLES = {
  'kabuk': {1: 'head', 3: 'torso', 4: 'uleg', 5: 'uarm', 6: 'lleg', 7: 'larm', 2: 'mask'},
  'kul':   {1: 'head', 2: 'torso', 3: 'ember', 4: 'uleg', 5: 'uarm', 6: 'lleg', 7: 'larm'},
}[name]
src = np.array(Image.open(f'{HERE}/assets/{name}/kaynak_parcalar.png').convert('RGBA'))
a = src[..., 3] > 40
lab, n = ndi.label(a)
objs = ndi.find_objects(lab); sizes = ndi.sum(a, lab, range(1, n + 1))
big = [i + 1 for i, s in enumerate(sizes) if s > 300]
big.sort(key=lambda i: (objs[i - 1][0].start // 200, objs[i - 1][1].start))   # kabaca okuma sırası
os.makedirs(f'{HERE}/assets/{name}/parts', exist_ok=True); os.makedirs(f'{HERE}/prototip-sis/sprites', exist_ok=True)
# bileşen numaralarını yukarıdaki tabloyla eşle (etiketleme sırası y.start artan, scipy find_objects sırası)
anchors = {}
full = {}
for idx, role in ROLES.items():
    sl = objs[idx - 1]; m = (lab[sl] == idx)
    crop = src[sl].copy(); crop[..., 3] = np.where(m, src[sl][..., 3], 0)
    if role == 'mask':   # kenar kirlerini temizle
        m2 = ndi.binary_opening(m, iterations=2); m2 = ndi.binary_closing(m2, iterations=2); crop[..., 3] = np.where(m2, 255, 0); m = m2
    if role == 'head' and name == 'kabuk':   # yandan görünüm için soldaki gözü kapat (dolu siyah), sağdaki (bakılan yön) kalsın
        hh, ww = m.shape; yy, xx = np.ogrid[:hh, :ww]
        disc = ((xx - ww / 2) ** 2 + (yy - hh / 2) ** 2) <= (min(ww, hh) / 2 - 1) ** 2
        left = disc & (xx < ww * 0.55); base = crop[int(hh * 0.8), int(ww * 0.6), :3].copy(); crop[left, :3] = base; crop[left, 3] = 255
    if role == 'torso' and name == 'kabuk':   # yan görünümde omuz/kalça topuzları gövdeden taşmasın: omuz ve kalça satırlarında yanları kes
        hh, ww = m.shape; cut = int(ww * 0.22)
        for rows in (slice(0, int(hh * 0.3)), slice(int(hh * 0.72), hh)):
            m[rows, :cut] = False; m[rows, ww - cut:] = False
        crop[..., 3] = np.where(m, 255, 0)
        ys, xs = np.where(m); sl2 = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1)); crop = crop[sl2]; m = m[sl2]
    img = Image.fromarray(crop)
    h, w = m.shape
    d = ndi.distance_transform_edt(m)
    def argmax_in(y0, y1):
        reg = d[int(y0):int(y1)]; yy, xx = np.unravel_index(np.argmax(reg), reg.shape); return [int(xx), int(yy + int(y0))]
    an = {}
    if role in ('uleg', 'uarm'): an = {'top': argmax_in(0, h * 0.35), 'bot': argmax_in(h * 0.65, h)}
    elif role in ('lleg', 'larm'): an = {'top': argmax_in(0, h * 0.35), 'bot': [w // 2, h - 1]}
    elif role == 'torso': an = {'neck': [w // 2, int(h * 0.04)], 'shoulder': [w // 2, int(h * 0.2)], 'hip': [w // 2, int(h * 0.88)]}
    elif role == 'head': an = {'neck': [w // 2, int(h * 0.9)]}
    img.save(f'{HERE}/assets/{name}/parts/{role}.png')
    s = SCALE * PART_SCALE.get(role, 1)
    out = img.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    out.save(f'{HERE}/prototip-sis/sprites/{name}_{role}.png', optimize=True)
    full[role] = {'w': w, 'h': h, 'k': round(s / 2, 5), **an}   # Godot için: tam çözünürlük pikseli, k = oyun pikseli/kaynak pikseli
    anchors[role] = {'w': out.width, 'h': out.height, **{k: [round(v[0] * s, 1), round(v[1] * s, 1)] for k, v in an.items()}}
    print(role, (w, h), '->', (out.width, out.height), an)
json.dump(anchors, open(f'{HERE}/prototip-sis/sprites/{name}_anchors.json', 'w'), indent=1)

gd = f'{HERE}/godot/assets/{name}'; os.makedirs(gd, exist_ok=True)
json.dump(full, open(f'{gd}/anchors.json', 'w'), indent=1)
import shutil
for r in ROLES.values(): shutil.copy(f'{HERE}/assets/{name}/parts/{r}.png', f'{gd}/{r}.png')
