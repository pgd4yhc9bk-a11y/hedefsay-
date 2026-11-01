# SİS: Önsöz ve geçiş sahneleri (Google Flow)

Toplam süre yaklaşık 50 saniye, 6 klip × 8 saniye. Hepsi sessiz anlatım: konuşma yok, ekranda yazı yok.
Önsözün son klibi, oyunun ilk karesiyle (`referans/oyun_ilk_kare.png`) bitiyor. Böylece video bitince oyun aynı kareden başlıyor.
Ayrıca bölüm sonu için bir kapanış klibi var (Klip 7).

## Nasıl çalışalım
1. **Referans görselleri yükle.** `referans/` klasöründeki görseller oyundaki modellerden alındı. Flow'da karakter veya nesne
   referansı verebildiğin bölüme (ör. *Ingredients*) şunları ekle:
   - Nehir: `nehir_uc_ceyrek.png`, `nehir_yuz.png`
   - Çınar: `cinar_uc_ceyrek.png`, `cinar_yuz.png`
   - Pofuk: `pofuk.png`
   - Ortamın havası için: `oyun_stil_orman.png`
2. **Her klipte stil bloğunu ve karakter bloğunu tekrar yaz.** Kopyala-yapıştır yeterli. Tutarlılığı bu sağlar.
3. **Klipleri birbirine bağla.** Bir klibin son karesini bir sonrakinin ilk karesi olarak ver (*Frames to Video* veya *Extend*).
   Klip 6'da **son kare** olarak `oyun_ilk_kare.png` ver.
4. **Ses:** Yalnızca rüzgâr, kar ve ayak sesi olsun; müzik ve konuşma olmasın. Flow ses üretirse sorun değil, gerekirse oyunda sesi biz koyarız.
5. **Bana gönder:** mp4 olarak `klip1.mp4 … klip7.mp4`. Godot için .ogv'ye ben dönüştürüp oyuna bağlarım.
   Tutarsız çıkan klibi (yüz, kıyafet değişmiş) 2–3 kez yeniden üret, en iyisini seç.

Her klipte 16:9 en-boy oranı kullan, çözünürlük 720p yeterli.

---

## Stil bloğu (her komutun başına)
```
Cinematic, atmospheric, melancholic. Cold winter dusk, dense fog, near-monochrome blue-grey palette; the only warm colors are a small orange lantern flame and a red wool scarf. Soft volumetric light, falling snow, quiet and still. Stylized realistic 3D animation, like a high-end animated film, consistent characters. Wide side-on compositions, slow camera, long takes. No text, no subtitles, no dialogue, no music.
```

## Karakter blokları (o klipte kim varsa ekle)
```
NEHIR: an 11-year-old girl, slim, pale skin, large dark-brown eyes, dark-brown hair with loose bangs and one long thick braid down her back, long chunky knitted red wool scarf, knee-length charcoal-black wool coat with a belt, black tights, grey knitted leg warmers, black lace-up boots.
```
```
CINAR: a 6-year-old boy, small, pale skin, big dark eyes, messy curly dark-brown hair, long red knitted wool scarf, slightly oversized charcoal-black wool coat, dark trousers, grey socks, small black boots.
```
```
POFUK: a worn cream-white plush bunny toy with very long floppy ears and small stitched eyes.
```
```
MOTHER: a woman in her late thirties, dark hair in a low bun, long dark-grey wool dress; seen mostly from behind or only her hands.
```
```
LANTERN: an old black iron cage lantern with a ring handle and a small warm orange flame.
```

---

## Klip 1: Köy evi (kuruluş)
**Ne oluyor:** Kış akşamı. Ormanın kenarında küçük ahşap bir ev, tek penceresinde lamba yanıyor. Sis ormandan eve doğru sürünüyor.
**Kamera:** Geniş plan, çok yavaş yaklaşma.
```
[STİL BLOĞU]
A small old wooden village house at the edge of a dark pine forest at winter dusk. One small window glows warm orange from an oil lamp on the sill. Thick fog slowly creeps out of the forest across the snowy field toward the house. Snow falls gently. Very slow push-in from a wide shot. Sound: soft wind.
```

## Klip 2: Pofuk uçuyor
**Ne oluyor:** Çınar verandada tavşanını tutuyor. Bir rüzgâr tavşanı elinden kapıyor; tavşan karda yuvarlanarak ormana doğru gidiyor. Çınar elini uzatıyor.
**Kamera:** Yandan, orta plan, sabit.
```
[STİL BLOĞU] [CINAR] [POFUK]
Side view, medium shot. CINAR stands on the snowy wooden porch of the house, hugging POFUK. A sudden gust of wind snatches POFUK from his hands; the bunny tumbles and rolls across the snow toward the dark foggy forest. CINAR reaches out with one hand, startled. Warm window light behind him, cold fog ahead. Static camera.
```

## Klip 3: Sise karışan çocuk
**Ne oluyor:** Çınar tavşanın peşinden ormana koşuyor. Ağaçların arasında sise gömülüyor; en son kırmızı atkısı görünüp kayboluyor.
**Kamera:** Orman kenarında sabit, yandan geniş plan. Çocuk küçülüp kaybolur.
```
[STİL BLOĞU] [CINAR]
Wide side-on shot at the edge of a dark pine forest. CINAR runs from left to right after a small cream-white toy bunny into the trees. The fog swallows him; his red scarf is the last thing visible before he disappears completely. The camera stays still. Silence except wind.
```

## Klip 4: Nehir kapıda
**Ne oluyor:** Nehir açık kapıda duruyor, sise bakıyor, endişeli. Annesinin elleri kırmızı atkıyı onun boynuna sarıyor. Nehir kapının yanındaki çividen feneri alıyor.
**Kamera:** İçeriden, kapı çerçevesinde; arkada sis. Yakın ve orta plan.
```
[STİL BLOĞU] [NEHIR] [MOTHER] [LANTERN]
Inside a dim wooden house looking out through an open front door into blue fog. NEHIR stands in the doorway, worried, staring into the fog. Her MOTHER's hands gently wrap a long red knitted scarf around NEHIR's neck. NEHIR takes the LANTERN from a nail beside the door; its small orange flame lights her face. Warm interior light, cold blue outside.
```

## Klip 5: Sise yürüyüş
**Ne oluyor:** Nehir verandadan karın içine iniyor, feneri kaldırıp ormana yürüyor. Arkasında evin penceresinde lamba yanıyor. Uzaklaştıkça turuncu küçük bir ışığa dönüşüyor.
**Kamera:** Yandan, yavaş takip ve geri çekilme.
```
[STİL BLOĞU] [NEHIR] [LANTERN]
Wide side-on shot. NEHIR steps down from the porch into deep snow and walks toward the dark foggy forest, holding the LANTERN up in front of her. Behind her the house window glows warm. As she walks away she becomes a small orange point of light in the fog. Slow tracking shot pulling back. Sound: footsteps crunching in snow, wind.
```

## Klip 6: Köprü, kayma ve düşüş (oyuna bağlanır)
**Ne oluyor:** Derin orman, gece, yoğun sis. Bir ağacın gövdesinde kırmızı bir kurdele (babanın işareti). Nehir dik bir yamaçta dikkatle yürüyor, ayağı kayıyor, yamaçtan aşağı yuvarlanıyor. Fener elinden düşüp yanına yuvarlanıyor, alevi titreşerek kısılıyor. Nehir karda hareketsiz yatıyor.
**Son kare:** `referans/oyun_ilk_kare.png` (yukarıdan bakış, kız karda yatıyor, fener yanında). Flow'da bu görseli **son kare** olarak ver.
```
[STİL BLOĞU] [NEHIR] [LANTERN]
Deep pine forest at night, dense fog, light snow. A faded red ribbon is tied around a tree trunk. NEHIR carefully walks along a steep snowy slope holding the LANTERN. Her foot slips; she tumbles down the slope into a snowy clearing between tall dark trunks. The LANTERN falls from her hand and rolls to rest beside her, its flame flickering low. She lies still in the snow. The camera rises to a high top-down angle looking down at her small figure and the faint lantern glow between the long tree shadows.
```

---

## Klip 7: Kapanış (bölüm sonu, oyun içi sarılmadan sonra)
**Ne oluyor:** Nehir ve Çınar el ele, sisin içinde ağaçlardaki kırmızı kurdeleleri takip ederek uzaklaşıyorlar. Kamera yükseliyor: ormanda onlarca kurdele.
**İlk kare:** Oyundaki final sarılması (gerekirse bu kareyi ben oyundan çıkarırım).
```
[STİL BLOĞU] [NEHIR] [CINAR] [POFUK] [LANTERN]
Wide side-on shot in a foggy winter forest at dawn. NEHIR holds the LANTERN in one hand and CINAR's hand in the other; CINAR hugs POFUK. They walk slowly away from the camera along a path where red ribbons are tied to the tree trunks, one after another into the fog. The camera slowly rises above the trees, revealing dozens of red ribbons fading into the mist. Calm, hopeful, melancholic.
```

---

## Sonraki adımlar
- Klipler gelince oyuna bağlayacağım: oyun açılışında önsöz oynar (dokunarak atlanabilir), Klip 6'nın son karesinden oyuna kesintisiz geçer.
- Bölüm geçişleri için aynı yöntemle yeni klipler yazacağız (Çayır, Orman, Dere…). Önce bu önsözün tutarlılığını görelim.
