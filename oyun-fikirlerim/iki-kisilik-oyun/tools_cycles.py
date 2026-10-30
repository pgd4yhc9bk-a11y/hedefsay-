"""Döngü sayfalarını (yürüme/koşma 4x2, bekleme 4x1) karelere ayırır; kareler ortak kutuya kırpılır (kayma olmaz).
Kullanım: python3 tools_cycles.py -> godot/assets/<karakter>/dongu/<ad>_NN.png ve poses.json içinde "cycles" """
import os, json
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
GAME_H = {'nehir': 54, 'cinar': 44}; RES = 4
GRID = {'yuruyus': (4, 2), 'kosma': (4, 2), 'bekleme': (4, 1)}
meta_path = f'{HERE}/godot/assets/poses.json'
meta = json.load(open(meta_path))
for who in ('nehir', 'cinar'):
    cyc = {}
    scale = None
    for name in ('yuruyus', 'kosma', 'bekleme'):
        im = Image.open(f'{HERE}/assets/{who}/dongu/{name}.png').convert('RGBA')
        cols, rows = GRID[name]; cw, ch = im.width / cols, im.height / rows
        frames = []
        for r in range(rows):
            for c in range(cols):
                fr = im.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))
                frames.append(fr)
        boxes = []
        for fr in frames:
            a = np.array(fr)[..., 3] > 40
            ys, xs = np.where(a); boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes); x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
        if scale is None:   # ölçek yürüme sayfasından: ortak kutu yüksekliği = ayakta karakter yüksekliği
            scale = GAME_H[who] * RES / (y1 - y0)
        s = scale if name != 'bekleme' else GAME_H[who] * RES / (y1 - y0) * (1.0)
        outdir = f'{HERE}/godot/assets/{who}/dongu'; os.makedirs(outdir, exist_ok=True)
        w = round((x1 - x0) * s); h = round((y1 - y0) * s)
        for i, fr in enumerate(frames):
            o = fr.crop((x0, y0, x1, y1)).resize((w, h), Image.LANCZOS)
            o.save(f'{outdir}/{name}_{i:02d}.png', optimize=True)
        # çapa: kutu tabanı ve yatay merkez (ayak ağırlığı)
        low = np.array(Image.open(f'{outdir}/{name}_00.png'))[..., 3] > 40
        yy, xx = np.where(low); sel = yy > yy.max() - max(4, int(h * 0.15))
        cyc[name] = {'n': len(frames), 'w': w, 'h': h, 'ax': round(float(xx[sel].mean()), 1), 'ay': float(h), 'res': RES}
        print(who, name, len(frames), (w, h), 'çapa', cyc[name]['ax'])
    meta[who + '_cycles'] = cyc
json.dump(meta, open(meta_path, 'w'), indent=1)
