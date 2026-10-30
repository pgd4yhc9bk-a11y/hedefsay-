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
json.dump(meta, open(f'{O}/cevre.json', 'w'), indent=1); print(json.dumps(meta))
