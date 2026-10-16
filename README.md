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
| Tam isabette süre bonusu | henüz yok (yalnızca tek oyunculu modda olacak) |
| Bot gücü | işlemde %45 tam isabet, aksi halde 1–12 fark; kelimede en iyi 12 kelimeden ağırlıklı seçim |
| Düello eşzamanlılığı | yok; bot sonucu tur bitince hesaplanır (gerçek düello Faz 4) |
