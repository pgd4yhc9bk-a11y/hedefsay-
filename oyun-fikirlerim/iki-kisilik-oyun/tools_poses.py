"""Poz görsellerini oyun için hazırlar: kırpar, ölçekler, ayak noktasını (çapa) bulur.
ChatGPT her pozu tuvale sığdıracak şekilde çizdiği için boyutlar tutarsızdır: göz beyazının büyüklüğüne göre
otomatik ölçek bulunur, aykırılar SCALE_FIX ile elle düzeltilir.
Kullanım: python3 tools_poses.py   -> godot/assets/<karakter>/poz/*.png + poses.json"""
import os, json
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
HERE = os.path.dirname(os.path.abspath(__file__))
# Duran karakterin oyundaki yüksekliği (px) x ÇÖZÜNÜRLÜK. Nehir 54, Çınar 44.
GAME_H = {'nehir': 54, 'cinar': 44}
RES = 4                                     # 4x süper çözünürlük
# Referans poz: yürüme (göz beyazı büyüklüğü bu pozdan alınır). Değer: kaynak pikselinde "baş boyu" tahmini
REF = {'nehir': ('02_yuruyus_a', 1177), 'cinar': ('01_yuruyus_a', 1167)}   # içerik yüksekliği (px) = karakter boyu
# Ölçek elle düzeltmeleri (pozun kaynak içerik yüksekliğine göre çarpan); gözle ayarlandı
SCALE_FIX = {
    'nehir': {'01_ziplama_yukselis': 0.78, '05_ziplama_tepe': 0.78, '06_dusme': 0.80, '07_inis_comelme': 0.80, '08_yuvarlanma': 0.80,
              '04_kosma': 0.82, '09_kayma_sendeleme': 0.82, '10_camurda_yuruyus': 0.92, '11_kutu_cekme': 0.80, '12_kutu_itme': 0.80,
              '13_fener_kaldirma': 0.88, '14_tirmanma': 0.88, '16_aglama': 0.88, '17_korku_cinari_koruma': 0.70, '15_sarilma_nehir_cinar': 0.70, '18_sirtta_tasima': 0.70},
    'cinar': {'04_kosma': 1.0, '05_ziplama_yukselis': 0.94, '06_ziplama_tepe': 0.89, '07_dusme': 0.91, '08_inis_comelme': 0.88, '09_yuvarlanma': 1.0,
              '10_buzda_kayma_neseli': 0.94, '11_camurda_yuruyus': 0.97, '12_surunme': 0.70, '13_bekleme_yukari_bakis': 0.65, '14_tirmanma': 0.88,
              '15_el_uzatma': 0.88, '16_korku_comelme': 0.64, '17_aglama': 0.88, '18_tavsana_sarilma': 0.88, '19_oturma_uyuma': 0.70},
}
out_all = {}
for who in ('nehir', 'cinar'):
    src = f'{HERE}/assets/{who}/poz'; dst = f'{HERE}/godot/assets/{who}/poz'; os.makedirs(dst, exist_ok=True)
    ref_name, ref_h = REF[who]
    base_scale = GAME_H[who] * RES / ref_h          # kaynak px -> çıktı px (referans pozda)
    meta = {}
    for f in sorted(os.listdir(src)):
        if not f.endswith('.png'): continue
        name = f[:-4]
        if name.startswith(('15_sarilma', '17_korku_cinari', '18_sirtta')) and who == 'nehir':
            pass   # ikili pozlar da hazırlanır (ara sahne)
        im = Image.open(f'{src}/{f}').convert('RGBA'); a = np.array(im)
        mask = a[..., 3] > 40
        ys, xs = np.where(mask); x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        crop = im.crop((x0, y0, x1, y1))
        s = base_scale * SCALE_FIX[who].get(name, 1.0)
        out = crop.resize((max(1, round(crop.width * s)), max(1, round(crop.height * s))), Image.LANCZOS)
        out.save(f'{dst}/{name}.png', optimize=True)
        # çapa: en alttaki %18'lik piksellerin ağırlık merkezi (ayaklar)
        m = np.array(out)[..., 3] > 40; yy, xx = np.where(m)
        low = yy > yy.max() - max(4, int((yy.max() - yy.min()) * 0.18))
        ax = float(xx[low].mean()); ay = float(yy.max())
        meta[name] = {'w': out.width, 'h': out.height, 'ax': round(ax, 1), 'ay': round(ay, 1), 'res': RES}
        print(who, name, out.size, 'çapa', meta[name]['ax'], meta[name]['ay'])
    out_all[who] = meta
json.dump(out_all, open(f'{HERE}/godot/assets/poses.json', 'w'), indent=1)
