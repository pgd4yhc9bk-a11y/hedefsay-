"""ChatGPT ızgara sayfalarını tek tek nesnelere böler: assets/cevre/oge/<sayfa>_NN.png
Hücre sınırı = eşit ızgara; her hücrede içerik kutusuna kırpılır. Hücre dışına taşan parçalar komşu hücreden ayrılmaz,
bu yüzden hücreye ait olmayan küçük kalıntılar (alan < MIN) silinir."""
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
HERE = os.path.dirname(os.path.abspath(__file__)); S = f'{HERE}/assets/cevre/sayfa'; O = f'{HERE}/assets/cevre/oge'
PAGES = {'bitki': (4, 2), 'kaya': (4, 2), 'esya': (4, 2), 'ev_fener': (2, 2), 'sarmasik': (3, 1)}
MIN = 120
os.makedirs(O, exist_ok=True)
for name, (cols, rows) in PAGES.items():
    im = Image.open(f'{S}/{name}_temiz.png').convert('RGBA'); cw, ch = im.width / cols, im.height / rows
    k = 0
    for r in range(rows):
        for c in range(cols):
            cell = im.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch)))
            a = np.array(cell); m = a[..., 3] > 10
            lab, n = ndi.label(ndi.binary_dilation(m, iterations=3))   # parçalı nesneleri bütün tut
            if n == 0: continue
            sizes = ndi.sum(m, lab, range(1, n + 1)); keep = [i + 1 for i, s in enumerate(sizes) if s >= MIN * 4]
            if not keep: continue
            km = np.isin(lab, keep); a[~km, 3] = 0
            ys, xs = np.where(a[..., 3] > 10); crop = Image.fromarray(a).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
            crop.save(f'{O}/{name}_{k:02d}.png', optimize=True); print(name, k, crop.size); k += 1
