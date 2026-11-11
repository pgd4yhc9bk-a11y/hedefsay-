# 3. Bölüm "Değirmen": Meshy model listesi (ChatGPT için)

Bölüm şu an **yer tutucu geometriyle** oynanıyor. Aşağıdaki modeller `godot/proto/modeller/` klasörüne
doğru adla konunca **kod değişmeden** yerine oturur: oyun modeli istenen yüksekliğe ölçekler, tabanını yere
(ya da tekerlerde merkezini mile) oturtur. Gelmeyen model için yer tutucu kalır; yani liste parça parça yapılabilir.

## ChatGPT'ye verilecek mesaj (kopyala-yapıştır)

```
SİS oyununun 3. bölümü (Değirmen) için Meshy ile 3D modeller üretmeni istiyorum.
Depo: pgd4yhc9bk-a11y/hedefsay-  ·  dal: claude/intelligent-edison-7fygf8
Önce şunları oku: oyun-fikirlerim/iki-kisilik-oyun/DEVIR.md ve DEGIRMEN-MESHY-PROMPTLARI.md

Kurallar:
1. DEGIRMEN-MESHY-PROMPTLARI.md içindeki tabloyu sırayla (önce ⭐ olanlar) Meshy "Text to 3D" ile üret.
   Her model için tablodaki İngilizce komutu kullan; sonuna ortak stil cümlesini ekle.
2. Oyun modeli: düşük poligon (hedef 3.000–8.000 üçgen, smart topology), 1K doku, rig YOK.
3. Her modeli GLB olarak indir. Dosya 1,5 MB'ı geçiyorsa küçült
   (oyun-fikirlerim/iki-kisilik-oyun/tools_meshy_hafiflet.py ya da Meshy remesh; doku 1024, JPEG).
4. Dosyayı tablodaki adla şuraya koy: oyun-fikirlerim/iki-kisilik-oyun/godot/proto/modeller/<ad>.glb
   (dokular GLB'nin içinde gömülü olsun; ayrı doku dosyası olmasın).
5. KODA DOKUNMA. Yalnız model dosyalarını ekle. Model ters/yan duruyorsa kodda değil, bana haber ver
   (degirmen.gd içindeki MODEL_YAW tablosundan düzeltilir).
6. Yön: modelin önü +Z'ye baksın, dik dursun (Y yukarı), tabanı yerde olsun.
   Tekerler (su çarkı, dişli, el çarkı): düz yüzü öne (+Z) baksın, mili Z ekseninde olsun.
7. Push'tan önce test et (ikisi de "hata=0" yazmalı):
   Godot --headless --path godot --import
   Godot --headless --path godot res://proto/degirmen.tscn -- --test=degirmen
   Godot --headless --path godot res://proto/degirmen.tscn -- --test=degirmenplay
8. Her 3-4 modelde bir commit at; commit mesajına [apk] yazma. Meshy API anahtarını sohbete ya da depoya yazma.

Ortak stil cümlesi (her komutun sonuna):
"Old weathered dark wood and rusty iron, 19th century rural mountain village, muted desaturated colors,
realistic stylized, low poly game asset, single object, no ground, no background."
```

## Model tablosu

Yükseklik, oyunun modeli ölçekleyeceği boydur (metre); Meshy'de ayarlamak gerekmez.

| # | Dosya adı | Nerede | Yükseklik | Meshy komutu (İngilizce) |
|---|---|---|---|---|
| ⭐1 | `su_carki.glb` | Değirmenin dışında dönen büyük su çarkı | 5.0 | `A large old wooden water wheel of a watermill, with paddles around the rim, wooden spokes and an iron axle hub, seen from the front as a flat wheel.` |
| ⭐2 | `degirmen_cephe.glb` | Değirmenin giriş ve çıkış duvarı (kapı boşluğu olan cephe) | 7.4 | `The front wall of an old wooden watermill building, vertical dark planks, heavy timber frame, a tall empty doorway opening in the lower middle, small roof overhang on top, flat facade.` |
| ⭐3 | `disli.glb` | Dişli takımı (büyük, küçük ve Çınar'ın taşıdığı kayıp dişli; hepsi aynı model) | 0.8–2.0 | `A single old wooden cogwheel gear from a mill, thick wooden teeth around the edge, iron band and iron hub in the center, seen from the front as a flat wheel.` |
| ⭐4 | `testere_bicak.glb` | İnip kalkan bıçkı testeresi (hareketli parça) | 2.6 | `A long vertical sawmill frame saw blade, rusty steel blade with large teeth along one edge, held between two short iron crossbars at top and bottom.` |
| ⭐5 | `testere_cerceve.glb` | Testerenin sabit ahşap çerçevesi | 4.2 | `A tall wooden sawmill frame gate, two thick vertical timber posts joined by a heavy beam on top, with an empty gap in the middle for a blade, and a low log carriage at the base.` |
| ⭐6 | `degirmen_kapisi.glb` | Giriş ve çıkış kapısı (yukarı kalkan) | 3.5 | `A heavy old wooden mill door made of vertical planks, three horizontal iron bands with rivets, a big iron ring handle, flat rectangular door panel.` |
| ⭐7 | `kol.glb` | Bütün kollar (mandal, debriyaj, kapı kolu) | 1.1 | `An old mechanical floor lever, a wooden handle on an iron arm tilted to one side, mounted on a small stone and iron base.` |
| 8 | `el_carki.glb` | Savak çarkı ve kilerdeki el çarkı | 1.0 | `An old iron hand wheel valve with eight spokes and a small wooden crank handle on the rim, seen from the front as a flat wheel.` |
| 9 | `ic_kapi.glb` | İç kapılar (testere sonrası, çatı katının altı) | 3.5 | `An old interior wooden sliding barn door, rough horizontal planks with a diagonal brace, iron rollers on top, flat rectangular panel.` |
| 10 | `surgulu_duvar.glb` | Dişli odasındaki bölme duvarı; alt köşesinde çocuk boyu delik | 3.5 | `An old wooden partition wall panel of thick planks with iron bands, with a small square crawl hole cut out at the bottom corner, flat rectangular panel.` |
| 11 | `cikrik.glb` | Yük asansörünün çıkrığı (Çınar tutar) | 1.3 | `A small old wooden hand winch windlass, a rope drum between two wooden A-frame supports, iron crank handle on one side, coiled rope on the drum.` |
| 12 | `degirmen_tasi.glb` | Öğütme düzeneği (süs) | 1.7 | `An old grain mill assembly, two round millstones stacked on a round wooden base, a wooden grain hopper above and an iron shaft through the center.` |
| 13 | `un_cuvali.glb` | Un çuvalları (süs, çok yerde) | 0.85 | `A full burlap flour sack standing upright, tied at the top with rope, dusty beige cloth with wrinkles.` |
| 14 | `fici.glb` | Fıçılar (süs, çok yerde) | 1.0 | `An old wooden barrel with two rusty iron hoops, standing upright.` |
| 15 | `tomruk.glb` | Bıçkıhane tomrukları (yatay) | 0.5 | `A cut tree log lying horizontally, rough dark bark, visible growth rings on both cut ends, about seven times longer than it is thick.` |
| 16 | `gaz_lambasi.glb` | Kilerde Nehir'in yaktığı asılı lambalar | 0.55 | `An old hanging oil lantern, black iron frame with glass panes, a small iron hook and short chain on top.` |
| 17 | `su_olugu.glb` | Dereden çarka inen tahta su oluğu | 3.6 | `An old wooden water flume trough on tall timber trestle legs, a long open plank channel slightly sloping to one side.` |
| 18 | `magara_agzi.glb` | Bölüm sonu: mağara girişi (4. bölüme kapı) | 6.5 | `A dark cave entrance in a rocky cliff face, large grey boulders forming an arch around a black opening, patches of snow on top.` |
| 19 | `asansor_tablasi.glb` | Yük asansörünün tablası (isteğe bağlı) | 0.2 | `A flat square wooden cargo lift platform made of thick planks with iron edge strips, very low and flat.` |

**En azından ⭐ olan 7 model** bölümün görüntüsünü değiştirir. Meshy'de önizleme (preview) modeli başına
yaklaşık 5–20 kredi, doku ile 15–30 kredi tutar; 19 modelin tamamı kabaca 300–550 kredi.

## Durum (11 Kasım)
- **Modeller:** ⭐ işaretli 7 model geldi ve oyunda (`chatgpt/degirmen-meshy-modeller` dalından alındı). Kalan 12 model yer tutucu.
- **Animasyonlar:** ⭐ işaretli 7 klip geldi ve bağlandı. Kaynak: Meshy'den indirilen iki "All animation" GLB (depoda değil, büyük);
  `godot/proto/tools/retarget_degirmen.gd -- nehir.glb cinar.glb` ile `mocap/degirmen_nehir.res` ve `degirmen_cinar.res` üretilir.

| Klip | Kod adı (Meshy) | Oyunda |
|---|---|---|
| Nehir `WheelHold` | `_01a1cb88…` | Savak çarkını tutarken (döngü) |
| Nehir `GearMount` | `_01a1cb8b…` | Dişliyi mile takarken |
| Nehir `LampLight` | `_01a1cb8c…` | Kilerde lambayı yakarken |
| Çınar `CarryWalk` | `_01a1cb9c…` | Dişliyi taşırken (döngü) |
| Çınar `Crank` | `_01a1cbb3…` | Çıkrığı çevirirken (döngü) |
| Çınar `Fear` | `_01a1cbb6…` | Karanlıkta ışıksız beklerken (döngü) |
| Çınar `Crawl` | `_01a1cbb9…` | Alçak delikten geçerken (döngü) |

Bekleyenler: Nehir DN4 (irkilme), DN5 (asansörde bekleme), DN6 (büyük kol); Çınar DC5 (dişliyi yerden alma), DC6 (el çarkını tutma), DC7 (korkuyla koşma).
Çınar'ın bölüme özel klipleri `degirmen.gd` içindeki `companion_clip()` ile seçilir.
