"""assets/ içindeki karakter karelerini oyun için kırpıp küçültür -> prototip/sprites/
ve (isteğe bağlı) tek dosyalık artifact sürümü üretir.
Kullanım: python3 tools_build_proto.py [artifact_cikti.html]"""
import sys, base64, io, os
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
# (dosya, hedef yükseklik px @2x, düzeltme). Düzeltme: ChatGPT karelerde baş boyunu hafif değiştiriyor.
REF = {'a': 128, 'b': 192}
FIX = {'a_idle':1, 'a_run1':.95, 'a_run2':.93, 'a_jump':.96, 'b_idle':1, 'b_run1':1.11, 'b_run2':1.11, 'b_jump':1.11}
idle_h = {}
for ch in 'ab':
    idle_h[ch] = Image.open(f'{HERE}/assets/char_{ch}_idle.png').getbbox()
out = {}
for key, fix in FIX.items():
    ch = key[0]
    im = Image.open(f'{HERE}/assets/char_{key[0]}_{key[2:]}.png').convert('RGBA')
    ib = idle_h[ch]; scale = REF[ch] / (ib[3] - ib[1]) * fix
    im = im.crop(im.getbbox())
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    p = f'{HERE}/prototip/sprites/{key}.png'
    im.save(p, optimize=True); out[key] = p
    print(key, im.size, os.path.getsize(p) // 1024, 'KB')
if len(sys.argv) > 1:
    html = open(f'{HERE}/prototip/index.html', encoding='utf-8').read()
    for key, p in out.items():
        b = base64.b64encode(open(p, 'rb').read()).decode()
        html = html.replace(f"'sprites/{key}.png'", f"'data:image/png;base64,{b}'")
    open(sys.argv[1], 'w', encoding='utf-8').write(html)
    print('artifact', sys.argv[1], len(html) // 1024, 'KB')
