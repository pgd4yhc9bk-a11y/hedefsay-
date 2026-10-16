# Hedef

Kelime ve işlem düellosu. Tasarım belgesi: [docs/TASARIM.md](docs/TASARIM.md).

## Web prototipi (`prototip/`)

Derleme gerekmez: `prototip/index.html` dosyasını tarayıcıda aç.

- `oyun.js` — arayüzden bağımsız çekirdek: sayı turu üretici + çözücü + ifade doğrulama, kelime turu harf üretici + sözlük denetimi + puan, bot rakip. Tohumlu rastgele sayı (günlük mod için).
- `sozluk.js` — **geçici** ~700 kelimelik deneme sözlüğü. Yayın sözlüğü değildir (bkz. TASARIM §9, lisans doğrulanacak).
- `index.html` — arayüz: botlu düello (4 tur, harfleri turlar sırayla seçer) ve günlük mücadele (tohum = tarih, günde bir kez, paylaşım metni).
- `test.js` — çekirdek testleri: `node prototip/test.js`

## Sunucu (`supabase/`)

Şema, RLS, günlük bulmaca üretimi ve skor doğrulama: [supabase/README.md](supabase/README.md).

**Prototipi sunucuya bağlama:** `prototip/config.js` içindeki `anonKey` alanına Supabase paneli → Project Settings → API'deki **anon / publishable** anahtarı yaz (herkese açık anahtardır; `service_role` ASLA). Doluysa günlük mod sunucudan oynanır: oyuncu kartı (takma ad + il), bulmaca ve puan sunucudan, süre sunucu damgasıyla, bugünün sıralaması ve il ligi. Boşsa günlük mod yerelde, sıralamasız çalışır. **Canlı düello** de sunucudan oynanır: gerçek rakip aranır, 15 sn içinde bulunamazsa açıkça "Bot" adıyla bot oynar; harfleri sistem seçer, süre bonusu yoktur. Pratik (bota karşı) her zaman yereldir.

## Prototipte sabitlenen / karar bekleyen değerler

| Konu | Prototipteki değer |
|---|---|
| Tüm harfleri kullanma bonusu | +10 (belgede yalnızca "ek bonus") |
| Kelime puanı | harf sayısı, jokersiz +3 |
| Tam isabette süre bonusu | yalnızca günlük modda: kalan her 10 sn için +1 (`SURE_BONUS_BOLEN`, çekirdekte) |
| Günlükte süre | iki tur de 60 sn sabit (ayar yalnızca düelloda; adalet için) |
| Bot gücü | işlemde %45 tam isabet, aksi halde 1–12 fark; kelimede en iyi 12 kelimeden ağırlıklı seçim |
| Pratik düello | bot sonucu tur bitince hesaplanır, yerel |
| Canlı düello | durum sunucuda; istemci ~1,2 sn'de bir `status` sorgular (Realtime kanalı yerine polling: bağlantı kopmasına doğal dayanıklı, test edilebilir); harfleri sistem seçer; 5 sn geri sayım; süre bonusu yok |

## Sözlük lisansı (Faz 0 notu)

- Zemberek-NLP **kodu** Apache 2.0; [SSS](https://github.com/ahmetaa/zemberek-nlp/wiki/FAQ) kapalı kaynaklı ticari üründe kullanıma izin verildiğini söylüyor (dağıtım koşullarına uyulmak şartıyla).
- Sözlük **verisinin** (ana sözlük / kelime listesi) lisansı SSS'de geçmiyor; bu **doğrulanmadı**. Yayından önce depodaki LICENSE dosyası ve veri dosyalarının kendi notları okunmalı. Belirsiz kalırsa belgedeki plana göre kendi listemizi hazırlarız.
- Proje bakım modunda (son sürüm 0.17.1, 2019).
