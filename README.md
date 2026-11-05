# Hedef

Kelime ve işlem düellosu. Tasarım belgesi: [docs/TASARIM.md](docs/TASARIM.md).

## Web prototipi (`prototip/`)

Derleme gerekmez: `prototip/index.html` dosyasını tarayıcıda aç.

- `oyun.js` — arayüzden bağımsız çekirdek: sayı turu üretici + çözücü + ifade doğrulama, kelime turu harf üretici + sözlük denetimi + puan, bot rakip. Tohumlu rastgele sayı (günlük mod için).
- `sozluk.js` — **geçici** ~700 kelimelik deneme sözlüğü. Yayın sözlüğü değildir (bkz. TASARIM §9, lisans doğrulanacak).
- `index.html` — arayüz: botlu düello (4 tur, harfleri turlar sırayla seçer) ve günlük mücadele (tohum = tarih, günde bir kez, paylaşım metni).
- `test.js` — çekirdek testleri: `node prototip/test.js`

## Prototipte sabitlenen / karar bekleyen değerler

| Konu | Prototipteki değer |
|---|---|
| Tüm harfleri kullanma bonusu | +10 (belgede yalnızca "ek bonus") |
| Kelime puanı | harf sayısı, jokersiz +3 |
| Tam isabette süre bonusu | yalnızca günlük modda: kalan her 10 sn için +1 (`SURE_BONUS_BOLEN`) |
| Bot gücü | işlemde %45 tam isabet, aksi halde 1–12 fark; kelimede en iyi 12 kelimeden ağırlıklı seçim |
| Düello eşzamanlılığı | yok; bot sonucu tur bitince hesaplanır (gerçek düello Faz 4) |

## Sözlük lisansı (Faz 0 notu)

- Zemberek-NLP **kodu** Apache 2.0; [SSS](https://github.com/ahmetaa/zemberek-nlp/wiki/FAQ) kapalı kaynaklı ticari üründe kullanıma izin verildiğini söylüyor (dağıtım koşullarına uyulmak şartıyla).
- Sözlük **verisinin** (ana sözlük / kelime listesi) lisansı SSS'de geçmiyor; bu **doğrulanmadı**. Yayından önce depodaki LICENSE dosyası ve veri dosyalarının kendi notları okunmalı. Belirsiz kalırsa belgedeki plana göre kendi listemizi hazırlarız.
- Proje bakım modunda (son sürüm 0.17.1, 2019).

## Kayıp Katlar (`katlar/`)

2.5D kat kat ilerlenen RPG'nin Etap 0 web prototipi. Grafikler Three.js (WebGL) ile 3D: `katlar/sahne.js` çizim, `katlar/oyun.js` oyun mantığı. Tasarım: [docs/KATLAR_TASARIM.md](docs/KATLAR_TASARIM.md).
`katlar/index.html` dosyasını tarayıcıda aç (internet gerekir: Three.js CDN'den yüklenir). İlerleme tarayıcıda (localStorage) saklanır.

- 3 sınıf (Savaşçı, Okçu, Büyücü), her biri otomatik saldırı + bir yetenek.
- Seviye 1–80 EXP eğrisi (içerik şimdilik 30'a kadar), 3 bölge × 20 kat, 10. ve 20. katta bekçi.
- Altın, Basma Taşı, Kor Tozu; rastgele özellikli eşyalar (4 nadirlik), envanter, kuşanma, satma.
- Demirci: eşya başına +1…+9, başarısızlıkta seviye düşmez, her başarısızlık +%15.
- Her 5 katta çıkış kapısı ganimeti güvene alır; ölünce son kapıdan sonraki ganimetin yarısı gider, EXP kalır.
- `golge/` eski gölge mekanikli deneme, artık kullanılmıyor.
