# Çevre Görselleri: ChatGPT Promptları (Çayır ve Orman perdeleri)

> Önce **stil kılavuzunu** (aşağıda) bir kez yapıştırın. Her prompt TEK görsel, GERÇEK şeffaf arka plan (dama deseni DEĞİL), yazı yok.
> Hepsi yan görünüm, düz siyah silüet; yalnızca belirtilen tek parça renkli (varsa). Karakterlerle aynı Limbo/Inside atmosferi.
> Boyutlar oyundaki gerçek ölçeğe göre: karakter 54 px boyunda, kamera 2 kat yakın. Görseller 2048 px geniş istenir, ben küçültürüm.

## 0) Stil kılavuzu (bir kez)
```
2D yandan görünümlü atmosferik bir bulmaca-platform oyunu için ÇEVRE nesneleri çizeceksin. Stil: Limbo / Inside.
- Düz siyah (#0B0B0C) silüet, ama dış hat ayrıntılı: yaprak uçları, çimen telleri, kabuk çatlakları, ahşap damarı çizgi olarak (ince koyu gri #2A2B2E çizgiler serbest).
- Renk yok. Gri tonları yalnızca ince çizgilerde ve uzak katmanlarda kullanılır.
- Boyama tarzı, doku, gradyan, parlama, arka plan sahnesi, zemin gölgesi YOK. Şeffaf arka plan, yazı yok, her istekte tek görsel.
- Yan görünüm. Nesneler tuvalin alt kenarına oturur (zemine basar), kenarlardan taşmaz, etrafında boşluk bırakır.
- Döşenebilir (tile) olarak istenenlerin sol ve sağ kenarı birbirine kusursuz uymalı.
```

## 1) ZEMİN (en önemli, önce bunlar)
**1.1 Çimen şeridi (zeminin üstü), döşenebilir**
```
Stil kılavuzuna uy. Zeminin üst kenarı: siyah toprak şeridinin üstünde düzensiz, yüksekliği değişen siyah çimen telleri ve küçük kuru otlar. YATAY DÖŞENEBİLİR: sol ve sağ kenarı birbirine kusursuz uysun. Alt kenar düz kesik (toprağa bağlanacak). Genişlik 2048, yükseklik 256. Şeffaf arka plan.
```
**1.2 Çimen şeridi, ikinci varyasyon (tekrar belli olmasın)**
```
Aynı istek, farklı çim deseni: daha seyrek, birkaç uzun sivri ot, iki küçük çiçek sapı (çiçeksiz, yalnızca ince sap). Yatay döşenebilir, 2048x256, alt kenar düz kesik.
```
**1.3 Toprak dolgusu (zeminin altı), döşenebilir**
```
Stil kılavuzuna uy. Zeminin altı için toprak/kaya dolgusu: düz siyah, içinde ince koyu gri çatlak çizgileri, birkaç küçük kök ve taş silüeti. Yatay ve dikey döşenebilir (dört kenar uyumlu). 1024x1024.
```
**1.4 Sol ve sağ zemin kenarı (uçurum köşesi)**
```
Stil kılavuzuna uy. Bir zemin parçasının SAĞ ucu: üstte çimen, ucu aşağı düzensiz kaya yüzeyiyle iniyor, birkaç kök sarkıyor. Ayrı ikinci görsel: aynısının SOL ucu (ayna değil, farklı çizim olsun). Her biri 768x768, üst kenarı çimen çizgisinde hizalı.
```
**1.5 Çamur zemini**
```
Stil kılavuzuna uy. Çamur zemin şeridi: yüzeyi kabarcıklı, yumuşak ve çukurlu, birkaç küçük kabarcık patlaması ve izler. Yatay döşenebilir. 2048x192.
```
**1.6 Buz zemini**
```
Stil kılavuzuna uy. İnce buz tabakası şeridi yandan: düz üst yüzey, içinde ince çatlak çizgileri (açık gri #8E9094 ince çizgiler serbest), altı koyu su. Yatay döşenebilir. 2048x192.
```

## 2) AĞAÇLAR VE BİTKİLER (Orman)
**2.1 Çam ağacı, ön plan (3 farklı)**
```
Stil kılavuzuna uy. Tek bir büyük çam ağacı, ön plan, siyah silüet: kalın gövde, yukarı doğru daralan sık dallar, dal uçlarında iğne yaprak detayı. Zemin köklerinde biter. Üç ayrı görsel olarak üç farklı ağaç (biri ince, biri kalın, biri yarı kurumuş). Her biri 1024x2048.
```
**2.2 Ölü ağaç ve devrik gövde**
```
Stil kılavuzuna uy. (a) Ölü, yaprağı olmayan çarpık ağaç, çıplak dallar. (b) Yere devrilmiş kalın ağaç gövdesi, kesik ucu görünür, kökleri havada; üstünden geçilebilir (platform olacak). (c) Kökleri toprağın üstüne çıkmış kütük. Her biri ayrı görsel, 1536x1024.
```
**2.3 Çalılar ve otlar**
```
Stil kılavuzuna uy. Alt bitki örtüsü: (a) sık çalı, (b) eğrelti otları öbeği, (c) uzun kuru ot öbeği, (d) küçük mantarlar, (e) çalı dalları. Her biri ayrı görsel, 768x512, zemine oturur.
```
**2.4 Kayalar**
```
Stil kılavuzuna uy. Zemine yarı gömülü kayalar: küçük (taş), orta, büyük (üstünde durulabilir, düz tepeli). Üç ayrı görsel, 768x512, yüzeylerinde ince çatlak çizgileri.
```
**2.5 Sarkan sarmaşık ve kökler (tavandan)**
```
Stil kılavuzuna uy. Yukarıdan aşağı sarkan sarmaşık ve kök perdesi: ince dallar, birkaç yaprak. Üst kenarı düz kesik. Yatay döşenebilir. 2048x768.
```

## 3) HİKÂYE NESNELERİ (Çayır ve Orman)
**3.1 Kırmızı kurdele, ağaca bağlı (kontrol noktası)**
```
Stil kılavuzuna uy. Bir ağaç dalına/direğine bağlanmış bir kırmızı kurdele: siyah dal ve düğüm silüeti, kurdele PARLAK KIRMIZI (#C0392B), rüzgârda hafif dalgalanıyor. Tek renkli parça kurdele. Üç kare: (1) sakin, (2) rüzgârda sola, (3) rüzgârda sağa (kurdelenin uçları farklı). Her kare ayrı görsel, 512x1024.
```
**3.2 Çit ve kapı**
```
Stil kılavuzuna uy. Eski tahta çit: (a) kısa çit parçası (3 direk, 2 çıta), yatay döşenebilir, (b) kırık çit (bir çıta eksik, bir direk eğik), (c) açık bahçe kapısı. Her biri ayrı görsel, 1024x512, zemine oturur.
```
**3.3 Fener direği (köye yakın)**
```
Stil kılavuzuna uy. Eski demir fener direği: ince direk, üstünde fener kafesi (YANMIYOR, içi boş siyah). Ayrıca aynı direğin yanan hâli: fenerin içinde turuncu alev (#FF8A1F), tek renkli parça. İki ayrı görsel, 512x1536.
```
**3.4 Küçük ayak izleri ve büyük çizme izi (kar/çamur üstünde)**
```
Stil kılavuzuna uy. Zemine basılmış izler, üstten değil YANDAN görünen çukur izi şeridi olarak: (a) küçük çocuk botu izleri (6 adet, düzensiz aralıkla), (b) büyük yetişkin botu izleri, yarı silinmiş, (c) bir koyun sürüsünün izleri. Her biri ayrı görsel, yatay şerit 1536x192.
```
**3.5 Köy evi ve pencere lambası (Çayır, uzaktan)**
```
Stil kılavuzuna uy. Uzak plan: küçük taş köy evi siluet, çatısı eğimli, bacası var; penceresinde sıcak turuncu (#FF8A1F) küçük ışık. Tek renkli parça pencere ışığı. 1024x768. Ayrıca aynı evin ışığı SÖNÜK hâli (pencere siyah), ayrı görsel.
```
**3.6 Baba'nın izleri (Orman): çuval, çan, düdük**
```
Stil kılavuzuna uy. Orman yolunda bulunan eski eşyalar, her biri küçük, ayrı görsel, 512x512: (a) eskimiş koyun çanı, (b) ahşap düdük ve ipi, (c) yere bırakılmış eski bir çuval, (d) kırık bir fener (içi boş), (e) yarım yenmiş ekmek bohçası.
```
**3.7 Koyun**
```
Stil kılavuzuna uy. Küçük bir koyun, yandan, ayakta, kıvırcık yünlü siyah silüet, gözü küçük beyaz bir nokta. İki ayrı poz: ayakta duruyor, otluyor (başı aşağıda). 768x768.
```

## 4) ARKA PLAN KATMANLARI (uzak, orta, yakın)
Oyunda şimdilik kodla çizilen çam ormanı var. İsterseniz bu görselleri de verin, onu değiştiririm.
```
Stil kılavuzuna uy. Üç ayrı YATAY DÖŞENEBİLİR arka plan şeridi, 3072x1024, şeffaf olmayan ama kendi içinde şeffaflık kenarı yok: (a) UZAK katman: sisli, soluk gri (#8E9094) çam ormanı siluetleri, çok sade, (b) ORTA katman: biraz koyu gri (#55585E) çam siluetleri, (c) YAKIN katman: koyu (#2A2B2E) iri çam gövdeleri ve dallar. Sol ve sağ kenarlar kusursuz uyumlu. Her biri alt kenarında zemin çizgisine biter, üstü gökyüzüne açık (şeffaf).
```

## 5) DOSYA ADLARI (kaydederken)
`assets/cevre/` altına: `cim_1.png`, `cim_2.png`, `toprak.png`, `kenar_sag.png`, `kenar_sol.png`, `camur.png`, `buz.png`,
`cam_ince.png`, `cam_kalin.png`, `cam_kuru.png`, `agac_olu.png`, `govde_devrik.png`, `kutuk.png`, `cali.png`, `egrelti.png`, `ot.png`,
`mantar.png`, `kaya_kucuk.png`, `kaya_orta.png`, `kaya_buyuk.png`, `sarmasik.png`, `kurdele_1..3.png`, `cit.png`, `cit_kirik.png`, `kapi.png`,
`fener_direk_sonuk.png`, `fener_direk_yanik.png`, `iz_cocuk.png`, `iz_buyuk.png`, `iz_koyun.png`, `ev_isikli.png`, `ev_sonuk.png`,
`cuval.png`, `dudak.png` (düdük), `can.png`, `koyun_ayakta.png`, `koyun_otlayan.png`.
**Ben dosya adlarını gelenlere göre kendim ayarlarım**; siz görselleri hangi adla gelirse gelsin klasöre atın ve bana "yeni görseller eklendi" deyin.

## Öncelik sırası (hepsini yaptırmanız gerekmez)
1. **Zemin:** 1.1, 1.3, 1.4 (bölümlerin temeli, ilk bunlar).
2. **Hikâye:** 3.1 (kurdele), 3.2 (çit), 3.5 (ev).
3. **Ağaç ve bitki:** 2.1, 2.2, 2.3, 2.4.
4. Kalanlar sonra.

---
# TOPLU PROMPTLAR (tek seferde çok görsel: sayfa/ızgara)
Her prompt bir ızgara sayfası üretir. Ben kesip tek tek oyuna alırım. Kurallar (hepsinde aynı): eşit kareli ızgara, her nesne kendi karesinde ortada ve ALT KENARA OTURUR, nesneler karelerinden taşmaz ve birbirine değmez, ızgara çizgisi/yazı/numara YOK, GERÇEK şeffaf arka plan.
Stil kılavuzu aynı sohbette verilmiş olsun (düz siyah silüet, ince koyu gri çizgi ayrıntıları, renk yok; yalnızca belirtilen tek parça renkli).

## Sayfa 1: Ağaçlar (3x2 = 6 ağaç)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 3 sütun x 2 satır, eşit boyutlu kareler, 3072x2048. Her karede ayrı bir ağaç, yandan, ağacın dibi karenin alt kenarında, kare içinde ortalı, hiçbiri karesinden taşmasın ve diğerine değmesin: (1) uzun ince çam, (2) kalın gövdeli iri çam, (3) yarı kurumuş çam, yalnızca üst dalları yeşil değil siyah, (4) tamamen ölü, yaprağı olmayan çarpık ağaç, (5) iki gövdeli çam, (6) küçük genç çam. Düz siyah silüet, ince koyu gri gövde çizgileri. Izgara çizgisi, yazı, numara yok. GERÇEK şeffaf arka plan.
```

## Sayfa 2: Bitki örtüsü (4x2 = 8 öğe)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 4 sütun x 2 satır, eşit kareler, 4096x2048. Her karede ayrı öğe, dibi karenin alt kenarında, ortalı, karesinden taşmasın: (1) sık çalı, (2) eğrelti otları öbeği, (3) uzun kuru ot öbeği, (4) küçük mantar kümesi, (5) dikenli çalı dalları, (6) kısa çimen öbeği, (7) yaban çiçeği sapları (çiçekler küçük, siyah), (8) kök ve çalı karışık yığın. Düz siyah silüet, ince koyu gri ayrıntı çizgileri. Izgara çizgisi, yazı, numara yok. GERÇEK şeffaf arka plan.
```

## Sayfa 3: Kayalar ve kütükler (4x2 = 8 öğe)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 4 sütun x 2 satır, eşit kareler, 4096x2048. Her karede ayrı öğe, dibi karenin alt kenarında, ortalı: (1) küçük taş, (2) orta kaya, (3) büyük kaya, üstü düz (üstünde durulabilir), (4) çatlak, iki parçalı kaya, (5) yere yatmış kalın ağaç gövdesi, kesik ucu görünür, (6) kökleri havada devrilmiş ağaç kütüğü, (7) kesilmiş ağaç kütüğü, halkaları görünür, (8) yosunlu taş yığını. Düz siyah silüet, ince koyu gri çatlak çizgileri. Izgara çizgisi, yazı yok. GERÇEK şeffaf arka plan.
```

## Sayfa 4: Hikâye eşyaları (4x2 = 8 öğe)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 4 sütun x 2 satır, eşit kareler, 4096x2048. Her karede ayrı küçük eşya, tabanı karenin alt kenarında, ortalı: (1) eskimiş koyun çanı, (2) ahşap düdük ve ipi, (3) yere bırakılmış eski çuval, (4) kırık eski fener (içi boş, alevi yok), (5) yarım yenmiş ekmek bohçası (kumaş, düğümlü), (6) ahşap bastón, (7) eski paslı çan zinciri yığını, (8) yere düşmüş küçük bir ahşap oyuncak at. Hepsi düz siyah silüet, ince koyu gri ayrıntı çizgileri. Renk yok. Izgara çizgisi, yazı yok. GERÇEK şeffaf arka plan.
```

## Sayfa 5: İzler ve küçük zemin süsleri (2 satır şerit)
```
Stil kılavuzuna uy. TEK GÖRSEL: 2 satır, her satır yatay bir şerit, 4096x1024 (her satır 4096x512). Satır 1: zemine basılmış küçük çocuk botu izleri, 6 adet, düzensiz aralıkla, yandan görünen çukur izi. Satır 2: büyük yetişkin botu izleri, yarı silinmiş, 5 adet. Düz siyah silüet, ince koyu gri ayrıntı. Izgara çizgisi, yazı yok. GERÇEK şeffaf arka plan.
```

## Sayfa 6: Işıklı ev ve fener direği (2x2)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 2 sütun x 2 satır, eşit kareler, 3072x2048. Üst sol: köy evi (taş duvar, eğimli çatı, bacası, tek penceresi, kapısı, yanında odun yığını), pencerede sıcak TURUNCU (#FF8A1F) lamba ışığı yanıyor, tek renkli parça pencere ışığı. Üst sağ: aynı ev, aynı çizim, pencere SÖNÜK ve siyah. Alt sol: eski demir fener direği, üstünde fener kafesi, alevi TURUNCU (#FF8A1F) yanıyor, tek renkli parça. Alt sağ: aynı direk, fener sönük ve boş. Evler ve direkler düz siyah silüet, ince koyu gri ayrıntı çizgileri. Izgara çizgisi, yazı yok. GERÇEK şeffaf arka plan.
```

## Sayfa 7: Sarmaşıklar ve kökler (tavandan sarkan, 3x1)
```
Stil kılavuzuna uy. TEK GÖRSEL, ızgara sayfası: 3 sütun x 1 satır, eşit kareler, 4608x1536. Her karede yukarıdan aşağı sarkan bir öğe, ÜST kenara bağlı ve kareden taşmaz: (1) ince sarmaşık perdesi, birkaç yaprak, (2) kalın kök sarkıtları, (3) kuru dallar ve örümcek ağı parçaları. Düz siyah silüet, ince koyu gri ayrıntı çizgileri. Izgara çizgisi, yazı yok. GERÇEK şeffaf arka plan.
```

## İpuçları
- İlk iki sayfa (ağaçlar, bitkiler) en çok iş görür. Sırayla: 1 → 2 → 3 → 4 → 6.
- ChatGPT bazen sayıyı yanlış çizer (7 ağaç yerine 6). Önemli değil, kaç tane geldiyse kullanırım.
- Izgara kayarsa ("Hizası bozuk") yine gönderin, ben nesneleri bulup tek tek keserim.
