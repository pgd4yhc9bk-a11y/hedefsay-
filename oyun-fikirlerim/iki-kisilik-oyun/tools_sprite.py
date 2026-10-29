"""ChatGPT'den gelen karakter görsellerini oyun için hazırlar.
Kullanım: python3 tools_sprite.py <kaynak.webp|png> <hedef.png>
Hepsi aynı ölçekle işlenir, böylece pozlar arasında boyut tutarlı kalır."""
import sys
from PIL import Image
SCALE, W, H, PAD = 0.55, 640, 512, 16   # kaynak px -> çıktı px, tuval, alt boşluk
im = Image.open(sys.argv[1]).convert('RGBA')
im.putalpha(im.getchannel('A').point(lambda v: 0 if v < 16 else v))  # kenar gürültüsünü sil
im = im.crop(im.getbbox())
im = im.resize((round(im.width * SCALE), round(im.height * SCALE)), Image.LANCZOS)
c = Image.new('RGBA', (W, H), (0, 0, 0, 0))
c.paste(im, ((W - im.width) // 2, H - PAD - im.height), im)          # ayaklar tabana
c.save(sys.argv[2], optimize=True)
print(sys.argv[2], im.size)
