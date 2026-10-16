# Hedef — Kelime ve İşlem Düellosu

> Çalışma adı. Aslan İnteraktif projesi. Sürüm 0.1 (Ekim 2026)

## 1. Özet

TRT’nin klasik yarışma formatından esinlenen, iki turlu (kelime + işlem) bir zekâ oyunu. Asıl fark: iki oyuncunun **aynı harf ve sayılarla, aynı anda** yarıştığı canlı düello, herkesin aynı bulmacayı çözdüğü **günlük mücadele** ve **il ligi**.

Hedef kitle: 16–60 yaş, Türkçe konuşan, kelime ve sayı oyunu seven geniş kitle. Nostaljiden dolayı 40+ yaş da hedefte.

## 2. Neden bu oyun

- Türde baskın bir mobil oyun yok. Mağazadaki muadiller küçük ve eski (binlerce indirme düzeyinde), sosyal özellikleri yok.
- En ciddi rakip Cumhuriyet’in web oyunu “1 Kelime & 1 Sayı”: kelime + sayı turları ve sıralama var; uygulama ve canlı düello yok.
- Günlük bulmaca + paylaşılabilir sonuç modeli kanıtlı (NYT Games 2025’te 11,2 milyar oynanma).
- Geliştirme maliyeti düşük: 2D arayüz, fizik yok, içerik büyük ölçüde otomatik üretilebilir (sayı turu tamamen, kelime turu sözlükle).

## 3. Hukuki sınırlar (baştan karar)

- “Bir Kelime Bir İşlem” TRT’nin program adı. **Mağazada, ikonda, açıklamada program adı, logosu, müziği ve görsel kimliği kullanılmayacak.** Açıklamada “TV programıyla bağlantısı yoktur” notu yer alacak.
- İsim adayları (mağaza ve alan adı kontrolü yapılacak): **Hedef**, Hedef Sayı, Altı Sayı Sekiz Harf, Kelime & Sayı Düellosu.
- Sözlük kaynağının lisansı yayından önce doğrulanacak (bkz. Bölüm 9).

## 4. Oyun kuralları

### 4.1 Sayı turu
- 5 adet tek basamaklı sayı (1–9) + 1 adet onluk sayı (10, 20 … 90).
- Hedef: 101–999 arası, üretici tarafından **tam ulaşılabilir** olacak şekilde seçilir (çözücü ile kontrol).
- Dört işlem; çıkarma ve bölmede sonuç pozitif tam sayı olmalı. Her sayı bir kez kullanılır, ara sonuçlar yeniden kullanılabilir.
- Süre: 60 sn (ayar ile 90 sn).
- Puan: tam isabet 10, 1–5 fark 7, 6–10 fark 5, daha uzak 0. Tam isabette kalan süre bonusu (yalnızca tek oyunculu modda).
- Tur sonunda “bilgisayarın çözümü” gösterilir.

### 4.2 Kelime turu
- 8 harf + 1 joker. Oyuncu (düelloda sırayla) “sesli / sessiz” seçerek harfleri açar; en az 3 sesli zorunlu.
- Süre: 60 sn. En uzun geçerli Türkçe kelimeyi kur.
- Puan: harf sayısı kadar puan; jokersiz kelimeye +3. Tüm harfleri kullanan kelimeye ek bonus.
- Tur sonunda “bu harflerle kurulabilecek en uzun kelime” gösterilir.

### 4.3 Bir oyun
- 4 tur: kelime, işlem, kelime, işlem. Final turu (sonraki sürüm): ortak tek soru, ilk doğru cevaplayan alır.

## 5. Modlar

| Mod | Açıklama | MVP |
|---|---|---|
| Günlük | Herkese aynı harfler ve sayılar; günde bir kez; il ve genel sıralama; renkli kare ile sonuç paylaşımı | Evet |
| Pratik | Sınırsız, bilgisayara karşı, sıralamasız | Evet |
| Canlı düello | Eşleştirme ile iki oyuncu, aynı harf ve sayılar, aynı anda | Evet |
| Arkadaşla düello | Davet linki veya kod ile özel oda | Evet |
| Asenkron meydan okuma | Rakip sonra oynar, sonuçlar yan yana | 1.1 |
| Turnuva / il ligi sezonu | Haftalık il sıralaması, sezon sonu rozet | 1.1 |

## 6. Sosyal döngü

- Oyuncu kartı: takma ad + il (zorunlu değil ama teşvikli).
- **İl Ligi:** günlük skorlar il hanesine yazılır, haftalık sıfırlanır.
- Paylaşım metni: tur başına ikon (🎯 tam, 🟨 yakın, ⬜ uzak) + puan; WhatsApp’ta yayılacak biçimde.
- Düello sonrası rövanş butonu; arkadaş listesi (1.1).

## 7. Gelir modeli

- Yayında: reklamsız ve satın almasız başlangıç (Sapla’daki yaklaşımla aynı), kullanıcı tabanı ölçülür.
- 1.1: ödüllü reklamla ek düello hakkı / ipucu, reklamsız paket, tema paketleri, arşiv erişimi (geçmiş günlükler).
- Ara reklam: düello ortasında asla.

## 8. Teknik mimari

- **İstemci:** Expo + React Native Skia (Sapla ile aynı hat, kod ve deneyim paylaşımı). Web prototipi tek HTML olarak paralel tutulur.
- **Sunucu:** Supabase
  - Postgres: oyuncular, günlük bulmacalar, skorlar, il ligi görünümleri.
  - Realtime kanalları: düello odası, eşleştirme kuyruğu.
  - Edge Functions: günlük bulmaca üretimi (cron), **skor doğrulama** (işlem ifadesini sunucuda yeniden hesapla, kelimeyi sunucudaki sözlükte kontrol et), eşleştirme.
- **Hile önlemi:** istemci yalnızca hamleyi gönderir, puanı sunucu hesaplar; günlük bulmaca sunucudan gelir, süre sunucu damgasıyla tutulur. Çözücü kullanımı tamamen engellenemez; düelloda hız ve süre sınırı bunu sınırlar.
- **Çevrimdışı:** pratik modu tamamen çevrimdışı çalışır.
- Geliştirme düzeni: GitHub deposu + Claude Code; özellik dalları, testler yeşilse birleştirme.

### Veri modeli (ilk taslak)
- `players(id, nick, city, created_at)`
- `daily_puzzles(date, letters, joker, numbers, target, best_word, best_expr)`
- `daily_scores(date, player_id, score, word, expr, duration_ms)`
- `matches(id, a, b, state, seed, created_at)` + `match_moves(match_id, round, player_id, payload, ts)`
- Görünüm: `city_league(week, city, total, players)`

## 9. İçerik ve sözlük

- **Sayı turu:** tamamen üretici + çözücü (prototipte hazır; hedefin tam ulaşılabilir olması garanti edilir).
- **Kelime turu:** açık lisanslı bir Türkçe kelime listesi gerekir. Aday: Zemberek-NLP sözlüğü; lisansı ve ticari kullanım koşulları doğrulanacak. TDK içeriği izinsiz kullanılmayacak.
- Sözlük temizliği: özel isim, kısaltma, argo ve hakaret filtresi; çekimli biçimler kabul edilmeyecek (yalın kök/madde başı kuralı netleştirilecek).
- Harf üretici: Türkçe harf frekansına göre ağırlıklı; her setin en az bir 6+ harfli çözümü olmalı.

## 10. MVP kapsamı (v1.0)

Dahil:
- Sayı ve kelime turu, 4 turluk oyun
- Günlük mod + genel ve il sıralaması + paylaşım
- Pratik modu (bilgisayara karşı)
- Canlı düello (eşleştirme) + arkadaşla özel oda
- Oyuncu kartı (takma ad, il)
- Aslan İnteraktif açılış intro’su (uygulama alta alınıp açıldığında tekrar gösterilmez)
- Türkçe arayüz

Hariç (1.1+): asenkron meydan okuma, final turu, turnuva, arkadaş listesi, reklam ve satın alma, başka diller.

## 11. Yol haritası

| Faz | İçerik | Süre |
|---|---|---|
| 0 | İsim, sözlük lisansı, Supabase projesi, depo kurulumu | 2–3 gün |
| 1 | Web prototipinde kelime turunu ekle, kuralları oynanarak sabitle | 1 hafta |
| 2 | Expo + Skia istemci: sayı ve kelime turu, pratik modu | 1,5 hafta |
| 3 | Supabase: günlük bulmaca cron, skor doğrulama, sıralama, il ligi | 1 hafta |
| 4 | Canlı düello: eşleştirme, oda, kopma/yeniden bağlanma | 1,5 hafta |
| 5 | Kapalı beta (Google Play), arkadaş testi, denge ayarı | 1–2 hafta |
| 6 | Mağaza yayını (Android + iOS) | — |

Toplam: yaklaşık 7–9 hafta.

## 12. Ölçütler

- D1 / D7 tutma (hedef: %40 / %15)
- Günlük modu oynayanların paylaşım oranı (hedef: %10+)
- Düello başına ortalama süre, rövanş oranı
- Eşleştirme bekleme süresi (hedef: < 15 sn; yoksa bota düş)

## 13. Riskler

| Risk | Önlem |
|---|---|
| Program adı / marka itirazı | Ad ve görsel kimlik tamamen özgün; açıklamada bağlantı olmadığı yazılır |
| Sözlük lisansı | Yayından önce lisans doğrulaması; gerekirse kendi listemiz |
| Düelloda yetersiz oyuncu | Bekleme süresi aşılırsa adı belirtilmiş bot rakip; günlük mod tek başına da değerli |
| Hile (çözücü) | Puan sunucuda; düelloda süre baskısı; şüpheli skor işaretleme |
| Yaş hedefleme | Play Console hedef kitlesi 13+ olarak doğru seçilir (çocuk dahil edilmez) |
| KVKK | Sadece takma ad ve il; aydınlatma metni ve hesap silme seçeneği |

## 14. Açık kararlar

- [ ] Kesin isim
- [ ] Sayı turu süresi: 60 mı 90 mı?
- [ ] Kelime turunda harfleri oyuncu mu seçsin, sistem mi?
- [ ] Bot rakip yayında olsun mu, adı açıkça “bot” mu yazsın?
- [ ] iOS ilk sürümde mi, 1.1’de mi?

## 15. Mevcut durum

- Sayı turu web prototipi hazır (Oyun Laboratuvarı #10): üretici, çözücü, 5 tur, sıralama.
- Sıradaki adım: prototipe kelime turunu ve düello akışını eklemek.
