"""assets/cevre/ görsellerini oyun için hazırlar -> godot/assets/cevre/ ve cevre.json (ölçekler, hizalama satırları)."""
import json, os
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); A = f'{HERE}/assets/cevre'; O = f'{HERE}/godot/assets/cevre'
os.makedirs(O, exist_ok=True); meta = {}
# çim şeridi (yatay döşenir): 2x süper çözünürlük, oyunda 0.14 x
g = Image.open(f'{A}/cim_1_kirpik.png').convert('RGBA'); GS = 0.28
a = np.array(g)[..., 3] > 40; frac = a.mean(axis=1); band = int(np.argmax(frac > 0.97))   # tam dolu bant başlangıç satırı
w, h = round(g.width * GS), round(g.height * GS); g.resize((w, h), Image.LANCZOS).save(f'{O}/cim.png', optimize=True)
meta['cim'] = {'w': w, 'h': h, 'band': round(band * GS), 'res': 2}
# toprak dolgusu: oyunda 0.5x (512 px görünür)
t = Image.open(f'{A}/toprak.png').convert('RGB').resize((512, 512), Image.LANCZOS); t.save(f'{O}/toprak.png', optimize=True)
meta['toprak'] = {'w': 512, 'h': 512, 'res': 1}
# zemin uçları
for n in ('kenar_sag', 'kenar_sol'):
    im = Image.open(f'{A}/{n}.png').convert('RGBA'); KS = 0.36
    pa = np.array(im)[..., 3] > 40
    # toprak üst satırı: sütun başına ilk dolu satırların medyanı (çim kökleri hizası)
    ys = [np.argmax(pa[:, x]) for x in range(0, im.width, 8) if pa[:, x].any()]
    top = int(np.percentile(ys, 70))
    w2, h2 = round(im.width * KS), round(im.height * KS)
    im.resize((w2, h2), Image.LANCZOS).save(f'{O}/{n}.png', optimize=True)
    meta[n] = {'w': w2, 'h': h2, 'top': round(top * KS), 'res': 2}
# dekor nesneleri ve şeritler (çit, kapı, ev, kurdele, çamur, buz)
DEK = {'kurdele_1': 110, 'kurdele_2': 110, 'kurdele_3': 110, 'cit': 230, 'cit_kirik': 230, 'kapi_acik': 230, 'ev_sonuk': 340}   # oyunda hedef: kurdele yüksekliği, diğerleri genişlik (px)
for n, target in DEK.items():
    im = Image.open(f'{A}/{n}.png').convert('RGBA'); pa = np.array(im)[..., 3] > 40
    ys, xs = np.where(pa); box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1); im = im.crop(box); pa = pa[box[1]:box[3], box[0]:box[2]]
    game_scale = (target / im.height) if n.startswith('kurdele') else (target / im.width)
    sc = game_scale * 2; w2, h2 = round(im.width * sc), round(im.height * sc)
    im.resize((w2, h2), Image.LANCZOS).save(f'{O}/{n}.png', optimize=True)
    low = pa[int(pa.shape[0] * 0.92):]; yy, xx = np.where(low); ax = float(xx.mean()) * sc
    meta[n] = {'w': w2, 'h': h2, 'ax': round(ax, 1), 'res': 2}
for n in ('camur', 'buz'):
    im = Image.open(f'{A}/{n}.png').convert('RGBA'); pa = np.array(im)[..., 3] > 40
    ys, xs = np.where(pa); im = im.crop((0, ys.min(), im.width, ys.max() + 1)); pa = pa[ys.min():ys.max() + 1]
    frac = pa.mean(axis=1); top = int(np.argmax(frac > (0.9 if n == 'camur' else 0.5)))
    sc = 0.28; w2, h2 = round(im.width * sc), round(im.height * sc)
    im.resize((w2, h2), Image.LANCZOS).save(f'{O}/{n}.png', optimize=True)
    meta[n] = {'w': w2, 'h': h2, 'top': round(top * sc), 'res': 2}
json.dump(meta, open(f'{O}/cevre.json', 'w'), indent=1); print(json.dumps(meta))
