"""ChatGPT bazen "şeffaf" diye dama desenini görüntünün içine pişirir. Bu araç dama arka planı gerçek şeffaflığa çevirir.
Kullanım: python3 tools_matte.py <girdi.png> <çıktı.png>"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
im = np.array(Image.open(sys.argv[1]).convert('RGB')).astype(np.int32)
mn, mx = im.min(axis=2), im.max(axis=2)
neutral = (mn > 150) & ((mx - mn) < 10)               # beyaz ve açık gri dama kareleri (krem tavşan hafif renkli, dışarıda kalır)
lab, n = ndi.label(neutral)
sizes = ndi.sum(neutral, lab, range(1, n + 1))
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.zeros_like(neutral)
for i in range(1, n + 1):
    if i in border or sizes[i - 1] > 120:
        bg |= (lab == i)
bg = ndi.binary_dilation(bg, iterations=1) & (mn > 90)   # kenardaki açık hale de sil
alpha = np.where(bg, 0, 255).astype(np.float32)
band = ndi.binary_dilation(bg, iterations=2) & ~bg           # kenar bandında yumuşak geçiş: koyu = opak
lum = im.mean(axis=2)
alpha[band] = np.clip((235 - lum[band]) / 235.0 * 1.25, 0, 1) * 255
out = np.dstack([im, alpha]).astype(np.uint8)
Image.fromarray(out, 'RGBA').save(sys.argv[2], optimize=True)
print(sys.argv[2], 'şeffaf yüzde', round((alpha < 10).mean() * 100, 1))

# --- küçük beyaz kalıntı lekeleri temizle (dama deseninden kalan): küçük ve açık renkli bileşenler silinir
res = np.array(Image.open(sys.argv[2]).convert('RGBA'))
op = res[..., 3] > 3
lab2, n2 = ndi.label(op)
if n2:
    sz = ndi.sum(op, lab2, range(1, n2 + 1)); lum2 = ndi.mean(res[..., :3].mean(axis=2), lab2, range(1, n2 + 1))
    kill = [i + 1 for i in range(n2) if sz[i] < 400 and lum2[i] > 110]
    if kill:
        res[np.isin(lab2, kill), 3] = 0
        Image.fromarray(res, 'RGBA').save(sys.argv[2], optimize=True)
        print('temizlenen leke:', len(kill))
