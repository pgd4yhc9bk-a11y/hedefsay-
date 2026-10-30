# ChatGPT Görsel Promptları (Limbo tarzı)

> Karakterler: **Kabuk** (solo) ve **Kül** (co-op). Aşağıdaki karakter promptları hazır.

## Karakter promptları
**Kabuk:** `Stil kılavuzuna uy. Yandan görünüm, sağa bakan, ayakta duran tek bir çizim. Küçük, ince bacaklı, siyah silüet bir yaratık; yüzü yerine kendi gövdesinden büyük, kırık, kapalı gözlü, açık krem (#E7E3D8) renkli bir porselen maske taşıyor. Maske tek açık renkli parça; gövde düz siyah. Şeffaf arka plan.`
**Kabuk (maskesiz):** `Aynı karakter, maskesiz: küçük, düz siyah çocuk silüeti, yalnızca gözleri beyaz parlak noktalar. Yan görünüm, ayakta. Şeffaf arka plan.`
**Maske (tek başına nesne):** `Kırık, kapalı gözlü porselen maske, krem rengi, çatlaklı, dik duran, yandan hafif eğik. Siyah ince dış hat. Şeffaf arka plan.`
**Kül:** `Stil kılavuzuna uy. Yandan görünüm, sağa bakan, ayakta duran küçük bir çocuk; siyah silüet, çatlak bir gövde; göğsünde küçük turuncu (#FF8A1F) parlayan köz tek renkli parça. Gözleri beyaz noktalar. Şeffaf arka plan.`
Her karakter için sırayla: idle, koş 1, koş 2, zıpla, düş, it/çek (Kabuk), maske fırlat (Kabuk), ölüm.
**Önemli:** "düz siyah silüet, iç detay yok, yalnızca imza öğesi renkli" demeyi unutmayın, yoksa ChatGPT boyama tarzına kayıyor.

## Stil Kılavuzu (her sohbetin başında bir kez yapıştırın)
```
2D yandan görünümlü atmosferik bir bulmaca-platform oyunu için görsel üreteceksin. Stil: Limbo.
- Siyah silüet çizim: düz siyah (#0B0B0C) şekiller, iç detay ve dış hat yok.
- Yalnızca karakterlerin gözleri küçük, parlak beyaz noktalardır.
- Arka planlar tek tonlu gri (#8E9094 ile #3A3C40 arası), yumuşak sis, ışık huzmesi, katmanlı derinlik, dokusuz.
- Renk yok, yalnızca gri tonları.
- Çıktı: nesneler şeffaf PNG (arka planlar hariç), tek görsel, kenarlarda boşluk, yazı yok.
```
## Üretim listesi (karakterler kesinleşince)
| Dosya | Açıklama |
|---|---|
| `bg_forest_far.png`, `bg_forest_mid.png`, `bg_forest_near.png` | Üç katmanlı sisli orman arka planı (parallax), 1920x1080 |
| `tile_ground.png` | Siyah zemin parçası, üstü pürüzlü, yatay döşenebilir |
| `platform.png` | Havada duran ahşap plank silueti |
| `crate.png` | İtilebilir kasa silueti |
| `rope_vine.png` | Sarkan sarmaşık veya zincir |
| `trap_spikes.png`, `trap_saw.png` | Tehlike nesneleri |
| `lever.png`, `button.png`, `door.png` | Mekanizma parçaları |
Karakter pozları (idle, koş, zıpla, düş, tırman, it, ölüm) tasarım onaylanınca eklenecek.
